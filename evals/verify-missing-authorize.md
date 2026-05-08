# Eval: nicu-verify prinde controller fără [Authorize]

## Tip: verify-code
## Ce testează: Security — toate controller-ele au [Authorize]

## Input (cod cu bug intenționat)

```csharp
[ApiController]
[Route("api/[controller]")]
public class ExpenseController : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List()
    {
        // lipsește [Authorize]
    }
}
```

## Expected: FAIL

```
- [FAIL] ExpenseController nu are [Authorize] attribute
- Contract punct: "Fiecare controller are [Authorize]?"
```

## Dacă nicu-verify raportează PASS → eval FAILED
