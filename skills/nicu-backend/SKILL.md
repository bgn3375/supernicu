# nicu-backend

Developer-ul backend. Scrie cod .NET conform pattern-urilor BONO.

## Cand se activeaza

Cand orchestratorul asigneaza task-uri backend: noi endpoints, modificari schema, servicii, CQRS queries/commands.

## Stack

- .NET 10 + ASP.NET Core 10
- NHibernate 5.6 + FluentNHibernate 3.4
- MariaDB 10.x+ (utf8mb4, InnoDB)
- CQRS: Query classes (read) + Command classes (write)
- OperationResult<T> pattern
- xUnit 2.5.3 + Moq 4.20 + SQLite in-memory pentru teste

## Secure by default — "pit of success"

Codul generat de nicu-backend e sigur by default. Calea nesigură cere acțiune explicită.

### Deny-by-default auth (FallbackPolicy)
Fiecare proiect are în `Program.cs`:
```csharp
builder.Services.AddAuthorization(options =>
{
    options.FallbackPolicy = new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build();
});
```
Efectul: ORICE endpoint cere auth. `[AllowAnonymous]` e excepția explicită, nu regula.

### API Separation — Customer vs Admin
Controller-ele customer și admin sunt ÎNTOTDEAUNA separate:
```csharp
// Customer API — public
[Route("api/v1/[controller]")]
public class EntitiesController : TenantControllerBase { ... }

// Admin API — privat, role-based
[Authorize(Roles = "Admin")]
[Route("api/admin/v1/[controller]")]
public class AdminEntitiesController : ControllerBase { ... }
```
Nu se amestecă funcții admin cu funcții customer în același controller.

### Base controller cu tenant extraction
Toate controller-ele customer extind `TenantControllerBase`:
```csharp
public abstract class TenantControllerBase : ControllerBase
{
    protected string TeamId => Request.Headers["X-Team-Id"].FirstOrDefault()
        ?? throw new UnauthorizedAccessException("Missing X-Team-Id");
    
    protected string UserId => User.FindFirst("sub")?.Value
        ?? throw new UnauthorizedAccessException("Missing user claim");
}
```
Agentul nu poate uita tenant extraction — vine din base class.

### Ownership validation (anti-IDOR)
Query-urile filtrează ÎNTOTDEAUNA pe `team_id` + `entity_id`:
```csharp
// CORECT — filtrează pe team_id + id
var entity = await session.Query<MyEntity>()
    .Where(e => e.Id == id && e.TeamId == teamId)
    .SingleOrDefaultAsync();

// GREȘIT — permite IDOR
var entity = await session.GetAsync<MyEntity>(id);
```

### No sensitive data in logs
```csharp
// CORECT — loghează eveniment, nu date
_logger.LogInformation("User {UserId} logged in from {IP}", userId, ip);

// GREȘIT — expune parola în logs
_logger.LogInformation("Login: {Email} / {Password}", email, password);
```

### No security theater
Autorizarea prin JWT claims, NICIODATĂ prin headere custom:
```csharp
// GREȘIT — oricine poate seta headerul
var source = Request.Headers["RequestBy"].ToString();
if (source != "admin-app") return Unauthorized();

// CORECT — JWT claim validat server-side
var role = User.FindFirst(ClaimTypes.Role)?.Value;
if (role != "Admin") return Forbid();
```

---

## Pattern de implementare (6 pasi)

### Pas 1: Domain Model (`DomainModel/`)
Entitatea cu proprietati, fara logica. Zero dependente.

```csharp
public class MyEntity
{
    public virtual Guid Id { get; set; }
    public virtual string TeamId { get; set; }
    // ... proprietati
    public virtual DateTime CreatedAt { get; set; }
    public virtual DateTime UpdatedAt { get; set; }
    public virtual DateTime? DeletedAt { get; set; }
}
```

### Pas 2: NHibernate Mapping (`Infrastructure.NHibernate/Mappings/`)
FluentNHibernate ClassMap cu Table, Id, Map, References.

```csharp
public class MyEntityMap : ClassMap<MyEntity>
{
    public MyEntityMap()
    {
        Table("my_entities");
        Id(x => x.Id).GeneratedBy.GuidComb();
        Map(x => x.TeamId).Column("team_id").Not.Nullable();
        // ... alte coloane
        ApplyFilter("tenantFilter", f => f.Condition("team_id = :teamId"));
    }
}
```

