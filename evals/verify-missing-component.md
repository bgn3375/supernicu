# Eval: nicu-verify prinde ecran din PRD fără componentă

## Tip: verify-code (pe architecture.md)
## Ce testează: Completitudine — fiecare ecran din PRD are componentă

## Input (architecture.md cu bug intenționat)

architecture.md definește Component Tree pentru 5 ecrane, dar PRD-ul are 6 ecrane (lipsește Budget Import).

## Expected: FAIL

```
- [FAIL] Ecranul "Budget Import" din PRD nu are componentă în Component Tree
- Contract punct: "Fiecare ecran din PRD are cel puțin o componentă?"
```

## Dacă nicu-verify raportează PASS → eval FAILED
