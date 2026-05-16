# SuperNicu — Convenții și Pattern-uri

SuperNicu este agentul de engineering BONO. Pipeline-ul complet este definit în `skills/supernicu/SKILL.md`. Acest fișier conține convențiile de cod, regulile de securitate și pattern-urile obligatorii.

## Stack tehnic BONO

| Layer | Tech | Versiune |
|-------|------|----------|
| Frontend | Next.js (App Router) + React 19 + TypeScript + Tailwind + shadcn/ui + TanStack Query 5 | Next.js 15.5 |
| Backend | ASP.NET Core + NHibernate + FluentNHibernate | .NET 10 |
| Database | MariaDB 10.x+ (utf8mb4) | MariaDB 10 |
| Storage | AWS S3 | |
| OCR | Conspectare | |
| Email | Mandrill | |
| Auth | JWT Bearer + Magic Link + Google OAuth | |
| Deploy | Railway (Docker) + GitHub Actions | |
| Design System | Bono "The Edge" E-33 | bono-ds.css |

## Reguli non-negociabile

1. **Secure by default** — Codul generat e sigur fără efort suplimentar. Calea nesigură cere acțiune explicită (ex: `[AllowAnonymous]`). Vezi `GUARDRAILS.md` pentru pattern-uri de eroare cunoscute
2. **API separation** — Customer API (`/api/v1/`) și Admin API (`/api/admin/v1/`) sunt întotdeauna separate: controller-e separate, routing separat, autorizare diferită
3. **Prototip > Design System** — Implementează 100% ce e în prototip, chiar dacă diferă de DS. Folosește DS doar pentru elemente care lipsesc din prototip
4. **Multi-tenant obligatoriu** — Fiecare tabel are `team_id`. Fiecare query filtrează pe `team_id`. NHibernate `tenantFilter`, `X-Team-Id` header. Zero excepții
5. **CQRS pattern** — Query classes pt read, Command classes pt write (sub `DomainServices/`)
6. **OperationResult<T>** — toate service methods returnează `OperationResult<T>`, controllers apelează `.ToActionResult()`
7. **DS tokens only** — elementele care nu sunt în prototip folosesc tokeni din Design System, nu hex hardcoded
8. **No secrets in code** — env vars pentru toate credentials. No sensitive data in logs
9. **Soft delete** — `deleted_at` column, nu DELETE fizic
10. **Audit log** — acțiuni importante logate
11. **Calitate > Viteza** — Opțiunea corectă e pixel-perfect cu SPEC complet, nu quick-fix. Dacă există o cale rapidă și una corectă, o alegem pe cea corectă
12. **Build verde obligatoriu** — După fiecare task. Dacă build-ul e roșu, se repară înainte de a continua
13. **An fiscal Aug-Aug** — 13 luni, August → August (nu an calendaristic)
14. **Max 150 linii per fișier** — Fișiere mari se sparg

## Pattern backend: 6 pași

Fiecare feature backend urmează exact acești pași, în ordine:

```
1. DomainModel      — Entity class (POCO, niciun atribut ORM)
2. FluentNH Mapping — ClassMap<T> cu tenantFilter
3. ServiceInterface — Interface + DTOs (record types cu required)
4. CQRS             — LoadXQuery / FindXQuery (read) + XCommand (write)
5. ServiceAdapter   — Implementează interface, orchestrează queries/commands
6. Controller       — Thin, extinde TenantControllerBase, apelează .ToActionResult()
```

**Convenții:**
- `LoadXQuery` = lookup by known key (ID)
- `FindXQuery` = search/filter criteria
- DTOs = `record` cu `required` properties, colecții cu `= []`
- `ValueTask<OperationResult<T>>` pe interfaces, `Task<IActionResult>` pe controllers
- NHibernate, nu Entity Framework. Queries folosesc NHibernate sessions

## Pattern frontend: 6 pași

Fiecare feature frontend urmează exact acești pași, în ordine:

```
1. Types            — TypeScript interfaces/types în types/
2. API Layer        — Server actions în app/actions/
3. TanStack Hooks   — Query hooks cu query keys în hooks/
4. Components       — Feature components în components/
5. Pages            — Next.js pages în app/
6. Navigation       — Links, routing, breadcrumbs
```

**Convenții:**
- Server Components by default. `"use client"` doar când necesar (interactivitate)
- API calls prin Next.js server actions, nu direct din client
- TanStack Query 5 pentru cache + refetch
- Clasele Tailwind se copiază din prototip. Nu se inventează stiluri noi
- Feature verticals: un feature = un director cu toate componentele lui

## Securitate — pit of success

Codul sigur e calea implicită. Codul nesigur cere acțiune explicită.

**Auth:**
- `FallbackPolicy` deny-by-default — fiecare endpoint necesită auth
- `[AllowAnonymous]` doar pe whitelist explicită: login, register, health, webhooks
- Customer controllers extind `TenantControllerBase`
- Admin controllers au `[Authorize(Roles = "Admin")]`

**Tenant isolation:**
- `team_id` pe fiecare tabel cu date tenant
- NHibernate `tenantFilter` aplicat automat
- `X-Team-Id` header validat pe fiecare request
- Anti-IDOR: ownership validation — user X nu vede datele user Y din același tenant

