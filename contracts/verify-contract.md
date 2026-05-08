# Contract: nicu-verify

Verifică output-ul oricărui sub-agent contra contractului lui. Spawn-uit fresh de fiecare dată (context curat).

## Două moduri de operare

### Mod 1: verify-code
Verifică documente sau cod contra unui checklist de contract.

**Primește:**
- Output-ul sub-agentului (fișier sau listă de fișiere)
- Contractul sub-agentului (din `contracts/`)
- Skill-urile relevante (pentru pattern compliance)

**Produce:**
```
## Verify Report

Status: PASS | FAIL
Checklist: 8/8 | 6/8

### Rezultate per punct
- [PASS] Fiecare tabel are team_id
- [PASS] Fiecare endpoint are autorizare
- [FAIL] Ecranul "Budget Import" nu are componentă în Component Tree
- [FAIL] Endpoint POST /budgets/import nu are request DTO

### Rezumat
2 puncte failed. Ambele legate de modulul Budget Import.
```

### Mod 2: verify-ui
Compară vizual implementarea cu prototipul.

**Primește:**
- Screenshots prototip (PNG-urile originale de la Bruce)
- URL dev server (pentru a face screenshot la implementare)

**Produce:**
```
## UI Verify Report

Status: MATCH | MISMATCH
Ecrane verificate: 5/5

### Per ecran
- [MATCH] expenses-list — layout, culori, spațiere OK
- [MISMATCH] pnl-table-realizat:
  - Luna curentă nu are highlight teal
  - Header-ul tabelului e aliniat stânga, în prototip e centrat
  - Lipsește hover effect pe coloane
```

## Reguli

- NU repară. Doar raportează.
- NU judecă subiectiv ("codul ar putea fi mai curat"). Verifică doar contra checklist.
- Fiecare FAIL include: ce punct din contract, ce fișier/ecran, ce s-a așteptat vs ce s-a găsit.
- PASS = toate punctele din checklist sunt OK. Un singur FAIL = tot raportul e FAIL.
- Diferențe vizuale acceptabile: font rendering OS-specific, scrollbar style, anti-aliasing.
- Diferențe vizuale inacceptabile: layout, culori, spațiere, elemente lipsă, dimensiuni greșite.

## Brain primește doar

```
nicu-verify: PASS (8/8)
```
sau
```
nicu-verify: FAIL (6/8)
- Budget Import: lipsă componentă + lipsă DTO
```

Maxim 5 rânduri. Brain nu primește raportul complet — doar verdictul și issues-urile.
