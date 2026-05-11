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

## Input documents

- PRD funcțional — documentul care descrie ce se construiește
- Prototip UI — fișiere React/TSX cu interfața vizuală
- Design System — bono-ds.css (tokeni, clase, componente)
- Cod existent — repo-urile backend și frontend ale proiectului
- GUARDRAILS.md — pattern-uri de eroare cunoscute, actualizat după fiecare retrospectivă
