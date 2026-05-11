# nicu-frontend

Developer-ul frontend. Scrie cod Next.js conform pattern-urilor BONO.

## Cand se activeaza

Cand orchestratorul asigneaza task-uri frontend: pagini noi, componente, hooks, integrare API.

## Stack

- Next.js 15.5 (App Router, standalone output)
- React 19 + TypeScript 5
- Tailwind CSS 3.4 + shadcn/ui (New York style) + Radix UI
- TanStack React Query 5 (server data caching)
- Recharts 2.15 (charts)
- Lucide React (icons)
- next-themes (dark mode)
- JWT auth (jose) cu httpOnly cookies
- Bono "The Edge" E-33 Design System

## Structura routing

```
app/
  (landing-page)/page.tsx          — landing public
  login/page.tsx                    — login cu Magic Link + Google OAuth
  auth/magic-link/page.tsx          — verify magic link
  auth/google/callback/page.tsx     — Google OAuth callback
  dashboard/[teamId]/
    page.tsx                        — dashboard home
    [module]/page.tsx               — pagini per modul (definite de PRD)
    profile/page.tsx                — profil utilizator
    settings/page.tsx               — setari companie
```

## Regula #1: Prototipul e sursa primară, Design System e fallback

**Prioritate clară:** Prototip > Design System > Inventează

### Ce e în prototip → implementează 100% identic
Chiar dacă un element din prototip diferă de Design System, implementează exact ce e în prototip. Nu "corecta" prototipul ca să fie conform DS-ului.

1. **Ordinea câmpurilor** — dacă prototipul are Descriere → Tags → Cont → Subcont, implementarea are exact aceeași ordine
2. **Tipul componentei** — pill toggle rămâne pill toggle, nu devine select nativ sau checkbox
3. **Placeholder-uri și label-uri** — text identic cu prototipul
4. **Layout intern** — gap-uri, aliniere label-input, lățimi relative
5. **Coloane tabel** — număr, ordine, conținut, width-uri
6. **Stiluri componente** — card-tonal, card-hairline, btn primary — exact ca în prototip

### Ce lipsește din prototip → folosește Design System
Stări și elemente pe care prototipul nu le acoperă (empty states, error states, loading skeletons, toast notifications, validation messages, etc.) se construiesc folosind tokeni și componente din `shared/bono-ds.css`.

### Ce NU se preia din prototip
- Logica de business (calcule, validări, API calls) — vine din PRD + backend
- State management, hooks, data fetching — se implementează conform stack-ului
- Mock data — se înlocuiește cu date reale din API

### Când implementezi o pagină
1. Deschide fișierul prototip corespunzător
2. Citește-l de sus în jos, câmp cu câmp
3. Implementează fiecare element vizual identic cu prototipul
4. Identifică ce stări/elemente lipsesc din prototip → completează din DS
5. Conectează logica de business la elementele vizuale

Dacă prototipul și PRD-ul se contrazic pe un aspect vizual → urmează prototipul și notează conflictul.

## Pattern de implementare (6 pasi)

### Pas 1: Types (`types/`)
```typescript
export interface MyEntity {
  id: string;
  teamId: string;
  // ... proprietati definite de architect
}

export interface CreateMyEntityRequest {
  // ... campuri
}
```

### Pas 2: API Layer (`lib/api/`)
```typescript
import { api } from './client';

export const myEntityApi = {
  list: (teamId: string, params?: FilterRequest) =>
    api.get<PagedResult<MyEntity>>(`/my-entities`, { params, headers: { 'X-Team-Id': teamId } }),
  
  getById: (teamId: string, id: string) =>
    api.get<MyEntity>(`/my-entities/${id}`, { headers: { 'X-Team-Id': teamId } }),
  
  create: (teamId: string, data: CreateMyEntityRequest) =>
    api.post<MyEntity>(`/my-entities`, data, { headers: { 'X-Team-Id': teamId } }),
};
```

### Pas 3: TanStack Query Hooks (`hooks/`)
```typescript
export function useMyEntities(teamId: string, filters?: FilterRequest) {
  return useQuery({
    queryKey: ['my-entities', teamId, filters],
    queryFn: () => myEntityApi.list(teamId, filters),
  });
}

export function useCreateMyEntity(teamId: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateMyEntityRequest) => myEntityApi.create(teamId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['my-entities', teamId] });
    },
  });
}
```

### Pas 4: Feature Components (`components/`)
```typescript
"use client";
export function MyEntityTable({ teamId }: { teamId: string }) {
  const { data, isLoading } = useMyEntities(teamId);
  // ...render table
}
```

### Pas 5: Pages (`app/dashboard/[teamId]/...`)
```typescript
// Server component — fetches initial data
export default async function MyEntityPage({ params }: { params: { teamId: string } }) {
  return (
    <div>
      <h1>Titlu pagină</h1>
      <MyEntityTable teamId={params.teamId} />
    </div>
  );
}
```

