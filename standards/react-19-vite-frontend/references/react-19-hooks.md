# React 19 Idioms — What This Template Uses and Skips

React 19 ships several new primitives. This file is the decision surface for which ones the template adopts, where it scopes them, and which ones it deliberately skips.

**Skipped (do not fire this skill toward these):** Server Components and the `'use client'` directive (we are a Vite SPA, not Next.js App Router), `<form action={serverAction}>` with server actions, any `app/`-directory layout, and ad-hoc `use(promise)` data-fetching (TanStack Query is the server-state layer — see `references/api-layer.md`).

**Adopted (described below):** `ref` as a regular prop, ref-callback cleanup, `useOptimistic` (narrow scope), `useFormStatus` (narrow scope), `use(Context)` for conditional context reads, native document metadata hoisting, plain-function components with named props types.

**Banned (described below):** `useActionState` (template-level decision — see `references/forms.md` § Why not `useActionState`), `React.FC`, `forwardRef` in new code, `react-helmet`.

## Compiler trust

The React Compiler automatically memoizes values and components. When the compiler is running, hand-applied `React.memo`, `useMemo`, and `useCallback` become redundant and should be stripped by default, keeping only the targeted cases profiling reveals.

**Caveat for this template:** check `vite.config.ts` for `babel-plugin-react-compiler` before applying that guidance. If the plugin is **not** installed, the compiler is not running and existing `useMemo`/`useCallback` uses for measurably expensive values remain acceptable. Do not preemptively strip them — that is a performance regression. Profile with React DevTools Profiler first, apply a targeted optimisation (lazy load, virtualisation, code split), re-profile.

## `ref` as a regular prop

`forwardRef` is deprecated in React 19. `ref` is just another prop.

```tsx
// BAD — React 18 forwardRef wrapper
const Input = forwardRef<HTMLInputElement, InputProps>((props, ref) => (
  <input ref={ref} {...props} />
));

// GOOD — React 19 ref-as-prop
type InputProps = React.InputHTMLAttributes<HTMLInputElement> & {
  ref?: React.Ref<HTMLInputElement>;
};

export function Input({ ref, ...props }: InputProps) {
  return <input ref={ref} {...props} />;
}
```

Do not use `forwardRef` in new code. Existing `forwardRef` call sites migrate opportunistically — not a review blocker on unrelated PRs.

## Ref callback cleanup functions

Ref callbacks can now return a cleanup function — React calls it on unmount instead of invoking the ref with `null`. This replaces the old "stash node in state, run `useEffect` that reads it" dance for DOM observation.

```tsx
function MeasuredBox() {
  return (
    <div
      ref={(node) => {
        if (!node) return;
        const observer = new ResizeObserver((entries) => {
          // handle the measurement (e.g. setSize(entries[0].contentRect))
        });
        observer.observe(node);
        return () => observer.disconnect();
      }}
    >
      Resizable content
    </div>
  );
}
```

Useful for `ResizeObserver`, `IntersectionObserver` when you need the observer scoped to one DOM node, event-listener attach/detach, and third-party widget attachment to a ref'd element.

## `useActionState`

**Not adopted in this template.** Full rationale (per-field error-code branching, clear-on-change UX, errorService coordination) and the template-level RFC escalation path live in `references/forms.md` § Why not `useActionState`. Ship new forms per `references/forms.md`; do not apply `useActionState` feature-locally.

`useFormStatus` is separately adoptable without committing to Actions — see the next section.

## `useOptimistic`

The template's default optimistic pattern is TanStack Query's `onMutate` + `queryClient.setQueryData` + `onError` rollback. That writes optimistically into the query cache, so every subscriber sees the pending value immediately.

```tsx
// Template default — TanStack Query onMutate with rollback
export function useToggle{Feature}Like({feature}Id: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: () => {feature}Service.toggleLike({feature}Id),
    onMutate: async () => {
      await queryClient.cancelQueries({ queryKey: {feature}QueryKeys.detail({feature}Id) });
      const previous = queryClient.getQueryData<{Feature}>({feature}QueryKeys.detail({feature}Id));
      queryClient.setQueryData<{Feature}>({feature}QueryKeys.detail({feature}Id), (curr) =>
        curr ? { ...curr, Liked: !curr.Liked } : undefined
      );
      return { previous };
    },
    onError: (_err, _vars, context) => {
      if (context?.previous) {
        queryClient.setQueryData({feature}QueryKeys.detail({feature}Id), context.previous);
      }
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: {feature}QueryKeys.detail({feature}Id) });
    },
  });
}
```

`useOptimistic` is the right tool when the optimistic value is **transient UI** rather than cached server state — typically a list item rendered with `opacity: 0.6` while its create/delete request is in flight, without writing the pending record into the query cache.

