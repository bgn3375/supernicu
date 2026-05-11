# API Layer — TanStack Query + Services

Anatomy and recipes for the data-fetching layer. Read this whenever you wire a new endpoint, refactor an existing service, or change cache behaviour.

## `httpClient` — the one fetch wrapper

Lives at `src/api/core/httpClient.ts`. All network calls go through it. It provides:

- `credentials: 'include'` on every request — cookies from the ASP.NET Core reverse-proxy layer flow automatically.
- JSON content-type default, overridable via `options.headers`.
- Response body parsing: empty body → `undefined`; non-empty → `JSON.parse`. No silent empty-string coercion.
- Error extraction: for non-`ok` responses it reads the body, parses JSON, and lifts `ErrorMessage`, `ErrorCode`, `errorMessage`, `message`, or `error` (in that order). Falls back to `HTTP {status}: {statusText}`.
- 401 hook: if a handler has been registered with `setUnauthorizedHandler`, it fires before the error is thrown. The template wires this in `src/main.tsx:15-17` to `authService.clearCache()`.

Surface:

```ts
httpClient.get<T>(endpoint: string): Promise<T>;
httpClient.post<T>(endpoint: string, body: unknown | FormData): Promise<T>;
httpClient.put<T>(endpoint: string, body: unknown): Promise<T>;
httpClient.delete<T>(endpoint: string): Promise<T>;
httpClient.getBlob(endpoint: string): Promise<Blob>;
httpClient.setUnauthorizedHandler(handler: () => void): void;
```

`post` accepts `FormData` directly (no `JSON.stringify`, no `Content-Type` — the browser sets the multipart boundary).

**Do not** add a second wrapper. If you need a new verb, extend `httpClient.ts` itself.

## `queryClient` defaults

Defined once at `src/lib/queryClient.ts`:

```ts
new QueryClient({
  defaultOptions: {
    queries: { staleTime: 0, gcTime: 300_000, retry: 2 },
  },
});
```

Implications:

- `staleTime: 0` → every hook refetches on mount. Override to `Infinity` for identity-shaped data (user profile) where staleness across the session is acceptable.
- `gcTime: 300_000` (300,000 ms = 5 minutes) → cache entries live 5 minutes after the last observer unmounts. Infinite lists override to `gcTime: 0` so filter changes do not resurrect stale pages.
- `retry: 2` → default two retries per query. Mutations do not retry by default; keep that.

## Query keys — `src/api/{feature}/{feature}QueryKeys.ts`

Pattern:

```ts
export const {feature}QueryKeys = {
  all: ['{feature}'] as const,
  list: (filters: Record<string, unknown>) => ['{feature}', 'list', filters] as const,
  detail: (id: number) => ['{feature}', 'detail', id] as const,
} as const;
```

Conventions:

- Root namespace is the feature slug (`['items']`, `['auth']`).
- Sub-keys are tuples with a literal discriminator (`'list'`, `'detail'`, `'profile'`).
- Parameterised keys are **functions** that return a tuple — never object keys. TanStack Query compares by structural equality and keys passed through `JSON.stringify` must be stable.
- `as const` on both the object and each returned tuple — this is what makes `ReturnType<typeof queryKeys.list>` usable as a `useInfiniteQuery` type parameter.

Invalidation:

```ts
queryClient.invalidateQueries({ queryKey: {feature}QueryKeys.all });       // everything under {feature}
queryClient.invalidateQueries({ queryKey: {feature}QueryKeys.list(f) });   // a specific list
queryClient.removeQueries({ queryKey: {feature}QueryKeys.detail(id) });    // evict a single record
```

Mutations that write to a feature invalidate its list keys on `onSuccess`, not inside the hook.

## Service — `src/api/{feature}/{feature}Service.ts`

