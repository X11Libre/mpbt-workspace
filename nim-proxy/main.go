package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"
)

var (
	nimURL           string
	retryAfterStr    string
	proxyPort        string
	logPath          string
	logFile          *os.File
	modelStatusMu    sync.RWMutex
	modelStatus      = make(map[string]ModelStatus)
	fallbackModel    string
	enableAutoSwitch bool
)

type ModelStatus struct {
	Name          string    `json:"name"`
	Server        string    `json:"server"`
	Healthy       bool      `json:"healthy"`
	LastError     string    `json:"last_error,omitempty"`
	LastErrorTime time.Time `json:"last_error_time,omitempty"`
	ErrorCount    int       `json:"error_count"`
	LastSuccess   time.Time `json:"last_success,omitempty"`
}

type ProxyResponse struct {
	Error       string `json:"error,omitempty"`
	RetryAfter  int    `json:"retry_after,omitempty"`
	SwitchModel string `json:"switch_model,omitempty"`
	Reason      string `json:"reason,omitempty"`
}

func main() {
	nimURL = getEnv("NIM_URL", "http://localhost:8000")
	retryAfterStr = getEnv("RETRY_AFTER_SECONDS", "1")
	proxyPort = getEnv("PROXY_PORT", ":8081")
	logPath = getEnv("PROXY_LOG_FILE", "proxy.log")
	fallbackModel = getEnv("FALLBACK_MODEL", "")
	enableAutoSwitch = getEnv("ENABLE_AUTO_SWITCH", "true") == "true"

	var err error
	logFile, err = os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		log.Fatalf("[NIM-SHIELD] Fehler beim Öffnen der Log-Datei: %v", err)
	}
	defer logFile.Close()

	multiWriter := io.MultiWriter(os.Stdout, logFile)
	log.SetOutput(multiWriter)
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)

	http.HandleFunc("/", handleProxy)
	http.HandleFunc("/health", handleHealth)
	http.HandleFunc("/models", handleModels)
	http.HandleFunc("/models/", handleModelStatus)

	log.Printf("[NIM-SHIELD] Schutzschild aktiv auf %s -> %s", proxyPort, nimURL)
	log.Printf("[NIM-SHIELD] OpenCode-Wartezeit bei Fehlern/Abbrüchen: %s Sek.", retryAfterStr)
	log.Printf("[NIM-SHIELD] Logs werden geschrieben nach: %s", logPath)
	log.Printf("[NIM-SHIELD] Fallback-Modell: %s", fallbackModel)
	log.Printf("[NIM-SHIELD] Auto-Switch: %v", enableAutoSwitch)

	if err := http.ListenAndServe(proxyPort, nil); err != nil {
		log.Fatalf("Proxy abgestürzt: %v", err)
	}
}

func handleProxy(w http.ResponseWriter, r *http.Request) {
	startTime := time.Now()
	targetURL := nimURL + r.URL.Path
	if r.URL.RawQuery != "" {
		targetURL += "?" + r.URL.RawQuery
	}

	var bodyBytes []byte
	if r.Body != nil {
		bodyBytes, _ = io.ReadAll(r.Body)
	}

	nimReq, err := http.NewRequest(r.Method, targetURL, bytes.NewBuffer(bodyBytes))
	if err != nil {
		sendRetrySignal(w, "Request-Erstellung fehlgeschlagen: "+err.Error(), r.URL.Path, 0, "")
		return
	}

	for k, v := range r.Header {
		nimReq.Header[k] = v
	}
	if parsed, err := url.Parse(nimURL); err == nil {
		nimReq.Host = parsed.Host
	}

	client := &http.Client{}
	nimResp, err := client.Do(nimReq)

	if err != nil {
		sendRetrySignal(w, "Netzwerkfehler/NIM offline: "+err.Error(), r.URL.Path, 0, "")
		return
	}
	if nimResp != nil && nimResp.StatusCode >= 500 {
		sendRetrySignal(w, "NIM lieferte HTTP "+nimResp.Status, r.URL.Path, 0, "")
		nimResp.Body.Close()
		return
	}
	defer nimResp.Body.Close()

	streamBuffer, readErr := io.ReadAll(nimResp.Body)

	if readErr != nil {
		sendRetrySignal(w, "Streaming Response Error (Abbruch mitten im Satz): "+readErr.Error(), r.URL.Path, 0, "")
		return
	}
	if len(streamBuffer) == 0 {
		sendRetrySignal(w, "Streaming-Fehler: NIM hat einen leeren Stream zurückgegeben", r.URL.Path, 0, "")
		return
	}

	errorDetail, isError := classifyError(streamBuffer)
	if isError {
		switchModel := ""
		if enableAutoSwitch && fallbackModel != "" {
			switchModel = fallbackModel
			modelName := extractModelName(r)
			serverName := extractServerName(r)
			updateModelStatus(modelName, serverName, false, errorDetail)
		}
		sendRetrySignal(w, errorDetail, r.URL.Path, nimResp.StatusCode, switchModel)
		return
	}

	duration := time.Since(startTime)
	log.Printf("[ERFOLG] %s %s verarbeitet in %v (%d Bytes)", r.Method, r.URL.Path, duration, len(streamBuffer))

	modelName := extractModelName(r)
	serverName := extractServerName(r)
	if modelName != "" {
		updateModelStatus(modelName, serverName, true, "")
	}

	for k, v := range nimResp.Header {
		w.Header()[k] = v
	}
	w.WriteHeader(nimResp.StatusCode)
	w.Write(streamBuffer)
}