**Defense-in-depth la data layer (G8):**

Fiecare entitate persistată primește verdict explicit în Faza 2 (ARCHITECT) — vezi „Query Safety Matrix":

| Clasificare | Mecanism de protecție | Ce înseamnă |
|------------|----------------------|-------------|
| Direct tenant-scoped | `TenantFilter` în mapping + `team_id` în query | Are coloană `team_id`. Filtrul automat e suficient |
| Indirect tenant-scoped | Query MUST JOIN parent + `parent.team_id` în WHERE | Nu are `team_id` (atașament, audit log, line item). Service-layer check NU e suficient |
| Global by design | Comentariu explicit în mapping | Nu e tenant data (currency rates, user whitelist, magic tokens) |

**Regula G8 (cazul "indirect"):** Service-layer check (`if (parent.TeamId != teamId) throw`) e singular line of defense. Defense-in-depth cere ca **query-ul însuși** să refuze să returneze datele altui tenant. Cod nou care apelează query-ul direct (skipping service) NU TREBUIE să poată leak-ui.

**Verificări obligatorii (Faza 4):**
- Endpoint fără token → 401
- Token expirat → 401
- Customer pe admin endpoint → 403
- X-Team-Id al altui tenant → zero date returnate
- Grep logs: password, token, apikey, secret, authorization → zero matches
- **Query Audit** (G8): pentru fiecare entitate Indirect tenant-scoped, fiecare `*Query.cs` conține JOIN explicit pe parent + filtru `team_id`

## Verificarea automată detectează prezența, nu adâncimea

Meta-principiu pentru orice hook, lint, grep pre-commit, sau check automat:

> **Hook-urile flag-ează tipare suspecte. Subagenții (review-bono) verifică structura. Blocările hard pe grep se introduc DOAR după ce pattern-ul s-a stabilizat empiric (2-3 proiecte cu false positives ≈ 0).**

Greșeala tipică: un grep care caută `team_id` într-un fișier de query pretinde că validează tenant scoping. Dar `team_id` poate apărea în comentariu, într-un alt where clause, sau într-un cast. Grep-ul detectează **prezența string-ului**, nu **structura logică**.

Consecințe practice:
1. Hook-uri noi pornesc ca **WARN-only**, nu BLOCK
2. Output-ul lor e o **listă de fișiere suspecte**, nu un verdict pass/fail
3. Lista e routată la **review-bono** care verifică structura manual
4. Hook-ul promovat la BLOCK doar după validare pe 2-3 proiecte reale

Aplicat la G7 (background opac) și G8 (query fără JOIN) — ambele au hook-uri WARN-only. Adâncimea o validează review-bono, nu grep-ul.

## Guardrails active (G1-G18)

Toate detaliile sunt în `GUARDRAILS.md` (format: Trigger / Instrucțiune / Motiv / Detecție). Lista de mai jos e pentru orientare rapidă:

| ID | Pattern | Enforcement în pipeline |
|----|---------|------------------------|
| G1 | Auth bypass — endpoint fără autorizare | Faza 4 STRATUL B.2 (HTTP behavior) |
| G2 | IDOR — acces date prin ghicirea ID-ului | Faza 4 STRATUL B.2 |
| G3 | Admin + customer pe același API | Faza 2 ARCHITECT A.1 + Faza 4 B.2 |
| G4 | Security theater — headere custom ca auth | Faza 2 ARCHITECT A.2 |
| G5 | Sensitive data in logs | Faza 4 STRATUL B.2 (grep logs) |
| G6 | File upload/download fără ownership check | Faza 2 ARCHITECT + Faza 4 B.2 |
| G7 | Background opac șterge grid-dot | Faza 4 STRATUL E + STRATUL F |
| G8 | Indirect tenant-scoped fără JOIN | Faza 2 ARCHITECT A.5 (Query Safety Matrix) + Faza 4 B.1 |
| G9 | Cascade pierdut la conversie soft-delete | Faza 2 ARCHITECT C.5 + C.6 |
| G10 | Secrets cu fallback hardcoded | Faza 2 ARCHITECT A.4.5 + Faza 4 B.3 |
| G11 | Auth tokens în URL query | Faza 4 STRATUL B.3 |
| G12 | Public-auth fără rate limit | Faza 2 ARCHITECT A.4 + Faza 4 B.3 |
| G13 | Long-lived credentials externe | Faza 2 ARCHITECT A.4.6 + Faza 4 B.4 |
| G14 | Fail-open negation pe gate logic | Faza 2 ARCHITECT (positive equality review) |
| G15 | Benign default la category boundary | Faza 4 STRATUL F (review structural) |
| G16 | Contract change fără call-site audit | Faza 3 — pre-edit grep workflow |
| G17 | Overloaded flag inheritance | Faza 2 ARCHITECT (flag intent vs mechanism) |
| G18 | Refactor care „simplifică" hides side effects | Faza 3 — audit înainte de simplificare |

**Citește GUARDRAILS.md** la fiecare activare — subagentul backend, frontend, sau review se ghidează după aceste reguli.