```ts
import { httpClient } from '@/api/core/httpClient';
import type { {Feature}PagedFilter, {Feature}PagedResult } from '@/types';

export const {feature}Service = {
  get{Feature}s: (filter: {Feature}PagedFilter): Promise<{Feature}PagedResult> =>
    httpClient.post<{Feature}PagedResult>('/api/{feature-route}/list', filter),

  get{Feature}: (id: number): Promise<{Feature}> =>
    httpClient.get<{Feature}>(`/api/{feature-route}/${id}`),
};
```

Rules:

- Plain namespace object, arrow-function members. No classes, no decorators, no DI container.
- Each method has a single responsibility: one verb + one endpoint. Compose in hooks or pages, not here.
- Argument shape uses project types from `@/types`; response type is the full DTO as returned by the backend (PascalCase fields — do not lowercase).
- `FilterOption` from `src/types/pagination.ts` is `{ Id: number; Text: string }` — used for entity selectors (see `PersonCombobox`). This is **not** the shape of enum-filter lists like `ITEM_STATUS_OPTIONS`, which are `{ value: string; label: string }[]` defined inline in `src/lib/{feature}FilterOptions.ts` with `as const`. Do not conflate the two.
- Paged reads use `POST /api/{feature-route}/list` with a `PagedFilter`-based body. The proxy layer expects this shape (see `dotnet-api-blueprint` skill for the server-side contract).
- Field-name tolerance at the boundary: if the backend sometimes returns camelCase, map in a private helper (see `mapUserProfile` in `src/api/auth/authService.ts:47-51`). Never mutate responses — build a new object.

## Query hook recipes — `src/hooks/use{Feature}*.ts`

### Infinite list

```ts
import { useInfiniteQuery, type InfiniteData } from '@tanstack/react-query';
import { {feature}Service } from '@/api/{feature}/{feature}Service';
import { {feature}QueryKeys } from '@/api/{feature}/{feature}QueryKeys';
import type { {Feature}PagedResult, {Feature}Status } from '@/types';

const PAGE_SIZE = 20;

export function use{Feature}sInfiniteQuery({ searchText, status }: { searchText?: string; status?: {Feature}Status }) {
  const { data, isLoading, isFetchingNextPage, hasNextPage, fetchNextPage } = useInfiniteQuery<
    {Feature}PagedResult,
    Error,
    InfiniteData<{Feature}PagedResult>,
    ReturnType<typeof {feature}QueryKeys.list>,
    number
  >({
    queryKey: {feature}QueryKeys.list({ searchText, status }),
    queryFn: ({ pageParam }) =>
      {feature}Service.get{Feature}s({
        StartIndex: pageParam,
        MaxResults: PAGE_SIZE,
        SearchText: searchText,
        Status: status,
      }),
    initialPageParam: 0,
    getNextPageParam: (lastPage, _all, lastPageParam) =>
      lastPage.HasMoreRecords ? lastPageParam + PAGE_SIZE : undefined,
    refetchOnWindowFocus: false,
    gcTime: 0,
  });

  return {
    items: data?.pages.flatMap((p) => p.Items) ?? [],
    totalCount: data?.pages[0]?.TotalRecords ?? 0,
    hasMore: hasNextPage,
    isLoadingMore: isFetchingNextPage,
    isInitialLoading: isLoading,
    fetchNextPage,
  };
}
```

Fixed choices (do not bikeshed):

- `PAGE_SIZE = 20`.
- `refetchOnWindowFocus: false` — infinite lists would flash the first page.
- `gcTime: 0` — filter changes should produce a clean slate.
- `StartIndex`/`MaxResults`/`HasMoreRecords` — matches the server contract in `src/types/pagination.ts`.

### Single record (identity-shaped)

Copy `src/hooks/useCurrentUserProfileQuery.ts`:

- `staleTime: Infinity`, `gcTime: Infinity` — profile does not change mid-session.
- `refetchOnWindowFocus: false`, `retry: false` — unauth redirect handles re-auth; retries would mask the 401 hook.
- Destructure `isPending` (not `isLoading`) for `useQuery` — the template aliases it to `isLoading` in the return to keep page code uniform.

