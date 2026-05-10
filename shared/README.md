# Bono Design System

Design system-ul oficial pentru **Bono The Edge** — platforma românească de contabilitate care unifică Landing, Dublin (dashboard client) și Ghiduri (blog) într-un singur limbaj vizual.

## Cum se folosește

Acest proiect e baseline-ul. Când începi un design nou:
1. Citește acest README ca să înțelegi tokens + reguli.
2. Importă `bono-ds.css` în orice fișier HTML nou.
3. Folosește utilitățile de tipografie (`.t-display`, `.t-h1`, `.t-lead`, `.t-eyebrow`, etc.) și culorile din variabile (`var(--c-pink)`, `var(--c-bej-1)`, etc.).
4. Pornește de la una din cele 4 pagini-mostre dacă vrei un punct de plecare:
   - `bono-ds-landing.html` — pagina marketing
   - `bono-ds-dublin.html` — dashboard SaaS (Dublin)
   - `bono-ds-blog.html` — articol editorial (Ghiduri)
   - `bono-ds-system.html` — referința completă a sistemului (toate componentele, tokens, reguli)

## Fișiere

```
bono-ds.css            ← tokens + utilități + componente shared (importă în orice fișier nou)
bono-ds-system.html    ← REFERINȚA — design system complet, navigabil
bono-ds-landing.html   ← mostră marketing (landing page Bono)
bono-ds-dublin.html    ← mostră app (dashboard Dublin)
bono-ds-blog.html      ← mostră editorial (articol blog)
assets/                ← logos (bono-logo.png, bono-mark.png, bono-wordmark.png)
```

---

## VOICE & COPY

**Limba:** română, primary. Engleza e ok doar pentru termeni tehnici (API, endpoint, coduri interne).

**Voice — 4 cuvinte:** *Simplu, direct, prietenos, smart.*
- **Simplu** — propoziții scurte. Bullet > paragraf când se poate.
- **Direct** — afirmă acțiunea sau faptul. Fără "probabil", "poate".
- **Prietenos** — "tu", nu "dvs.".
- **Smart** — respect pentru cititor. Termenii contabili (TVA, deductibilitate) folosiți corect.

**Casing:** sentence case pentru UI labels, butoane, titluri. UPPERCASE doar pentru eyebrow labels mono cu letter-spacing (`.t-eyebrow`). Diacritice obligatorii (ă, â, î, ș, ț).

**Numere & bani:** `1.245,80 RON` (separator zecimal virgulă, mii cu punct). Date: `13 Apr 2026`.

**Don't:** emoji, ALL CAPS pentru emfază, "Click here", exclamări marketing-y, "Să descoperim împreună…".

---

## VISUAL FOUNDATIONS

### Palete LOCKED (nu se inventează culori noi)

**Surfaces** (4 — atât):
- `--c-white` `#FFFFFF` — KPI, table cards, inputs (lifted surfaces)
- `--c-bej-0` `#FBFAF7` — page bg unic (Landing, Dublin, Blog, System), cu dot grid pe `body.has-grid`
- `--c-bej-1` `#EFEBE4` — tonal universal: sidebar, action cards, thead, KPI bg
- `--c-dark` `#110D10` — dark surface + ink
- `--c-dark` `#110D10` — dark surface + ink

**Text — un singur ink închis:**
- `--c-ink` `#110D10` — text primar, peste tot pe light
- `--c-fog` `#7A7570` — labels, meta secundar
- `--c-mist` `#ABA59E` — placeholder, muted

**Brand:**
- `--c-pink` `#EE4379` — culoarea Bono. Folosită ca accent (nu pe text, nu peste tot).
- `--c-pink-deep` `#C9255B` — hover/press
- `--c-pink-tint` `#FDE7F0` — backgrounds soft, callouts

**Status (toate au tint + ink închis):**
- success `#1F7A4D` / bg `#ECF7F1`
- warn `#B8580A` / bg `#FBF1E2`
- error `#B91C1C` / bg `#FCEAEA`
- AI `#A8336E` / bg `#F4E4EE` / gradient `linear-gradient(135deg, #EE4379, #7B2A6E)`

**Lines (rules):**
- `--c-rule-card` `ink @ 12%` — borduri pe carduri/KPI/inputs (containere albe pe bej)
- `--c-rule` `ink @ 10%` — hairline secundar
- `--c-rule-soft` `ink @ 6%` — divider intern subtil

### Tipografie

**Familii:**
- **Inter** (300/400/500/600/700) — display + UI + body majoritar
- **Source Serif 4** — exclusiv pentru body editorial pe blog (.t20-serif)
- **Fraunces** — display heading variant (folosit cu `<em>` pentru emfază italică pe display)

