---
name: react-19-vite-frontend
description: Feature-vertical pattern for React 19 + Vite 7 + TypeScript + Tailwind 4 + shadcn/ui + TanStack Query 5 + React Router 7. Applies the 6-step flow (types → API → hook → components → page → route) and Edge Design System token + showcase rules. FIRE for any frontend feature in this stack — pages, lists (infinite or paginated), detail views, forms, filters, dialogs, empty/status UI, route guards, redirect-back-after-login, custom query/mutation hooks, shadcn primitives or wrappers, query keys, invalidation, debounced search. Fire on oblique phrasings — "screen that shows X", "wire up endpoint", "show customers", "add a button" — and when stack is unnamed. DO NOT fire for: Next.js App Router/server actions, .NET/Quartz, NHibernate/EF queries, Python/SQL/regex, React Native, or backend-only prompts.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(pnpm:*), Bash(npm:*), Bash(npx:*)
---

<!-- Version: 1.7.0 | Last updated: 2026-04-23 | Changelog: references/changelog.md -->

# React 19 + Vite Frontend — Feature Blueprint

Opinionated pattern for building feature verticals in a React frontend that follows the `{Project}.ClientApp` conventions: feature page in `src/pages/`, URL-driven filters via `useSearchParams`, TanStack Query hook in `src/hooks/`, service + query-keys pair in `src/api/{feature}/`, reusable list + filter + dialog primitives. Follow the pattern exactly — deviations cost more than they save.

**SKILL.md is the decision surface.** Full code templates, worked examples, and extended rules live under `references/`. Jump to a reference only when the section below tells you to.

## Adapting to your project

Placeholders used throughout this skill. Keep them consistent.

| Placeholder | Casing | Example |
|---|---|---|
| `{Project}` | PascalCase | `Bono`, `Portal` |
| `{Project}.ClientApp` | PascalCase + literal `.ClientApp` | `Bono.ClientApp`, `Portal.ClientApp` |
| `{Feature}` | PascalCase, singular or plural | `Invoice`, `Invoices` |
| `{feature}` | camelCase of `{Feature}` | `invoice`, `invoices` |
| `{feature-route}` | kebab-case | `invoices`, `bank-statements` |

**Reusable (do not reimplement — import):**

- `src/api/core/httpClient.ts` — typed `fetch` wrapper, `credentials: 'include'`, JSON/FormData/blob, 401 hook
- `src/lib/queryClient.ts` — shared `QueryClient` (staleTime=0, gcTime=300_000, retry=2)
- `src/lib/utils.ts` — `cn`, `parsePositiveInt`, `formatDate`, `formatNumber`, `setOrDelete`, `EMPTY_VALUE_PLACEHOLDER`, etc.
- `src/lib/constants.ts` — `TOAST_DURATION_MS`
- `src/services/errorService.ts` — `handleApiError`, `normalizeError`, `Operation` union
- `src/components/ui/*` — shadcn primitives (Button with `isLoading` + `loadingText`, Card, Dialog, Input, Select, …)
- `src/components/list/InfiniteScrollList.tsx` + `ListItemErrorBoundary.tsx`
- `src/components/filters/{SearchInput,PersonCombobox,ClearButton}.tsx`
- `src/components/dialog/ConfirmDialog.tsx` (async `onConfirm`, keeps open on error)
- `src/components/shared/EmptyState.tsx`, `src/components/{ErrorBoundary,RouteErrorBoundary}.tsx`
- `src/hooks/{useInfiniteScroll,useEscapeKey,useComboboxClear,useCurrentUserProfileQuery}.ts` (barrel: `src/hooks/index.ts`)
- `src/types/pagination.ts` — `PagedFilter`, `ExtendedPagedFilter<T>`, `PagedSearchResult<T>`, `FilterOption`

**Project-specific (you create):**

- `src/types/{feature}.ts` (+ re-export in `src/types/index.ts`)
- `src/api/{feature}/{feature}Service.ts` + `{feature}QueryKeys.ts`
- `src/hooks/use{Feature}*.ts` (+ re-export in `src/hooks/index.ts`)
- `src/components/{feature}/*`
- `src/pages/{Feature}.tsx` (+ `{Feature}Detail.tsx`, `{Feature}Create.tsx` as needed)
- `src/lib/{feature}FilterOptions.ts` (if the feature has selectable filters)
- One entry in `src/router.tsx` + one nav entry in `src/components/layout/Header.tsx`