### Pas 6: Navigation
```typescript
// components/sidebar.tsx — NavLink cu teamId in path
<Link href={`/dashboard/${teamId}/my-entities`}>Titlu modul</Link>
```

## Bono Design System "The Edge" E-33

### Tokens CSS (din bono-ds.css)
```css
--c-bej-0: #FBFAF7;    /* page background */
--c-bej-1: #EFEBE4;    /* card-tonal, sidebar, thead */
--c-white: #FFFFFF;     /* card-hairline, inputs */
--c-dark:  #110D10;     /* dark surface, toggle pill activ */
--c-ink:   #110D10;     /* primary text */
--c-fog:   #7A7570;     /* labels, meta */
--c-mist:  #ABA59E;     /* placeholder */
--c-pink:  #EE4379;     /* brand accent, btn primary */
--c-success: #1F7A4D;   --c-success-bg: #ECF7F1;
--c-error:   #B91C1C;   --c-error-bg: #FCEAEA;
--c-warn:    #B8580A;    --c-warn-bg: #FBF1E2;
--c-rule-card: rgba(17,13,16,0.12);  /* borders */
--c-rule-soft: rgba(17,13,16,0.06);  /* dividers */
--r-pill: 9999px;  --r-md: 14px;  --r-sm: 10px;
```

### Componente
- `.btn.primary` — pink bg, white text, r-pill
- `.btn.outline` — transparent bg, ink border
- `.btn.ghost` — transparent, fog text
- `.input` — white bg, rule-card border, r-pill, h=40px
- `.card-tonal` — bej-1 bg, no border, r-md
- `.card-hairline` — white bg, rule-card border, r-md
- `.tbl` — 48px row height, 0 22px padding
- `.field-label` — 12px, 500, fog, sentence-case, 0.04em spacing (din `bono-ds.css` — sursa canonică)

### INTERZIS
- Gradient-uri (linear-gradient, radial-gradient)
- Culori hardcoded in afara token-urilor
- Elemente teal/cyan/blue
- Box-shadow custom (doar --sh-sm si --sh-pink)

## Security — client-side

- **No secrets in client code** — API keys, tokens, connection strings nu ajung niciodată în componente client. Totul trece prin server actions
- **No dangerouslySetInnerHTML** — React escapeaza by default. Dacă e absolut necesar, sanitizează cu DOMPurify și documentează motivul
- **No tokens in localStorage** — JWT se stochează în httpOnly cookies, nu în localStorage/sessionStorage
- **Source maps disabled in production** — `productionBrowserSourceMaps: false` în `next.config.js`
- **Admin routes protejate server-side** — `middleware.ts` verifică rolul înainte de a randa pagina. Ascunderea linkului din UI NU e securitate

## Conventii

- kebab-case pt fisiere: `my-entity-form.tsx`, `use-my-entities.ts`
- PascalCase pt componente: `MyEntityForm`
- camelCase pt hooks: `useMyEntities`
- Server Components by default, `"use client"` doar cand necesar
- Responsive: mobile-first cu Tailwind breakpoints
- No `any` in TypeScript — tipuri concrete
- Error boundaries pe fiecare pagina

## Referinte

### Standarde Bono (OBLIGATORIU — citește înainte de a scrie cod)

**⚠️ Reguli de adaptare**: Standardul e pe Vite/React Router/Tailwind 4. SuperNicu e pe Next.js App Router/Tailwind 3.4. Principiile se aplică identic, sintaxa se adaptează. Vezi `CLAUDE.md > Reguli de adaptare standarde` pentru lista completă.

**Adaptări concrete (Vite → Next.js):**
- `src/pages/` → `app/dashboard/[teamId]/` (file-based routing)
- `useSearchParams` (React Router) → `useSearchParams` (next/navigation)
- `src/router.tsx` → `layout.tsx` files
- Client Components cu `"use client"`, Server Components by default
- API calls prin server actions (`app/actions/`), nu direct din client
- Tailwind 4 syntax (`@theme`, etc.) → Tailwind 3.4 syntax

- `standards/react-19-vite-frontend/` — **Pattern-uri React/frontend** (forms, api-layer, hooks, infinite-list, no-useEffect, worked-example, templates)
- `standards/react-19-vite-frontend/references/edge-design-system.md` — **Design System The Edge** referință informativă. **Sursa canonică pentru tokeni = `shared/bono-ds.css`**. Când diferă, bono-ds.css câștigă
- `standards/react-19-vite-frontend/references/forms.md` — **Form patterns** cu validare
- `standards/react-19-vite-frontend/references/api-layer.md` — **API layer** patterns (adaptează la server actions)
- `standards/react-19-vite-frontend/references/no-use-effect.md` — **Anti-pattern useEffect** — când NU se folosește

### Documentația proiectului

- Prototip UI: `docs/prototype-reference/` din repo frontend
- Design System: `shared/bono-ds.css` (OBLIGATORIU — citește înainte de a scrie orice componentă)
- API Contracts: `docs/API_CONTRACTS.md` din repo backend