func classifyError(body []byte) (string, bool) {
	bodyStr := string(body)
	bodyLower := strings.ToLower(bodyStr)

	// ZEN specific errors
	if strings.Contains(bodyLower, "zen-ratelimit") ||
		strings.Contains(bodyLower, "worker local total request limi") {
		return "zen-ratelimit: Worker local total request limit exceeded", true
	}
	if strings.Contains(bodyLower, "nim-overload") {
		return "nim-overload: NIM server overloaded", true
	}

	// Generic rate limit / quota errors
	quotaPatterns := []string{
		"quota", "rate limit", "too many requests", "429",
		"usage limit", "out of quota", "exceeded", "daily limit",
		"monthly limit", "billing limit",
	}
	for _, pattern := range quotaPatterns {
		if strings.Contains(bodyLower, pattern) {
			return "rate-limit/quota: " + bodyStr, true
		}
	}

	// Stream errors
	streamPatterns := []string{
		"streaming response failed", "stream interrupted", "response stream",
		"connection closed", "broken pipe", "unexpected eof", "stream closed",
		"resourceexhausted", "stream error",
	}
	for _, pattern := range streamPatterns {
		if strings.Contains(bodyLower, pattern) {
			return "stream-error: " + bodyStr, true
		}
	}

	// JSON error format
	if strings.Contains(bodyStr, `"error"`) && strings.Contains(bodyStr, `"message"`) {
		return "NIM-Fehler im Stream: " + bodyStr, true
	}

	return "", false
}

func extractModelName(r *http.Request) string {
	if model := r.Header.Get("X-Model"); model != "" {
		return model
	}
	if model := r.Header.Get("X-Model-ID"); model != "" {
		return model
	}
	// Try to extract from JSON body
	var reqBody map[string]interface{}
	if r.Body != nil {
		bodyBytes, _ := io.ReadAll(r.Body)
		r.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
		if err := json.Unmarshal(bodyBytes, &reqBody); err == nil {
			if model, ok := reqBody["model"].(string); ok {
				return model
			}
		}
	}
	return ""
}

func extractServerName(r *http.Request) string {
	if server := r.Header.Get("X-Provider"); server != "" {
		return server
	}
	if server := r.Header.Get("X-Provider-ID"); server != "" {
		return server
	}
	return ""
}

func updateModelStatus(model, server string, healthy bool, errMsg string) {
	modelStatusMu.Lock()
	defer modelStatusMu.Unlock()

	key := model
	if key == "" {
		key = "unknown"
	}
	if server != "" {
		key = server + "/" + key
	}

	status := modelStatus[key]
	if model != "" {
		status.Name = model
	}
	if server != "" {
		status.Server = server
	}
	status.Healthy = healthy
	if errMsg != "" {
		status.LastError = errMsg
		status.LastErrorTime = time.Now()
		status.ErrorCount++
	} else {
		status.LastSuccess = time.Now()
	}
	modelStatus[key] = status
}

func getModelStatus(model, server string) *ModelStatus {
	modelStatusMu.RLock()
	defer modelStatusMu.RUnlock()

	key := model
	if server != "" {
		key = server + "/" + key
	}
	if status, ok := modelStatus[key]; ok {
		return &status
	}
	return nil
}

func sendRetrySignal(w http.ResponseWriter, reason string, path string, statusCode int, switchModel string) {
	retryAfter := 1
	if v, err := parseRetryAfter(retryAfterStr); err == nil {
		retryAfter = v
	}

	log.Printf("[RETTUNG] Fehler abgefangen auf %s! Grund: %s. Sende HTTP 429 (Retry-After: %d)", path, reason, retryAfter)

	w.Header().Set("Retry-After", retryAfterStr)
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-NIM-Shield", "true")
	w.WriteHeader(http.StatusTooManyRequests)

	resp := ProxyResponse{
		Error:      "transient_error",
		RetryAfter: retryAfter,
		Reason:     reason,
	}
	if switchModel != "" {
		resp.SwitchModel = switchModel
	}
	json.NewEncoder(w).Encode(resp)
}

func parseRetryAfter(s string) (int, error) {
	s = strings.TrimSpace(s)
	if strings.HasSuffix(s, "s") {
		s = strings.TrimSuffix(s, "s")
	}
	var v int
	_, err := fmt.Sscanf(s, "%d", &v)
	return v, err
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"status":       "ok",
		"proxy":        "nim-shield",
		"version":      "2.0.0",
		"fallback":     fallbackModel,
		"auto_switch":  enableAutoSwitch,
		"upstream":     nimURL,
	})
}

func handleModels(w http.ResponseWriter, r *http.Request) {
	modelStatusMu.RLock()
	defer modelStatusMu.RUnlock()

	models := make([]ModelStatus, 0, len(modelStatus))
	for _, s := range modelStatus {
		models = append(models, s)
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(models)
}

func handleModelStatus(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/models/"), "/")
	if len(parts) < 1 || parts[0] == "" {
		http.NotFound(w, r)
		return
	}
	model := parts[0]
	server := ""
	if len(parts) > 1 {
		server = parts[1]
	}

	if status := getModelStatus(model, server); status != nil {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(status)
		return
	}
	http.NotFound(w, r)
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}