## Before generating code

### Prerequisite check

Verify the host project provides the shared pieces. Run these Globs from the repository root (the `{Project}.ClientApp` segment varies per project):

```
**/ClientApp/src/api/core/httpClient.ts
**/ClientApp/src/lib/queryClient.ts
**/ClientApp/src/lib/utils.ts
**/ClientApp/src/services/errorService.ts
**/ClientApp/src/components/ui/button.tsx
**/ClientApp/src/components/list/InfiniteScrollList.tsx    # required only for infinite lists
**/ClientApp/src/styles/main.css                            # must contain an `@theme` block
**/ClientApp/vite.config.ts                                 # must declare `@` alias and `@tailwindcss/vite` plugin
**/ClientApp/components.json                                # shadcn config
```

- **All present** → proceed with the 6-step flow below.
- **Any missing** → **do not re-scaffold.** Stop and surface the gap. Creating a parallel copy per-feature silently diverges from the template. If the user confirms the file should not exist (brand-new frontend), ask whether to bootstrap the shared pieces first.

Before mirroring service-method signatures, open and skim `src/api/core/httpClient.ts`, `src/services/errorService.ts`, and `src/lib/utils.ts` — real signatures are ground truth; examples below may drift.

## The 6-step feature flow

Consistent contract for every feature: **types → API layer → hook → components → page → route**. One feature = six edits, in this order.

### 1. Types — `src/types/{feature}.ts`

Model the domain with `PagedFilter`-based shapes. Reuse generics from `src/types/pagination.ts`. Backend casing is `PascalCase` — do **not** rename inside the service. Re-export from `src/types/index.ts`.

Template: see `references/worked-example.md` § 1. Types.

### 2. Service + query keys — `src/api/{feature}/`

Two thin files. Pure: no component state, no toasts, no error UI.

- `{feature}QueryKeys.ts` — object literal with `as const` tuples; `all`, `list(filters)`, `detail(id)`.
- `{feature}Service.ts` — plain namespace object, arrow-function members. Always route through `httpClient` (carries `credentials: 'include'`, 401 hook, body parsing). Paged reads use `POST /api/{feature-route}/list`.

Full templates + body-parsing key order + field-name tolerance: `references/api-layer.md` § Query keys, § Service.

### 3. TanStack Query hook — `src/hooks/use{Feature}*.ts`

One hook file per read or mutation. **Full code templates live in `references/api-layer.md` § Query hook recipes** (infinite list, single record identity, single record fresh, mutation).

**Normalized return shape for infinite lists — pages depend on it:**

```ts
{ items, totalCount, hasMore, isLoadingMore, isInitialLoading, fetchNextPage }
```

**Hook rules — do not deviate:**

- **Infinite list**: `PAGE_SIZE = 20`, `refetchOnWindowFocus: false`, `gcTime: 0` (discards stale pages on filter change — see `useItemsInfiniteQuery.ts` § `gcTime` option).
- **Single record (identity-shaped)**: `staleTime: Infinity`, `gcTime: Infinity`, `retry: false`. Copy `useCurrentUserProfileQuery.ts`.
- **Single record (fresh)**: `staleTime: 0` + default `gcTime`. Use for mutable records (detail, settings).
- **Mutation**: bare `useMutation({ mutationFn })`. No toasts/invalidation/error-service inside the hook — the page owns UX.
- **Loading-flag naming**: `useQuery` → `isPending` (prefer over `isLoading` alias). `useInfiniteQuery` → `isLoading` (first page) + `isFetchingNextPage` (subsequent); normalized shape surfaces them as `isInitialLoading` / `isLoadingMore`. A single-record hook reading `isFetchingNextPage` never resolves.

Re-export every new hook from `src/hooks/index.ts`. Pages import from `@/hooks`, never from the file directly.

**Invalidation after mutation** — call `useQueryClient()` inside a component or custom hook (Rules-of-Hooks). Pick the narrowest key that captures the mutation's effect: `.all` for create/delete/list-shape-changing updates; `.detail(id)` + `.list({...same filters})` for same-shape updates. Full rule table + `Operation` union extension rules: `references/api-layer.md` § Invalidation cheatsheet, § Extending errorService.

