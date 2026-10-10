#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright © 2026 Enrico Weigelt, metux IT consult
#
# starfleet-testbed.sh — manage a fully isolated starfleetctl testbed.
#
# The testbed is a SEPARATE workspace under _WORK_/ that lives INSIDE the real
# workspace (so ships keep their normal file permissions) but is completely
# decoupled: its own .starfleet-ai/ (conf/var/dashboard/bus), its own web and
# model-proxy ports, and its own bus identity. It is used to exercise a
# starfleetctl build — and, above all, the model-proxy — BEFORE pushing and
# bootstrapping into the live fleet.
#
# Why: the fleet now runs entirely through the model-proxy, so a proxy bug can
# take the whole fleet down. Test it in isolation first.
#
# Subcommands:
#   create    create/reset the testbed root, install the binary, write conf,
#             run bootstrap --fix + sop reindex
#   sync      rebuild the dev clone, reinstall the binary, re-run bootstrap --fix
#             (keeps the testbed conf)
#   start     start testbed daemons (model-proxy, web, timer worker)
#   stop      stop testbed daemons
#   restart   stop + start
#   status    show daemon + port status
#   smoke     run isolation + health checks (exit 0 = healthy)
#   destroy   stop + remove the testbed root completely (back to zero)
#   shell     open a shell inside the testbed root with the env set
#
# Env overrides: TESTBED_ROOT, DEV_CLONE, WEB_PORT, PROXY_PORT, TB_SHIP_ID
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIVE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TESTBED_ROOT="${TESTBED_ROOT:-$LIVE_ROOT/_WORK_/starfleet-testbed}"
DEV_CLONE="${DEV_CLONE:-$LIVE_ROOT/_WORK_/starfleetctl/sources/starfleetctl}"
LIVE_CONF="${LIVE_CONF:-$LIVE_ROOT/.starfleet-ai/conf}"

WEB_PORT="${WEB_PORT:-18080}"
PROXY_PORT="${PROXY_PORT:-18443}"
TB_SHIP_ID="${TB_SHIP_ID:-Testbed}"

TB_BIN="$TESTBED_ROOT/.starfleet-ai/bin/starfleetctl"

log() { printf 'testbed: %s\n' "$*" >&2; }
die() { printf 'testbed: ERROR: %s\n' "$*" >&2; exit 1; }

# Safety: never operate on the live workspace root.
[[ "$TESTBED_ROOT" == *"/_WORK_/"* ]] || die "TESTBED_ROOT must live under _WORK_/ (got: $TESTBED_ROOT)"
[[ "$WEB_PORT" != "8080" ]] || die "WEB_PORT must differ from the live 8080"
[[ "$PROXY_PORT" != "8443" ]] || die "PROXY_PORT must differ from the live 8443"

# Run a starfleetctl command inside the testbed root (cwd + env), so nothing
# leaks into the live workspace. `bootstrap` in particular resolves its root
# from cwd, NOT from MPBT_WORKSPACE_ROOT (cmd/starfleetctl/main.go).
tb() { ( cd "$TESTBED_ROOT" && MPBT_WORKSPACE_ROOT="$TESTBED_ROOT" STARFLEET_SHIP_ID="$TB_SHIP_ID" "$TB_BIN" "$@" ); }

# tb_bg runs a daemon-spawning subcommand with stdio detached. The daemonizer
# forks a child that INHERITS our stdout/stderr (only stdin is nil'd); if that
# is a pipe, the pipe stays open as long as the daemon lives and the caller
# blocks forever. Redirecting to a file (not a pipe) fixes that.
tb_bg() {
    mkdir -p "$TESTBED_ROOT/.starfleet-ai/var/log"
    ( cd "$TESTBED_ROOT" && MPBT_WORKSPACE_ROOT="$TESTBED_ROOT" STARFLEET_SHIP_ID="$TB_SHIP_ID" "$TB_BIN" "$@" \
        </dev/null >>"$TESTBED_ROOT/.starfleet-ai/var/log/testbed-boot.log" 2>&1 )
}

install_binary() {
    [[ -d "$DEV_CLONE" ]] || die "dev clone not found: $DEV_CLONE"
    if [[ "${1:-}" == "--build" || ! -x "$DEV_CLONE/starfleetctl" ]]; then
        log "building dev clone ($DEV_CLONE)"
        ( cd "$DEV_CLONE" && make all )
    fi
    [[ -x "$DEV_CLONE/starfleetctl" ]] || die "binary missing: $DEV_CLONE/starfleetctl"
    mkdir -p "$TESTBED_ROOT/.starfleet-ai/bin"
    rm -f "$TB_BIN"   # rm avoids text-file-busy if a testbed daemon still holds it
    cp "$DEV_CLONE/starfleetctl" "$TB_BIN"
    chmod +x "$TB_BIN"
    log "installed binary: $("$TB_BIN" version 2>/dev/null || git -C "$DEV_CLONE" log --oneline -1)"
}

