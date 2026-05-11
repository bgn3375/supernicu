# Worked example — Invoices feature

Narrative walk-through of the 6-step feature flow, with one concrete vertical: an **Invoices** page with infinite scroll, status filter, search, and a delete action. Copy-paste templates live under `references/templates/*.tmpl` — this file is the glue + decision commentary.

## Substitute concrete → placeholder when copying

The templates use literal names instead of placeholders so they compile and read naturally. When copying for a different feature, substitute:

| Concrete (in templates) | Placeholder | Example target |
|---|---|---|
| `Invoice` | `{Feature}` | `Customer`, `Order`, `Recipe` |
| `invoice` | `{feature}` (camelCase) | `customer`, `order`, `recipe` |
| `invoices` | `{feature-route}` (kebab, plural form) | `customers`, `orders`, `recipes` |
| `Bono` | `{Project}` (PascalCase) | `Portal`, `Admin`, `Workspace` |
| `InvoiceStatus` enum values | your domain enum | `'pending' \| 'shipped' \| 'cancelled'` |
| `/api/invoices/...` | `/api/{feature-route}/...` | backend contract |

Canonical placeholder reference: `SKILL.md` § Adapting to your project.

## Assumptions

- Host project is named `Bono` (so ClientApp directory is `Bono.ClientApp/`; substitute `{Project}.ClientApp`).
- Backend exposes `POST /api/invoices/list` returning `PagedSearchResult<Invoice>` and `DELETE /api/invoices/:id`.
- Prerequisite check has passed — all shared infrastructure (httpClient, queryClient, InfiniteScrollList, etc.) is in place.

## 6-step walk-through

### 1. Types — `src/types/invoice.ts`

Model the domain with `PagedFilter`-based shapes. Re-export from `src/types/index.ts`.

Template: `references/templates/types.ts.tmpl`.

### 2. API — `src/api/invoices/`

Two files. Pure: no component state, no toasts, no error UI.

- Query keys: `references/templates/queryKeys.ts.tmpl` — `as const` tuple keys; `all`, `list(filters)`, `detail(id)`.
- Service: `references/templates/service.ts.tmpl` — plain namespace object, arrow-function members. Always route through `httpClient`.

### 3. Hooks — `src/hooks/`

- Infinite list: `references/templates/useInfiniteQuery.ts.tmpl` — `PAGE_SIZE = 20`, `refetchOnWindowFocus: false`, `gcTime: 0`. Returns the normalized shape `{ items, totalCount, hasMore, isLoadingMore, isInitialLoading, fetchNextPage }`.
- Delete mutation: `references/templates/useDeleteMutation.ts.tmpl` — bare `useMutation`; page owns `onSuccess`/`onError`/invalidation.

Re-export both from `src/hooks/index.ts` (snippet in `references/templates/router-entries.tsx.tmpl`).

### 4. Components — `src/components/invoices/`

One file per role. Use `cn()` from `@/lib/utils`, shadcn primitives, icons from `lucide-react`. Keep each file under ~150 lines.

- Filter options (co-lives in `src/lib/`, shared between components + page): `references/templates/filterOptions.ts.tmpl`.
- Row renderer: `references/templates/ListItem.tsx.tmpl` — static `Record<Status, string>` class map for status badges.
- Column header: `references/templates/ListHeader.tsx.tmpl` — grid template must match ListItem.
- Skeleton: `references/templates/ListSkeleton.tsx.tmpl` — 5 placeholder rows.
- Empty state: `references/templates/EmptyState.tsx.tmpl` — two variants gated by `hasActiveFilters`.

### 5. Page — `src/pages/Invoices.tsx`

Assembles filters + hook + list + delete flow. Template: `references/templates/Page.tsx.tmpl`.

Delete-flow design notes (worth understanding before editing):

- `onConfirm` is `async`; errors propagate from `mutateAsync` so `ConfirmDialog` keeps itself open (see `ConfirmDialog.tsx` § `onConfirm` contract).
- Invalidation uses `invoicesQueryKeys.all` so **every** list filter permutation refetches — not just the current one. A delete always changes list totals and ordering; narrower keys would leave stale list entries in other filter buckets.
- `onError` inside `mutateAsync` **re-throws** after routing to `errorService` so the dialog catches it. Without the re-throw, the dialog would close on a failed delete.
- `'delete'` must exist in the `Operation` union in `src/services/errorService.ts` before compile — extend per `references/api-layer.md` § Extending errorService.

### 6. Route + nav — `src/router.tsx` + `src/components/layout/Header.tsx`

Add route entry inside `'/'` (AppLayout) children, alphabetical by path. Add matching nav entry in `Header.tsx`. Snippets: `references/templates/router-entries.tsx.tmpl`.

Parent route already attaches `protectedLoader` and `RouteErrorBoundary` — do not duplicate.

## Checklist

Before opening the PR, verify:

- [ ] `src/types/invoice.ts` exists and is re-exported from `src/types/index.ts`.
- [ ] `src/api/invoices/{invoicesService,invoicesQueryKeys}.ts` both exist; keys use `as const` tuples.
- [ ] `useInvoicesInfiniteQuery` returns the normalized shape and uses `gcTime: 0`.
- [ ] The delete hook is a bare `useMutation` with no toast/error-service wiring inside.
- [ ] Both hooks re-exported from `src/hooks/index.ts`.
- [ ] `InfiniteScrollList` used with `keyExtractor` + `renderItem`; header lives **outside** it.
- [ ] URL-driven filters via `useSearchParams` + `setOrDelete`; 400 ms debounce on text; debounce cancelled on unmount.
- [ ] No hex literals, no arbitrary Tailwind values, no inline `style={{ color: '…' }}`.
- [ ] No direct `toast.error` in mutation `onError` for API failures — always `errorService.handleApiError(normalizeError(err), { operation })`.
- [ ] `'delete'` present in the `Operation` union (extend if missing).
- [ ] Route entry in `router.tsx`; nav entry in `Header.tsx`.
- [ ] `pnpm type-check && pnpm lint && pnpm format:check` all green.
