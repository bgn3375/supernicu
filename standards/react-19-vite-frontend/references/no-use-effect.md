# useEffect — Ban and Replacement Rules

`useEffect` is reserved for DOM effects and a narrow set of reactive side effects. It is **never** for data fetching, derived state, action relays, or resetting state when a prop changes. The template provides five explicit replacements plus one escape hatch.

Workflow when you see a `useEffect` in new or existing code: identify what the effect is doing, pick the matching rule below, apply the replacement, run `pnpm lint` + `pnpm typecheck` + `pnpm test --filter=<package>`.

Lint rule: `no-restricted-syntax` is configured to ban `useEffect` call sites (AST selector: `CallExpression[callee.name="useEffect"]`). The `useMountEffect` helper described below wraps `useEffect` with a narrow `eslint-disable-next-line` so the ban stays enforced at every other call site.

## Cheatsheet

| Instead of `useEffect` for… | Use |
|---|---|
| Deriving state from other state or props | Inline computation (Rule 1) |
| Fetching data | TanStack Query hook (Rule 2) — see `references/api-layer.md` |
| Responding to user actions | Event handlers (Rule 3) |
| One-time external sync on mount | `useMountEffect` (Rule 4) |
| Resetting state when an id/prop changes | `key` prop on parent (Rule 5) |

## Rule 1 — Derive, do not sync

Most effects that call `setX(deriveFromY(y))` are unnecessary and add an extra render cycle. Compute the value inline.

```tsx
// BAD — two render cycles: first stale, then filtered
function ProductList() {
  const [products, setProducts] = useState<Product[]>([]);
  const [filteredProducts, setFilteredProducts] = useState<Product[]>([]);

  useEffect(() => {
    setFilteredProducts(products.filter((p) => p.inStock));
  }, [products]);
}

// GOOD — one render, always consistent
function ProductList() {
  const [products, setProducts] = useState<Product[]>([]);
  const filteredProducts = products.filter((p) => p.inStock);
}
```

**Smell test:** you are about to write `useEffect(() => setX(deriveFromY(y)), [y])`, or you have state that only mirrors other state/props.

## Rule 2 — TanStack Query, not useEffect + fetch

Effect-based fetching creates race conditions, duplicates caching logic, and bypasses `httpClient` (so 401 handling, body parsing, and credential-include defaults are lost).

```tsx
// BAD — race condition on rapid prop changes; no 401 handler; no cache
function {Feature}Page({ {feature}Id }: { {feature}Id: number }) {
  const [{feature}, set{Feature}] = useState<{Feature} | null>(null);

  useEffect(() => {
    fetch(`/api/{feature-route}/${ {feature}Id }`)
      .then((r) => r.json())
      .then(set{Feature});
  }, [{feature}Id]);
}

// GOOD — TanStack Query hook fronted by {feature}Service + {feature}QueryKeys
function {Feature}Page({ {feature}Id }: { {feature}Id: number }) {
  const { data: {feature}, isPending } = use{Feature}Query({feature}Id);
  if (isPending) return <Skeleton />;
  return <{Feature}Detail {feature}={{feature}} />;
}
```

Build the hook per `references/api-layer.md` § `use{Feature}Query` — `useQuery` wrapping `{feature}Service.get{Feature}(id)`, keyed by `{feature}QueryKeys.detail(id)`.

**Smell test:** your effect calls `fetch(...)` then `setState(...)`, or you are re-implementing caching, retries, cancellation, or staleness.

## Rule 3 — Event handlers, not effects

If a user click triggers the work, do the work in the handler — not by flipping a flag and reacting to it in an effect.

```tsx
// BAD — state-as-flag + effect-as-action-relay
function LikeButton() {
  const [liked, setLiked] = useState(false);

  useEffect(() => {
    if (liked) {
      postLike();
      setLiked(false);
    }
  }, [liked]);

  return <button onClick={() => setLiked(true)}>Like</button>;
}

// GOOD — direct event-driven action via mutation
function LikeButton({ {feature}Id }: { {feature}Id: number }) {
  const mutation = useToggle{Feature}Like();
  return (
    <Button onClick={() => mutation.mutate({feature}Id)} isLoading={mutation.isPending}>
      Like
    </Button>
  );
}
```

**Smell test:** state is a flag so an effect can do the real action, or you are building "set flag → effect runs → reset flag" mechanics.

## Rule 4 — Reach for `useMountEffect`

When you genuinely need to sync with an external system on mount (DOM integration, third-party widget lifecycles, browser API subscription), use `useMountEffect` — not a bare `useEffect`.

