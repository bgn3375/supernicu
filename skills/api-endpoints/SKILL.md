---
name: api-endpoints
description: .NET API endpoint implementation skill. 4-layer pattern (interface → DTOs → adapter → controller). Fires on "create endpoint", "API route", "controller", "DTO".
---

# API Endpoints — .NET 4-Layer Pattern

Implementarea endpoint-urilor backend urmând pattern-ul din proiectul P&L real.

## Stack

- ASP.NET Core 10
- NHibernate 5.6 (NU Entity Framework)
- CQRS: Query classes pentru GET, Command classes pentru POST/PUT/DELETE
- OperationResult<T> pe toate service-urile
- MariaDB (nu PostgreSQL)

## Pattern per endpoint (6 pași)

### Pas 1: Service Interface

```csharp
// PnL.DomainServices/Expenses/IExpenseService.cs
public interface IExpenseService
{
    ValueTask<OperationResult<PagedResult<ExpenseResponse>>> ListAsync(ListExpensesRequest request);
    ValueTask<OperationResult<ExpenseResponse>> GetByIdAsync(Guid id);
    ValueTask<OperationResult<ExpenseResponse>> CreateAsync(CreateExpenseRequest request);
}
```

- `ValueTask<OperationResult<T>>` pe toate metodele
- Un interface per feature

### Pas 2: DTOs

```csharp
// PnL.DomainServices/Expenses/ExpenseDtos.cs
public record CreateExpenseRequest
{
    public required decimal Amount { get; init; }
    public required string Currency { get; init; }
    public required Guid CategoryId { get; init; }
    public List<string> Tags { get; init; } = [];
}

public record ExpenseResponse
{
    public required Guid Id { get; init; }
    public required decimal AmountRon { get; init; }
    public decimal? AmountEur { get; init; }
}
```

- `record` cu `required`
- Colecții cu `= []`

### Pas 3: Query / Command

```csharp
// PnL.DomainServices/Expenses/Queries/ListExpensesQuery.cs
public class ListExpensesQuery
{
    private readonly ISession _session;

    public async ValueTask<List<Expense>> ExecuteAsync(Guid teamId, ...)
    {
        return await _session.Query<Expense>()
            .Where(e => e.TeamId == teamId && !e.IsDeleted)
            .ToListAsync();
    }
}
```

- NHibernate `ISession`, nu DbContext
- Filtrare pe `team_id` EXPLICITĂ (pe lângă tenantFilter)
- Query pentru GET, Command pentru mutații

### Pas 4: Service Adapter

```csharp
// PnL.ServiceAdapters/Expenses/ExpenseServiceAdapter.cs
public class ExpenseServiceAdapter : IExpenseService
{
    public async ValueTask<OperationResult<ExpenseResponse>> CreateAsync(CreateExpenseRequest request)
    {
        // Business logic, validări, calcule
        // Returnează OperationResult.Success(response) sau OperationResult.Failure(error)
    }
}
```

### Pas 5: Controller

```csharp
// PnL.Api/Controllers/ExpenseController.cs
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ExpenseController : ControllerBase
{
    [HttpPost]
    [Authorize(Roles = "Admin,Approver,Member")]
    public async Task<IActionResult> Create([FromBody] CreateExpenseRequest request)
    {
        var teamId = Request.Headers["X-Team-Id"].ToString();
        var result = await _expenseService.CreateAsync(request);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
    }
}
```

- `[Authorize]` pe clasă + roluri specifice pe actions
- `Task<IActionResult>` (nu ValueTask)
- Citește `X-Team-Id` din header

### Pas 6: DI Registration

```csharp
services.AddScoped<IExpenseService, ExpenseServiceAdapter>();
```

## Reguli

1. Ordinea 1→6 obligatorie.
2. NHibernate sessions, NU Entity Framework.
3. OperationResult<T>, NU throw pentru business errors.
4. Record types pe DTOs.
5. ValueTask pe interfaces, Task pe controllers.
6. [Authorize] pe toate endpoint-urile.
7. X-Team-Id din header pe fiecare controller action.
8. Fiecare query filtrează pe team_id.