## Hook-uri SuperNicu

7 scripturi în `hooks/` — discovery tools (flag-ează tipare), nu enforcement:

| Hook | Când rulează | Scop |
|------|-------------|------|
| `pre-commit-build.sh` | Git pre-commit | Build verde înainte de commit |
| `pre-commit-spec.sh` | Git pre-commit | Avertizează dacă pagini modificate n-au SPEC |
| `sync-skill.sh` | Git post-commit | Propagă SKILL.md la `~/.claude/skills/` |
| `build-query-safety-matrix.sh` | Faza 2 ARCHITECT (G8) | Auto-generează matrix entități |
| `query-tenant-check.sh` | Faza 4 B.1 (G8) | Flag-ează queries fără tenant scope |
| `schema-preflight.sh` | Faza 2 C.6 (G9) | Scan cascade chains + migration safety |
| `secrets-scan.sh` | Faza 4 B.3 (G10/G11/G12) | Secrets/tokens/rate limit scan |

Toate de tip „flag" sunt **WARN-only**. Vezi meta-principiul de mai sus.

## Skill-uri Bono canonice (de la Prodan)

Skill-urile canonice Bono sunt instalate ca user-level skills în `~/.claude/skills/`. Sunt scrise de Prodan (bono-ro/bono-skills) și se folosesc **în integralitatea lor** — SKILL.md + toate fișierele din `references/` și `assets/`.

| Skill | Conținut | Când se activează |
|-------|----------|-------------------|
| `dotnet-api-blueprint` | SKILL.md + references/ (worked-example, conventions) | Cod .NET API |
| `nhibernate-cqrs` | SKILL.md + references/ (query-patterns, command-patterns, queryover-reference, execution-modes, entity-mappings) | Queries/Commands/Mappings NHibernate |
| `dotnet-quartz-jobs` | SKILL.md + references/logging-patterns.md | Scheduled jobs |
| `internal-email-template` | SKILL.md + references/template-pipeline.md + assets/ (2 HTML exemple) | Email templates |
| `react-19-vite-frontend` | SKILL.md + evals/ + references/ (api-layer, forms, hooks, router, infinite-list, no-use-effect, edge-design-system, worked-example, templates/) | Frontend UI |
| `edge-33` | SKILL.md + BRAND.md + bono-ds.css + references/ (4 HTML pagini) + assets/ + uploads/ | Design System Bono "The Edge" |

În Faza 3, SuperNicu invocă explicit aceste skill-uri (defense in depth — chiar dacă auto-activation eșuează, pipeline-ul forțează citirea).

### Adaptări react-19-vite-frontend → Next.js 15.5

`react-19-vite-frontend` e scris pentru Vite 7 + React Router 7 + Tailwind 4. SuperNicu folosește Next.js 15.5 App Router + Tailwind 3.4. Aplică principiile (feature verticals, TanStack Query, query keys, forms, no-useEffect), dar adaptează:

- `src/pages/` → `app/dashboard/[teamId]/`
- `src/router.tsx` → `layout.tsx` în `app/`
- React Router → `next/navigation`
- API calls din client → server actions în `app/actions/`
- Server Components by default, `"use client"` doar când necesar
- `@theme` (Tailwind 4) nu se aplică

### Adaptări dotnet-api-blueprint + nhibernate-cqrs → SuperNicu stack

Standardele Prodan sunt scrise pentru un Bono generic. SuperNicu folosește:
- **ORM**: FluentNHibernate `ClassMap<T>` (NU XML `.hbm.xml`) — principiile entity-mappings se aplică, sintaxa e FluentNH
- **API**: 6-step direct-DB (DomainModel → Mapping → ServiceInterface → CQRS → ServiceAdapter → Controller) — pattern-ul 4-layer din dotnet-api-blueprint se adaptează la 6-step
- **DTOs**: `record` types cu `required` + colecții `= []` (NU class)
- **Return types**: `ValueTask<OperationResult<T>>` pe interfaces, `Task<IActionResult>` pe controllers
- **Auth**: `TenantControllerBase` + JWT + `X-Team-Id` + `FallbackPolicy` deny-by-default

### Design System

- **Sursa canonică**: `~/.claude/skills/edge-33/` (skill auto-activat, conține bono-ds.css + brand + referințe)
- **Mirror local în repo**: `shared/bono-ds.css` (pentru portabilitate când clonezi SuperNicu fără ~/.claude/)

## Structura proiect

```
Backend (SRV.Bono.{Project}):
├── Api/Controllers/           — thin controllers
├── Api.ServiceInterface/      — interfaces + DTOs (record types)
├── DomainModel/               — entities + FluentNH mappings
├── DomainServices/            — CQRS queries + commands + service adapters
└── Infrastructure.NHibernate/ — NHibernate base classes, helpers

Frontend (WEB.Bono.{Project}):
├── app/                       — Next.js App Router pages
├── components/                — React components
├── hooks/                     — TanStack Query hooks
├── lib/api/                   — API layer
├── types/                     — TypeScript interfaces
└── shared/bono-ds.css         — Design System tokens (canonical)
```
