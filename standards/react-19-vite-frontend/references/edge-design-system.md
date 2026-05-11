# Edge Design System — Tokens + shadcn + Tailwind v4

Complete reference for the visual layer. Source of truth is `src/styles/main.css`; this file mirrors its contents and explains the extension policy.

## Tailwind v4 setup

The project uses Tailwind CSS **4** with the CSS-first configuration. There is no `tailwind.config.js`. All tokens, variants, and utilities live in `src/styles/main.css`.

Entry file shape:

```css
@import 'tailwindcss';
@import 'tw-animate-css';

@custom-variant dark (&:is(.dark *));

@theme inline {
  /* … tokens … */
}

:root  { /* …light-mode variable values… */ }
.dark  { /* …dark-mode variable values… */ }

@layer base      { /* body font, border-border, outline */ }
@layer utilities { /* .shadow-card, .card-minheight */ }
```

Tailwind's `@theme inline` block maps every `--color-*`, `--radius-*`, etc. into CSS variables that double as utility sources. Utilities such as `bg-primary`, `text-foreground`, `border-border`, `rounded-md` are generated from those mappings — not from a JS config.

Vite plugin registration lives in `vite.config.ts`:

```ts
import tailwindcss from '@tailwindcss/vite';
export default defineConfig({ plugins: [plugin(), tailwindcss()] });
```

Do not add `postcss.config.js` or `tailwind.config.js`. If a future design requires a JS config, raise it as a template-level change.

## Dark mode

One custom variant drives it:

```css
@custom-variant dark (&:is(.dark *));
```

Combined with `next-themes` (`ThemeProvider attribute="class" defaultTheme="light" enableSystem={false} forcedTheme="light"` in `main.tsx`). The template **forces light mode**; dark-mode token values exist in `main.css` but the provider does not flip the class. Do not remove the dark-mode variables — they stay in the file for when the template is adopted by a project that wants dark mode.

## Radius scale

Driven by one root variable:

```css
:root { --radius: 0.625rem; }   /* 10 px */
```

Derived utilities (from `@theme inline`):

| Utility | Computed |
|---|---|
| `rounded-sm` | `calc(--radius - 4px)` |
| `rounded-md` | `calc(--radius - 2px)` |
| `rounded-lg` | `--radius` |
| `rounded-xl` | `calc(--radius + 4px)` |
| `rounded-2xl` | `calc(--radius + 8px)` |
| `rounded-3xl` | `calc(--radius + 12px)` |
| `rounded-4xl` | `calc(--radius + 16px)` |

Never hardcode `rounded-[6px]` / `rounded-[10px]`. Use the scale.

## Colour tokens — semantic

Mapped into `@theme inline` from `:root` variables (OKLCH values). Utility = `bg-*`, `text-*`, `border-*`, `ring-*`.

| Token | Role | Light-mode OKLCH |
|---|---|---|
| `background` / `foreground` | Page background / body text | `oklch(1 0 0)` / `oklch(0.227 0.024 272.787)` |
| `card` / `card-foreground` | Card surface / card text | `oklch(1 0 0)` / `oklch(0.227 0.024 272.787)` |
| `popover` / `popover-foreground` | Popover surface / popover text | `oklch(1 0 0)` / `oklch(0.227 0.024 272.787)` |
| `primary` / `primary-foreground` | Primary action | `oklch(0.636 0.209 5.027)` (brand magenta) / `oklch(1 0 0)` |
| `secondary` / `secondary-foreground` | Secondary surface | `oklch(0.968 0.007 247.896)` / `oklch(0.208 0.042 265.755)` |
| `muted` / `muted-foreground` | Muted surface / muted text | `oklch(0.968 0.007 247.896)` / `oklch(0.516 0.025 260.631)` |
| `accent` / `accent-foreground` | Hover-like accents | `oklch(0.968 0.007 247.896)` / `oklch(0.208 0.042 265.755)` |
| `destructive` | Destructive action | `oklch(0.577 0.245 27.325)` |
| `border` | Default border | `oklch(0.896 0.009 252.894)` |
| `input` | Input border | `oklch(0.896 0.009 252.894)` |
| `ring` | Focus ring | `oklch(0.704 0.04 256.788)` |
| `card-header` | Card header tint | `oklch(0.955 0.006 264.529)` |
| `success` / `success-dark` | Success status | `oklch(0.696 0.143 175.117)` / `oklch(0.609 0.124 175.117)` |
| `warning` | Warning status | `oklch(0.713 0.159 66.519)` |
| `sidebar` / `sidebar-foreground` / `sidebar-primary` / `sidebar-accent` / `sidebar-border` / `sidebar-ring` | Sidebar variants | see `main.css` |
| `chart-1` … `chart-5` | Chart palette | see `main.css` |

## Colour tokens — BONO extensions (static hex)

Added alongside the semantic tokens in `@theme inline`, used when a UI element must stay identical across light + dark:

