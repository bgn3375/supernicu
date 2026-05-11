# Router, Layouts, and Entry Point

Wiring reference for `src/router.tsx`, `src/main.tsx`, and the layout components. Read this when adding a route, changing auth flow, or touching the app shell.

## `createBrowserRouter` structure

`src/router.tsx` defines the full route tree. Three top-level entries:

1. `/login` — public, `element: <Login />`, `errorElement: <RouteErrorBoundary />`.
2. `/` — protected, `loader: protectedLoader`, `element: <AppLayout />`, with children for every feature.
3. `*` — catch-all, `loader: protectedLoader`, `element: <NotFound />`, `errorElement: <RouteErrorBoundary />`.

Every entry carries `hydrateFallbackElement` — a light-grey full-screen filler — to suppress the flash before the loader resolves.

Adding a feature route:

```tsx
{
  path: '{feature-route}',
  element: <{Feature}s />,
},
```

Insert under the protected children array, alphabetical order. Do **not** add a separate `errorElement` — the parent `<AppLayout />` entry already declares one, and it is inherited.

If the feature needs a detail page:

```tsx
{ path: '{feature-route}', element: <{Feature}s /> },
{ path: '{feature-route}/:id', element: <{Feature}Detail /> },
```

Use `useParams<{ id: string }>()` in the detail page and `parsePositiveInt` from `@/lib/utils` to coerce.

## Protected loader

```ts
const protectedLoader = async () => {
  const isAuthenticated = await authService.checkAuth();
  return isAuthenticated ? null : redirect('/login');
};
```

Mechanics:

- `authService.checkAuth()` (`src/api/auth/authService.ts:74-90`) has a 5-minute in-memory cache. First call per session hits `/api/authentication/check`; subsequent calls are synchronous.
- Returning `null` keeps the route; returning `redirect('/login')` kicks the user out.
- The loader runs on navigation, not on every render. After a logout, evict the cache via `authService.clearCache()` so the next navigation rechecks.
- 401 during a navigation (e.g. expired cookie) throws → `RouteErrorBoundary` renders. The 401 hook in `httpClient` clears the auth cache so the next route-entry forces `/login`.

Do not add a second loader to protected routes — `protectedLoader` is attached to the shared parent and applies to all children.

**Security boundary, not auth authority.** The 5-minute cache is a UX guard — it prevents a network round-trip per navigation. Authoritative auth state lives in the `httpOnly` session cookie on the server. `authService.clearCache()` prevents flash-of-protected-content after logout; actual revocation happens when the server invalidates the session (via `/api/authentication/logout`) and the next `/api/authentication/check` returns 401. If an attacker retains a stolen cookie, the cache is irrelevant — the server is still the gate. Never rely on `checkAuth()` for authorization decisions inside a component (e.g., "should this user see this button?") — read the user's roles/claims from a server-issued payload, never from a client-side flag.

**Logout:** any programmatic logout flow must call `authService.clearCache()` before navigating. The cache has a 5-minute TTL; without the explicit clear, `protectedLoader` will return `null` (cached `true`) on the next navigation even after the server session is destroyed, and the user will briefly see protected pages (UX regression, not a privilege escalation — the next authenticated request still 401s). `authService.logout` already clears it — call `authService.logout()` rather than reimplementing the `/api/authentication/logout` call.

## `AppLayout`

`src/layouts/AppLayout.tsx` is the app shell for every authenticated route.

```tsx
<div className="min-h-screen flex flex-col bg-gray-100">
  <Header />
  <main className="flex-1 container mx-auto p-4">
    <div className="bg-white rounded-lg">
      <ErrorBoundary>
        <Outlet />
      </ErrorBoundary>
    </div>
  </main>
  <ScrollRestoration getKey={(location) => location.key} />
</div>
```

Contracts:

- Every child feature renders inside `<ErrorBoundary>` — render-time exceptions are already caught.
- `ScrollRestoration` uses `location.key` as the key, which changes on every navigation. Effect: the browser never restores scroll automatically. Pages that want fresh-navigation scroll reset must do it themselves (see `references/infinite-list.md`, `src/pages/Items.tsx:39-45`).
- `Header` lives in `src/components/layout/Header.tsx`. Add nav entries there when you ship a new top-level route.

