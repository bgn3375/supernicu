---
name: plan
description: Task breakdown and DAG generation skill. Decomposes architecture.md into epics → stories → tasks with dependencies. Fires on "break down into tasks", "create execution plan", "task dependencies".
---

# Plan — Task Breakdown & DAG

Descompune architecture.md în task-uri executabile cu dependențe.

## Structura

```
Epic (modul mare — ex: Expenses)
  └── Story (funcționalitate — ex: Listare cheltuieli)
        └── Task (unitate de lucru — ex: Scrie ListExpensesQuery.cs)
```

## Format task

```markdown
### TASK-E1-001: Create Expense service interface
- Epic: Expenses
- Story: CRUD Expenses
- Agent: nicu-backend
- Contract: backend-contract.md (pas 1: service interface)
- Input: architecture.md secțiunea API Endpoints > Expenses
- Output: PnL.DomainServices/Expenses/IExpenseService.cs
- Depends on: (none)
- Skills: api-endpoints
```

## Reguli DAG

1. **DB schema primul.** Tabele înainte de queries/commands.
2. **Backend înainte de frontend.** API endpoints înainte de UI.
3. **Interface înainte de implementare.** Service interface → adapter → controller.
4. **Shared înainte de feature.** Componente shared → feature components → pages.
5. **Fiecare task are un singur output.** Un fișier sau un set mic de fișiere.
6. **Fiecare task specifică agentul.** nicu-backend sau nicu-frontend.
7. **Fiecare task specifică contractul** și pasul din contract.
8. **Fiecare task specifică skill-urile** necesare.

## Ordinea pe module

```
1. DB schema (tabele + mappings) — nicu-backend
2. Backend per endpoint (6 pași din contract) — nicu-backend
3. Frontend per ecran (6 pași din contract) — nicu-frontend
4. Integration (server actions → backend) — nicu-frontend
```

## Output

Un document `plan.md` cu:
- Lista epics
- Lista stories per epic
- Lista tasks per story (cu dependențe)
- Ordinea de execuție (topological sort pe DAG)
- Estimare: câte task-uri total
