# MariaDB Multi-tenant Patterns (NHibernate)

## How it works

MariaDB does NOT support PostgreSQL-style Row Level Security. Multi-tenant isolation is done via:

### 1. NHibernate Global Filter

Defined once in the NHibernate configuration:
```xml
<filter-def name="tenantFilter">
  <filter-param name="teamId" type="String"/>
</filter-def>
```

### 2. Applied on every entity mapping

```csharp
// Every ClassMap with team_id must include:
ApplyFilter("tenantFilter", f => f.Condition("team_id = :teamId"));
```

### 3. Activated per session

When opening a NHibernate session, the middleware sets:
```csharp
session.EnableFilter("tenantFilter").SetParameter("teamId", teamIdFromHeader);
```

### 4. X-Team-Id Header

Every request must include `X-Team-Id` header. Middleware reads it:
```csharp
var teamId = context.Request.Headers["X-Team-Id"].ToString();
```

## Key Rules (when the product is multi-tenant)

1. Tables with tenant data have `team_id VARCHAR(255) NOT NULL`
2. FluentNHibernate mappings have `ApplyFilter("tenantFilter", ...)`
3. Query classes call `OpenSession(teamId)` which activates the filter
4. Controllers extract teamId from headers
5. Services accept teamId as first parameter

## Schema Conventions

```sql
CREATE TABLE IF NOT EXISTS new_entity (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  team_id VARCHAR(255) NOT NULL,
  -- ... entity-specific columns ...
  created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  deleted_at DATETIME(6),
  INDEX idx_new_entity_team_id (team_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## Common Mistakes to Avoid

- Forgetting `ApplyFilter` on a new mapping → cross-tenant data leak
- Using `session.CreateSQLQuery()` without WHERE team_id → bypasses filter
- Not passing teamId to queries → filter not activated
- DELETE without checking team_id first → could delete other tenant's data
