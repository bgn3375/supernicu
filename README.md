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
│  FAZA 4: VERIFY   │ ← Swiss Cheese: 5 straturi (Build, Security, SPEC, Quality, DS)
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

           [Faza 4] Swiss Cheese — 5 straturi:
           ✓ Stratul A — Build: pass
           ✓ Stratul B — Security: 7/7 (toate endpoint-urile require auth)
           ⚠ Stratul C — SPEC compliance: 47/49 items bifate
             (lipsesc: tooltip pe coloana "Sold", error state pe form)
           ✓ Stratul D — Code Quality: zero TODO, zero `any`
           ✓ Stratul E — DS Compliance: zero hex hardcoded

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
    ├── pre-commit-build.sh    # Verifică build verde înainte de commit
    └── pre-commit-spec.sh     # Avertizează dacă pagini modificate n-au SPEC
```

**bono-skills** (user skills în `~/.claude/skills/`) conține standardele canonice Bono — se auto-activează când Claude Code întâlnește cod relevant, ȘI sunt invocate explicit de SuperNicu în Faza 3.

## Principii

- **Specs-first** — Fiecare pagină primește un SPEC cu 10 secțiuni înainte de orice cod. SPEC-ul = criteriile de acceptare
- **Security pit of success** — Codul sigur e calea implicită. `FallbackPolicy` deny-by-default, `TenantControllerBase`, anti-IDOR
- **Swiss Cheese verification** — 5 straturi independente de verificare. Găurile unui strat nu se aliniază cu ale altuia. Toate trebuie să treacă pentru commit
- **Calitate > Viteza** — Pixel-perfect cu SPEC complet. Nu oferim "rapid dar inconsistent"
- **Self-improving** — Fiecare retrospectivă adaugă reguli în GUARDRAILS.md
- **Parallel execution** — Backend + frontend rulează simultan în worktrees separate
- **Autonomie** — Se oprește doar pentru: aprobări gate, PRD incomplet, security blocker

## Versiuni

- **v2.0** *(current)* — Single agent, unified pipeline, 5 faze cu gate stops
- **v1.0** — Multi-skill architecture (7 nicu-* skills + standards) — `git checkout v1.0`

---

Construit pentru [BONO](https://bono.ro).
