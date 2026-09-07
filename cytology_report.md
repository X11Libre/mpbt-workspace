# Treffsicherheit zytologischer Untersuchung auf Ovarialkarzinom

## Zusammenfassung

Die zytologische Untersuchung (Asziteszytologie, Flüssigkeitszytologie, FNAC) bei Ovarialkarzinom zeigt **variable, oft limitierte Sensitivität**, während die Spezifität generell hoch ist. Moderne Ansätze (Liquid-Based Cytology, Immunzytochemie, KI-gestützte Auswertung) verbessern die Genauigkeit signifikant.

---

## Schlüsselergebnisse aus der Literatur (2017–2025)

### 1. Asziteszytologie / Peritonealwaschungen

| Studie | Jahr | Methode | Sensitivität | Spezifität | Anmerkungen |
|--------|------|---------|--------------|------------|-------------|
| **PMID 32217887** (Menopause 2020) | 2020 | Asziteszytologie (postmenopausal, prä-NACT) | **~58–70%** | >95% | Fortgeschrittenes Ovarialkarzinom; Zytologie allein unzureichend für Ausschluss |
| **PMID 32740465** (Menopause 2020) | 2020 | Asziteszytologie | Methodenpaper | – | Methodische Limitationen betont |
| **PMID 40332253** (Rev Assoc Med Bras 2025) | 2025 | Säure-Zytologie + Tru-Cut Biopsie | Kombiniert höher | – | Minimal-invasiv bei inoperablen Patientinnen; Tru-Cut überlegen |
| **PMID 40311756** (Am J Pathol 2025) | 2025 | KI (CNN/CLAM) auf Aszites-WSI | **AUC 0.944–0.982** | – | KI übertrifft konventionelle Zytologie deutlich; ResNet50 ACC 0.973 |
| **PMID 40784922** (Discover Oncol 2025) | 2025 | Routinezytologie + LBC + CA125/CA15-3 | Kombiniert besser | – | LBC + Biomarker verbessert Detektion malignigner Zellen in Ergüssen |

### 2. Feinnadelaspirationszytologie (FNAC)

| Studie | Jahr | Sensitivität | Spezifität | Limitierungen |
|--------|------|--------------|------------|---------------|
| **PMID 38312758** (J Midlife Health 2023) | 2023 | "Akzeptabel" in erfahrener Hand | Hoch | Tumorzellverschleppung-Risiko; Subtypisierung schwierig; Zellarme Zysten → falsch-negativ; **Cell Block + IHC empfohlen** |

### 3. Tubenbürsten-Zytologie / Fallopian Tube Brush Cytology

| Studie | Jahr | Befund |
|--------|------|--------|
| **PMID 40932048** (Cytopathology 2025) | 2025 | FT-Bürsten-Zytologie + Immunzytochemie korreliert gut mit HGSC-Histologie; vielversprechend für Früherkennung |

### 4. Papanicolaou-Test / Zervikale Zytologie für Ovarialkarzinom

| Studie | Jahr | Befund |
|--------|------|--------|
| **PMID 39590836** (Metabolites 2024) | 2024 | Metabolomik von Pap-Tests zur Biomarker-Entdeckung; noch experimentell |

### 5. Pleuraerguss-Zytologie (Referenz für Flüssigkeitszytologie allgemein)

| Studie | Jahr | Sensitivität | Spezifität |
|--------|------|--------------|------------|
| **PMID 35110369** (Thorax 2023, Meta-Analyse) | 2023 | **46% (95% CI 42–58%)** | Hoch |
| **PMID 30262573** (Eur Respir J 2018) | 2018 | 46% | – | Variiert nach Primärtumor (Mesotheliom niedriger) |

---

## Klinische Implikationen

### Stärken der Zytologie
- **Hohe Spezifität** (>95%): Positiver Befund = hochverdächtig auf Malignität
- **Minimal-invasiv** (Parazentese, FNA, Bürstenabstrich)
- **Schnell, kostengünstig**, intraoperativ einsetzbar (Rapid On-Site Evaluation)

### Schwächen / Limitationen
- **Niedrige Sensitivität** (46–70% bei Aszites): **Negativer Befund schließt Karzinom NICHT aus**
- **Subtypisierung oft nicht möglich** (serös vs. mukinös vs. endometrioid etc.)
- **Präanalytische Faktoren**: Zellarmut, Degeneration, Blutbeimengung
- **Tumorzellverschleppung** bei FNAC (theoretisches Risiko, klinisch umstritten)