**Scale (utilități în CSS):**
- `.t-display` — hero / display, ~60–72px, tight leading
- `.t-h1` ... `.t-h6` — hierarchy
- `.t-lead` — paragraf intro, mai larg
- `.t-body`, `.t-body-sm`
- `.t-eyebrow` — uppercase mono cu dot prefix (DM Mono, letter-spacing 0.12em)
- `.t-meta`, `.t-meta-sm`
- `.t-num-inline`, `.t-num-lg`, `.t-num-md` — numere mono pentru KPI-uri / sume
- `.t-badge` — text pentru pill/badge (uppercase mono mic)
- `.t-actor`, `.t-em` — varianți utility
- `.t-suffix-rON`, `.t-suffix-percent` — sufixe mono pentru numere

**Reguli:**
- Display & headings sunt tight (line-height 1.0–1.1, letter-spacing ușor negativ).
- Body: line-height 1.5–1.7.
- `<em>` pe display = Fraunces italic — folosit pentru a accentua un cuvânt (NU mai mult de 1–2 per heading).
- **Niciodată gradient pe text.** **Niciodată pink pe text.** Pink = fills, borders, accents only.

### Grid pattern (textură de pagină)

`.has-grid` aplică un **dot grid** subtil pe orice container care arată bej-0. Folosit pe `<body>` în toate paginile (Landing, Dublin, Blog, System).

Tokens:
- `--grid-color: rgba(17, 13, 16, 0.15)` — ink @ 15% (cross-device stable)
- `--grid-size: 32px` — spacing punct la punct
- `--grid-radius: 1px` (Ø 2px) — radius dot
- `--grid-edge: 1.5px` — tranziție sharp la transparent

Implementarea folosește `::before` separat (`pointer-events: none`, `z-index: 0`) ca să nu intercepteze click-uri. Vibe: graphite paper / Notion canvas.

### Section utilities

`.sec-page` / `.sec-app` / `.sec-mkt` / `.sec-mkt-grid` — toate transparente (page bg + grid vin de pe `body.has-grid`).
`.sec-tonal` — bej-1.
`.sec-dark` — dark + text alb.

### Spacing & Layout

Spacing scale (numele = pixeli): 4, 8, 12, 16, 24, 28, 40, 56, 92.

**Desktop:** sidebar 240px (bej-1) + content padding 32–40px.
**Tablet (768–1024):** sidebar collapses la 64px icon-only.
**Mobile (< 768):** topbar sticky + bottom-nav.
**Marketing:** max-width 1200px, vertical rhythm 64–96px între secțiuni.

### Corners (radii)

- `--r-xs` 6px — chips foarte mici
- `--r-sm` 10px — inputs, flow steps
- `--r-md` 14px — **cards (canonical Bono radius)**
- `--r-lg` 20px — modal mare, hero card
- `--r-xl` 24px — KPI hero
- `--r-pill` 9999px — butoane, badges, tabs, nav items

**Niciodată colțuri drepte pe controale interactive.**

### Shadows

Design e **flat**. Singurele shadows acceptate:
- `--sh-sm` — micro shadow pe carduri lifted (KPI), foarte subtil
- `--sh-pink` — pe primary CTA (gradient pink), accent moment unic per ecran

Fără shadow pe carduri default. Fără glassmorphism, fără backdrop-blur.

### Borders

- Default `1px solid var(--c-rule-card)` pe orice container alb pe bej.
- `var(--c-rule-soft)` pentru dividere interne foarte subtili.
- `var(--c-pink)` pe focus/active state pentru inputs.

### Hover & press

- Carduri: border shifts spre pink @ 30%. Fără lift/scale.
- Butoane primary (pink fill): darken `filter: brightness(0.95)`. Press: `transform: scale(0.98)` brief.
- Linkuri: color shifts spre `--c-pink`.
- `transition: all 0.15s` ca baseline. Reduced-motion respectat.

---

## ICONOGRAPHY

**Approach:** SVG inline, stroke-based, monocrom, `currentColor`. Stroke-width 1.4–1.6 pentru icons mici (14×14, 18×18). Fără fills, fără two-tone, fără 3D.

**No emoji** în UI chrome. Niciodată Unicode glyphs (✓ ✕ →) — folosește SVG.

**Logos:** `assets/bono-logo.png`, `assets/bono-mark.png`, `assets/bono-wordmark.png`.

---

## CONVENȚII DE COD

- Importă `bono-ds.css` ca primul stylesheet după Google Fonts.
- Pentru layout-specific, scrie un `<style>` inline care folosește **tokens** (`var(--c-bej-1)`), niciodată hex codes hard-coded.
- Folosește utilitățile `.t-*` pentru tipografie. Nu redefini `font-size`/`font-weight` din `<style>` decât pentru cazuri specifice.
- Pentru pagini noi, copiază topnav-ul din `bono-ds-landing.html` (`.v3-topnav`) ca cross-link între pagini.

---

## Use din Claude

Când lucrezi cu Claude pe Bono:
1. Spune-i să citească `README.md` + `bono-ds.css`.
2. Spune-i de ce surface ai nevoie (Landing / Dublin / Blog / System reference).
3. Folosește una din mostrele `bono-ds-*.html` ca punct de plecare.
4. Roagă să folosească **doar** tokens și utilități existente, nu să inventeze culori sau type scale noi.
