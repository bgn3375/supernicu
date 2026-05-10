# SuperNicu

A multi-agent engineering system that turns product specs into production code.

SuperNicu takes a PRD and UI prototype as input, orchestrates 7 specialized agents, and outputs a working full-stack application — backend, frontend, tested and reviewed.

## How it works

```
PRD + Prototype
     │
     ▼
┌─────────┐     ┌────────────┐     ┌────────────────────────┐
│  Specs  │────▶│ Orchestrator│────▶│ Architect              │
└─────────┘     └────────────┘     └────────────────────────┘
                                          │
                                    ┌─────┴─────┐
                                    ▼           ▼
                              ┌──────────┐ ┌──────────┐
                              │ Backend  │ │ Frontend │  ← parallel
                              └──────────┘ └──────────┘
                                    └─────┬─────┘
                                          ▼
                                    ┌──────────┐
                                    │    QA    │
                                    └──────────┘
                                          │
                                          ▼
                                    ┌──────────┐
                                    │  Review  │
                                    └──────────┘
                                          │
                                          ▼
                                       Commit
```

**Specs** is the gatekeeper — no implementation starts without an approved SPEC document. After implementation, it runs a retrospective and accumulates rules to prevent repeat mistakes.

## Agents

| Agent | Role |
|-------|------|
| `nicu-specs` | Produces a detailed SPEC per page (9 sections + checklist). Blocks implementation until user approves. Runs retrospective post-build. |
| `nicu-orchestrator` | Reads PRD, creates execution plan, delegates to specialists, manages parallel work. |
| `nicu-architect` | Designs DB schema, API contracts, component tree. |
| `nicu-backend` | Writes .NET code: entities, NHibernate mappings, CQRS services, controllers. |
| `nicu-frontend` | Writes Next.js code: types, API layer, hooks, components, pages. |
| `nicu-qa` | Build verification, unit tests, browser check, edge cases. |
| `nicu-review` | Code review + security audit against 6 checklists. |

## Stack

- **Backend:** .NET 10, ASP.NET Core, NHibernate, MariaDB
- **Frontend:** Next.js 15.5, React 19, TypeScript, Tailwind, shadcn/ui, TanStack Query
- **Design System:** Bono "The Edge" E-33 (flat, token-based)
- **Patterns:** CQRS, multi-tenant isolation, OperationResult\<T\>

## Structure

```
supernicu/
├── CLAUDE.md              # Main config — stack, rules, lifecycle
├── shared/
│   ├── bono-ds.css        # Design System (single source of truth)
│   ├── assets/            # Brand assets
│   └── references/        # DS reference pages
└── skills/
    ├── nicu-specs/        # SPEC production + retrospective
    ├── nicu-orchestrator/ # Task coordination
    ├── nicu-architect/    # Architecture design
    ├── nicu-backend/      # .NET implementation
    ├── nicu-frontend/     # Next.js implementation
    ├── nicu-qa/           # Testing & verification
    └── nicu-review/       # Code review & security
```

## Key design decisions

- **Specs-first workflow** — Every page gets a 9-section SPEC before any code is written. The SPEC becomes the acceptance criteria.
- **Self-improving** — Each retrospective adds rules that prevent the same class of error from recurring.
- **Parallel execution** — Backend and frontend run in separate worktrees simultaneously.
- **Single DS source** — One CSS file in `shared/` referenced by specs, frontend, and review agents.
- **No skipped steps** — The pipeline is strict. QA catches build issues, Review catches pattern violations, Specs catches drift from requirements.

## Usage

SuperNicu runs as a Claude Code plugin. Point it at a PRD + prototype and it handles the rest.

```
You: "Implementează pagina Transactions conform PRD-ului"
SuperNicu: specs → plan → build → test → review → commit
```

## Error handling

- Build fails → agent fixes and retries (up to 3x)
- SPEC mismatch → changes requested, agent corrects
- Security issue → review blocks merge, provides fix location
- Ambiguity in PRD → stops and asks user

---

Built for [BONO](https://bono.ro) engineering.
