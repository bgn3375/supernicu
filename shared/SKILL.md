---
name: bono-design
description: Use this skill to generate well-branded interfaces and assets for Bono The Edge. Contains tokens (colors, type, spacing), utilities, and four reference pages (Landing, Dublin dashboard, Blog, System) showing how to compose them.
user-invocable: true
---

Read `README.md` for full brand context, then `bono-ds.css` for tokens and utilities.

## Files

- `README.md` — voice, content rules, visual foundations, conventions
- `bono-ds.css` — canonical tokens + utilities + shared components (import in every artifact)
- `bono-ds-system.html` — REFERENCE: every component, token, and rule, navigable
- `bono-ds-landing.html` — marketing landing page (Bono public site)
- `bono-ds-dublin.html` — Dublin client SaaS dashboard
- `bono-ds-blog.html` — editorial article (Ghiduri / blog)
- `assets/` — logos (bono-logo.png, bono-mark.png, bono-wordmark.png)

## When generating

1. Identify the surface — **Landing / marketing**, **Dublin / app**, or **Blog / editorial**. They share tokens but differ in feel:
   - Landing: bej-0 + dot grid, pink CTA, Fraunces `<em>` highlights, generous vertical rhythm.
   - Dublin: bej-0 + dot grid, white KPI cards on bej-1 sidebar, dense tables, mono numerics.
   - Blog: bej-0 + dot grid, Source Serif 4 body (`.t20-serif`), narrow column.
2. Always import `bono-ds.css` first.
3. Use existing **tokens** (`var(--c-*)`) and **utilities** (`.t-*`, `.sec-*`). Do NOT introduce new hex values or new type sizes.
4. Copy structure from the closest reference page (`bono-ds-landing.html` etc.) and adapt.
5. Write copy in Romanian — `tu`, simplu, direct.

## Hard rules

**DO**
- Use `--c-pink` (#EE4379) sparingly: primary CTA, focus, active states, accent dot. Max 1 pink CTA per screen.
- Use `<em>` on display headings to apply Fraunces italic on a single highlighted word.
- Use `.t-eyebrow` (with leading dot) for section labels.
- Use `--r-md` (14px) for cards, `--r-pill` (9999px) for buttons/badges/tabs.
- Use mono numerics (`.t-num-*`) for sums and KPIs.
- Pair semantic backgrounds with neutral text (`--c-ink`) — except status text where the saturated color goes on its own tint bg.

**DON'T**
- No new colors. No new gradients. No new type sizes.
- No gradient on text.
- No pink on body text.
- No emoji in UI.
- No shadows on default cards (only `--sh-sm` on lifted KPI surfaces, `--sh-pink` on the single primary CTA).
- No square corners on interactive controls.
- No Inter for editorial body — use `.t20-serif` (Source Serif 4) on blog prose.
- No "Click here", no "Află mai multe!", no exclamation marks in marketing copy.

## Voice samples

- Hero: "Contabilitatea ta, pe pilot automat."
- Empty state: "Încă nu ai nimic aici. Adaugă primul document și începem."
- Success: "Am primit documentul. Nu mai e nimic de făcut."
- Error: "Ceva n-a mers. Încearcă din nou sau scrie-ne."
- CTA: "Începe gratuit", "Trimite la interpretare", "Vezi cum funcționează"

## If invoked without context

Ask the user:
1. Which surface? (Landing / Dublin / Blog / something new)
2. What's the goal of the screen? (conversion / task / info)
3. Any specific copy or content to use?

Then act as an expert designer outputting HTML — start from the closest reference page and adapt.