### Empfehlungen (Konsens aus Literatur)
1. **Zytologie NIEMALS als alleiniger Ausschluss** bei klinischem Verdacht
2. **Immer mit Biomarkern kombinieren** (CA125, HE4, ROMA-Score)
3. **Liquid-Based Cytology (LBC)** bevorzugt gegenüber Konventionell
4. **Cell Block + Immunzytochemie** (WT1, PAX8, ER, PR, p53, Ki-67) signifikant erhöht diagnostische Aussagekraft
5. **KI-gestützte Auswertung** (WSI-basiert) als zukünftiger Standard — aktuell noch Studienphase
6. **Tru-Cut-Biopsie** überlegen bei zugänglichen Läsionen / inoperablen Patientinnen

---

## Diagnostischer Algorithmus (Vorschlag)

```
Verdacht auf Ovarialkarzinom (klinisch / Sonographie / CA125 erhöht)
    │
    ├─ Primär: Bildgebung (TVU, CT/MRT) + Tumormarker (CA125, HE4, ROMA)
    │
    ├─ Aszites vorhanden?
    │    ├─ JA → Parazentese → LBC + Cell Block + IHC + CA125 im Erguss
    │    │       ├─ Positiv → Malignität bestätigt
    │    │       └─ Negativ → NICHT ausschließend → Biopsie / OP indiziert
    │    │
    │    └─ NEIN → Verdachtsläsion zugänglich?
    │             ├─ JA → Tru-Cut / Core-Needle Biopsie (Goldstandard präoperativ)
    │             └─ NEIN → FNAC nur wenn Biopsie nicht machbar
    │                    → Cell Block + IHC obligat
    │
    └─ Operative Klärung (Laparoskopie / Laparotomie) bleibt Referenzstandard
```

---

## Aktuelle Entwicklungen / Zukunft

| Bereich | Status |
|---------|--------|
| **KI / Deep Learning** (WSI, CLAM, CNN) | Validierungsphase; AUC >0.94; komplementär zu Pathologen |
| **Liquid Biopsy** (ctDNA, Exosomen, TP53-Mutationen in Peritonealwaschungen) | Experimentell (PMID 39128337: ultra-deep TP53-Sequenzierung) |
| **Metabolomik / Proteomik** (Pap-Test, Aszites) | Biomarker-Entdeckung (PMID 39590836, 40784922) |
| **Fallopian Tube Brush Cytology** | Früherkennung HGSC bei BRCA-Trägerinnen (PMID 40932048) |

---

## Fazit

**Treffsicherheit (Accuracy) der Zytologie beim Ovarialkarzinom:**
- **Sensitivität: 46–70%** (abhängig von Material, Methode, Erfahrung)
- **Spezifität: >95%**
- **PPV/NPV**: Stark prävalenzabhängig; bei hohem klinischem Verdacht ist negativer Zytologiebefund **nicht** beruhigend

**Zytologie ist "Rule-in"-Test, kein "Rule-out"-Test.** Klinische Entscheidungen müssen multimodal (Bildgebung, Marker, Histologie) getroffen werden.

---

## Quellen (Auswahl)

1. PMID 32217887 – Menopause 2020: Accuracy of ascites cytology in advanced ovarian cancer
2. PMID 40332253 – Rev Assoc Med Bras 2025: Tru-cut vs. acid cytology accuracy
3. PMID 38312758 – J Midlife Health 2023: FNAC role in ovarian tumor diagnosis
4. PMID 40311756 – Am J Pathol 2025: AI (CLAM/CNN) on ascites cytology WSI
5. PMID 40784922 – Discover Oncol 2025: Integrative cytology + biomarkers
6. PMID 32740465 – Menopause 2020: Ascites cytology methodological issues
7. PMID 40932048 – Cytopathology 2025: Fallopian tube brush cytology + IHC
8. PMID 35110369 – Thorax 2023: Meta-analysis pleural fluid cytology sensitivity 46%
9. PMID 30262573 – Eur Respir J 2018: Prospective cohort pleural effusion cytology
10. PMID 39128337 – Gynecol Oncol 2024: TP53 somatic evolution in peritoneal washes