## `ShowcaseLayout`

`src/layouts/ShowcaseLayout.tsx` is the shell for `/showcase/*`. It renders `<ShowcaseNav />` + `<Outlet />` inside a separate container. Do not route business features through it; it is the design-system documentation tree.

## Entry point — `main.tsx`

```tsx
createRoot(rootElement).render(
  <StrictMode>
    <ThemeProvider attribute="class" defaultTheme="light" enableSystem={false} forcedTheme="light">
      <QueryClientProvider client={queryClient}>
        <RouterProvider router={router} />
        {import.meta.env.DEV && <ReactQueryDevtools initialIsOpen={false} />}
        <Toaster position="top-center" duration={5000} closeButton />
      </QueryClientProvider>
    </ThemeProvider>
  </StrictMode>
);
```

Observations:

- `StrictMode` is on — components must tolerate the development double-invoke. This is why `useInfiniteScroll` stores `onLoadMore` in a ref (`src/hooks/useInfiniteScroll.ts:17-21`) — the callback must remain stable across re-renders.
- `ThemeProvider` **forces** light mode. The `forcedTheme` prop wins over system preference. Do not remove.
- `QueryClientProvider` wraps the whole tree. There is exactly one `QueryClient` (from `src/lib/queryClient.ts`); do not instantiate another.
- `ReactQueryDevtools` only renders in dev (`import.meta.env.DEV`). Never guard with `process.env.NODE_ENV` — Vite uses `import.meta.env`.
- `Toaster` at `top-center` with `closeButton`. Duration is 5000 ms to match `TOAST_DURATION_MS`. One `<Toaster />` per app.

401 wiring:

```ts
httpClient.setUnauthorizedHandler(() => {
  authService.clearCache();
});
```

Runs once at module load. Do not register a second handler; only one slot exists.

Root guard:

```ts
const rootElement = document.getElementById('root');
if (!rootElement) {
  throw new Error('Root element not found. Ensure index.html contains a <div id="root"></div>');
}
```

Keep it — `createRoot(null)` otherwise yields an opaque error.

## `ErrorBoundary` vs `RouteErrorBoundary`

| | `ErrorBoundary` | `RouteErrorBoundary` |
|---|---|---|
| Where it lives | `src/components/ErrorBoundary.tsx` | `src/components/RouteErrorBoundary.tsx` |
| Catches | React render errors in children | Router errors (loader `throw`, `redirect` failure, HTTP errors during navigation) |
| Wired at | `AppLayout` around `<Outlet />` | `errorElement` on every top-level route entry |
| Recovery | Retry button bumps `resetKey` → remounts children | Retry (`navigate(0)`), Back (`navigate(-1)`), Home (`Link to="/"`) |
| Status-aware | No | Yes — reads `isRouteErrorResponse(error)` + `error.status` (404, 401, 500) |
| Keep the user signed in | Yes — resets inside the layout | No — full-page error UI outside `AppLayout` |

Do not confuse them. Render errors inside a feature should produce the in-layout boundary. Loader errors (including unauthenticated access) should produce the full-page boundary.

`ListItemErrorBoundary` is a **third**, per-item class component used only inside `InfiniteScrollList` — it replaces one broken row with a muted inline notice. Do not reuse it outside a list.

## Navigation within features

- `useNavigate()` — programmatic navigation, client-side.
- `<Link to>` — declarative, client-side.
- `window.location.href = '/'` — full reload. Reserve for auth-state transitions where the protected loader must re-run against fresh cookies (see `src/pages/Login.tsx:26`). Never use for intra-app routing. **Never** feed `searchParams.get('redirectTo')` or any user-supplied value into `window.location.href` without validation — that is an open-redirect vector. Use the canonical `isSafeRedirect` helper below.

### `isSafeRedirect` — same-origin relative-path validator

```ts
// src/lib/redirect.ts
export function isSafeRedirect(value: string | null | undefined): value is string {
  if (!value) return false;
  // Must start with a single '/', must not start with '//' (protocol-relative),
  // must not contain a scheme (http:, javascript:, data:), must not encode a backslash.
  if (!/^\/[^/\\]/.test(value)) return false;
  if (/[\r\n]/.test(value)) return false;
  return true;
}
```

