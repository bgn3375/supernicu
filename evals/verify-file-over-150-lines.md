# Eval: nicu-verify prinde fișier peste 150 linii

## Tip: verify-code
## Ce testează: Max 150 linii per fișier

## Input (cod cu bug intenționat)

Un fișier cu 200+ linii (controller mare cu toate action methods inline).

## Expected: FAIL

```
- [FAIL] ExpenseController.cs are 210 linii (max 150)
- Contract punct: "Fiecare fișier e sub 150 linii?"
```

## Dacă nicu-verify raportează PASS → eval FAILED
