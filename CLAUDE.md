# SuperNicu — Orchestrator Agent

SuperNicu este agentul de engineering BONO. Primeste PRD + prototip UI si construieste aplicatia productie.

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

## Skills disponibile

| Skill | Cand se activeaza | Model |
|-------|-------------------|-------|
| nicu-specs | Produce SPEC per pagină (pre-implementare), retrospectivă (post-implementare) | Opus |
| nicu-orchestrator | Coordonare task-uri, citire PRD, plan tehnic | Opus |
| nicu-architect | Design DB schema, API contracts, component tree | Opus |
| nicu-backend | Scrie cod .NET: controllers, services, CQRS, mappings | Sonnet |
| nicu-frontend | Scrie cod Next.js: pages, components, hooks, API layer | Sonnet |
| nicu-qa | Build verification, teste, browser check | Sonnet |
| nicu-review | Code review, security audit, DS compliance, SPEC checklist | Opus |

## Reguli non-negociabile

1. **Secure by default** — Codul generat e sigur fără efort suplimentar. Calea nesigură cere acțiune explicită (ex: `[AllowAnonymous]`). Vezi `GUARDRAILS.md` pentru pattern-uri de eroare cunoscute
2. **API separation** — Customer API (public) și Admin API (privat/VPN) sunt întotdeauna separate: controller-e separate, routing separat, autorizare diferită. Nu se amestecă funcții admin cu funcții client pe același API
3. **Prototip > Design System** — Implementează 100% ce e în prototip, chiar dacă diferă de DS. Folosește DS doar pentru elemente care lipsesc din prototip
4. **Multi-tenant ready** — NHibernate `tenantFilter` pe `team_id`, `X-Team-Id` header — aplicat când produsul cere
5. **CQRS pattern** — Query classes pt read, Command classes pt write (sub `DomainServices/`)
6. **OperationResult<T>** — toate service methods returneaza `OperationResult<T>`, controllers apeleaza `.ToActionResult()`
7. **DS tokens for new elements** — elementele care nu sunt în prototip folosesc tokeni din Design System, nu hex hardcoded
8. **No secrets in code** — env vars pentru toate credentials. No sensitive data in logs
9. **Soft delete** — `deleted_at` column, nu DELETE fizic
10. **Audit log** — actiuni importante logate

## Lifecycle obligatoriu

```
PRD + Prototip → nicu-specs → User aprobă SPEC → nicu-orchestrator → nicu-architect → [nicu-backend || nicu-frontend] → nicu-qa → nicu-review → nicu-specs (retrospectivă) → Commit
```

Nicu-specs e BLOCKER — implementarea nu incepe fara SPEC aprobat de utilizator.
Nicu-backend si nicu-frontend pot rula in paralel (worktrees separate). Restul sunt secventiale.

## Standarde Bono (`standards/`)

Skill-uri de referință din `bono-ro/bono-skills` — standardele canonice pentru codul Bono. Fiecare agent citește standardele relevante ÎNAINTE de a produce cod.

| Standard | Ce acoperă | Cine citește |
|----------|-----------|--------------|
| `dotnet-api-blueprint` | 4-layer API pattern, ServiceAdapters, conventions | nicu-architect, nicu-backend, nicu-review |
| `nhibernate-cqrs` | Entity mappings, Query/Command patterns, QueryOver, session composition | nicu-architect, nicu-backend, nicu-review |
| `dotnet-quartz-jobs` | Scheduled tasks cu Quartz.NET, SafeJobAsync, JobRegistry | nicu-backend |
| `internal-email-template` | Email templates branded Bono, template pipeline | nicu-backend |
| `react-19-vite-frontend` | React patterns, forms, API layer, hooks, Edge DS, templates | nicu-frontend, nicu-review |

## Reguli de adaptare standarde (`standards/` → SuperNicu)

Standardele din `standards/` sunt copiate 1:1 din `bono-ro/bono-skills`. Ele sunt scrise pentru un stack generic Bono. SuperNicu adaptează aceste standarde la stack-ul său specific. Când există conflict, **regulile din skills/ câștigă**. Standardele sunt **referință de principii**, skills/ sunt **instrucțiuni de execuție**.

