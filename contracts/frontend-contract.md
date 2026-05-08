# Contract: nicu-frontend

## Primește

| Input | De la | Format |
|-------|-------|--------|
| architecture.md | nicu-architect (via Brain) | Markdown |
| Screenshots prototip | Bruce (via Brain) | PNG per ecran |
| Cod prototip | Bruce (via Brain) | React/TSX cu stiluri exacte |
| Skills relevante | skills/ folder | SKILL.md |

## Produce

Cod Next.js 15 funcțional care arată identic cu prototipul dar are logica reală.

### Per ecran produce (în ordine):

1. **Types** — `types/{feature}.ts`
   - TypeScript interfaces care mapează pe response DTOs din architecture.md
   - Export-uri named (nu default)

2. **Server actions** — `app/actions/{feature}.ts`
   - `"use server"` directive
   - Apelează backend-ul prin HTTP (cu auth headers + X-Team-Id)
   - Returnează typed responses

3. **TanStack Query hooks** — `hooks/use{Feature}.ts`
   - `useQuery` pentru GET, `useMutation` pentru POST/PUT/DELETE
   - Query keys consistente: `["{feature}", teamId, ...params]`
   - Invalidare cache la mutații

4. **Feature components** — `components/{feature}/`
   - Copiază structura HTML și clasele Tailwind din codul prototip
   - Înlocuiește mock data cu date reale din hooks
   - Adaugă loading states, error states, empty states

5. **Pages** — `app/dashboard/[teamId]/{feature}/page.tsx`
   - Server component care importă feature components
   - Metadata (title, description)

6. **Navigation** — actualizează sidebar/nav cu noua rută

### Reguli de stil

- Clasele Tailwind se copiază din codul prototip — nu se inventează noi
- Dacă prototipul folosește un token Bono The Edge, se folosește acel token
- Dacă prototipul folosește un hex hardcodat, se caută tokenul echivalent
- Apple Liquid Glass: backdrop-filter, transparențe, shadows — se copiază exact
- Tema teal pe calendare și date-pickers
- Dark mode suportat (next-themes)
- Luna curentă evidențiată în tabele cu perioade

### Structura fișiere

```
app/
  dashboard/[teamId]/
    {feature}/
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

## Checklist de verificare (folosit de nicu-verify)

### Code checklist
- [ ] Fiecare ecran din architecture.md are o pagină Next.js?
- [ ] Fiecare componentă din architecture.md există ca fișier?
- [ ] Fiecare componentă care afișează date folosește un TanStack Query hook?
- [ ] Fiecare mutație invalidează cache-ul relevant?
- [ ] Server actions au `"use server"` directive?
- [ ] Toate request-urile includ auth headers și X-Team-Id?
- [ ] Build trece fără erori și fără warnings?
- [ ] Fiecare fișier e sub 150 linii?
- [ ] Niciun secret în cod frontend?

### UI checklist (verificat de nicu-verify în mod verify-ui)
- [ ] Layout-ul fiecărui ecran se potrivește cu screenshot-ul prototip?
- [ ] Culorile se potrivesc (tokens, nu hex-uri hardcodate)?
- [ ] Spațierile sunt consistente cu prototipul?
- [ ] Empty states există și arată ca în prototip?
- [ ] Loading states există?
- [ ] Hover effects funcționează?
- [ ] Dark mode funcționează fără artefacte vizuale?
- [ ] Tabelele P&L au highlight pe luna curentă?
- [ ] Revenue-ul e editabil inline în tab-ul Realizat?

## Limite

- NU ia decizii de arhitectură — urmează architecture.md
- NU scrie cod backend
- NU inventează stiluri noi — copiază din prototip
- NU sare peste pași — ordinea 1→6 e obligatorie
- Dacă prototipul și architecture.md se contrazic, raportează la Brain
