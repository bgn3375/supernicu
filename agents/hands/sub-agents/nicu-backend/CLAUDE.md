# nicu-backend — Scrie Cod .NET

**Model:** Sonnet
**Părinte:** Hands
**Contract:** `contracts/backend-contract.md`

## Ce primește

- architecture.md (secțiunile Data Model + API Endpoints)
- Skills relevante din `skills/`
- Fix task (opțional, dacă e repair loop)

## Ce produce

Cod .NET per endpoint, în ordinea din contract:

### 1. Service interface — `I{Feature}Service.cs`
- Metode cu `ValueTask<OperationResult<T>>`
- Un fișier per feature

### 2. DTOs — `{Feature}Dtos.cs`
- `record` types cu `required`
- Colecții cu `= []`
- Request DTO + Response DTO per endpoint

### 3. Query sau Command
- `{Action}{Feature}Query.cs` pentru GET
- `{Action}{Feature}Command.cs` pentru POST/PUT/DELETE
- NHibernate sessions (NU Entity Framework)
- TOATE filtrează pe `team_id`

### 4. Service adapter — `{Feature}ServiceAdapter.cs`
- Implementează interface-ul
- Business logic, validări, calcule
- Returnează `OperationResult<T>`

### 5. Controller — `{Feature}Controller.cs`
- `[Authorize]` pe toate action methods
- Citește `X-Team-Id` din header
- `Task<IActionResult>` (nu ValueTask)
- Route: `[Route("api/[controller]")]`

### 6. DI registration
- În `Startup.cs` sau modul-specific

## Structura fișiere

```
PnL.DomainServices/{Feature}/
  I{Feature}Service.cs
  {Feature}Dtos.cs
  Queries/{Action}{Feature}Query.cs
  Commands/{Action}{Feature}Command.cs

PnL.ServiceAdapters/{Feature}/
  {Feature}ServiceAdapter.cs

PnL.Api/Controllers/
  {Feature}Controller.cs
```

## Reguli

- Ordinea 1→6 e obligatorie. Nu sări pași.
- Citește contractul ÎNAINTE de a scrie.
- Citește skill-urile relevante din `skills/` ÎNAINTE de a scrie.
- Fiecare fișier sub 150 linii.
- Build verde după fiecare fișier.
- NHibernate sessions, NU Entity Framework.
- OperationResult<T>, NU throw pentru business logic.
- Fiecare query filtrează pe `team_id`.
- Record types pe DTOs, NU clase.
- NU adaugă endpoint-uri care nu sunt în architecture.md.
- NU ia decizii de arhitectură. Dacă ceva e ambiguu, raportează la Brain.

## Output

```
DONE — Expenses module
Fișiere: 6
Build: PASS
```
