# task-yaml-configuration-per-web-editierbar-machen

**Status:** ✅ **done**

**Description:** yaml configuration per web editierbar machen

**Problem:** YAML-Konfigurationsdateien (project.yaml, fleet.yaml, ship-names.yaml, models.yaml, web.yaml etc.) sollten im Web-UI bearbeitbar sein. WICHTIG: Beim Speichern dürfen vorhandene Kommentare in den YAML-Dateien NICHT zerstört werden.

**Lösung:** 
1. **Web UI (index.html)**: 
   - "Bearbeiten" Button im File-Viewer hinzugefügt
   - Editor-Modal mit Textarea für YAML-Content
2. **Backend API (web.go)**: 
   - Neuer Endpoint `POST /api/files/save` mit JSON `{path, content}`
   - Verwendet `gopkg.in/yaml.v3` für Round-Trip-Parsing mit Kommentar-Erhaltung
   - `saveYAMLWithComments()` lädt Original mit Kommentaren, merged neue Werte, schreibt zurück
   - `mergeYAMLNodes()` rekursiver Merge der YAML-Nodes mit Kommentar-Erhaltung
   - Für non-YAML Files: direktes Speichern
3. **Deployment**: Build + bootstrap passed

**Files changed:**
- `internal/web/web.go` — apiFileSave, saveYAMLWithComments, mergeYAMLNodes, yaml.v3 import
- `internal/web/index.html` — Edit Button, Editor Modal, fileEdit/fileSave/fileCloseEditor JS functions

**Verified:** Build + bootstrap passed, deployed.