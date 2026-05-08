# Eval: nicu-verify prinde endpoint orfan

## Tip: verify-code (cross-reference)
## Ce testează: Layer 7 — endpoint definit în backend dar neapelat din frontend

## Input (cod cu bug intenționat)

Backend are `POST /api/expenses/duplicate-check` dar nicio server action și nicio componentă nu-l apelează.

## Expected: FAIL

```
- [FAIL] Endpoint POST /api/expenses/duplicate-check definit dar neapelat
- Contract punct: "Zero endpoints orfane (definite dar neapelate)?"
```

## Dacă nicu-verify raportează PASS → eval FAILED
