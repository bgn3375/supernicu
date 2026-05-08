---
name: exe
description: Code execution process skill. How Hands processes a task — read spec, load skills, write code, verify build. Fires on every task execution.
---

# Exe — Task Execution Process

Cum procesează Hands un task de la Brain.

## Flow per task

```
1. Citește task-ul (ce trebuie făcut, ce fișiere)
2. Citește contractul relevant:
   - Backend? → contracts/backend-contract.md
   - Frontend? → contracts/frontend-contract.md
3. Citește skill-urile necesare din skills/
4. Scrie cod urmând pașii din contract, în ordine
5. Verifică build după fiecare fișier
6. Raportează: DONE + lista fișierelor + build status
```

## Reguli

1. **Citește înainte de a scrie.** Contract + skill relevante. Nu scrie din memorie.
2. **Un task la un moment dat.** Termină unul, apoi următorul.
3. **Ordinea din contract e obligatorie.** Backend: 6 pași. Frontend: 6 pași.
4. **Build verde după fiecare fișier.** Roșu = repară înainte de a continua.
5. **Max 150 linii per fișier.** Sparge dacă depășește.
6. **Nu improviza.** Urmează patterns din contract și skills exact.
7. **Nu adăuga features extra.** Doar ce e în architecture.md.
8. **Dacă ceva e ambiguu** → raportează la Brain, nu ghici.

## Skills disponibile (în skills/)

### Process
- `arhi` — structura arhitecturală
- `plan` — task breakdown
- `db` — MariaDB schema + NHibernate mappings

### Domain (selectează pe baza task-ului)
- `auth` — Magic Link, Google OAuth, JWT, 5 roluri
- `multitenant` — X-Team-Id + NHibernate tenantFilter
- `design-system` — Bono The Edge, Apple Liquid Glass
- `api-endpoints` — .NET 4-layer pattern
- `forms` — React forms, validare, mutații
- `lists` — Liste, tabele, paginare, filtre
- `ocr` — Conspectare integration
- `forex` — BNR cursuri, multi-currency
- `export` — Excel/PDF generation
- `email-ingest` — email forwarding to expense creation

## Output

```
DONE — [task name]
Fișiere: [count]
Build: PASS
```

Dacă build FAIL:
```
BLOCKED — [task name]
Build error: [fișier:linie] [error message]
Attempting fix...
```

Retry automat pe build fail. Dacă nu se rezolvă în 3 încercări → raportează la Brain.