### 4. Feature components — `src/components/{feature}/`

One file per role. Use `cn()` from `@/lib/utils`, shadcn primitives from `@/components/ui/*`, icons from `lucide-react`. Keep each file under ~150 lines.

- `{Feature}ListItem.tsx` — row renderer; static class maps for status badges.
- `{Feature}ListHeader.tsx` — grid column labels aligned with the item grid.
- `{Feature}ListSkeleton.tsx` — 5 placeholder rows (use `Skeleton` from `@/components/ui/skeleton`).
- `{Feature}EmptyState.tsx` — wraps `EmptyState` with two variants: `hasActiveFilters` (suggest clearing) vs no-data (suggest creating).

**Status badge idiom** — static `Record<{Feature}Status, string>` of Tailwind class strings, looked up per row, passed as `className` on `<Badge variant="outline">` from `@/components/ui/badge`. The Tailwind palette (`border-green-200 bg-green-50 text-green-700`) is intentional for 4+-state spectrums where semantic tokens (`success`/`warning`/`destructive`) do not map cleanly. Precedent: `ItemListItem.tsx` § `STATUS_CLASS_MAP` + `<Badge>` render.

### 5. Page — `src/pages/{Feature}.tsx`

One file assembling filters + hook + list. Mirror `src/pages/Items.tsx`. Full pattern + scroll-reset + debounce rules: `references/infinite-list.md`.

Contract summary:

- Filters read from URL via `useSearchParams()`; enum params validated against the options array before coercing.
- Search text: URL + local state; sync URL → local in `useEffect`; debounce local → URL with `useDebouncedCallback` at **400 ms**; cancel on unmount.
- Scroll to top on filter changes via `useRef` first-render flag + `window.scrollTo({ top: 0, behavior: 'instant' })`.
- Render branches: `isInitialLoading` → skeleton; `items.length === 0` → empty state; otherwise → `InfiniteScrollList` with `keyExtractor` + `renderItem`.
- Header row sits **outside** `InfiniteScrollList` (header should not be wrapped per-item in `ErrorBoundary`).
- Always render the filter bar, even while loading.

### 6. Route + nav — `src/router.tsx` + `src/components/layout/Header.tsx`

Add the route as a child of the protected `AppLayout` tree. `protectedLoader` already guards it; `RouteErrorBoundary` is inherited.

```tsx
{ path: '{feature-route}', element: <{Feature}s /> },
```

Add a matching nav entry in `Header.tsx` (`<Link to="/{feature-route}">` + active-state styling) — a route without a nav link is effectively hidden. Keep imports in `router.tsx` alphabetical.

Detail/create sibling routes — use an `id` param:

```tsx
{ path: '{feature-route}/:id', element: <{Feature}Detail /> },
{ path: '{feature-route}/new', element: <{Feature}Create /> },
```

Full route mechanics + `protectedLoader` + `AppLayout` behaviour: `references/router-and-layouts.md`.

## Forms sub-flow

Plain React 19, **no** `useActionState` (rationale: `references/forms.md` § Why not `useActionState`). Mirror `src/pages/Login.tsx` (thin) or `src/pages/Settings.tsx` (full — multi-field validation + error-code map + eye-toggle password inputs).

Contract:

1. One `useState` per field. One `useState<FieldErrors>({})` for per-field error messages (interface declared top of file, not exported).
2. On change: update the field and clear only that field's error.
3. On submit: `e.preventDefault()` → `validate()` returns `boolean` and calls `setFieldErrors(errors)` → early return if invalid.
4. `mutation.mutate(payload, { onSuccess, onError })`:
   - `onSuccess(data)` — branch on `data.ok` / `data.errorCode`. Map known codes to **hardcoded user-safe copy** — never interpolate server strings into `toast.*`. Generic success → `toast.success` with `duration: TOAST_DURATION_MS` and `clearForm()`.
   - `onError(err)` — `errorService.handleApiError(normalizeError(err), { operation: '…' })`. No direct `toast.error` for API errors.
   - **Auth flows only:** `window.location.href = '/'` (hardcoded literal) to force a full reload so `protectedLoader` re-runs against fresh cookies.
   - **Open-redirect:** never feed `searchParams.get('redirectTo')` into `window.location.href` directly. Gate via `isSafeRedirect` from `@/lib/redirect` (see `references/router-and-layouts.md` § `isSafeRedirect`); fall back to `'/'`.
