---
name: arhi
description: Architecture design skill. Produces architecture.md with Data Model, API Endpoints, Component Tree, Security Requirements. Fires on "design architecture", "plan the structure", "what components do we need".
---

# Arhi — Architecture Design

Proiectează arhitectura tehnică a unui modul sau a întregii aplicații.

## Stack

- **Backend:** .NET 10 + ASP.NET Core 10 + NHibernate 5.6 + MariaDB
- **Frontend:** Next.js 15 (App Router) + React 19 + TypeScript 5 + Tailwind + shadcn/ui
- **Multi-tenant:** X-Team-Id header + NHibernate tenantFilter pe team_id
- **Auth:** Magic Link + Google OAuth + JWT
- **Design:** Bono The Edge (flat, bej surfaces, pink accent, tokens din bono-ds.css)

## Output: architecture.md

Document cu 4 secțiuni. Vezi `contracts/architect-contract.md` pentru detalii.

### Secțiunea 1: Data Model

Per tabel:
```markdown
### expenses
| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | CHAR(36) | NO | GuidComb | PK |
| team_id | CHAR(36) | NO | - | Tenant isolation |
| amount_ron | DECIMAL(18,2) | NO | - | Suma în RON |
| amount_eur | DECIMAL(18,2) | YES | - | Echivalent EUR |
| currency | VARCHAR(3) | NO | 'RON' | RON/EUR/USD/GBP |
| exchange_rate | DECIMAL(18,6) | YES | - | Curs BNR |
...

FK: category_id → categories.id (RESTRICT)
FK: created_by → users.id (RESTRICT)
Index: idx_expenses_team_id (team_id)
Index: idx_expenses_category (category_id)
```

### Secțiunea 2: API Endpoints

Per endpoint:
```markdown
### POST /api/expenses
- Auth: Admin, Approver, Member
- Request DTO: CreateExpenseRequest { amount, currency, categoryId, ... }
- Response DTO: ExpenseResponse { id, amount, status, ... }
- Validations: amount > 0, categoryId exists, currency in [RON,EUR,USD,GBP]
```

### Secțiunea 3: Component Tree

Per ecran:
```markdown
### /dashboard/[teamId]/expenses
ExpensesPage (server component)
  └── ExpensesList (client component)
        ├── ExpenseListHeader — filtre, search, buton "Adaugă"
        ├── ExpenseListItem[] — per expense: furnizor, sumă, status, acțiuni
        │     └── props: expense: ExpenseResponse
        │     └── endpoint: GET /api/expenses (via useExpenses hook)
        ├── ExpenseEmptyState — când lista e goală
        └── ExpensePagination — paginare
```

### Secțiunea 4: Security Requirements

```markdown
### Matrice roluri × endpoints (modul Expenses)
| Endpoint | Admin | Approver | Member | Accounting Viewer |
|----------|-------|----------|--------|-------------------|
| GET /api/expenses | ✓ | ✓ | own only | ✓ |
| POST /api/expenses | ✓ | ✓ | ✓ | ✗ |
| PUT /api/expenses/{id}/approve | ✓ | ✓ | ✗ | ✗ |
```

## Backend namespace-uri

```
PnL.DomainServices/{Feature}/
  I{Feature}Service.cs
  {Feature}Dtos.cs
  Queries/
  Commands/

PnL.ServiceAdapters/{Feature}/
  {Feature}ServiceAdapter.cs

PnL.Api/Controllers/
  {Feature}Controller.cs
```

## Frontend structura

```
app/dashboard/[teamId]/{feature}/
  page.tsx
app/actions/
  {feature}.ts
components/{feature}/
  {Component}.tsx
hooks/
  use{Feature}.ts
types/
  {feature}.ts
```

## Reguli

1. Citește PRD-ul complet înainte de orice.
2. Fiecare tabel are `team_id`.
3. An fiscal Aug-Aug (13 luni) în module cu perioade.
4. Multi-currency unde PRD-ul cere.
5. NU scrie cod — doar structură logică.
6. Dacă PRD-ul e ambiguu, listează ambiguitatea. Nu ghici.
7. Verifică output-ul contra checklist din `contracts/architect-contract.md`.
