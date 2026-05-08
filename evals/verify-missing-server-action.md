# Eval: nicu-verify prinde API call direct din componentă client

## Tip: verify-code
## Ce testează: Frontend — server actions obligatorii, nu fetch direct

## Input (cod cu bug intenționat)

```tsx
'use client'

export function ExpensesList({ teamId }: { teamId: string }) {
  const { data } = useQuery({
    queryKey: ['expenses', teamId],
    queryFn: () => fetch(`/api/expenses`, {
      headers: { 'X-Team-Id': teamId }
    }).then(r => r.json()),
  });
  // fetch direct din client component, fără server action
}
```

## Expected: FAIL

```
- [FAIL] ExpensesList face fetch direct din client component
- Contract punct: "Server actions, nu API calls din client?"
- Expected: queryFn apelează o server action din app/actions/
```

## Dacă nicu-verify raportează PASS → eval FAILED