5. `<Button type="submit" isLoading={mutation.isPending} loadingText="…">` — the shadcn `Button` renders the spinner.
6. Password inputs: eye-toggle (`<button type="button" tabIndex={-1}>` + `<Eye />` / `<EyeOff />` from `lucide-react`).
7. Destructive mutation: `<ConfirmDialog />` with async `onConfirm` (dialog stays open if `onConfirm` throws).

Extending `errorService` (new operation kind + `ERROR_MESSAGES` + `import.meta.env.DEV` log gate): `references/api-layer.md` § Extending errorService.

## Edge Design System integration

Tailwind v4 is CSS-first. Tokens live in `src/styles/main.css` `@theme inline { … }`. Never hardcode colour or radius literals.

Three rules:

1. **Use tokens, not literals.**
   - **Semantic tokens** (preferred) — `bg-primary`, `text-foreground`, `border-border`, `bg-muted/30`, `text-destructive`.
   - **Project brand palette** (brand-fixed surfaces) — `bg-bono-500`, `bg-pink-500`, `text-fuchsia-800`, `bg-success`, `bg-warning`. Names vary per project — read the project's `main.css` `@theme` block for the actual palette.
   - **Tailwind default palette** (status-swatch fallback only) — `bg-green-50`, `border-green-200` inside a `Record<Status, string>` class map where the spectrum does not reduce to semantic tokens.

   Never `bg-[#…]`, `style={{ color: '#…' }}`, `rounded-[6px]`, or any arbitrary Tailwind value — review-blocking. Radius via `rounded-md` / `rounded-lg` / `rounded-full`. Spacing via Tailwind scale (4/8/12/16/24/32/40/64).

   Brand gradient lives inside `<Button>` default variant (`src/components/ui/button.tsx` § `buttonVariants.default`). Do not hand-roll per-feature — reach for the primitive.
2. **Extend shadcn alongside, not inside.** New variants ship as sibling files under `src/components/ui/`. Precedent: `select-with-clear.tsx` (wraps `Select`). Do not fork `select.tsx`; do not inline in a feature folder.
3. **Showcase every primitive.** Any new component in `src/components/ui/` ships with a matching `<ShowcaseSection title description>` in `src/pages/showcase/*`. A primitive without a showcase entry blocks review.

Install new shadcn primitives with `npx shadcn@latest add <primitive>` — reads `components.json`, writes `src/components/ui/`. Review + add showcase in the same PR. Always import via `@/` aliases, never relative paths.

Full token dump, dark-mode strategy, shadcn config, linting conventions: `references/edge-design-system.md`.

## Error handling

- `AppLayout` wraps `<Outlet />` in `<ErrorBoundary>` — render-time exceptions already caught.
- `<RouteErrorBoundary />` attached to every top-level route — handles loader `throw`, `redirect` failure, HTTP 4xx/5xx during navigation.
- `<ListItemErrorBoundary>` per-row inside `InfiniteScrollList` — one broken row renders an inline muted message.
- Mutation errors: `errorService.handleApiError(normalizeError(err), { operation })` — reads `operation` from the `Operation` union.
- 401: `httpClient.setUnauthorizedHandler` wired once in `main.tsx:15-17` to `authService.clearCache()`. Do not add a second handler.
- Programmatic logout: call `authService.clearCache()` (or `authService.logout()`) before navigating — the 5-minute auth-cache TTL would otherwise mask a dead server session until next refresh.

## Anti-patterns — Do NOT

### Data, state, effects

- Do not call `fetch` directly — always `httpClient`. The 401 handling, body parsing, and credentials default live there.
- Do not inline query keys at call sites — centralise in `{feature}QueryKeys.ts`.
- Do not `useEffect` for data-fetching, derived state, action relays, or prop-change resets. Five replacements (derive / TanStack Query / event handler / `useMountEffect` / `key` prop) + four allowed uses: `references/no-use-effect.md`.
- Do not close over mutable callbacks inside `useEffect` / intersection observers / long-lived subscriptions — stash in a `useRef` (`useInfiniteScroll.ts` § callback-ref stash). StrictMode double-invokes in dev and a stale closure fires the wrong callback.
- Do not use React Context for server state — TanStack Query is the only server-state container.

