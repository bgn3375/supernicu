---
name: review
description: Code review and security audit skill. Pattern compliance, security, multi-tenant, Design System. Fires on "review code", "security audit", "final check", or at lifecycle end before merge.
---

# Review — Code Review + Security Audit

Ultimul pas din pipeline. După review APPROVED → merge în GitHub.

Vezi `contracts/review-contract.md` pentru output format complet.

## Ce verifică (5 categorii)

### 1. Pattern Compliance

**Backend:**
- Ordinea: interface → DTOs → query/command → adapter → controller → DI?
- CQRS: queries separate de commands?
- OperationResult<T> pe toate service-urile?
- Record types cu `required` pe DTOs?
- ValueTask pe interfaces, Task pe controllers?
- NHibernate sessions (nu Entity Framework)?

**Frontend:**
- Ordinea: types → server actions → hooks → components → pages → nav?
- Server actions cu `"use server"`?
- TanStack Query hooks cu query keys consistente?
- Stiluri copiate din prototip (nu inventate)?

### 2. Security

- Fiecare query filtrează pe `team_id` (NHibernate tenantFilter activ)?
- Fiecare controller are `[Authorize]`?
- Queries parametrizate (NHibernate params, nu string concat)?
- Zero `dangerouslySetInnerHTML`?
- Zero secrets în cod frontend?
- CSRF protecție pe mutații?
- X-Team-Id validat (user are acces la acel team)?

### 3. Code Quality

- Fișiere sub 150 linii?
- Naming consistent?
- Zero cod duplicat?
- Zero cod mort?
- Error handling: OperationResult backend, error boundaries frontend?

### 4. Design System

- Tokens din Bono The Edge, nu hex hardcodat?
- Apple Liquid Glass: backdrop-filter, transparențe, shadows din prototip?
- Teal pe calendare și date-pickers?
- Dark mode fără artefacte?

### 5. Architecture Alignment

- Codul implementează exact architecture.md?
- Zero endpoint-uri extra sau lipsă?
- Component Tree respectat?
- Namespace-uri corecte: PnL.DomainServices, PnL.ServiceAdapters, PnL.Api?

## Verdict

- **APPROVED** — merge în GitHub
- **CHANGES REQUESTED** — repair loop

Un security BLOCKER = CHANGES REQUESTED automat.

## Reguli

- Opus model — judecată critică
- NU rescrie cod, doar identifică issues
- Recommendations non-blocking se notează separat
- Raportul către Brain: maxim 5 rânduri