```tsx
// BAD — guard inside an always-mounted effect
function VideoPlayer({ isLoading }: { isLoading: boolean }) {
  useEffect(() => {
    if (!isLoading) playVideo();
  }, [isLoading]);
}

// GOOD — mount only when preconditions are met
function VideoPlayerWrapper({ isLoading }: { isLoading: boolean }) {
  if (isLoading) return <LoadingScreen />;
  return <VideoPlayer />;
}

function VideoPlayer() {
  useMountEffect(() => playVideo());
}
```

`useMountEffect` is also the right tool for context-owned singletons whose dependency never changes across the component's lifetime:

```tsx
// BAD — dependency is a stable singleton; the effect re-binds needlessly on re-render
useEffect(() => {
  connectionManager.on('connected', handleConnect);
  return () => connectionManager.off('connected', handleConnect);
}, [connectionManager]);

// GOOD — intent is "mount once, cleanup on unmount"
useMountEffect(() => {
  connectionManager.on('connected', handleConnect);
  return () => connectionManager.off('connected', handleConnect);
});
```

**Smell test:** you are synchronising with an external system, and the behaviour is naturally "setup on mount, cleanup on unmount."

## Rule 5 — Reset with `key`, not dependency choreography

If an effect's only job is to re-run when an id changes, that is what `key` is for.

```tsx
// BAD — effect emulates remount
function VideoPlayer({ videoId }: { videoId: string }) {
  useEffect(() => {
    loadVideo(videoId);
  }, [videoId]);
}

// GOOD — parent forces a clean remount by changing the key
function VideoPlayerWrapper({ videoId }: { videoId: string }) {
  return <VideoPlayer key={videoId} videoId={videoId} />;
}

function VideoPlayer({ videoId }: { videoId: string }) {
  useMountEffect(() => loadVideo(videoId));
}
```

**Smell test:** you are writing an effect whose only job is to reset local state when an id/prop changes, or you want the component to behave like a brand-new instance per entity.

## `useMountEffect` — the escape hatch

The template does not ship `useMountEffect` by default. Create it on first need at `src/hooks/useMountEffect.ts` and re-export from `src/hooks/index.ts`.

```ts
import { useEffect } from 'react';

export function useMountEffect(effect: () => void | (() => void)) {
  /* eslint-disable-next-line no-restricted-syntax */
  useEffect(effect, []);
}
```

The `eslint-disable-next-line` comment is the single sanctioned bypass of the `no-restricted-syntax` rule. The helper's empty dependency array makes the "mount only, cleanup on unmount" intent explicit to reviewers.

## Allowed uses of `useEffect` in this template

These are the four effects currently in the template and they are **legitimate** — do not cite this reference to reject them in review. Anything outside this list is a candidate for one of the five rules above or for `useMountEffect`.

- **URL → local sync on mount** — `src/pages/Items.tsx:21-28` reads `useSearchParams()` and hydrates local filter state for browser back/forward navigation.
- **Debounce cancel on unmount** — `src/pages/Items.tsx:55-57` cancels the `useDebouncedCallback` on unmount to prevent a late write to a stale setter.
- **Scroll reset on filter change** — `src/pages/Items.tsx:30-45` uses a `useRef` first-render flag + `window.scrollTo({ top: 0, behavior: 'instant' })` when filters change.
- **Intersection observer for infinite scroll** — `src/hooks/useInfiniteScroll.ts:17-21` stashes the `onLoadMore` callback in a `useRef` and attaches an `IntersectionObserver` whose disconnect is returned as the cleanup.

All four are `useEffect` uses that do not fit the five-rule replacement cleanly. The first three are reactive-side-effect + unmount-cleanup pairs; the fourth is an external-system integration whose dependency set is not stable enough for `useMountEffect` alone.

## Component structure convention

Computed values come after hooks and local state. They are **not** `useEffect + setState` — they are inline expressions.

```tsx
export function {Feature}Component({ {feature}Id }: {Feature}ComponentProps) {
  // Hooks first
  const { data, isPending } = use{Feature}Query({feature}Id);

  // Local state
  const [isOpen, setIsOpen] = useState(false);

  // Computed values — NOT useEffect + setState
  const displayName = data?.Name ?? 'Unknown';

  // Event handlers
  const handleClick = () => setIsOpen(true);

  // Early returns
  if (isPending) return <{Feature}ListSkeleton />;

  // Render
  return (
    <div className="flex flex-col gap-4">
      <h2>{displayName}</h2>
      <Button onClick={handleClick}>Open</Button>
    </div>
  );
}
```
