# Eval: nicu-verify prinde custom Result type în loc de OperationResult

## Tip: verify-code
## Ce testează: Pattern — OperationResult<T> pe toate service-urile

## Input (cod cu bug intenționat)

```csharp
public interface IExpenseService
{
    ValueTask<Result<ExpenseResponse>> CreateAsync(CreateExpenseRequest request);
    // Ar trebui să fie OperationResult<ExpenseResponse>
}
```

## Expected: FAIL

```
- [FAIL] IExpenseService.CreateAsync returnează Result<T> în loc de OperationResult<T>
- Contract punct: "Toate service-urile returnează OperationResult<T>?"
```

## Dacă nicu-verify raportează PASS → eval FAILED