write_conf() {
    mkdir -p "$TESTBED_ROOT/.starfleet-ai/conf"

    # web.yaml — own port + own identity (never collides with the live console)
    # NOTE the `web:` wrapper: config.Load reads the top-level key `web`.
    # A flat file is silently ignored and falls back to the default (8080).
    cat > "$TESTBED_ROOT/.starfleet-ai/conf/web.yaml" <<EOF
# testbed web config (managed by scripts/starfleet-testbed.sh)
web:
  listen_addr: "127.0.0.1:$WEB_PORT"
  autostart_enabled: false
  pid_file: ".starfleet-ai/var/web.pid"
  log_file: ".starfleet-ai/var/log/web.log"
  ship_id: "$TB_SHIP_ID"
  ship_handle: "$TB_SHIP_ID"
  terminal_rows: 60
  terminal_cols: 120
  terminal_scrollback: 10000
EOF

    # fleet.yaml — test identity, NO standing ships (must not spawn real ships)
    cat > "$TESTBED_ROOT/.starfleet-ai/conf/fleet.yaml" <<EOF
# testbed fleet identity (managed by scripts/starfleet-testbed.sh)
fleet:
  flagship: "$TB_SHIP_ID"
EOF

    # model-proxy.yaml — copy the live provider/strategy config (so the proxy
    # under test is representative), then override:
    #   * listen_addr  -> the testbed port
    #   * health interval -> "0s" DISABLED. The background health loop probes
    #     ALL ~130 models in parallel (parallel=4) against the SAME upstreams
    #     with the SAME API keys. A second instance doubles that probe load and
    #     trips upstream rate limits, which surfaces in the LIVE fleet as
    #     "stream ended without [DONE]" / "Cannot connect to API". The testbed
    #     proxy must therefore stay quiet. (Assumes the only `interval:` key is
    #     the health one — verified against the live conf.)
    if [[ -f "$LIVE_CONF/model-proxy.yaml" ]]; then
        sed -e "s|^\([[:space:]]*listen_addr:\).*|\1 \"127.0.0.1:$PROXY_PORT\"|" \
            -e "s|^\([[:space:]]*interval:\).*|\1 \"0s\"|" \
            "$LIVE_CONF/model-proxy.yaml" \
            > "$TESTBED_ROOT/.starfleet-ai/conf/model-proxy.yaml"
    else
        cat > "$TESTBED_ROOT/.starfleet-ai/conf/model-proxy.yaml" <<EOF
model_proxy:
  listen_addr: "127.0.0.1:$PROXY_PORT"
EOF
    fi
    # Validate: a broken/empty model-proxy.yaml silently falls back to the
    # DEFAULT listen address (127.0.0.1:8443 = the LIVE proxy). Then `model-proxy
    # stop` would kill the live proxy and autostart would consider it "already
    # running". Refuse to proceed in that case.
    grep -q "127.0.0.1:$PROXY_PORT" "$TESTBED_ROOT/.starfleet-ai/conf/model-proxy.yaml" \
        || die "model-proxy.yaml does not bind :$PROXY_PORT — refusing (would collide with the live proxy)"
    grep -q "127.0.0.1:$WEB_PORT" "$TESTBED_ROOT/.starfleet-ai/conf/web.yaml" \
        || die "web.yaml does not bind :$WEB_PORT"

    log "wrote conf (web :$WEB_PORT, proxy :$PROXY_PORT, ship $TB_SHIP_ID)"
}

cmd_create() {
    log "creating testbed at $TESTBED_ROOT"
    mkdir -p "$TESTBED_ROOT/scripts"
    [[ -f "$TESTBED_ROOT/scripts/README.txt" ]] || echo "testbed landmark (workspaceRoot discovery)" > "$TESTBED_ROOT/scripts/README.txt"
    [[ -f "$TESTBED_ROOT/.gitignore" ]] || : > "$TESTBED_ROOT/.gitignore"   # non-git tree; silences bootstrap's gitignore check
    [[ -f "$TESTBED_ROOT/starfleet-bootstrap" ]] || cp "$LIVE_ROOT/starfleet-bootstrap" "$TESTBED_ROOT/starfleet-bootstrap" 2>/dev/null || true
    install_binary
    write_conf
    tb bootstrap --fix   || true
    tb sop reindex       || true
    log "created — next: $0 start"
}

cmd_sync() {
    log "syncing testbed from dev clone"
    install_binary --build
    write_conf
    tb bootstrap --fix || true
    tb sop reindex     || true
    log "synced"
}

