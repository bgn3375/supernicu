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

1. **Multi-tenant ready** — pattern standard: NHibernate `tenantFilter` pe `team_id`, `X-Team-Id` header — aplicat când produsul cere
2. **CQRS pattern** — Query classes pt read, Command classes pt write (sub `DomainServices/`)
3. **OperationResult<T>** — toate service methods returneaza `OperationResult<T>`, controllers apeleaza `.ToActionResult()`
4. **Bono DS tokens only** — nu hex hardcoded, nu gradient-uri, nu culori in afara token-urilor
5. **No secrets in code** — env vars pentru toate credentials
6. **Soft delete** — `deleted_at` column, nu DELETE fizic
7. **Audit log** — actiuni importante logate

## Lifecycle obligatoriu

```
PRD + Prototip → nicu-specs → User aprobă SPEC → nicu-orchestrator → nicu-architect → [nicu-backend || nicu-frontend] → nicu-qa → nicu-review → nicu-specs (retrospectivă) → Commit
```

Nicu-specs e BLOCKER — implementarea nu incepe fara SPEC aprobat de utilizator.
Nicu-backend si nicu-frontend pot rula in paralel (worktrees separate). Restul sunt secventiale.

## Input documents

- PRD funcțional — documentul care descrie ce se construiește
- Prototip UI — fișiere React/TSX cu interfața vizuală
- Design System — bono-ds.css (tokeni, clase, componente)
- Cod existent — repo-urile backend și frontend ale proiectului
