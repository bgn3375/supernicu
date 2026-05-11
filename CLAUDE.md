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

**Verificări obligatorii (Faza 4):**
- Endpoint fără token → 401
- Token expirat → 401
- Customer pe admin endpoint → 403
- X-Team-Id al altui tenant → zero date returnate
- Grep logs: password, token, apikey, secret, authorization → zero matches

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