**IMPORTANT**: Dacă produsul e multi-tenant, `ApplyFilter("tenantFilter", ...)` pe toate entitățile cu `team_id`.

### Pas 3: Service Interface + DTOs (`Api.ServiceInterface/`)

```csharp
// Interface
public interface IMyService
{
    Task<OperationResult<MyResponse>> GetById(string teamId, Guid id);
    Task<OperationResult<PagedQueryResult<MyListItem>>> List(string teamId, MyFilterRequest filter);
    Task<OperationResult<MyResponse>> Create(string teamId, string userId, CreateMyRequest request);
    Task<OperationResult<MyResponse>> Update(string teamId, Guid id, UpdateMyRequest request);
    Task<OperationResult<bool>> Delete(string teamId, Guid id);
}

// DTOs
public class CreateMyRequest { ... }
public class UpdateMyRequest { ... }
public class MyResponse { ... }
public class MyFilterRequest : PagedRequest { ... }
```

### Pas 4: CQRS Queries + Commands (`DomainServices/`)

**Query** (citeste date, deschide propria sesiune, filtrează pe team_id):
```csharp
public class GetMyEntityQuery : NHibernateGenericQuery<MyEntity>
{
    public async Task<MyEntity> Execute(string teamId, Guid id)
    {
        using var session = OpenSession(teamId);
        // Filtrează pe team_id + id — previne IDOR
        return await session.Query<MyEntity>()
            .Where(e => e.Id == id && e.TeamId == teamId)
            .SingleOrDefaultAsync();
    }
}
```

**Command** (scrie date, primeste sesiunea de la caller):
```csharp
public class SaveMyEntityCommand : NHibernateGenericCommand<MyEntity>
{
    public async Task Execute(ISession session, MyEntity entity)
    {
        await session.SaveOrUpdateAsync(entity);
    }
}
```

### Pas 5: Service Adapter (`DomainServices/`)
Implementeaza interfata, coordoneaza queries + commands, business logic.

```csharp
public class MyService : IMyService
{
    private readonly GetMyEntityQuery _getQuery;
    private readonly SaveMyEntityCommand _saveCommand;
    
    public async Task<OperationResult<MyResponse>> Create(string teamId, string userId, CreateMyRequest request)
    {
        // Validari
        if (string.IsNullOrEmpty(request.Name))
            return OperationResult<MyResponse>.Failure("Name is required");
        
        // Business logic
        var entity = new MyEntity { TeamId = teamId, ... };
        
        using var session = _sessionFactory.OpenSession();
        using var tx = session.BeginTransaction();
        await _saveCommand.Execute(session, entity);
        await tx.CommitAsync();
        
        return OperationResult<MyResponse>.Success(MapToResponse(entity));
    }
}
```

### Pas 6: Controller (`Api/Controllers/`)
Thin controller, extinde `TenantControllerBase`, delegheaza la service.

```csharp
[ApiController]
[Route("api/v1/[controller]")]
public class MyController : TenantControllerBase
{
    private readonly IMyService _service;
    
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var result = await _service.GetById(TeamId, id);
        return result.ToActionResult();
    }
    
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateMyRequest request)
    {
        var result = await _service.Create(TeamId, UserId, request);
        return result.ToActionResult();
    }
}
```

**Notă:** Nu mai e nevoie de `[Authorize]` explicit — FallbackPolicy îl aplică by default. `TeamId` și `UserId` vin din `TenantControllerBase`.

## Conventii

- snake_case pt DB columns si table names
- PascalCase pt C# types
- `team_id` pe tabelele cu date tenant (când produsul e multi-tenant)
- `deleted_at` pt soft delete (nu DELETE fizic)
- UUID (CHAR(36)) pt primary keys — **niciodată auto-increment secvențial pe ID-uri expuse în API**
- `OperationResult<T>` pt TOATE return types din services
- Audit log pt actiuni importante
- Customer controllers extind `TenantControllerBase`, admin controllers au `[Authorize(Roles = "Admin")]`
- Fiecare `[AllowAnonymous]` are un comentariu cu motivul

## Teste

```csharp
[Fact]
public async Task Create_ValidRequest_ReturnsSuccess()
{
    // Arrange - SQLite in-memory session
    // Act - call service method
    // Assert - verify OperationResult.IsSuccess
}
```

## Referinte

- `docs/ARCHITECTURE.md` din repo backend — patterns si structura
- `docs/API_CONTRACTS.md` din repo backend — toate endpoint-urile existente
- `schema.sql` din repo backend — schema si relatii
