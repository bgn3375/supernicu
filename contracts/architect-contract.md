# Contract: nicu-architect

## Primește

| Input | De la | Format |
|-------|-------|--------|
| PRD narativ | Bruce (via Brain) | Markdown |
| Screenshots prototip | Bruce (via Brain) | PNG per ecran |
| Cod prototip | Bruce (via Brain) | React/TSX |

## Produce

Un singur document `architecture.md` cu 4 secțiuni:

### Secțiunea 1: Data Model
- Lista tabelelor cu coloanele lor (nume, tip, nullable, default)
- Relații între tabele (FK, cascade rules)
- Indexuri
- NU include SQL — doar structura logică

### Secțiunea 2: API Endpoints
- Per endpoint: method, route, request DTO, response DTO
- Autorizare: ce roluri au acces
- Validări pe input
- Grupate per modul (ex: Expenses, Categories, Budgets)

### Secțiunea 3: Component Tree
- Per ecran: lista componentelor React necesare
- Ierarhie: page → feature components → shared components
- Per componentă: ce date primește (props), ce acțiuni expune
- Mapare pe API endpoints (ce componentă apelează ce endpoint)

### Secțiunea 4: Security Requirements
- Autorizare per endpoint (matrice rol × endpoint)
- Multi-tenant isolation points
- Input validation rules
- Sensitive data handling (ce câmpuri se loghează, ce nu)

## Checklist de verificare (folosit de nicu-verify)

- [ ] Fiecare ecran din PRD are cel puțin o componentă în Component Tree?
- [ ] Fiecare componentă care afișează date are un endpoint API mapat?
- [ ] Fiecare endpoint API are request DTO și response DTO definite?
- [ ] Fiecare tabel are coloana `team_id`?
- [ ] Fiecare endpoint are autorizare definită (ce roluri au acces)?
- [ ] Fiecare tabel cu date financiare are coloane multi-currency (RON + EUR)?
- [ ] Perioadele folosesc an fiscal Aug-Aug, nu an calendaristic?
- [ ] Fiecare relație FK are cascade rule definită?

## Limite

- NU scrie cod (nici SQL, nici TypeScript, nici C#)
- NU ia decizii de implementare (ex: ce librărie de forms)
- NU decide structura de fișiere (doar structura logică de componente)
- Dacă PRD-ul e ambiguu pe un punct, listează ambiguitatea explicit — nu ghicește
