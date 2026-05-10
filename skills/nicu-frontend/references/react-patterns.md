# React Patterns — BONO Frontend

## Project structure (standard per proiect)

```
app/
  (landing-page)/           — public pages
  login/                    — auth flow
  dashboard/[teamId]/       — authenticated pages per tenant
components/
  ui/                       — shadcn/ui primitives
  [feature]/                — feature-specific components
hooks/
  use-[entity].ts           — TanStack Query hooks
lib/
  api/                      — API layer (typed fetch wrappers)
  utils/                    — helpers
types/
  [entity].ts              — TypeScript interfaces
```

### Next.js App Router Patterns

**Server Component (default):**
```tsx
// app/dashboard/[teamId]/[module]/page.tsx
import { EntityTable } from '@/components/[feature]/entity-table';

export default async function EntityPage({
  params,
}: {
  params: { teamId: string };
}) {
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-lg font-semibold">Titlu pagină</h1>
      </div>
      <EntityTable teamId={params.teamId} />
    </div>
  );
}
```

**Client Component with TanStack Query:**
```tsx
"use client";

import { useQuery } from '@tanstack/react-query';
import { entityApi } from '@/lib/api/entities';

interface Props {
  teamId: string;
}

export function EntityTable({ teamId }: Props) {
  const { data, isLoading, error } = useQuery({
    queryKey: ['entities', teamId],
    queryFn: () => entityApi.list(teamId),
  });

  if (isLoading) return <TableSkeleton />;
  if (error) return <ErrorState />;

  return (
    <table className="w-full">
      {/* ... */}
    </table>
  );
}
```

### API Client Pattern

```tsx
// lib/api/client.ts
const BASE_URL = process.env.NEXT_PUBLIC_API_URL;

export async function apiClient<T>(
  path: string,
  options: RequestInit & { teamId?: string } = {}
): Promise<T> {
  const { teamId, ...fetchOptions } = options;
  
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(teamId ? { 'X-Team-Id': teamId } : {}),
    // JWT token from cookie/context
  };

  const res = await fetch(`${BASE_URL}/api/v1${path}`, {
    ...fetchOptions,
    headers: { ...headers, ...fetchOptions.headers },
  });

  if (!res.ok) throw new Error(`API error: ${res.status}`);
  return res.json();
}
```

### Bono DS + Tailwind Integration

```ts
// tailwind.config.ts
export default {
  theme: {
    extend: {
      colors: {
        'bej-0': '#FBFAF7',
        'bej-1': '#EFEBE4',
        'ink': '#110D10',
        'fog': '#7A7570',
        'mist': '#ABA59E',
        'pink': '#EE4379',
        'success': '#1F7A4D',
        'success-bg': '#ECF7F1',
        'error': '#B91C1C',
        'error-bg': '#FCEAEA',
        'warn': '#B8580A',
        'warn-bg': '#FBF1E2',
      },
      borderRadius: {
        'pill': '9999px',
        'md-ds': '14px',
        'sm-ds': '10px',
      },
      borderColor: {
        'rule-card': 'rgba(17,13,16,0.12)',
        'rule-soft': 'rgba(17,13,16,0.06)',
      },
    },
  },
};
```

### Component Conventions

```tsx
// File naming: kebab-case
// entity-form.tsx, entity-list.tsx

// Component naming: PascalCase
export function EntityForm({ teamId }: Props) { ... }

// Hook naming: camelCase with use prefix
export function useEntities(teamId: string) { ... }

// Types: separate file in types/
export interface Entity { ... }
export interface CreateEntityRequest { ... }
```