| Token | Utility | Hex |
|---|---|---|
| `pink-50` | `bg-pink-50` | `#fdf2f8` |
| `pink-100` | `bg-pink-100` | `#fce7f3` |
| `pink-200` | `bg-pink-200` | `#fbcfe8` |
| `pink-300` | `bg-pink-300` | `#f9a8d4` |
| `pink-400` | `bg-pink-400` | `#f472b6` |
| `pink-500` | `bg-pink-500` (brand) | `#EE4379` |
| `pink-600` | `bg-pink-600` | `#db2777` |
| `pink-700` | `bg-pink-700` | `#be185d` |
| `pink-800` | `bg-pink-800` | `#9d174d` |
| `pink-900` | `bg-pink-900` | `#831843` |
| `card-header` (static) | `bg-card-header` | `#F1F1F4` |
| `secondary-light` | `bg-secondary-light` | `#F1F1F4` |
| `secondary-main` | `bg-secondary-main` | `#434A60` |
| `nav-border` | `border-nav-border` | `#DCDFE4` |
| `grey-50` | `bg-grey-50` | `#FAFAFA` |
| `chip-border` | `border-chip-border` | `#B3B9C6` |
| `divider` | `bg-divider` | `#DCDFE4` |
| `success` (static) | `bg-success` | `#15B79F` |
| `success-dark` (static) | `bg-success-dark` | `#0E9382` |
| `warning` (static) | `bg-warning` | `#f59e0b` |

Brand gradient (not a token — **do not compose inline**; reach for the default `<Button>` variant which already carries it):

```
linear-gradient(97deg, var(--color-pink-500) 6%, var(--color-bono-500) 47%, var(--color-fuchsia-800) 110%)
```

Source: `src/components/ui/button.tsx:14`. Uses CSS variables (not hex literals) so dark-mode overrides on `--color-*` tokens propagate automatically. If a surface genuinely needs the gradient outside the Button primitive, promote it to a token via `@theme inline --gradient-brand: …;` + a `.bg-gradient-brand` utility — do not hand-roll the `linear-gradient(...)` string per-feature (and do not revert to hex literals: that violates the "no hex" token rule in § Do not).

## Typography

```css
body {
  font-family: 'Inter', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}
```

Inter is the only face used. Weights 400 / 500 / 600 / 700. Headings use `font-semibold` (600); body uses the default (400); labels and muted text use `text-sm`. No other families.

Use `text-2xl font-semibold` for page titles (per `Items.tsx:97`, `Settings.tsx:105`) and `text-lg font-semibold` for card titles / section headers.

## Utilities

| Class | Defined in | Effect |
|---|---|---|
| `.shadow-card` | `@layer utilities` in `main.css` | `0 0 0 1px rgba(0,0,0,0.06), 0 5px 22px 0 rgba(0,0,0,0.04)` — layered ring + soft drop |
| `.card-minheight` | `@layer utilities` in `main.css` | `min-height: 350px` — cards that must not collapse while loading |

## Base layer

```css
@layer base {
  * { @apply border-border outline-ring/50; }
  body { @apply bg-background text-foreground; font-family: 'Inter', …; }
}
```

Global `border-border` means every Tailwind border utility without an explicit colour uses the design token. Do not reset this. `outline-ring/50` gives focus outlines the token colour with 50 % opacity by default.

## Toast styling hooks

sonner toasts get their BONO look from selectors in `main.css` (outside `@theme`):

```css
[data-sonner-toast][data-styled='true'] {
  background-color: white !important;
  border: 1px solid oklch(0.929 0.013 255.508) !important;
}
[data-sonner-toast][data-styled='true'].toast-success { border-left: 4px solid #15B79F !important; }
[data-sonner-toast][data-styled='true'].toast-success [data-icon] { color: #15B79F !important; }
/* …toast-error, toast-info, toast-warning identical shape… */
```

Apply via the `className` option when calling `toast.*` — see `references/forms.md`. Do not edit the selectors; add new status classes if needed.

## shadcn config — `components.json`

```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "src/styles/main.css",
    "baseColor": "slate",
    "cssVariables": true,
    "prefix": ""
  },
  "iconLibrary": "lucide",
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  },
  "registries": {}
}
```

Implications:

- `style: "new-york"` — darker borders, more compact spacing than `default`. Stick with it.
- `rsc: false` — this is a SPA. Do not port RSC-only shadcn recipes.
- `baseColor: "slate"` — overridden by the BONO tokens at the `@theme` layer. Do not change.
- `cssVariables: true` — tokens live in CSS, not in a JS config. This is what Tailwind v4 CSS-first requires.
- `iconLibrary: "lucide"` — icons come from `lucide-react`. Do not mix in `@radix-ui/react-icons`, heroicons, etc.

Adding a shadcn primitive:

```
npx shadcn@latest add <primitive>
```

It lands in `src/components/ui/<primitive>.tsx` with tokens already wired. Review the file, delete any default-variant comments that do not add value, and commit.

