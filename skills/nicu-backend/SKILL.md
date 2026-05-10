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

**Query** (citeste date, deschide propria sesiune):
```csharp
public class GetMyEntityQuery : NHibernateGenericQuery<MyEntity>
{
    public async Task<MyEntity> Execute(string teamId, Guid id)
    {
        using var session = OpenSession(teamId);
        return await session.GetAsync<MyEntity>(id);
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
Thin controller, delegheaza la service.

```csharp
[ApiController]
[Route("api/v1/[controller]")]
[Authorize]
public class MyController : ControllerBase
{
    private readonly IMyService _service;
    
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var teamId = Request.Headers["X-Team-Id"].ToString();
        var result = await _service.GetById(teamId, id);
        return result.ToActionResult();
    }
    
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateMyRequest request)
    {
        var teamId = Request.Headers["X-Team-Id"].ToString();
        var userId = User.FindFirst("sub")?.Value;
        var result = await _service.Create(teamId, userId, request);
        return result.ToActionResult();
    }
}
```

## Conventii

- snake_case pt DB columns si table names
- PascalCase pt C# types
- `team_id` pe tabelele cu date tenant (când produsul e multi-tenant)
- `deleted_at` pt soft delete (nu DELETE fizic)
- UUID (CHAR(36)) pt primary keys
- `OperationResult<T>` pt TOATE return types din services
- Audit log pt actiuni importante

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
