# Contract: Bruce → SuperNicu

Definește ce primește SuperNicu de la Bruce + Bogdan înainte de a porni pipeline-ul.

## Input obligatoriu

### 1. PRD narativ confirmat
- Format: Markdown
- Confirmat explicit de Bogdan ("da, e complet")
- Conține: module, roluri, reguli de business, edge cases
- Fiecare ecran din aplicație e descris

### 2. Screenshots prototip
- Format: PNG, un fișier per ecran
- Sursă: Claude Design / Claude Chat artefacte
- Convenție nume: `ecran-nume.png` (ex: `expenses-list.png`, `pnl-table-realizat.png`)
- Conține toate stările vizibile: empty state, loaded, error, hover, modal deschis

### 3. Cod prototip
- Format: fișiere React/TSX din Claude Design
- Conține: componente cu stiluri Tailwind exacte, layout, mock data
- NU conține: API reală, state management, routing, autentificare
- Scop: referință vizuală de stil, nu cod de producție

### 4. Design tokens
- Format: lista de tokens Tailwind / CSS variables folosite în prototip
- Sursă: Bono The Edge design system
- Include: culori, spațiere, tipografie, shadows, border-radius

## Checklist de completitudine

Brain verifică fiecare punct înainte de a porni. Dacă orice punct e "nu", Brain returnează la Bogdan cu lista de lipsuri.

- [ ] PRD-ul acoperă fiecare ecran din prototip?
- [ ] Fiecare ecran are screenshot PNG?
- [ ] Fiecare ecran are cod prototip TSX?
- [ ] Rolurile și permisiunile sunt definite per ecran?
- [ ] Edge cases sunt documentate per modul?
- [ ] An fiscal (Aug-Aug) e reflectat în toate modulele cu perioade?
- [ ] Design tokens sunt listate explicit?

## Ce NU primește SuperNicu

- Specificații de implementare (asta face nicu-architect)
- Schema DB (asta face nicu-architect)
- Decizii de arhitectură cod (asta face nicu-architect)
- Cod de producție (asta fac nicu-backend și nicu-frontend)

## Output dacă input-ul e incomplet

Brain produce un document structurat:

```
## Lipsuri identificate
- [ ] Ecranul "Budget Import" nu are screenshot
- [ ] PRD-ul nu descrie comportamentul la upload Excel invalid
- [ ] Rolul "Accounting Viewer" nu are permisiuni definite pe ecranul P&L
```

Pipeline-ul NU pornește până Bogdan confirmă completarea.
