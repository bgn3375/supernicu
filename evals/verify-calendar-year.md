# Eval: nicu-verify prinde an calendaristic în loc de an fiscal

## Tip: verify-code
## Ce testează: An fiscal Aug-Aug, nu Jan-Dec

## Input (cod cu bug intenționat)

```typescript
const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
// 12 luni calendaristice, ar trebui 13 luni Aug-Aug
```

## Expected: FAIL

```
- [FAIL] Tabelul P&L folosește 12 luni calendaristice (Jan-Dec)
- Contract punct: "Perioadele folosesc an fiscal Aug-Aug (13 luni)?"
- Expected: 13 coloane Aug, Sep, Oct, Nov, Dec, Jan, Feb, Mar, Apr, May, Jun, Jul, Aug
```

## Dacă nicu-verify raportează PASS → eval FAILED