start_web() {
    # Do NOT use `web autostart` here: it calls cleanupWrongPortProcesses(),
    # which kills ANY starfleetctl `web start` process on a port other than the
    # configured one — that would kill the live console on :8080. Start a
    # detached foreground instance bound to the testbed port instead.
    if curl -s -m2 -o /dev/null "http://127.0.0.1:$WEB_PORT/" 2>/dev/null; then
        log "web already running on :$WEB_PORT"
        return 0
    fi
    mkdir -p "$TESTBED_ROOT/.starfleet-ai/var/log"
    # setsid --fork: the parent exits immediately, the daemon is reparented to
    # init and fully detached (a plain `setsid ... &` got reaped here).
    ( cd "$TESTBED_ROOT" && MPBT_WORKSPACE_ROOT="$TESTBED_ROOT" \
        setsid --fork "$TB_BIN" web start --addr "127.0.0.1:$WEB_PORT" \
        </dev/null >>"$TESTBED_ROOT/.starfleet-ai/var/log/web.log" 2>&1 )
    sleep 1
}

cmd_start() {
    install_binary   # ensure binary present (no rebuild)
    tb_bg model-proxy autostart
    start_web
    tb_bg timer worker autostart 2>/dev/null || true
    log "started (model-proxy :$PROXY_PORT, web :$WEB_PORT)"
}

cmd_stop() {
    [[ -x "$TB_BIN" && -d "$TESTBED_ROOT/.starfleet-ai" ]] || { log "nothing to stop"; return 0; }
    tb web stop         || true
    tb model-proxy stop || true
    tb timer worker stop 2>/dev/null || true
    # `web start` writes no PID file (only autostart does), so `web stop` may
    # miss it. Kill any web proc bound to the TESTBED port only — the
    # port-scoped match can never hit the live console on :8080.
    pkill -f "web start --addr 127.0.0.1:$WEB_PORT" 2>/dev/null || true
    log "stopped"
}

cmd_status() {
    echo "testbed root: $TESTBED_ROOT"
    echo "web  port:    $WEB_PORT"
    echo "proxy port:   $PROXY_PORT"
    echo "--- listeners ---"
    ss -ltnp 2>/dev/null | grep -E ":$WEB_PORT |:$PROXY_PORT " || echo "(no testbed listeners)"
    echo "--- model-proxy ---"
    tb model-proxy status || true
}

cmd_smoke() {
    local rc=0
    echo "== smoke: $TESTBED_ROOT =="

    # web HTTP
    local code
    code=$(curl -s -m3 -o /dev/null -w '%{http_code}' "http://127.0.0.1:$WEB_PORT/" || echo 000)
    echo "web  http :$WEB_PORT -> $code"
    [[ "$code" == "200" ]] || { echo "  FAIL: web not 200"; rc=1; }

    # JS parse of the served SPA (a 200 alone proves nothing)
    if command -v node >/dev/null 2>&1; then
        local nq
        nq=$(curl -s "http://127.0.0.1:$WEB_PORT/" | grep -c "'''" || true)
        echo "web  js   ''' count -> $nq (must be 0)"
        [[ "$nq" == "0" ]] || { echo "  FAIL: ''' in served page"; rc=1; }
        curl -s "http://127.0.0.1:$WEB_PORT/" \
          | python3 -c "import re,sys; print(re.findall(r'<script[^>]*>(.*?)</script>', sys.stdin.read(), re.S)[0])" 2>/dev/null \
          | node --check 2>/dev/null && echo "web  js   node --check OK" || { echo "  FAIL: served JS does not parse"; rc=1; }
    fi

    # model-proxy health (endpoint is /healthz)
    local pcode
    pcode=$(curl -s -m5 -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PROXY_PORT/healthz" || true)
    echo "proxy /healthz :$PROXY_PORT -> $pcode"
    [[ "$pcode" == "200" ]] || { echo "  FAIL: proxy not healthy on :$PROXY_PORT"; rc=1; }

    # comms isolation — must only show the testbed identity
    echo "--- comms board (must be testbed-only) ---"
    tb comms board || true

    echo "== smoke rc=$rc =="
    return $rc
}

cmd_destroy() {
    log "destroying testbed at $TESTBED_ROOT"
    cmd_stop || true
    rm -rf "$TESTBED_ROOT"
    log "removed"
}

usage() {
    sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
}

cmd="${1:-}"; shift || true
case "$cmd" in
    create)  cmd_create "$@" ;;
    sync)    cmd_sync "$@" ;;
    start)   cmd_start "$@" ;;
    stop)    cmd_stop "$@" ;;
    restart) cmd_stop; cmd_start ;;
    status)  cmd_status "$@" ;;
    smoke)   cmd_smoke "$@" ;;
    destroy) cmd_destroy "$@" ;;
    shell)   ( cd "$TESTBED_ROOT" && MPBT_WORKSPACE_ROOT="$TESTBED_ROOT" exec "${SHELL:-bash}" ) ;;
    ""|-h|--help|help) usage ;;
    *) die "unknown subcommand: $cmd (try: $0 help)" ;;
esac
