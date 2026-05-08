# Contract: nicu-qa

## Primește

| Input | De la | Format |
|-------|-------|--------|
| Cod backend complet | nicu-backend (via Brain) | Fișiere .NET |
| Cod frontend complet | nicu-frontend (via Brain) | Fișiere Next.js |
| architecture.md | nicu-architect (via Brain) | Markdown |
| PRD narativ | Bruce (via Brain) | Markdown |
| Screenshots prototip | Bruce (via Brain) | PNG per ecran |

## Produce

Un QA Report cu 7 layers Swiss Cheese. Fiecare layer e PASS sau FAIL.

### Layer 1: Build Verification
```
- Backend: dotnet build (zero errors, zero warnings)
- Frontend: pnpm build (zero errors, zero warnings)
```

### Layer 2: Unit Tests
```
- Backend: dotnet test (toate trec)
- Frontend: vitest/jest run (toate trec)
- Acoperire minimă: 80% pe business logic
```

### Layer 3: Integration Tests
```
- API endpoints răspund cu status codes corecte
- Response shapes match DTOs din architecture.md
- Queries returnează date corecte
```

### Layer 4: UI Verification
```
- Dev server pornește fără erori
- Pagini se încarcă (no blank screens)
- Console: zero errors
- Happy path funcțional per ecran (navigare, formulare, liste)
- Verificare vizuală contra screenshots prototip
```

### Layer 5: Security Check
```
- Toate query-urile filtrează pe team_id
- Cross-tenant query returnează zero results
- Toate controller-ele au [Authorize]
- No SQL injection vectors (parametrized queries only)
- No XSS vectors (no dangerouslySetInnerHTML)
- No secrets în cod frontend (grep: API keys, tokens, passwords)
```

### Layer 6: Spec Compliance
```
- Fiecare feature din PRD e implementat
- Edge cases din PRD sunt acoperite
- An fiscal Aug-Aug corect în toate modulele cu perioade
- Multi-currency (RON/EUR) prezent unde specificat
```

### Layer 7: Cross-Reference Consistency
```
- Routes din frontend match endpoints din backend
- DTOs din frontend match DTOs din backend
- Naming conventions consistente (kebab-case routes, PascalCase DTOs)
- Niciun import broken
- Niciun endpoint orfan (definit dar neapelat)
- Niciun hook orfan (definit dar nefolosit)
```

## Format output

```markdown
## QA Report — [Modul name]

### Summary
Layers passed: 7/7 | 5/7
Blockers: 0
Majors: 2
Minors: 1
Verdict: PASS | FAIL

### Findings

#### [BLOCKER] Build fail in frontend
- Layer: 1
- File: components/expenses/ExpenseForm.tsx:23
- Issue: Type error — property 'amount' does not exist on type 'ExpenseDto'
- Expected: property exists (defined in architecture.md section 2)

#### [MAJOR] Missing tenant isolation
- Layer: 5
- File: PnL.DomainServices/Budgets/Queries/ListBudgetsQuery.cs:15
- Issue: Query nu filtrează pe team_id
- Expected: WHERE team_id = @teamId
- Repro: Login as Tenant A, GET /api/budgets → returnează date Tenant B
```

## Severitate

- **BLOCKER** — build fail, security vulnerability, data leak. Pipeline se oprește.
- **MAJOR** — test fail, feature lipsă, spec deviation. Trebuie reparat.
- **MINOR** — warning, stil, improvement. Se poate merge, se repară opțional.

## Brain primește doar

```
nicu-qa: FAIL (5/7)
- Layer 1 FAIL: 1 blocker (build error ExpenseForm.tsx)
- Layer 5 FAIL: 1 major (missing tenant filter ListBudgetsQuery.cs)
```

Maxim 5 rânduri. Raportul complet rămâne în fișier pentru repair loop.

## Reguli

- NU repară cod. Doar raportează.
- Fiecare finding are: severitate, layer, fișier, linia, ce s-a așteptat, ce s-a găsit.
- BLOCKERs și MAJORs au pași de reproducere.
- Layer 7 (Cross-Reference) se rulează ultimul — prinde inconsistențe subtile.
- Un singur BLOCKER = tot raportul e FAIL.