### React 19 idioms

Bans live in `references/react-19-hooks.md` — load it before touching React 19 primitives. Quick index (each § in the reference holds the rule + rationale):

- `forwardRef` in new code → § `ref` as a regular prop
- `React.FC` → § TypeScript props convention
- Hand-rolled optimistic-rollback, or blending `setQueryData` with `useOptimistic` on one record → § `useOptimistic`
- `react-helmet` for `<title>` / `<meta>` / `<link>` → § Document metadata
- Prop-drilling `isPending` / `isSubmitting` → § `useFormStatus`
- `useActionState` / `<form action={…}>` → § `useActionState` + `references/forms.md` § Why not `useActionState` (template-level ban; RFC required)
- `use(promise)` as data-fetching layer → § `use()` (`use(Context)` for conditional reads is permitted)

### Template conventions

- Do not roll your own infinite scroll — reuse `useInfiniteScroll` + `InfiniteScrollList`.
- Do not hold filter state only in component `useState` — persist via `useSearchParams()` + `setOrDelete` for shareable URLs and back/forward.
- Do not install a new UI library when a shadcn primitive covers it — extend via sibling `components/ui/*.tsx`.
- Do not bypass `ErrorBoundary` / `RouteErrorBoundary` — every route is protected via `AppLayout`.
- Do not omit a showcase section when adding a DS primitive.
- Do not call `toast.error(...)` from `onError` for API failures — use `errorService.handleApiError`. Direct `toast.error` is for non-API UX feedback.
- Do not import from relative paths — use the `@/` alias.
- Do not use default exports — named exports throughout.
- Do not interpolate `data.errorCode` / `data.errorMessage` into `toast.*` — map known codes to hardcoded user-safe copy (server strings may contain PII or internal paths).
- Do not feed user-supplied values (`redirectTo`, query params, hash) into `window.location.href` / `redirect(...)` — open-redirect risk. Gate via `isSafeRedirect`; fall back to `'/'`. Hand-rolled `startsWith('/')` passes `//evil.com` — do not.
- Do not ship secrets as `VITE_*` env vars — inlined at build time, visible in DevTools. Secrets belong server-side on the ASP.NET Core proxy.

## References

- `references/worked-example.md` — Invoices feature narrative (types → API → hooks → components → page with delete + invalidation → route + nav). Code blocks live under `references/templates/*.tmpl` — copy those when generating.
- `references/changelog.md` — skill version history.
- `references/api-layer.md` — `httpClient`, `queryClient` defaults, service + query-keys contract, 401 handling, hook recipes, invalidation cheatsheet, `errorService` extension.
- `references/infinite-list.md` — URL filters, debounce, scroll-reset, `InfiniteScrollList` wiring, `gcTime: 0` rationale.
- `references/forms.md` — field-state + error-map idiom, mutation wiring, error-code branching, eye-toggle inputs, async `ConfirmDialog`, `useActionState` rationale.
- `references/edge-design-system.md` — full `@theme` token dump, brand tokens, brand gradient source, utility classes, dark mode, shadcn config, showcase contract, path aliases, linting.
- `references/router-and-layouts.md` — `createBrowserRouter` + `protectedLoader`, `AppLayout` + `ScrollRestoration`, `RouteErrorBoundary`, `isSafeRedirect`, `main.tsx` wiring.
- `references/no-use-effect.md` — useEffect ban, five replacement rules, `useMountEffect` escape hatch, the four legitimate template uses.
- `references/react-19-hooks.md` — React 19 idioms: ref-as-prop, ref-callback cleanup, `useOptimistic` vs `onMutate`, `useFormStatus`, `use(Context)`, document metadata, compiler trust, "stop using" table, TypeScript props convention.

## See also

- `dotnet-api-blueprint` — ASP.NET Core 4-layer pattern used by the reverse-proxy shell (`{Project}.Website`) in front of this client app.
- `nhibernate-cqrs` — backend data-access conventions this frontend consumes via the proxy.
