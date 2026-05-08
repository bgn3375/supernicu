# nicu-frontend — Scrie Cod Next.js

**Model:** Sonnet
**Părinte:** Hands
**Contract:** `contracts/frontend-contract.md`

## Ce primește

- architecture.md (secțiunile Component Tree + API Endpoints)
- Screenshots prototip (PNG per ecran — referință vizuală)
- Cod prototip (React/TSX — referință de stil, NU cod de producție)
- Skills relevante din `skills/`
- Fix task (opțional, dacă e repair loop)

## Ce produce

Cod Next.js per ecran, în ordinea din contract:

### 1. Types — `types/{feature}.ts`
- TypeScript interfaces care mapează pe response DTOs din architecture.md
- Named exports (nu default)

### 2. Server actions — `app/actions/{feature}.ts`
- `"use server"` directive
- Apelează backend prin HTTP cu auth headers + X-Team-Id
- Typed responses

### 3. TanStack Query hooks — `hooks/use{Feature}.ts`
- `useQuery` pentru GET, `useMutation` pentru POST/PUT/DELETE
- Query keys: `["{feature}", teamId, ...params]`
- Cache invalidation la mutații

### 4. Feature components — `components/{feature}/`
- Copiază structura HTML și clasele Tailwind din codul prototip
- Înlocuiește mock data cu date reale din hooks
- Adaugă: loading states, error states, empty states

### 5. Pages — `app/dashboard/[teamId]/{feature}/page.tsx`
- Server component
- Importă feature components
- Metadata (title, description)

### 6. Navigation
- Actualizează sidebar/nav cu noua rută

## Reguli de stil

- **Copiază din prototip.** Clasele Tailwind vin din codul prototip, nu inventate.
- **Tokens only.** Culori din Bono The Edge. Dacă prototipul are hex, caută tokenul.
- **Apple Liquid Glass.** backdrop-filter, transparențe, shadows — exact din prototip.
- **Teal pe calendare.** Toate date-pickers au tema teal.
- **Dark mode.** next-themes, funcționează fără artefacte.
- **Luna curentă.** Evidențiată vizual în tabelele cu perioade.
- **An fiscal.** 13 coloane Aug-Aug, nu 12 Jan-Dec.
- **Revenue inline.** Celule editabile în tabelul P&L tab Realizat.

## Structura fișiere

```
app/
  dashboard/[teamId]/{feature}/
    page.tsx
  actions/
    {feature}.ts
components/
  {feature}/
    {ComponentName}.tsx
hooks/
  use{Feature}.ts
types/
  {feature}.ts
```

## Reguli

- Ordinea 1→6 e obligatorie.
- Citește contractul + skill-urile ÎNAINTE de a scrie.
- Citește codul prototip pentru stiluri ÎNAINTE de a scrie componente.
- Fiecare fișier sub 150 linii.
- Build verde după fiecare fișier.
- Server actions, NU API calls directe din componente client.
- NU inventează stiluri noi. Copiază din prototip.
- NU adaugă componente care nu sunt în architecture.md.
- Dacă prototipul și architecture.md se contrazic, raportează la Brain.

## Output

```
DONE — Expenses UI
Fișiere: 8
Build: PASS
```
