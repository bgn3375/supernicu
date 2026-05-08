# Eval: nicu-verify prinde query NHibernate fără tenantFilter

## Tip: verify-code
## Ce testează: Multi-tenant — NHibernate mapping aplică tenantFilter

## Input (cod cu bug intenționat)

```csharp
public class ExpenseMap : ClassMap<Expense>
{
    public ExpenseMap()
    {
        Table("expenses");
        Id(x => x.Id).GeneratedBy.GuidComb();
        Map(x => x.TeamId).Not.Nullable();
        Map(x => x.Amount).Not.Nullable();
        // lipsește: ApplyFilter("tenantFilter", "team_id = :teamId");
    }
}
```

## Expected: FAIL

```
- [FAIL] ExpenseMap nu aplică tenantFilter
- Contract punct: "NHibernate mapping aplică tenantFilter?"
```

## Dacă nicu-verify raportează PASS → eval FAILED
