# .NET Patterns — BONO Backend

## Project structure (standard per proiect)

```
[Project].Api/              — Controllers, Program.cs, middleware
[Project].Api.ServiceInterface/  — Interfaces + DTOs
[Project].DomainModel/      — Entities (POCOs, virtual properties)
[Project].DomainServices/   — CQRS Queries, Commands, Service Adapters
[Project].Infrastructure.NHibernate/  — Mappings, session factory
[Project].Common/           — OperationResult<T>, shared utilities
[Project].Api.Tests/        — xUnit tests
```

## Key Files to Study Before Writing Code

- `[Project].Api/Program.cs` — DI registration, middleware pipeline
- `[Project].Api/Controllers/` — reference controllers
- `[Project].DomainServices/` — reference service implementations
- `[Project].DomainModel/` — reference entities
- `[Project].Infrastructure.NHibernate/Mappings/` — reference mappings
- `[Project].Api.ServiceInterface/` — reference interfaces + DTOs
- `[Project].Common/OperationResult.cs` — the result wrapper pattern
- `[Project].Api.Tests/` — reference tests

### NHibernate Session Patterns

**Opening a session for queries:**
```csharp
public class MyQuery : NHibernateGenericQuery<MyEntity>
{
    // OpenSession(teamId) activates tenantFilter
    public async Task<MyEntity> GetById(string teamId, Guid id)
    {
        using var session = OpenSession(teamId);
        return await session.GetAsync<MyEntity>(id);
    }
    
    public async Task<PagedQueryResult<MyEntity>> List(string teamId, int page, int pageSize)
    {
        using var session = OpenSession(teamId);
        var query = session.QueryOver<MyEntity>()
            .Where(x => x.DeletedAt == null)
            .OrderBy(x => x.CreatedAt).Desc;
        
        var total = await query.RowCountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ListAsync();
        
        return new PagedQueryResult<MyEntity>(items, total);
    }
}
```

**Opening a session for commands (transaction):**
```csharp
public async Task<OperationResult<MyResponse>> Create(string teamId, string userId, CreateMyRequest req)
{
    using var session = _sessionFactory.OpenSession();
    session.EnableFilter("tenantFilter").SetParameter("teamId", teamId);
    using var tx = session.BeginTransaction();
    
    try
    {
        var entity = new MyEntity
        {
            TeamId = teamId,
            // ... map request fields
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        
        await session.SaveAsync(entity);
        await tx.CommitAsync();
        
        return OperationResult<MyResponse>.Success(MapToResponse(entity));
    }
    catch (Exception ex)
    {
        await tx.RollbackAsync();
        return OperationResult<MyResponse>.Failure(ex.Message);
    }
}
```

### Testing Pattern (SQLite in-memory)

```csharp
public class MyServiceTests
{
    private ISessionFactory _factory;
    
    public MyServiceTests()
    {
        // SQLite in-memory for fast tests
        _factory = Fluently.Configure()
            .Database(SQLiteConfiguration.Standard.InMemory())
            .Mappings(m => m.FluentMappings.AddFromAssemblyOf<MyEntityMap>())
            .BuildSessionFactory();
    }
    
    [Fact]
    public async Task Create_ValidInput_ReturnsSuccess()
    {
        // Create schema in memory
        using var session = _factory.OpenSession();
        new SchemaExport(cfg).Execute(true, true, false, session.Connection, null);
        
        // Arrange
        var service = new MyService(/* inject dependencies */);
        var request = new CreateMyRequest { Name = "Test" };
        
        // Act
        var result = await service.Create("team-1", "user-1", request);
        
        // Assert
        Assert.True(result.IsSuccess);
        Assert.Equal("Test", result.Value.Name);
    }
}
```

## Naming conventions

- DB tables: `snake_case` plural (`team_expenses`)
- DB columns: `snake_case` (`created_at`, `team_id`)
- C# entities: `PascalCase` singular (`TeamExpense`)
- C# properties: `PascalCase` (`CreatedAt`)
- Controllers: `PascalCase` plural (`ExpensesController`)
- Endpoints: `kebab-case` (`/api/v1/team-expenses`)
