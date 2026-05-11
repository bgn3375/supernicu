# QueryOver API Reference

Quick reference for NHibernate's QueryOver API as used in this project. For full query/command examples, see `query-patterns.md` and `command-patterns.md`.

---

## Filtering

```csharp
.Where(x => x.Property == value)          // Equality
.And(x => x.IsActive)                     // Additional conditions
.And(x => !x.IsCancelled)                 // Negation
.And(x => x.CreatedAt < cutoffDate)       // Comparison
.Where(x => x.Role.Id == (int)enumValue)  // Enum/FK filtering
.Where(() => alias.Property == value)     // Filter on joined alias
```

---

## Joins

```csharp
// Declare alias variable (null-initialized, NHibernate fills it)
User userAlias = null;

// Inner join (default)
.JoinAlias(w => w.User, () => userAlias)

// Left outer join
.JoinAlias(f => f.DocumentType, () => docTypeAlias, JoinType.LeftOuterJoin)
```

---

## Eager loading

```csharp
// Fetch associated entity in same query (avoids lazy loading)
.Fetch(SelectMode.Fetch, q => q.WorkflowType)
.Fetch(SelectMode.Fetch, df => df.DocumentType)
```

---

## Ordering

```csharp
.OrderBy(w => w.Id).Asc
.OrderBy(s => s.CreatedAt).Desc
```

---

## Limiting and result selection

```csharp
.Take(1)                  // LIMIT 1
.SingleOrDefault()        // Returns single entity or null
.List()                   // Returns IList<T>
.List().ToList()          // Returns List<T>
```

---

## Caching

```csharp
// Entity must have <cache usage="read-write"/> in .hbm.xml
.Cacheable()              // Enable L2 query cache for this query
```

---

## Projection extensions (QueryOverExtensions)

```csharp
// Project to DTO via constructor
queryOver.ListAs(new MyDto(default, default));

// Project to DTO via property matching
queryOver.ListAs<MyDto>();

// Dynamic sort direction
queryOver.OrderBy(x => x.Name).SortAsc(ascending: true);

// List shorthand
queryOver.ExecuteList();
```
