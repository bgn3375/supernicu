# Eval: nicu-verify prinde tabel fără team_id

## Tip: verify-code
## Ce testează: Regula #1 — fiecare tabel are team_id

## Input (cod cu bug intenționat)

```sql
CREATE TABLE expenses (
  id CHAR(36) NOT NULL,
  amount_ron DECIMAL(18,2) NOT NULL,
  currency VARCHAR(3) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);
```

## Expected: FAIL

```
- [FAIL] Tabelul "expenses" nu are coloana team_id
- Contract punct: "Fiecare tabel are team_id CHAR(36) NOT NULL?"
```

## Dacă nicu-verify raportează PASS → eval FAILED
