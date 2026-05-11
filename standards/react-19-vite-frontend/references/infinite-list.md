# Infinite List — URL Filters + Pagination

Pattern for any paginated list page. The canonical implementation is `src/pages/Items.tsx` + `src/hooks/useItemsInfiniteQuery.ts` + `src/components/list/InfiniteScrollList.tsx`. Read those first if the example below diverges.

## Page state layers

Three layers, each with a specific job. Do not collapse them.

1. **URL (`useSearchParams`)** — the source of truth for shareable filter state. Survives refresh, back/forward, copy-paste.
2. **Local `useState`** — input buffer for the text search only. Keeps typing responsive while the URL catches up on a debounce.
3. **TanStack Query cache** — server state keyed on the URL-derived filter shape.

Rule: every filter that affects the list keys into the URL. Local state exists only to decouple typing speed from URL write speed.

## URL → hook params

```tsx
const [searchParams, setSearchParams] = useSearchParams();

const searchText = searchParams.get('searchText') ?? '';

const rawStatus = searchParams.get('status');
const status = FEATURE_STATUS_OPTIONS.some((o) => o.value === rawStatus) /* e.g. ITEM_STATUS_OPTIONS */
  ? (rawStatus as {Feature}Status)
  : undefined;

const { items, totalCount, hasMore, isLoadingMore, isInitialLoading, fetchNextPage } =
  use{Feature}sInfiniteQuery({
    searchText: searchText || undefined,
    status,
  });
```

Validate enum params against the options array before coercing (`src/pages/Items.tsx:20-28`). An unknown status from a hand-crafted URL becomes `undefined`, not a runtime error in the hook.

## Local input buffer + debounce

```tsx
const [inputValue, setInputValue] = useState(searchText);
const isFirstRender = useRef(true);

useEffect(() => {
  setInputValue(searchText);
}, [searchText]);

const debouncedSetSearch = useDebouncedCallback((value: string) => {
  setSearchParams((prev) => {
    const next = new URLSearchParams(prev);
    setOrDelete(next, 'searchText', value);
    return next;
  });
}, 400);

useEffect(() => () => debouncedSetSearch.cancel(), [debouncedSetSearch]);

const handleInputChange = (value: string) => {
  setInputValue(value);
  debouncedSetSearch(value);
};
```

- 400 ms debounce — matches `Items.tsx:53`. Not 250, not 500.
- URL-sync effect (URL → local) handles browser back/forward; it does **not** create a loop because writing the same value is a no-op.
- Always cancel on unmount; an in-flight debounce that writes to a stale `setSearchParams` is a silent bug.
- `setOrDelete` (from `@/lib/utils`) deletes the key when empty — the URL stays clean (`/items` not `/items?searchText=`).

## Scroll reset on filter change

```tsx
useEffect(() => {
  if (isFirstRender.current) {
    isFirstRender.current = false;
    return;
  }
  window.scrollTo({ top: 0, behavior: 'instant' });
}, [searchText, status, category]);
```

Skip the initial mount so a deep link does not jump; subsequent filter changes reset position because new results are unrelated to the old scroll offset. `AppLayout` uses `ScrollRestoration` with `getKey={(location) => location.key}` (`src/layouts/AppLayout.tsx:16-21`) to disable default route-scroll memory — that is why the page owns its own scroll-reset logic.

## `InfiniteScrollList` contract

Generic component at `src/components/list/InfiniteScrollList.tsx`.

```tsx
<InfiniteScrollList
  items={items}
  hasMore={hasMore}
  isLoading={isLoadingMore}
  onLoadMore={fetchNextPage}
  renderItem={(item) => <{Feature}ListItem item={item} />}
  keyExtractor={(item) => item.Id}
/>
```

`renderItem` has signature `(item: T, index: number) => ReactNode`. Omit `index` when unused (as above); accept it when the row needs its position for zebra striping, separator rendering, or index-based actions.

Internals:

- Delegates to `useInfiniteScroll` for intersection-observer sentinel (`rootMargin: '200px'`, `threshold: 0`).
- Wraps every row in `<ListItemErrorBoundary>` — a render error in one item becomes an inline muted notice, not a crashed list.
- Renders a bottom spinner when `isLoading`.
- Renders a sentinel `<div>` when `hasMore && !isLoading`. The observer `ref` is only attached when `items.length > 0` — an empty list with `hasMore` still renders the div but will not fire intersection until an item exists.
- Returns `null` when `items.length === 0 && !isLoading` — the page is responsible for the empty state, not the list.

Do not:

- Wrap the header row in the list — it belongs outside so it is not per-item error-bounded or styled with `divide-y`.
- Pass `isLoading` on the initial load — use `isInitialLoading` to branch to the skeleton before mounting the list.
- Reimplement the sentinel. The spacing and margins are tuned.

## Page branching

Three render states, in this order:

```tsx
{isInitialLoading ? (
  <>
    <{Feature}ListHeader />
    <{Feature}ListSkeleton />
  </>
) : items.length === 0 ? (
  <{Feature}EmptyState
    hasActiveFilters={hasActiveFilters}
    onClearFilters={handleClearFilters}
  />
) : (
  <>
    <{Feature}ListHeader />
    <InfiniteScrollList … />
  </>
)}
```

Empty state has two variants driven by `hasActiveFilters`:

- `true` — "No results for these filters", action: `Clear filters`. Wire `onClearFilters` to cancel the debounce and reset both URL + input.
- `false` — "No {feature} yet", action: `Create …` or none.

```tsx
const handleClearFilters = () => {
  debouncedSetSearch.cancel();
  setSearchParams({});
  setInputValue('');
};

const hasActiveFilters = !!(searchText || status || category);
```

## `gcTime: 0` rationale

The infinite hook sets `gcTime: 0` (`src/hooks/useItemsInfiniteQuery.ts:37`). Effects:

- Filter change → the old query key becomes inactive → TanStack Query evicts immediately instead of keeping pages around for 5 minutes.
- Unmount (navigate away) → pages drop from cache right away.

This trades bandwidth (a revisit refetches) for memory + correctness (no risk of seeing stale paginated pages from a different filter). Keep it.

## Totals + pluralization

```tsx
<p className="mt-1 text-sm text-muted-foreground">
  {formatNumber(totalCount)} {totalCount === 1 ? 'item' : 'items'}
</p>
```

`totalCount` comes from `data?.pages[0]?.TotalRecords` — the server returns it on every page, but the first page is authoritative. Use `formatNumber` from `@/lib/utils` for locale-aware separators.

## When a list needs sorting

Add `SortBy?: string; SortAsc?: boolean;` fields to the service filter (they exist on `PagedFilter` already — see `src/types/pagination.ts:5-6`). Persist via `useSearchParams` using the same `setOrDelete` pattern. Add a header click handler on `{Feature}ListHeader`. Do not store sort state only in local state.

## When a list needs selection

Lift selection into local `useState<Set<number>>(new Set())` in the page. Pass a `selected` prop + `onToggle` handler into the row. Do not persist selection in the URL (too noisy) and do not put it in TanStack Query (selection is UI state, not server state).
