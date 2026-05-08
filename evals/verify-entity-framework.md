# Eval: nicu-verify prinde Entity Framework în loc de NHibernate

## Tip: verify-code
## Ce testează: Stack — NHibernate only, nu Entity Framework

## Input (cod cu bug intenționat)

```csharp
public class ExpenseServiceAdapter : IExpenseService
{
    private readonly DbContext _context;

    public async ValueTask<OperationResult<List<Expense>>> ListAsync()
    {
        var expenses = await _context.Set<Expense>()
            .Where(e => !e.IsDeleted)
            .ToListAsync();
        return OperationResult.Success(expenses);
    }
}
```

## Expected: FAIL

```
- [FAIL] ExpenseServiceAdapter folosește DbContext (Entity Framework) în loc de ISession (NHibernate)
- Contract punct: "NHibernate sessions, nu Entity Framework?"
```

## Dacă nicu-verify raportează PASS → eval FAILED