Allowed: `/invoices`, `/settings/password`, `/items?status=active`.
Blocked: `//evil.com`, `https://evil.com`, `javascript:alert(1)`, `/\\evil.com`, `\t/foo`, empty, `null`.

Usage in a login page with redirect-back:

```tsx
import { isSafeRedirect } from '@/lib/redirect';

const [searchParams] = useSearchParams();
const redirectTo = searchParams.get('redirectTo');
const destination = isSafeRedirect(redirectTo) ? redirectTo : '/';
window.location.href = destination;
```

Hardcode `'/'` as the fallback. Do **not** fall back to `document.referrer`, `history.state`, or another user-influenced source — they carry the same open-redirect risk.

`useSearchParams()` is separate from navigation; it writes to `location.search` without triggering a route change. Use it for filters (see `references/infinite-list.md`).

## Adding a new top-level area

Checklist:

1. Create `src/pages/{Feature}.tsx` following the 6-step flow (see `SKILL.md`).
2. Add the route under `AppLayout` children in `src/router.tsx`.
3. Add a nav entry in `src/components/layout/Header.tsx` if the area is user-visible.
4. If the area has sub-routes, add them as `children:` on the new entry, with a sibling layout if needed.
5. Import in `router.tsx` is alphabetical — preserve the order.

## `src/components/index.ts` — not a general barrel

The template has `src/components/index.ts` that re-exports only `ErrorBoundary` and `RouteErrorBoundary` (used by `AppLayout` via `import { ErrorBoundary } from '@/components'`). It is **not** a general-purpose barrel. When adding feature components:

- Do not add a barrel `index.ts` inside `src/components/{feature}/` — the template folders (`items/`, `dialog/`, `list/`, `shared/`) show the convention: import components directly from their file paths (`@/components/items/ItemListItem`, not `@/components/items`).
- Do not append new feature components to `src/components/index.ts` — it stays scoped to the two top-level error boundaries.

## Environment variables and secrets

Vite exposes `import.meta.env` at build time. Two rules:

1. `import.meta.env.DEV` — boolean, `true` in `pnpm dev`, `false` in `pnpm build`. Use for dev-only UI (`<ReactQueryDevtools />` in `main.tsx:29`) and dev-only logging (`errorService.ts:41`). Never guard with `process.env.NODE_ENV` — Vite does not inject it.
2. `import.meta.env.VITE_*` — any env var prefixed `VITE_` is **inlined into the bundle** at build time. It ships to the browser and is visible in DevTools → Sources. Only put **intentionally-public** values there (a public analytics site-ID, a feature-flag boolean, a public CDN URL). **Never** put API keys, signing secrets, tokens, or anything you would not paste into a public gist. Secrets belong on the ASP.NET Core proxy server-side and are read by the SPA via `/api/...` calls that the cookie session authorises.

## `HydrateFallback` and `loading.tsx`

React Router 7 renders `hydrateFallbackElement` until the loader resolves. The template uses a single grey div; do not swap it for a shadcn spinner — the transition should be silent, not attention-grabbing. Per-feature loading states live in the page branches (skeleton / empty / list), not here.

## Do not

- Do not mount a second `QueryClient`, `ThemeProvider`, or `Toaster`.
- Do not add `errorElement` to protected children — it overrides the parent and creates a shallower catch point that misses loader-level failures.
- Do not rely on browser scroll restoration — `ScrollRestoration` with `location.key` disables it.
- Do not use `useEffect` to redirect — use a loader that returns `redirect(…)`. Loaders run before render, so there is no intermediate flash.
- Do not wrap pages in their own `ErrorBoundary` — `AppLayout` already does. A second boundary swallows errors before they reach the layout's retry UI.
- Do not mutate `router` (e.g. `router.navigate` from module scope). Navigate from components via `useNavigate()` or declarative `redirect()` inside loaders.
- Do not add `console.error` to `ErrorBoundary` / `RouteErrorBoundary` / `ListItemErrorBoundary` without the `import.meta.env.DEV` guard the template already uses. Leaking stack traces in production inflates the browser console and may expose internal file paths.
