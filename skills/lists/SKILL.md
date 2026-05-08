---
name: lists
description: List and table implementation skill for Next.js 15. Paginated tables, filtered views, search, empty states. Fires on "list", "table", "pagination", "filter", "search", "data grid".
---

# Lists — Tables & Lists in Next.js 15

Pattern-uri pentru liste de date, tabele, filtre, paginare.

## Stack

- Next.js 15 App Router
- TanStack React Query 5
- shadcn/ui Table components
- `useSearchParams` din `next/navigation` (NU din react-router-dom)

## Pattern: Lista cu filtre

### 1. Server action

```typescript
// app/actions/expenses.ts
'use server'

export async function getExpenses(teamId: string, params: {
  page?: number;
  search?: string;
  status?: string;
}) {
  const token = await getAccessToken();
  const query = new URLSearchParams();
  if (params.page) query.set('page', String(params.page));
  if (params.search) query.set('search', params.search);
  if (params.status) query.set('status', params.status);

  const res = await fetch(`${API_URL}/api/expenses?${query}`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'X-Team-Id': teamId,
    },
  });
  return res.json();
}
```

### 2. TanStack Query hook

```typescript
// hooks/useExpenses.ts
export function useExpenses(teamId: string, params: ListParams) {
  return useQuery({
    queryKey: ['expenses', teamId, params],
    queryFn: () => getExpenses(teamId, params),
  });
}
```

### 3. List component

```typescript
// components/expenses/ExpensesList.tsx
'use client'

import { useSearchParams } from 'next/navigation';

export function ExpensesList({ teamId }: { teamId: string }) {
  const searchParams = useSearchParams();
  const page = Number(searchParams.get('page') ?? '1');
  const search = searchParams.get('search') ?? '';

  const { data, isLoading } = useExpenses(teamId, { page, search });

  if (isLoading) return <ListSkeleton />;
  if (!data?.items.length) return <EmptyState />;

  return (
    <Table>
      <TableHeader>...</TableHeader>
      <TableBody>
        {data.items.map(item => <ListItem key={item.id} item={item} />)}
      </TableBody>
    </Table>
  );
}
```

## Componente obligatorii per listă

1. **Header** — titlu, search, filtre, buton acțiune
2. **Loading skeleton** — placeholder vizual cât se încarcă
3. **Empty state** — mesaj + acțiune când lista e goală
4. **List items** — rânduri cu date
5. **Pagination** — dacă >1 pagină

## Reguli

1. `useSearchParams` din `next/navigation`, NU din react-router-dom.
2. Filtrele sunt URL-driven (searchParams). Refresh-ul păstrează filtrele.
3. Server actions pentru data fetching, nu fetch direct din componente.
4. Stiluri din prototip (Bono The Edge — flat, bej, pink accent).
5. Fiecare fișier sub 150 linii.
6. Dark mode suportat.
