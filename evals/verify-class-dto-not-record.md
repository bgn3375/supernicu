# Eval: nicu-verify prinde DTO ca clasă în loc de record

## Tip: verify-code
## Ce testează: Record types pe DTOs, nu clase

## Input (cod cu bug intenționat)

```csharp
public class CreateExpenseRequest
{
    public decimal Amount { get; set; }
    public string Currency { get; set; }
    public Guid CategoryId { get; set; }
}
```

## Expected: FAIL

```
- [FAIL] CreateExpenseRequest e clasă, nu record
- [FAIL] Properties au { get; set; } în loc de required + { get; init; }
- Contract punct: "DTOs sunt record cu required?"
```

## Dacă nicu-verify raportează PASS → eval FAILED
