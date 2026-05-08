---
name: design-system
description: Bono The Edge design system — Apple Liquid Glass style. Teal primary, frosted glass, dark mode. Fires on "design system", "styling", "colors", "typography", "tokens", "how should this look".
---

# Design System — Bono The Edge (Apple Liquid Glass)

Interfața P&L urmează un design "frosted glass" inspirat de Apple.

## Principii vizuale

1. **Frosted glass** — carduri semi-transparente cu `backdrop-filter: blur()`
2. **Umbre soft** — nu hard shadows, ci subtile cu opacity
3. **Border-radius generos** — rounded-xl pe carduri, rounded-lg pe butoane
4. **Teal ca accent** — calendare, luna curentă, link-uri active, focus states
5. **Dark mode complet** — prin next-themes, fără artefacte

## Culori

```
Teal (primary):     tokens din design system, nu hex hardcodat
Background:         gradient subtil, nu flat
Cards:              semi-transparent (bg-white/80 dark:bg-slate-900/80)
Text:               slate-900 / slate-100 (dark)
Borders:            slate-200/50 / slate-700/50 (dark)
```

**INTERZIS:** hex-uri hardcodate. Folosește tokens sau clasele Tailwind din prototip.

## Componente

### Carduri
```
backdrop-filter: blur(12px)
background: semi-transparent (white/80 sau slate-900/80)
border: 1px solid semi-transparent
border-radius: rounded-xl
shadow: shadow-sm sau shadow-md (soft)
```

### Tabele (P&L)
```
Luna curentă: coloană evidențiată (background teal subtle)
Hover pe rând: background change subtil
Hover pe coloană: highlight vizual
Celule editabile: focus ring teal
```

### Calendare / Date-pickers
```
Tema teal (nu default shadcn)
Selected date: teal background
Today: teal ring
```

### Butoane
```
Primary: teal background
Secondary: transparent cu border
Destructive: red
Disabled: opacity redusă
```

### Status badges (cheltuieli)
```
Draft:     gri/neutru
Submitted: albastru/teal
Approved:  verde
Rejected:  roșu
Paid:      verde închis
```

## Reguli

1. **Stiluri din prototip.** nicu-frontend copiază clasele Tailwind din codul prototip.
2. **Tokens only.** Niciun hex hardcodat.
3. **Dark mode pe tot.** Fiecare componentă funcționează în dark mode.
4. **Consistență.** Același card style peste tot. Același button style peste tot.
5. **shadcn/ui base.** Componente shadcn/ui (New York variant) customizate cu tokens.
6. **Responsive.** Desktop-first, dar funcțional pe mobile.

## Ce NU facem

- NU flat design pur (avem frosted glass, blur, transparențe)
- NU pink/bej dominant (teal e culoarea primară)
- NU hard shadows (doar soft, cu opacity)
- NU inventăm stiluri noi — copiem din prototip
