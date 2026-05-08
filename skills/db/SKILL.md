---
name: db
description: MariaDB database design skill for SuperNicu. Use when designing database schema, tables, relationships, indexes, and NHibernate mappings. Fires on "design database", "create schema", "add table", "migration", "tenant isolation at DB level".
---

# DB — MariaDB Schema Design

Proiectează schema bazei de date MariaDB pentru module P&L.

## Stack

- MariaDB 10.x+ (utf8mb4_unicode_ci)
- NHibernate 5.6 + FluentNHibernate 3.4
- UUIDs generate de aplicație (NHibernate GuidComb), nu de DB
- Multi-tenant prin coloana `team_id` + NHibernate tenantFilter
- NU PostgreSQL. NU RLS. NU Entity Framework.

## Template tabel

```sql
CREATE TABLE {table_name} (
  id CHAR(36) NOT NULL,
  team_id CHAR(36) NOT NULL,
  -- business columns here --
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by CHAR(36) NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  INDEX idx_{table_name}_team_id (team_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## NHibernate mapping template

```csharp
public class {Entity}Map : ClassMap<{Entity}>
{
    public {Entity}Map()
    {
        Table("{table_name}");
        Id(x => x.Id).GeneratedBy.GuidComb();
        Map(x => x.TeamId).Not.Nullable();
        Map(x => x.CreatedAt).Not.Nullable();
        Map(x => x.UpdatedAt).Not.Nullable();
        Map(x => x.IsDeleted).Not.Nullable();
        ApplyFilter("tenantFilter", "team_id = :teamId");
    }
}
```

## Tenant filter (global, activat per sesiune)

```csharp
cfg.AddFilterDefinition(
    new FilterDefinition("tenantFilter", "team_id = :teamId",
        new Dictionary<string, IType> { { "teamId", NHibernateUtil.String } }));
```

Middleware citește `X-Team-Id` header → activează filtrul pe sesiunea NHibernate.

## Reguli obligatorii

1. **Fiecare tabel are `team_id` CHAR(36) NOT NULL.** Indexat. Zero excepții.
2. **Soft delete.** `is_deleted` TINYINT(1). Nu DELETE fizic.
3. **UUID ca PK.** CHAR(36), GuidComb din NHibernate.
4. **Timestamps.** `created_at` + `updated_at` pe fiecare tabel.
5. **Audit.** `created_by` pe tabele user-facing.
6. **FK cu index.** Fiecare foreign key are index separat.
7. **Cascade explicit.** RESTRICT default. CASCADE doar unde PRD-ul cere (ex: categorie → subcategorii).
8. **An fiscal.** Coloane de perioadă: 13 luni Aug-Aug.
9. **Multi-currency.** Tabele financiare: `amount_ron`, `amount_eur`, `currency`, `exchange_rate`.
10. **Charset.** utf8mb4_unicode_ci pe tot.

## Checklist per tabel

- [ ] Are `team_id` CHAR(36) NOT NULL cu index?
- [ ] PK e CHAR(36) UUID?
- [ ] Are `created_at` + `updated_at`?
- [ ] Are `is_deleted` TINYINT(1)?
- [ ] FK-urile au index separat?
- [ ] FK-urile au cascade rule explicită?
- [ ] NHibernate mapping aplică `tenantFilter`?
- [ ] Charset utf8mb4?
