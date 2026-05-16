# SuperNicu

![version](https://img.shields.io/badge/version-2.0-EE4379)
![stack](https://img.shields.io/badge/stack-.NET%2010%20%2B%20Next.js%2015.5-FBFAF7?labelColor=222)
![status](https://img.shields.io/badge/status-active-22c55e)
![for](https://img.shields.io/badge/built%20for-BONO-EE4379)

Un agent de engineering care transformă PRD + prototip UI în aplicație full-stack funcțională.

## Cum funcționează

SuperNicu este un **singur agent** cu un pipeline de 5 faze:

```
PRD + Prototip
     │
     ▼
┌───────────────────┐
│  FAZA 1: SPECS    │ ← produce SPEC per pagină (10 secțiuni + checklist)
└───────────────────┘
     │  ▶ STOP — utilizatorul aprobă
     ▼
┌───────────────────┐
│  FAZA 2: ARCHITECT│ ← securitate, DB, API, component tree
└───────────────────┘
     │  ▶ STOP — utilizatorul aprobă
     ▼
┌───────────────────┐
│  FAZA 3: IMPLEMENT│ ← backend + frontend în paralel (worktrees)
└───────────────────┘
     │
     ▼
┌───────────────────┐
│  FAZA 4: VERIFY   │ ← Swiss Cheese: 6 straturi (Build, Security, SPEC, Quality, DS, Independent Review)
└───────────────────┘
     │  ▶ STOP — utilizatorul confirmă commit
     ▼
┌───────────────────┐
│  FAZA 5: FINALIZE │ ← merge, commit, retrospectivă
└───────────────────┘
```

## Utilizare

```
Tu: /supernicu
    sau: "pornește SuperNicu", "implementează PRD-ul", "construiește aplicația"
```

SuperNicu citește PRD-ul, prototipul, și codul existent, apoi execută pipeline-ul autonom. Se oprește doar la gate-uri (Faza 1, 2, 4) pentru aprobare.

## Exemplu de sesiune

```
Tu: /supernicu
    PRD: docs/prd-transactions.md
    Prototip: docs/prototype-reference/transactions/

SuperNicu: [Faza 1] Citesc PRD + prototip + bono-ds.css...
           Produs 3 SPEC-uri: TransactionsList, TransactionForm, TransactionDetail.
           Fiecare cu 10 secțiuni + checklist verificabil.

           ▶ Raport S10 (Prototip vs DS):
             - Prototipul folosește pill-toggle (NON-STANDARD)
             - Prototipul nu are empty state — propun DS .empty-state-card
             - Câmpul "Suma" diferă: prototip = right-aligned, DS = left

           Aprobi SPEC-urile?

Tu: aprob, dar pune empty state pe ambele liste

SuperNicu: [Faza 2] Security architecture:
           - Customer API: /api/v1/transactions (TenantControllerBase + JWT)
           - Admin API: nu există funcții admin pentru transactions
           - [AllowAnonymous]: zero endpoints noi
           DB: ALTER transactions ADD attachment_url, idx_team_date
           API: 5 endpoints noi
           Ordine fișiere: 12 backend, 8 frontend.

           Confirmi planul?

Tu: da

SuperNicu: [Faza 3] Lansez subagenți paraleli:
           ├─ backend (worktree: feature/transactions-backend)
           └─ frontend (worktree: feature/transactions-frontend)

           ✓ Backend done (12 fișiere, build verde)
           ✓ Frontend done (8 fișiere, build verde, TypeScript clean)

           [Faza 4] Swiss Cheese — 6 straturi:
           ✓ Stratul A — Build: pass
           ✓ Stratul B — Security (Behavior + Structure): 7/7 endpoint, 12/12 query
           ⚠ Stratul C — SPEC compliance: 47/49 items bifate
             (lipsesc: tooltip pe coloana "Sold", error state pe form)
           ✓ Stratul D — Code Quality: zero TODO, zero `any`
           ✓ Stratul E — DS Compliance: zero hex hardcoded + verificare vizuală
           ✓ Stratul F — Independent Review (review-bono): pass pe 3 fișiere flag-uite

           Fix și re-verificare? sau commit așa?

Tu: fix

SuperNicu: ✓ Re-verificare: 49/49 items. Toate OK.
           Confirmi commit?

Tu: da

SuperNicu: [Faza 5] Merge worktrees. Commit pe main.

           Retrospectivă:
           - SPEC-ul TransactionForm a omis error state pentru câmpul "Sumă"
             → Propun regulă nouă R8-ERROR-STATE: fiecare câmp validabil din SPEC
               primește row obligatoriu "Eroare:" în tabel
           - DS lipsește un component "tooltip pe header de tabel"
             → Propun adăugare în shared/bono-ds.css

           Aprobi regulile/completările?
```

## Stack

- **Backend:** .NET 10, ASP.NET Core, NHibernate + FluentNH, MariaDB
- **Frontend:** Next.js 15.5, React 19, TypeScript, Tailwind 3.4, shadcn/ui, TanStack Query 5
- **Design System:** Bono "The Edge" E-33 (flat, token-based, `shared/bono-ds.css`)
- **Patterns:** CQRS, multi-tenant isolation, OperationResult\<T\>, server actions

## Structura

```
supernicu/
├── CLAUDE.md                  # Convenții de cod, pattern-uri, reguli de securitate
├── GUARDRAILS.md              # Pattern-uri de eroare cunoscute (actualizat prin retrospective)
├── skills/
│   └── supernicu/SKILL.md     # Pipeline-ul complet (5 faze)
├── shared/
│   ├── bono-ds.css            # Design System (sursa canonică de tokeni)
│   ├── assets/                # Brand assets
│   └── references/            # DS reference pages
└── hooks/
    ├── pre-commit-build.sh           # Git hook — verifică build verde înainte de commit
    ├── pre-commit-spec.sh            # Git hook — avertizează dacă pagini modificate n-au SPEC
    ├── sync-skill.sh                 # Post-commit — propagă SKILL.md la ~/.claude/skills/
    ├── build-query-safety-matrix.sh  # Faza 2 — auto-generează Query Safety Matrix (G8)
    ├── query-tenant-check.sh         # Faza 4 B.1 — flag-ează queries fără tenant scope (G8)
    ├── schema-preflight.sh           # Faza 2 — scan cascade chains + migration safety (G9)
    └── secrets-scan.sh               # Faza 4 B.3 — secrets/tokens/rate limit scan (G10-G12)
```

Toate hook-urile de tip „flag" sunt **WARN-only**. Validarea adâncimii e job-ul review-bono (Stratul F), nu al grep-ului.

## Bono skills

Standardele canonice Bono (scrise de Prodan, din `bono-ro/bono-skills`) sunt instalate ca user-level skills în `~/.claude/skills/` și se folosesc **în integralitatea lor** — SKILL.md + toate fișierele din `references/` și `assets/`.

| Skill | Conținut |
|-------|----------|
| `dotnet-api-blueprint` | Pattern API .NET — SKILL.md + worked-example.md + conventions.md |
| `nhibernate-cqrs` | NHibernate queries/commands — SKILL.md + 5 references (query-patterns, command-patterns, queryover-reference, execution-modes, entity-mappings) |
| `dotnet-quartz-jobs` | Scheduled jobs — SKILL.md + logging-patterns.md |
| `internal-email-template` | Email templates — SKILL.md + template-pipeline.md + 2 HTML exemple |
| `react-19-vite-frontend` | Pattern frontend — SKILL.md + 8 references + 11 templates + evals |
| `edge-33` | Design System Bono "The Edge" — SKILL.md + BRAND.md + bono-ds.css + 4 HTML pagini + assets |

**Două căi de activare:**
1. **Auto-activation** — Claude le citește când description-ul se potrivește cu task-ul (orice proiect, oricând)
2. **Invocare explicită prin SuperNicu** — Faza 3 instruiește subagenții să citească standardele relevante cu toate `references/`-urile

**Adaptări pentru stack-ul SuperNicu** (documentate în CLAUDE.md):
- ORM: FluentNHibernate `ClassMap<T>` în loc de XML `.hbm.xml`
- API: 6-step direct-DB în loc de 4-layer
- Frontend: Next.js 15.5 App Router + Tailwind 3.4 în loc de Vite 7 + React Router 7 + Tailwind 4
- DTOs: `record` types cu `required`
- Return types: `ValueTask<OperationResult<T>>` pe interfaces, `Task<IActionResult>` pe controllers

## Principii

- **Specs-first** — Fiecare pagină primește un SPEC cu 10 secțiuni înainte de orice cod. SPEC-ul = criteriile de acceptare
- **Security pit of success** — Codul sigur e calea implicită. `FallbackPolicy` deny-by-default, `TenantControllerBase`, anti-IDOR
- **Swiss Cheese verification** — 6 straturi independente de verificare (Build, Security, SPEC, Quality, DS, Independent Review). Găurile unui strat nu se aliniază cu ale altuia. Toate trebuie să treacă pentru commit
- **Calitate > Viteza** — Pixel-perfect cu SPEC complet. Nu oferim "rapid dar inconsistent"
- **Self-improving** — Fiecare retrospectivă adaugă reguli în GUARDRAILS.md
- **Parallel execution** — Backend + frontend rulează simultan în worktrees separate
- **Autonomie** — Se oprește doar pentru: aprobări gate, PRD incomplet, security blocker

## Versiuni

- **v2.0** *(current)* — Single agent, unified pipeline, 5 faze cu gate stops
- **v1.0** — Multi-skill architecture (7 nicu-* skills + standards) — `git checkout v1.0`

---

Construit pentru [BONO](https://bono.ro).
