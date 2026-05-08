# Contract: nicu-backend

## Primește

| Input | De la | Format |
|-------|-------|--------|
| architecture.md | nicu-architect (via Brain) | Markdown |
| Skills relevante | skills/ folder | SKILL.md |

## Produce

Cod .NET funcțional pentru fiecare endpoint din architecture.md.

### Per endpoint produce (în ordine):

1. **Service interface** — `I{Feature}Service.cs`
   - Metode cu `ValueTask<OperationResult<T>>`
   - Un fișier per feature (nu per endpoint)

2. **DTOs** — `{Feature}Dtos.cs`
   - `record` types cu `required` modifier
   - Colecții inițializate cu `= []`
   - Request DTO + Response DTO per endpoint

3. **Query sau Command** — `{Action}{Feature}Query.cs` / `{Action}{Feature}Command.cs`
   - CQRS pattern: Query pentru GET, Command pentru POST/PUT/DELETE
   - NHibernate sessions, nu Entity Framework
   - Toate query-urile filtrează pe `team_id`

4. **Service adapter** — `{Feature}ServiceAdapter.cs`
   - Implementează interface-ul
   - Business logic aici (validări, calcule, reguli)
   - Returnează `OperationResult<T>` (success/failure)

5. **Controller** — `{Feature}Controller.cs`
   - `[Authorize]` pe toate endpoint-urile
   - Citește `X-Team-Id` din header
   - `Task<IActionResult>` (nu ValueTask) pe action methods
   - Routing: `[Route("api/[controller]")]`

6. **DI registration** — în `Startup.cs` sau modul-specific

### Structura fișiere

```
PnL.DomainServices/
  {Feature}/
    I{Feature}Service.cs
    {Feature}Dtos.cs
    Queries/{Action}{Feature}Query.cs
    Commands/{Action}{Feature}Command.cs

PnL.ServiceAdapters/
  {Feature}/
    {Feature}ServiceAdapter.cs

PnL.Api/
  Controllers/
    {Feature}Controller.cs
```

## Checklist de verificare (folosit de nicu-verify)

- [ ] Fiecare endpoint din architecture.md are controller action?
- [ ] Fiecare query/command filtrează pe `team_id`?
- [ ] Fiecare controller are `[Authorize]`?
- [ ] Toate service-urile returnează `OperationResult<T>`?
- [ ] DTOs sunt `record` cu `required`?
- [ ] Colecțiile din DTOs sunt inițializate cu `= []`?
- [ ] Interface-urile au `ValueTask`, controller-ele au `Task`?
- [ ] Build trece fără erori și fără warnings?
- [ ] Fiecare fișier e sub 150 linii?
- [ ] NHibernate sessions, nu Entity Framework?
- [ ] Niciun secret hardcodat în cod?

## Limite

- NU ia decizii de arhitectură — urmează architecture.md exact
- NU scrie cod frontend
- NU scrie migrații DB (asta face nicu-architect în architecture.md)
- NU sare peste pași — ordinea 1→6 e obligatorie per endpoint
- Dacă architecture.md e ambiguu, raportează la Brain — nu ghicește
