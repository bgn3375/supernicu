# SuperNicu

**Un super-agent care transformă specificații în aplicații funcționale.**

SuperNicu primește un PRD (Product Requirements Document) de la Bruce și un prototip UI din Claude Design, apoi generează singur o aplicație full-stack — backend, frontend, bază de date, teste — gata de deploy.

---

## Cum funcționează

E un sistem de agenți AI care lucrează ca o echipă de programatori — fiecare cu un rol clar, reguli stricte, și verificări la fiecare pas.

Trei agenți principali, șase sub-agenți specializați:

```
Bruce PRD + Prototip UI
        │
        ▼
    ┌─ Brain ─────────────────────────┐
    │  Orchestratorul. Nu scrie cod.  │
    │  Citește PRD-ul, face planul,   │
    │  deleghează, verifică.          │
    │                                 │
    │  nicu-architect → arhitectura   │
    │  nicu-verify   → PASS / FAIL   │
    │  nicu-review   → approve / fix  │
    └────────────┬────────────────────┘
                 │
        ┌────────┴────────┐
        ▼                 ▼
    ┌─ Hands ─┐     ┌─ Test ──┐
    │ Scrie   │     │ Testează│
    │ codul   │     │ totul   │
    │         │     │         │
    │ backend │     │ nicu-qa │
    │ frontend│     │ 7 layere│
    └─────────┘     └─────────┘
                         │
                         ▼
                  GitHub repo ✓
```

**Brain** (Opus) e un dispecer subțire. Nu citește cod, nu analizează fișiere. Primește doar verdicte de 5 linii: PASS sau FAIL. Dacă FAIL, trimite înapoi la Hands cu instrucțiuni precise. Max 3 încercări per task — dacă nu trece, se oprește și raportează.

**Hands** (Sonnet) scrie cod. Un task la un moment dat, build verde obligatoriu după fiecare. Doi sub-agenți: `nicu-backend` pentru .NET și `nicu-frontend` pentru Next.js.

**Test** (Sonnet) testează tot ce au scris ceilalți. 7 straturi de verificare (Swiss Cheese): build, unit tests, integration, UI, security, spec compliance, cross-reference. Raportează buguri, nu le repară.

## Ciclul complet

1. **Input** — Brain primește PRD-ul de la Bruce + screenshots și cod React din prototip
2. **Arhitectură** — `nicu-architect` proiectează: schema DB, API endpoints, component tree
3. **Verificare** — `nicu-verify` confirmă arhitectura contra PRD (PASS/FAIL)
4. **Backend** — `nicu-backend` scrie codul .NET urmând un pattern de 6 pași
5. **Verificare** — `nicu-verify` confirmă backend-ul contra contractului
6. **Frontend** — `nicu-frontend` scrie codul Next.js urmând un pattern de 6 pași
7. **Verificare** — `nicu-verify` confirmă frontend-ul contra contractului
8. **QA** — `nicu-qa` rulează cele 7 straturi de teste
9. **Review** — `nicu-review` face code review + security audit
10. **Output** — Cod funcțional într-un GitHub repo

Fiecare pas are un **contract** care definește exact ce primește și ce livrează. Fiecare contract are un **checklist** mecanic — nu interpretare subiectivă, ci verificare punct cu punct.

## Stack-ul tehnic

| Layer | Tehnologii |
|-------|-----------|
| Backend | .NET 10, ASP.NET Core, NHibernate, MariaDB |
| Frontend | Next.js 15, React 19, TypeScript, Tailwind, shadcn/ui |
| Design | Bono The Edge — Apple Liquid Glass (frosted glass, teal, dark mode) |
| Auth | Magic Link + Google OAuth + JWT |
| Multi-tenant | Header X-Team-Id + NHibernate filter |
| Teste | Vitest (unit), Playwright (E2E) |

## Ce conține repo-ul

```
supernicu/
├── CLAUDE.md          ← regulile globale + stack-ul real
├── agents/            ← Brain, Hands, Test — fiecare cu CLAUDE.md propriu
├── contracts/         ← 7 contracte (input/output/checklist per sub-agent)
├── skills/            ← 15 skills tehnice (DB, API, forms, auth, etc.)
├── evals/             ← 15 teste care verifică că verificatorul prinde buguri
└── prd/               ← PRD-uri de la Bruce
```

## Principii

- **Calitate, nu viteză.** Zero bugs e mai important decât livrare rapidă.
- **Verificare la fiecare pas.** Niciun cod nu trece neverificat.
- **Contracte, nu instrucțiuni vagi.** Fiecare agent știe exact ce primește și ce livrează.
- **Fresh spawn.** Verificatorul pornește de la zero de fiecare dată — fără bias.
- **Fail fast.** Dacă ceva nu merge după 3 încercări, se oprește și raportează.

---

*SuperNicu e parte din ecosistemul BONO, unde Bruce scrie specificațiile, Claude Design face prototipul, iar SuperNicu transformă totul în cod funcțional.*