## Path aliases

`vite.config.ts`:

```ts
resolve: { alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) } }
```

Plus the `aliases` block in `components.json`. Always import via `@/`:

- `@/components/ui/button` — shadcn primitives
- `@/components/{feature}/…` — feature components
- `@/hooks` — hook barrel
- `@/lib/utils` — `cn`, formatters, `setOrDelete`
- `@/api/{feature}/…` — services + query keys
- `@/types` — type barrel
- `@/services/errorService` — operation-aware error reporter

Do not import via relative paths. `tsconfig.app.json` / `tsconfig.json` also declare the alias for the TypeScript resolver.

## shadcn extensions — `select-with-clear` precedent

Custom variants and composed primitives live alongside the shadcn primitive, not in feature folders. Example: `src/components/ui/select-with-clear.tsx` wraps `Select` and renders a clear-`X` `<button>` absolute-positioned inside the trigger. The file exports one component — keep that scope.

Rules when extending:

1. New file under `src/components/ui/<kebab-case-name>.tsx` — the file name is kebab-case, the exported component is PascalCase.
2. Import the base primitive from the sibling file — do not fork it.
3. Use tokens (`text-muted-foreground`, `hover:text-foreground`) — never hex.
4. Pointer-safe close pattern (see `select-with-clear.tsx`): `onPointerDown={(e) => { e.preventDefault(); e.stopPropagation(); … }}` prevents the underlying `Select` from re-opening when the user clicks the clear button.
5. Export named — do not default-export.

## Showcase contract

Every new UI primitive ships with a section in one of `src/pages/showcase/{Buttons,Cards,Inputs,Data,Feedback,Layout,Display}Showcase.tsx` (the closest-fit page). Use `<ShowcaseSection title description>` from `src/components/showcase/ShowcaseSection.tsx`:

```tsx
<ShowcaseSection title="Buttons with clear" description="Buttons that expose a reset affordance.">
  <div className="flex flex-wrap items-center gap-3">
    <SelectWithClear … />
  </div>
</ShowcaseSection>
```

If the primitive does not fit existing pages, add a new showcase page + route under `/showcase/<name>` (see `src/router.tsx:55-71` for the pattern). Do not omit the showcase — it is the public contract between designers and engineers.

## Linting and formatting

Prettier config lives at `Template.ClientApp/.prettierrc.json`:

```json
{
  "singleQuote": true,
  "printWidth": 100,
  "trailingComma": "es5",
  "semi": true
}
```

Rules to preserve in generated code:
- Single quotes for strings (`'…'`), double quotes only when escaping would be noisier (JSX attributes use double quotes per Prettier's default).
- 100-character line width.
- Trailing commas on multi-line arrays / objects / function arguments (ES5 mode — no trailing commas in function parameters).
- Semicolons required.

Run `pnpm format` (writes) or `pnpm format:check` (CI-friendly) from `Template.ClientApp/`. Files that do not round-trip through Prettier will fail the check.

ESLint config at `Template.ClientApp/eslint.config.js` uses the flat-config API with this stack:

- `@eslint/js` recommended
- `typescript-eslint` recommended (rules on `.ts`, `.tsx`)
- `eslint-plugin-react-hooks` flat-recommended
- `eslint-plugin-react-refresh` vite preset (fast-refresh safety)
- `eslint-config-prettier` — **must be last** so Prettier formatting rules win over any ESLint stylistic rules

One relaxation:

```js
'react-refresh/only-export-components': ['warn', { allowConstantExport: true }]
```

`allowConstantExport: true` lets shadcn/ui primitives export sibling constants (variant objects, helper functions) alongside the component without triggering the fast-refresh warning. Preserve this when extending any file under `src/components/ui/`.

Run `pnpm lint`. Flat-config ignores `dist/`. Do not add `.eslintrc*` files — the flat-config replaces them.

## Do not

- Do not hardcode hex colours in components — use tokens.
- Do not use Tailwind arbitrary values (`bg-[#…]`, `rounded-[6px]`, `text-[13px]`) — extend the theme or use the scale.
- Do not install a second UI library — extend shadcn via `components/ui/` siblings.
- Do not edit shadcn primitives in place to add variants — create a sibling file.
- Do not use inline `style={{ color: '#…' }}` — Tailwind utilities with tokens are the convention.
- Do not break dark-mode tokens in `main.css` even though the current app runs `forcedTheme="light"` — the template is inherited by projects that may flip it on.
- Do not run `npx shadcn@latest add` in a project without `components.json` — the tool falls back to `style: "default"` and produces primitives visually inconsistent with the rest of the template. Verify `components.json` first (prerequisite Glob catches this).
- Do not reorder the ESLint `extends:` array — `eslint-config-prettier` must remain last.
- Do not switch Prettier to double quotes, 80-char, or `trailingComma: 'all'` — the whole codebase will churn on the next PR.
