# Query Patterns

All queries inherit from `NHibernate{Project}GatewayQuery<TResult>` and pass parameters via **primary constructor**. There is no TArgs variant.

## Base class

```csharp
public abstract class NHibernateGenericQuery<TResult>
{
    protected ISession Session { get; private set; }
    protected abstract ISession CreateSession();

    public NHibernateGenericQuery<TResult> UseExternalSession(ISession session) { ... }
    public TResult Execute() { ... }
    protected abstract TResult OnExecute();
}
```

- When called standalone, `Execute()` creates a session via `CreateSession()`, runs `OnExecute()`, and disposes the session.
- When called with `.UseExternalSession(session)`, it uses the provided session and does **not** dispose it.

The project-specific variant auto-wires the session factory:

```csharp
public abstract class NHibernateAppGatewayQuery<TResult> : NHibernateGenericQuery<TResult>
{
    protected override ISession CreateSession() => NHibernateAppGateway.OpenSession();
}
```

---

## Pattern 1: Parameterless query returning a list

```csharp
public class LoadActiveProductsQuery : NHibernateAppGatewayQuery<IList<Product>>
{
    protected override IList<Product> OnExecute()
    {
        return Session.QueryOver<Product>()
            .Where(p => p.IsActive)
            .List();
    }
}

// Usage:
var products = new LoadActiveProductsQuery().Execute();
```

---

## Pattern 2: Query with constructor parameters

Pass arguments via the primary constructor. This is the most common pattern.

```csharp
public class LoadUserQuery(string username) : NHibernateAppGatewayQuery<User>
{
    protected override User OnExecute()
    {
        return Session.QueryOver<User>()
            .Where(u => u.Username == username)
            .And(u => u.IsActive)
            .SingleOrDefault();
    }
}

// Usage:
var user = new LoadUserQuery("john.doe").Execute();
```

Any type can be a constructor parameter — primitives, dates, enums, entities:

```csharp
public class LoadStaleWorkflowsQuery(DateTime cutoffDate) : NHibernateAppGatewayQuery<IList<Workflow>>
{
    protected override IList<Workflow> OnExecute()
    {
        User userAlias = null;

        return Session.QueryOver<Workflow>()
            .JoinAlias(w => w.User, () => userAlias)
            .Where(() => userAlias.IsActive)
            .And(w => w.WorkflowType.Id == (int)KnownWorkflowTypes.Reservation)
            .And(w => !w.IsCancelled)
            .And(w => w.CreatedAt < cutoffDate)
            .OrderBy(w => w.Id).Asc
            .List();
    }
}

// Usage:
var stale = new LoadStaleWorkflowsQuery(DateTime.UtcNow.AddDays(-30)).Execute();
```

---

## Pattern 3: Joins and eager loading

Use `JoinAlias` to join related entities and `Fetch(SelectMode.Fetch, ...)` to eagerly load associations (avoiding lazy load N+1).

```csharp
public class FindAllPendingJobsQuery(int maxRetries = 4)
    : NHibernateAppGatewayQuery<List<Job>>
{
    protected override List<Job> OnExecute()
    {
        User userAlias = null;

        return Session.QueryOver<Job>()
            .JoinAlias(j => j.User, () => userAlias)
            .Fetch(SelectMode.Fetch, j => j.JobType)
            .Where(j => j.RetryCount <= maxRetries)
            .OrderBy(j => j.Id).Asc
            .List()
            .ToList();
    }
}
```

---

## Pattern 4: Left outer joins and custom result types

When a query returns a composite result, define a nested record type.

```csharp
public class LoadDocumentArchiveQuery(string uniqueCode)
    : NHibernateAppGatewayQuery<DocumentArchiveBag>
{
    public record DocumentArchiveBag(DocumentArchive Archive, IList<ArchiveFile> Files);

    protected override DocumentArchiveBag OnExecute()
    {
        var archive = Session.QueryOver<DocumentArchive>()
            .Where(a => a.UniqueCode == uniqueCode)
            .SingleOrDefault();

        if (archive == null)
            return null;

        ArchiveFilePayload payloadAlias = null;
        DocumentType docTypeAlias = null;

        var files = Session.QueryOver<ArchiveFile>()
            .Where(f => f.Archive.Id == archive.Id)
            .JoinAlias(f => f.Payload, () => payloadAlias)
            .JoinAlias(f => f.DocumentType, () => docTypeAlias, JoinType.LeftOuterJoin)
            .List();

        return new DocumentArchiveBag(archive, files);
    }
}
```

---

## Pattern 5: Ordering, Take, and SingleOrDefault

For "find the most recent" queries.

```csharp
public class LoadCurrentSessionQuery(User user) : NHibernateAppGatewayQuery<UserSession>
{
    protected override UserSession OnExecute()
    {
        return Session.QueryOver<UserSession>()
            .Where(s => s.User.Id == user.Id)
            .And(s => s.ExpiresAt > DateTime.UtcNow)
            .OrderBy(s => s.CreatedAt).Desc
            .Take(1)
            .SingleOrDefault();
    }
}
```

---

## Batch Loading

For queries with large IN clauses, use `BatchLoader` to chunk IDs:

```csharp
var results = BatchLoader.With(idList)
    .BatchLoad(batchIds =>
        Session.QueryOver<Entity>()
            .WhereRestrictionOn(e => e.Id).IsIn(batchIds)
            .List(),
        batchSize: 100);
```

For QueryOver API details (filtering, joins, eager loading, projections), see `queryover-reference.md`.
