---
name: qa
description: Quality assurance skill — 7 layers Swiss Cheese. Use when nicu-qa tests code. Fires on "test this", "verify", "QA check", or after task completion.
---

# QA — 7 Layers Swiss Cheese

Testare completă pe 7 straturi. Fiecare strat prinde defecte pe care celelalte le pot scăpa.

Vezi `contracts/qa-contract.md` pentru output format complet.

## Layer 1: Build Verification

```bash
# Backend
dotnet build --no-restore
# Zero errors, zero warnings

# Frontend
pnpm build
# Zero errors, zero warnings
```

FAIL = BLOCKER. Nimic altceva nu se rulează dacă build-ul pică.

## Layer 2: Unit Tests

```bash
dotnet test
pnpm test
```
- Toate testele trec
- 80% acoperire pe business logic (adapters, hooks)

## Layer 3: Integration Tests

- API endpoints răspund cu status codes corecte
- Response shapes match DTOs din architecture.md
- Queries returnează date corecte
- NHibernate sessions funcționează corect

## Layer 4: UI Verification

- Dev server pornește fără erori
- Pagini se încarcă (zero blank screens)
- Console: zero errors, zero unhandled promises
- Happy path funcțional per ecran
- Compară vizual cu screenshots prototip

## Layer 5: Security Check

- **Tenant isolation:** fiecare query filtrează pe `team_id`
- **Cross-tenant:** login Tenant A, setează X-Team-Id Tenant B → 403
- **Auth:** toate controller-ele au `[Authorize]`
- **SQL injection:** toate queries parametrizate (NHibernate params)
- **XSS:** zero `dangerouslySetInnerHTML`, output encoding
- **Secrets:** `grep -r "apikey\|secret\|password\|token" --include="*.ts" --include="*.tsx"` → zero în frontend

## Layer 6: Spec Compliance

- Fiecare feature din PRD implementat
- Edge cases acoperite
- An fiscal Aug-Aug corect (13 luni, nu 12)
- Multi-currency prezent unde specificat
- 5 roluri din PRD respectate

## Layer 7: Cross-Reference Consistency

- Routes frontend match endpoints backend
- DTOs frontend match response shapes backend
- Naming consistent (PascalCase C#, camelCase TS, kebab-case routes)
- Zero imports broken
- Zero endpoints orfane (definite dar neapelate)
- Zero hooks orfane (definite dar nefolosite)
- Server actions apelează endpoint-urile corecte

## Severitate

- **BLOCKER** — build fail, security vulnerability, data leak
- **MAJOR** — test fail, feature lipsă, spec deviation
- **MINOR** — warning, stil, improvement (non-blocking)

## Reguli

- NU repara cod. Doar raportează.
- Fiecare finding: severitate, layer, fișier, linie, expected, found.
- BLOCKERs și MAJORs au pași de reproducere.
- Layer 7 ultimul.
- La re-test: doar layerele care au picat.