```tsx
import { startTransition, useOptimistic } from 'react';

type Todo = { id: string; text: string; done: boolean };
type OptimisticTodo = Todo & { pending?: boolean };

// useOptimistic — render pending row without mutating cache
function TodoList({ todos, addTodo }: { todos: Todo[]; addTodo: (t: Todo) => Promise<void> }) {
  const [optimisticTodos, setOptimisticTodos] = useOptimistic<OptimisticTodo[], Todo>(
    todos,
    (current, newTodo) => [...current, { ...newTodo, pending: true }]
  );

  async function handleAdd(formData: FormData) {
    const text = formData.get('text') as string;
    const newTodo: Todo = { id: crypto.randomUUID(), text, done: false };
    startTransition(async () => {
      setOptimisticTodos(newTodo);
      await addTodo(newTodo);
    });
  }

  return (
    <ul>
      {optimisticTodos.map((t) => (
        <li key={t.id} style={{ opacity: t.pending ? 0.6 : 1 }}>{t.text}</li>
      ))}
    </ul>
  );
}
```

Pick one pattern per feature. Do not blend `setQueryData` + `useOptimistic` on the same record — the precedence becomes ambiguous and rollback semantics diverge.

## `useFormStatus`

`useFormStatus` reads the pending state of the nearest ancestor `<form>`. The component using it must be rendered **inside** that form, not be the form itself.

The template default is a form-local submit button that receives `isLoading={mutation.isPending}` directly — no prop-drilling to reach. `useFormStatus` is useful only when the submit button lives inside a reusable component that should not prop-drill pending.

```tsx
import { useFormStatus } from 'react-dom';

export function SubmitButton({ label = 'Submit' }: { label?: string }) {
  const { pending } = useFormStatus();
  return (
    <Button type="submit" isLoading={pending} loadingText="Submitting…">
      {label}
    </Button>
  );
}
```

`useFormStatus` is permissible where applicable but not the default. Sticking with the Settings.tsx convention (button local to the form, `isLoading={mutation.isPending}`) is fine and remains the template recommendation.

## `use()` — promise and context reading

`use()` is unique: it can be called conditionally and inside loops.

- **For promises:** do **not** use `use(promise)` for feature data-fetching. The template's server-state layer is TanStack Query (`references/api-layer.md`). `use(loaderPromise)` with React Router 7's `defer()` is a defensible future direction but is out of scope — raise as an RFC before adopting.
- **For context:** `use(Context)` is accepted when a context read must be gated on a prop or flag (something `useContext` can't do because it must be called unconditionally).

```tsx
import { use } from 'react';
import { FeatureFlagsContext } from '@/contexts/FeatureFlagsContext';

function {Feature}Panel({ showAdvanced }: { showAdvanced: boolean }) {
  if (!showAdvanced) return null;
  const flags = use(FeatureFlagsContext);
  return flags.canEdit ? <Edit{Feature} /> : <View{Feature} />;
}
```

**Pinned rule** (applies if you ever use `use(promise)` in any context — including future router-loader integrations): never create the promise inside the component that calls `use()`. A new promise reference on every render would cause an infinite suspense loop. Create the promise in a parent, route loader, or server action so the reference is stable across renders.

## Document metadata — native title/meta/link hoisting

React 19 hoists `<title>`, `<meta>`, and `<link>` tags to `<head>` automatically. Render them at the top of the page's JSX.

```tsx
export function {Feature}Page() {
  const { data } = use{Feature}ListQuery();
  return (
    <div>
      <title>{data?.Title ?? '{Feature}s'} — {Project}</title>
      <meta name="description" content="Manage {feature} records." />
      <h1>{data?.Title}</h1>
      {/* ... */}
    </div>
  );
}
```

Prefer native hoisting over `react-helmet`. Do not introduce `react-helmet` for page titles in new pages — the template does not ship it, and adding a dependency for a stock React 19 feature is a step backward.

## "Stop using" table

Applied to this template specifically — the source React 19 guidance drops some rows (RSC-only) and qualifies others (compiler caveat).

| Legacy pattern | Template replacement |
|---|---|
| `forwardRef((props, ref) => …)` | `function Comp({ ref, ...props })` — see § `ref` as a regular prop |
| `React.FC<Props>` | Plain function with a named props type — see § TypeScript props convention |
| `React.memo(Component)` / `useMemo` / `useCallback` by default | Let the compiler optimise **if installed** — profile first (see § Compiler trust) |
| Manual optimistic-rollback state machines | TanStack Query `onMutate` + `setQueryData` for cached state, `useOptimistic` for transient list-row UI |
| Prop-drilling `isSubmitting` / `isPending` through multiple layers | Keep button local OR use `useFormStatus` — see § `useFormStatus` |
| `useContext(MyCtx)` in a conditional path | `use(MyCtx)` — see § `use()` |
| `react-helmet` for page titles | Native `<title>` / `<meta>` hoisting — see § Document metadata |
| `useEffect` + `useState` for data fetching | TanStack Query hook — see `references/no-use-effect.md` Rule 2 |
| `useActionState` / `<form action>` | Plain `useState` + `mutation.mutate` — see `references/forms.md` (template-level decision) |

## TypeScript props convention

```tsx
// GOOD — named type, explicit props, no React.FC
type {Feature}CardProps = {
  {feature}: {Feature};
  onSelect?: (id: number) => void;
  variant?: 'compact' | 'full';
};

export function {Feature}Card({ {feature}, onSelect, variant = 'full' }: {Feature}CardProps) {
  // …
}
```

Do not use `React.FC`. It adds implicit `children` typing, provides no real benefit in modern TypeScript + React, and clashes with the ref-as-prop pattern.
