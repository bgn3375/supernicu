---
name: multitenant
description: Multi-tenancy skill using MariaDB + NHibernate tenantFilter + X-Team-Id header. Use when implementing tenant isolation, team_id filtering, cross-tenant protection. Fires on "multi-tenant", "tenant isolation", "team_id", "data isolation".
---

# Multi-Tenant — MariaDB + NHibernate Filter

Izolarea datelor între firme (tenants) prin NHibernate filter pe `team_id`.

## Cum funcționează

```
Request → Middleware → citește X-Team-Id header
                    → activează NHibernate tenantFilter pe sesiune
                    → toate query-urile filtrează automat pe team_id
```

NU folosim PostgreSQL RLS. MariaDB nu suportă RLS.

## Componentele

### 1. Header `X-Team-Id`
Frontend-ul trimite header-ul pe fiecare request:
```typescript
// Next.js server action
const response = await fetch(`${API_URL}/api/expenses`, {
  headers: {
    'Authorization': `Bearer ${token}`,
    'X-Team-Id': teamId,
  },
});
```

### 2. Middleware .NET
```csharp
public class TenantMiddleware
{
    public async Task InvokeAsync(HttpContext context)
    {
        var teamId = context.Request.Headers["X-Team-Id"].FirstOrDefault();
        if (string.IsNullOrEmpty(teamId))
        {
            context.Response.StatusCode = 400;
            return;
        }
        context.Items["TeamId"] = teamId;
        await _next(context);
    }
}
```

### 3. NHibernate filter definition
```csharp
cfg.AddFilterDefinition(
    new FilterDefinition("tenantFilter", "team_id = :teamId",
        new Dictionary<string, IType> { { "teamId", NHibernateUtil.String } }));
```

### 4. Filter activation per sesiune
```csharp
session.EnableFilter("tenantFilter").SetParameter("teamId", currentTeamId);
```

### 5. Fiecare entity mapping
```csharp
ApplyFilter("tenantFilter", "team_id = :teamId");
```

## Reguli

1. **Fiecare tabel are `team_id`.** Zero excepții.
2. **Fiecare NHibernate mapping aplică `tenantFilter`.**
3. **Fiecare query filtrează pe `team_id`.** Chiar dacă filtrul e activ, query-urile explicite (SQL nativ) trebuie și ele filtrate.
4. **X-Team-Id obligatoriu.** Request fără header → 400 Bad Request.
5. **Validare:** team_id din header trebuie să fie un team la care user-ul are acces. Middleware-ul verifică.
6. **Cross-tenant test:** la QA, testul obligatoriu: login ca Tenant A, setează X-Team-Id al Tenant B → trebuie să primească 403.

## Checklist

- [ ] Fiecare tabel are `team_id`?
- [ ] Fiecare mapping are `ApplyFilter("tenantFilter")`?
- [ ] Middleware-ul verifică X-Team-Id pe fiecare request?
- [ ] Request fără X-Team-Id → 400?
- [ ] X-Team-Id de alt tenant → 403?
- [ ] Query-urile native (raw SQL) filtrează explicit pe team_id?
