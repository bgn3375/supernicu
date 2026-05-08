# Contract: nicu-review

## Primește

| Input | De la | Format |
|-------|-------|--------|
| Cod complet (backend + frontend) | După QA PASS (via Brain) | Fișiere |
| architecture.md | nicu-architect | Markdown |
| QA Report | nicu-qa | Markdown |
| PRD narativ | Bruce | Markdown |

## Produce

Un Review Report cu verdict: APPROVED sau CHANGES REQUESTED.

### Ce verifică (în ordine)

#### 1. Pattern Compliance
- Backend urmează ordinea din contract: interface → DTOs → query/command → adapter → controller → DI?
- Frontend urmează ordinea: types → server actions → hooks → components → pages → nav?
- CQRS pattern respectat (queries separate de commands)?
- OperationResult<T> pe toate service-urile?
- Record types pe toate DTOs?

#### 2. Security Review
- Multi-tenant isolation: fiecare query filtrează pe team_id?
- SQL injection: toate queries parametrizate?
- XSS: niciun dangerouslySetInnerHTML sau interpolări nesanitizate?
- Auth: toate endpoint-urile protejate cu [Authorize]?
- Secrets: niciun secret în cod frontend sau hardcodat în backend?
- CSRF: protecție pe endpoint-urile mutative?

#### 3. Code Quality
- Fișiere sub 150 linii?
- Naming consistent (PascalCase C#, camelCase TS, kebab-case routes)?
- Niciun cod duplicat (DRY)?
- Niciun cod mort (funcții/componente nefolosite)?
- Error handling consistent (OperationResult backend, error boundaries frontend)?

#### 4. Design System Compliance
- Culori: tokens din Bono The Edge, nu hex hardcodat?
- Tipografie: clasele din design system, nu font-size custom?
- Spațiere: clasele Tailwind din prototip, nu valori arbitrare?
- Dark mode: funcționează fără artefacte?

#### 5. Architecture Alignment
- Codul implementează exact ce descrie architecture.md?
- Niciun endpoint adăugat care nu e în architecture.md?
- Niciun endpoint din architecture.md neimplementat?
- Relațiile între componente respectă Component Tree?

## Format output

```markdown
## Review Report — [Modul name]

Verdict: APPROVED | CHANGES REQUESTED

### Summary
- Pattern compliance: OK
- Security: 1 issue
- Code quality: OK
- Design System: OK
- Architecture alignment: OK

### Issues

#### [SECURITY] Potential SQL injection in supplier search
- File: PnL.DomainServices/Suppliers/Queries/SearchSuppliersQuery.cs:22
- Issue: Supplier name concatenat în query string
- Fix: Folosește parametru NHibernate
- Severity: BLOCKER

### Recommendations (non-blocking)
- ExpenseServiceAdapter.cs:45 — metoda SubmitForApproval are 3 responsabilități, ar putea fi splitată
```

## Brain primește doar

```
nicu-review: APPROVED
```
sau
```
nicu-review: CHANGES REQUESTED
- 1 security blocker: SQL injection in SearchSuppliersQuery.cs
```

## Reguli

- Opus model — judecată critică, nu mecanică
- Un singur BLOCKER security = CHANGES REQUESTED automat
- Recommendations sunt non-blocking — le notează dar nu blochează merge
- NU rescrie cod — doar identifică ce trebuie schimbat
- Dacă QA a ratat ceva, îl menționează explicit ("QA Layer 5 a ratat asta")
- Review-ul e ultimul pas — după asta fie merge, fie repair loop
