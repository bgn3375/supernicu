# SuperNicu

Un agent de engineering care transformă PRD + prototip UI în aplicație full-stack funcțională.

## Cum funcționează

SuperNicu este un **singur agent** cu un pipeline de 5 faze:

```
PRD + Prototip
     │
     ▼
┌──────────────────┐
│  FAZA 1: SPECS   │ ← produce SPEC per pagină (10 secțiuni + checklist)
└──────────────────┘
     │  ▶ STOP — utilizatorul aprobă
     ▼
┌──────────────────┐
│  FAZA 2: ARCHITECT│ ← securitate, DB, API, component tree
└──────────────────┘
     │  ▶ STOP — utilizatorul aprobă
     ▼
┌──────────────────┐
│  FAZA 3: IMPLEMENT│ ← backend + frontend în paralel (worktrees)
└──────────────────┘
     │
     ▼
┌──────────────────┐
│  FAZA 4: VERIFY  │ ← build, security, SPEC compliance, code quality
└──────────────────┘
     │  ▶ STOP — utilizatorul confirmă commit
     ▼
┌──────────────────┐
│  FAZA 5: FINALIZE│ ← merge, commit, retrospectivă
└──────────────────┘
```

## Utilizare

```
Tu: /supernicu
    sau: "pornește SuperNicu", "implementează PRD-ul", "construiește aplicația"
```

SuperNicu citește PRD-ul, prototipul, și codul existent, apoi execută pipeline-ul autonom. Se oprește doar la gate-uri (Faza 1, 2, 4) pentru aprobare.

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

**bono-skills** (plugin separat în `~/.claude/plugins/bono-skills/`) conține standardele canonice Bono — se auto-activează când Claude Code întâlnește cod relevant.

## Principii

- **Specs-first** — Fiecare pagină primește un SPEC cu 10 secțiuni înainte de orice cod. SPEC-ul = criteriile de acceptare
- **Security pit of success** — Codul sigur e calea implicită. `FallbackPolicy` deny-by-default, `TenantControllerBase`, anti-IDOR
- **Calitate > Viteza** — Pixel-perfect cu SPEC complet. Nu oferim "rapid dar inconsistent"
- **Self-improving** — Fiecare retrospectivă adaugă reguli în GUARDRAILS.md
- **Parallel execution** — Backend + frontend rulează simultan în worktrees separate
- **Autonomie** — Se oprește doar pentru: aprobări gate, PRD incomplet, security blocker

---

Construit pentru [BONO](https://bono.ro).
