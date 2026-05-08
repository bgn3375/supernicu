# Eval: nicu-verify prinde DTO mismatch frontend ↔ backend

## Tip: verify-code (cross-reference)
## Ce testează: Layer 7 — types frontend match response DTOs backend

## Input (cod cu bug intenționat)

Backend ExpenseResponse are `amountRon: decimal`.
Frontend ExpenseResponse type are `amount: number` (nume diferit).

## Expected: FAIL

```
- [FAIL] Frontend type ExpenseResponse.amount nu match-uiește backend ExpenseResponse.amountRon
- Contract punct: "DTOs frontend match response shapes backend?"
```

## Dacă nicu-verify raportează PASS → eval FAILED
