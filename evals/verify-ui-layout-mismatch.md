# Eval: nicu-verify (UI mode) prinde diferență de layout

## Tip: verify-ui
## Ce testează: Implementarea arată ca prototipul

## Input

- Screenshot prototip: tabel P&L cu luna curentă evidențiată vizual, 13 coloane
- Screenshot implementare: tabel P&L fără highlight pe luna curentă, 12 coloane

## Expected: MISMATCH

```
- [MISMATCH] pnl-table-realizat:
  - Luna curentă nu are highlight vizual (prototipul are)
  - Tabelul are 12 coloane (Jan-Dec), prototipul are 13 (Aug-Aug)
```

## Dacă nicu-verify raportează MATCH → eval FAILED
