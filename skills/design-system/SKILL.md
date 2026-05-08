---
name: design-system
description: Bono The Edge design system — pink brand, bej surfaces, flat design, dot grid. Fires on "design system", "styling", "colors", "typography", "tokens", "how should this look".
---

# Design System — Bono The Edge

Sursa de adevăr: `references/bono-ds.css` (tokens + utilități canonice).

## Principii vizuale

1. **Flat design** — fără glassmorphism, fără backdrop-blur, fără transparențe
2. **Bej backgrounds** — bej-0 (#FBFAF7) ca page bg, bej-1 (#EFEBE4) ca tonal
3. **Pink (#EE4379) ca accent** — CTA, focus states, accente. Max 1 pink CTA per ecran
4. **Dot grid** — pattern subtil pe body (.has-grid), textură de graphite paper
5. **Shadows minimale** — doar --sh-sm pe KPI lifted + --sh-pink pe primary CTA

## Suprafețe (4 — atât)

```
--c-white    #FFFFFF     KPI cards, table cards, inputs (lifted)
--c-bej-0    #FBFAF7     page bg unic (Landing, Dublin, Blog)
--c-bej-1    #EFEBE4     tonal: sidebar, action cards, thead, KPI bg
--c-dark     #110D10     dark surface + ink
```

## Culori

```
Brand:       --c-pink (#EE4379), --c-pink-deep (#C9255B), --c-pink-tint (#FDE7F0)
Text:        --c-ink (#110D10), --c-fog (#7A7570), --c-mist (#ABA59E)
Lines:       --c-rule-card (ink@12%), --c-rule (ink@10%), --c-rule-soft (ink@6%)
Status:      success #1F7A4D, warn #B8580A, error #B91C1C, AI #A8336E
```

## Tipografie

```
Inter (300–700)         — display, UI, body
Source Serif 4          — editorial body (blog only, .t20)
Fraunces (italic)       — accent pe display headings via <em>
DM Mono                 — eyebrow labels (.t12)
```

Scale: .t60, .t48, .t40, .t32, .t28, .t24, .t20, .t18, .t16, .t14, .t12
Numere: .tn40, .tn28, .t-num-inline (tabular-nums)

## Corners (radii)

```
--r-xs   6px      chips mici
--r-sm   10px     inputs, flow steps
--r-md   14px     cards (canonical Bono radius)
--r-lg   20px     modal mare
--r-xl   24px     KPI hero
--r-pill 9999px   butoane, badges, tabs
```

## Componente

### Carduri
```
Default: white bg, 1px solid var(--c-rule-card), border-radius var(--r-md)
Tonal:   bej-1 bg, fără border
Hover:   border shifts spre pink @ 30%. Fără lift/scale.
```

### Butoane
```
Primary:     pink fill, --sh-pink shadow, hover brightness(0.95)
Secondary:   transparent cu border
Destructive: error red
Disabled:    opacity redusă
Corners:     --r-pill (niciodată colțuri drepte pe controale)
```

### Status badges
```
Draft:     neutru
Submitted: pink-tint bg
Approved:  success-bg + success text
Rejected:  error-bg + error text
Paid:      success
```

### Tabele
```
Header:    bej-1 bg
Rows:      white bg, hover subtil
Borders:   var(--c-rule-soft)
Numere:    tabular-nums, aliniate dreapta
```

## Reguli

1. **Tokens only.** Niciun hex hardcodat. Folosește var(--c-*) din bono-ds.css.
2. **Stiluri din prototip.** nicu-frontend copiază clasele din codul prototip.
3. **Flat, nu glass.** Fără backdrop-filter, fără blur, fără transparențe pe carduri.
4. **Pink sparingly.** Max 1 pink CTA per ecran. Pink pe fills/borders/accente, NU pe text.
5. **Niciodată gradient pe text.**
6. **No emoji în UI.** Niciodată Unicode glyphs — folosește SVG inline.
7. **Sentence case** pe labels, butoane, titluri. UPPERCASE doar pe .t12 eyebrow.
8. **Responsive:** desktop-first, sidebar 240px, collapses la 64px pe tablet.

## Ce NU facem

- NU glassmorphism / backdrop-blur / frosted glass
- NU teal — culoarea brand e pink
- NU shadows pe carduri default (doar pe KPI lifted + pink CTA)
- NU inventăm culori sau type sizes noi
- NU gradient pe text
- NU pink pe body text
- NU emoji în UI chrome