### Single record (fresh)

Same as above with `staleTime: 0` and default `gcTime`. Use for records that mutate during a session (invoice detail, user settings).

### Mutation

Copy `src/hooks/useChangePassword.ts`:

```ts
export function use{Feature}Save() {
  return useMutation({
    mutationFn: (payload: {Feature}) => {feature}Service.save{Feature}(payload),
  });
}
```

No toasts, no invalidation, no optimistic updates inside the hook. The page supplies `onSuccess` / `onError`; optimistic updates and invalidation live there too. This keeps hooks reusable across pages that need different UX.

## Barrel — `src/hooks/index.ts`

Every new hook is re-exported:

```ts
export { use{Feature}sInfiniteQuery } from './use{Feature}sInfiniteQuery';
```

Pages import from `@/hooks`, never from `@/hooks/use{Feature}sInfiniteQuery` directly.

## `use()` for conditional context reads

React 19's `use()` can be called conditionally and inside loops — unlike `useContext`, which must run unconditionally. It is the right tool when a context read must be gated on a prop or feature flag before the branch returns early. For server state, keep using TanStack Query hooks; `use(promise)` is **not** the template's data-fetching layer — no ad-hoc promises passed into `use()` in feature code.

See `references/react-19-hooks.md` § `use()` for a worked example, the rules around `use(Context)` vs `use(promise)`, and the pinned rule that any promise passed to `use()` must be created outside the calling component so its reference is stable across renders.

## Unauthorized handling

`main.tsx` wires exactly one handler:

```ts
httpClient.setUnauthorizedHandler(() => {
  authService.clearCache();
});
```

`authService.clearCache()` removes the in-memory auth cache and `queryClient.removeQueries({ queryKey: authQueryKeys.all })`. Pages then see the next `protectedLoader` redirect to `/login`.

Do not register a second handler; there is only one slot. If behaviour needs to change, edit `main.tsx`.

## When a mutation should invalidate

```ts
mutation.mutate(payload, {
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: {feature}QueryKeys.all });
    toast.success('Saved', { duration: TOAST_DURATION_MS });
  },
  onError: (err) => errorService.handleApiError(normalizeError(err), { operation: 'save' }),
});
```

### Invalidation cheatsheet

Pick the narrowest key that still captures every affected query:

| Mutation | Invalidate | Why |
|---|---|---|
| **Create** new record (appears in list) | `.all` | New row affects list ordering, totals, and filter buckets — every `.list(...)` entry is stale. |
| **Update** existing record (no list-shape change) | `.detail(id)` + `.list({...same filters})` | Detail view + currently-rendered list need refresh; other filter combos are still valid. |
| **Update** with list-shape change (status flip, rename, sort key) | `.all` | Could move the row across filter buckets or pages — narrow key would leave stale list entries. |
| **Delete** record | `.all` | Always changes list totals + ordering; `.detail(id)` would orphan a now-404 cache entry. |
| **Bulk** mutation (multi-record) | `.all` | Per-key invalidation churns; one root invalidate is cheaper. |

The `useQueryClient` hook must be called inside a component or custom hook — not in an event handler or module scope.

## Extending `errorService`

When you add a new operation kind to the `Operation` union in `src/services/errorService.ts`, preserve two invariants:

1. **Keep the `import.meta.env.DEV` gate** around any `console.error` / `console.log`. The template gates it deliberately (`errorService.ts:41-43`) — unconditional logging in production leaks stack traces, endpoint paths, and server-side error details to the browser console. Do not add an always-on log call.
2. **Map to a user-safe string literal** in `ERROR_MESSAGES`. Never reference `error.message` or `error.stack` in the toast copy — a server-returned error string is not a user-facing message.

The `Operation` union currently lists: `'download' | 'upload' | 'send' | 'fetch' | 'review' | 'sign' | 'add-status' | 'save' | 'change-password'`. `'delete'` is not present — add it if you ship a destructive feature.
