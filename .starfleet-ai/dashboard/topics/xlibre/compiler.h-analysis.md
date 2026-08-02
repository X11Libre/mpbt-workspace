Title: "compiler.h: Analyse abgeschlossen — Subtasks bereit"
Category: active
Kind: "task"
Status: "analysis-done"
Assigned-To: "Saratoga"
Tags: "xlibre,sdk-cleanup,compiler.h"
Slug: compiler.h-analysis

## compiler.h Analyse (v0.1 — 1021 Zeilen)

Was public bleiben muß (von Treibern referenziert):

1. **Port-I/O: inb/outb/inw/outw/inl/outl** (alle Arch-Zweige)
   - Verwendet von: ark, chips, cirrus, mga, neomagic, ast, vesa, geode,
     mach64, i740, i128, tdfx, trident, xgi, savage, siliconmotion, nv,
     s3virge, sis, vbox, vmware, vmmouse, keyboard
   - NICHT von modernen KMS-Treibern (intel, modesetting, ati/amdgpu, nouveau)
   - ~600 Zeilen, verteilt auf x86, Alpha, SPARC, ARM, PowerPC, nds32
   - SPARC-Varianten nutzen barrier() intern → barrier-Fallbacks bleiben
     transitiv erhalten

2. **slowbcopy_tobus / slowbcopy_frombus** (Zeilen 1006-1017)
   - Verwendet von: mga, sis, vesa (und vgahw intern)
   - Für VGA-Font-Kopien

3. **MMIO_IN8/16/32, MMIO_OUT8/16/32** (Zeilen 920-1004)
   - Verwendet von: chips, tdfx, mga, cirrus, savage, siliconmotion,
     trident, sis, sisusb (per Makro), vgahw, int10
   - Catch-all-Fallback (Zeilen 989-1003) ist die primäre Nutzung
   - Arch-spezifische Varianten (alpha, ppc, sparc, nds32) notwendig

4. **IOPortBase** (Zeile 448) — chips Treiber
   **ioBase** (Zeile 526) — chips Treiber

5. **barrier/mem_barrier/write_mem_barrier** (Zeilen 62-138)
   - Von Treibern nicht direkt genutzt, aber via outb/inb auf SPARC nötig
   - Können nicht weg solange Port-I/O public bleibt

Kann/muß NICHT public bleiben (nur xserver-intern):

6. **xf86ReadMmio8/16/32 + xf86WriteMmio8/16/32** (Einzelfunktionen)
   - Treiber nutzen MMIO_IN/MMIO_OUT Makros, nicht die Einzelfunktionen
   - Sind aber die Basis der MMIO-Makros → können nicht komplett separiert
     werden ohne die Makros umzuschreiben

7. **Nicht mehr relevante Architekturen prüfen:**
   - Alpha: tot (kein Linux-Kernel-Support mehr)
   - nds32: Nische (Andes), nur ein Treiber
   - SPARC: solaris-check ci prüft noch
   - ARM non-Linux: obsolet

Vorschlag weitere Schritte:
   A) compiler.h in funktionale Sektionen aufteilen (barrier.h, portio.h,
      mmio.h, slowbcopy.h) — als neue interne header unter include/ (NICHT
      public SDK)
   B) compiler.h selbst wird zum dünnen Wrapper der die public-Teile
      re-exportiert (oder Treiber inkludieren portio.h direkt)
   C) Arch-Blöcke in eigene header (x86/io.h, ppc/io.h, sparc/io.h, …)
   D) Prüfen ob neuere Compiler builtins __sync_synchronize oder
      __atomic_thread_fence nutzen können statt eigener asm-Barriers
