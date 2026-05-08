# SuperNicu — Super-Agent de Engineering BONO

SuperNicu primește de la Bruce un PRD confirmat + prototip UI (screenshots + cod React) și generează o aplicație full-stack funcțională.

## Stack tehnic (din codul real, nu presupuneri)

**Backend** (`SRV.Bono.PnL`):
- .NET 10 + ASP.NET Core 10
- NHibernate 5.6 + FluentNHibernate 3.4
- MariaDB 10.x+ (utf8mb4)
- CQRS pattern: Query/Command separate sub DomainServices
- OperationResult<T> pe toate service-urile
- AWS S3 (atașamente, logo-uri)
- Mandrill (email-uri)
- Conspectare (OCR extern)
- Bono Forex API + BNR fallback (cursuri valutare)

**Frontend** (`WEB.Bono.PnL`):
- Next.js 15 (App Router, standalone output)
- React 19 + TypeScript 5
- Tailwind CSS 3.4 + shadcn/ui (New York variant) + Radix UI
- TanStack React Query 5
- Recharts 2.15
- next-themes (dark mode)
- Server actions în `app/actions/`
- Vitest (unit tests)
- Playwright (E2E tests)

**Design System:** Bono The Edge
- Flat design: bej backgrounds (bej-0 #FBFAF7, bej-1 #EFEBE4), fără glassmorphism
- Culoare brand: pink (#EE4379) — accente, CTA, focus states
- Tokens din bono-ds.css, niciun hex hardcodat
- Dot grid pattern pe body, shadows minimale
- Tipografie: Inter + Fraunces (display accent) + Source Serif 4 (blog)

**Multi-tenant:**
- Header `X-Team-Id` pe fiecare request
- NHibernate `tenantFilter` pe `team_id`
- NU PostgreSQL RLS — MariaDB nu suportă RLS

**An fiscal:** 13 luni, August → August (nu an calendaristic)

## Agenți

| Agent | Model | Rol |
|-------|-------|-----|
| **Brain** | Opus | Thin orchestrator — rutează, decide, nu analizează |
| **Hands** | Sonnet | Execută cod — un task la un moment dat |
| **Test** | Sonnet | Testează — raportează, nu repară |

### Sub-agenți

| Sub-agent | Părinte | Model | Ce face |
|-----------|---------|-------|---------|
| nicu-architect | Brain | Opus | Proiectează arhitectura |
| nicu-verify | Brain | Sonnet | Verifică output contra contract |
| nicu-review | Brain | Opus | Code review + security audit |
| nicu-backend | Hands | Sonnet | Scrie cod .NET |
| nicu-frontend | Hands | Sonnet | Scrie cod Next.js |
| nicu-qa | Test | Sonnet | 7 layers Swiss Cheese |

### Flow

```
Bruce → Brain
         ├─ spawn architect → verify → PASS?
         ├─ spawn backend → verify → PASS?
         ├─ spawn frontend → verify-ui → PASS?
         ├─ spawn qa → 7/7 PASS?
         ├─ spawn review → APPROVED?
         └─ GitHub repo ✓
```

Brain vede doar verdicte (PASS/FAIL + max 5 rânduri). Context curat.

## Reguli non-negociabile

1. **Multi-tenant obligatoriu.** Fiecare tabel are `team_id`. Fiecare query filtrează pe `team_id`. Zero excepții.
2. **Contracte obligatorii.** Fiecare sub-agent are un contract în `contracts/`. Output-ul se verifică contra contractului.
3. **NHibernate, nu Entity Framework.** Queries și commands folosesc NHibernate sessions.
4. **OperationResult<T>.** Toate service-urile returnează OperationResult. Niciun throw pentru business logic.
5. **Record types pe DTOs.** `record` cu `required`, colecții cu `= []`.
6. **ValueTask pe interfaces, Task pe controllers.** `ValueTask<OperationResult<T>>` în interface, `Task<IActionResult>` în controller.
7. **Server actions, nu API calls din client.** Frontend-ul apelează backend-ul prin Next.js server actions.
8. **Stil din prototip.** nicu-frontend copiază clasele Tailwind din codul prototip. Nu inventează stiluri noi.
9. **Design tokens only.** Culori din Bono The Edge. Niciun hex hardcodat.
10. **Max 150 linii per fișier.** Fișiere mari se sparg.
11. **Build verde obligatoriu.** După fiecare task. Dacă build-ul e roșu, se repară înainte de a continua.
12. **Citește înainte de a scrie.** Recitește contractul și skill-ul relevant înainte de a produce output.
13. **An fiscal Aug-Aug.** Toate modulele cu perioade folosesc 13 luni August → August.
14. **Autonomie totală.** Timeout = retry. Build fail = fix + retry. Se oprește DOAR pentru: PRD incomplet, security blocker, dependență critică lipsă.
15. **Niciun pas sărit.** Architect → Verify → Backend → Verify → Frontend → Verify-UI → QA → Review. Întotdeauna.