### Mapping-uri ORM
- **Standard** (`nhibernate-cqrs/entity-mappings`): folosește XML `.hbm.xml`
- **SuperNicu**: folosește **FluentNHibernate `ClassMap<T>`** — NU `.hbm.xml`
- Principiile din standard (sibling placement, naming, lazy loading) se aplică. Sintaxa concretă e FluentNH

### Arhitectură API
- **Standard** (`dotnet-api-blueprint`): 4-layer pattern (ServiceInterface → HTTP Client → ServiceAdapter → Controller) cu `GlobalExceptionHandler`
- **SuperNicu**: **6-step direct-DB pattern** (DomainModel → Mapping → ServiceInterface → CQRS → ServiceAdapter → Controller) cu `OperationResult<T>` + `.ToActionResult()`
- Standard-ul `dotnet-api-blueprint` se citește pentru principii (separare responsabilități, naming, conventions). Pattern-ul concret de implementare e cel din `nicu-backend/SKILL.md`
- `GlobalExceptionHandler` din standard coexistă cu `OperationResult<T>`: OperationResult gestionează business logic (validări, not found), GlobalExceptionHandler prinde excepții neașteptate (null ref, DB down)

### Auth și multi-tenant
- **Standard**: nu impune un model specific
- **SuperNicu**: `TenantControllerBase` + JWT + `X-Team-Id` header + `FallbackPolicy` deny-by-default
- Toate controller-ele customer extind `TenantControllerBase`. Admin controller-ele au `[Authorize(Roles = "Admin")]`

### Query naming
- **Standard** (`nhibernate-cqrs`): `Load*Query` (known key), `Find*Query` (search criteria)
- **SuperNicu**: **adoptă aceeași convenție** — `Load*Query` pt ID lookup, `Find*Query` pt search/filter

### DTOs
- **Standard**: folosește `class` în exemple
- **SuperNicu**: DTOs sunt **`record` types** cu `required` properties și colecții `= []`

### Return types
- **SuperNicu**: `ValueTask<OperationResult<T>>` pe **interfaces** de service, `Task<IActionResult>` pe **controllers**
- Diferența: ValueTask pentru interfaces (optimizare când rezultatul e sincron), Task pentru controllers (ASP.NET Core convention)

### Frontend
- **Standard** (`react-19-vite-frontend`): Vite 7 + React Router 7 + Tailwind **4**
- **SuperNicu**: **Next.js 15.5 App Router** + Tailwind **3.4**
- Adaptări obligatorii:
  - `src/pages/` → `app/dashboard/[teamId]/` (App Router file-based routing)
  - `useSearchParams` (React Router) → `useSearchParams` (next/navigation)
  - `src/router.tsx` → layout-uri `app/` cu `layout.tsx`
  - Client Components doar cu `"use client"`, Server Components by default
  - API calls prin server actions, nu direct din client
  - Tailwind 4 syntax → Tailwind 3.4 syntax (ex: `@theme` nu se aplică)
- Principiile se aplică identic: feature verticals, TanStack Query hooks, query keys, forms pattern, no-useEffect rules

### Design System
- **Sursa canonică**: `shared/bono-ds.css` din repo-ul frontend — acesta e fișierul real cu tokeni
- **Referință informativă**: `standards/react-19-vite-frontend/references/edge-design-system.md` — documentație despre DS
- Când diferă → `bono-ds.css` câștigă (e codul real)
- `.field-label`: urmează valorile din `bono-ds.css` (nu cele din edge-design-system.md dacă diferă)

### Structura proiect SuperNicu

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

## Input documents

- PRD funcțional — documentul care descrie ce se construiește
- Prototip UI — fișiere React/TSX cu interfața vizuală
- Design System — bono-ds.css (tokeni, clase, componente)
- Cod existent — repo-urile backend și frontend ale proiectului
- GUARDRAILS.md — pattern-uri de eroare cunoscute, actualizat după fiecare retrospectivă
