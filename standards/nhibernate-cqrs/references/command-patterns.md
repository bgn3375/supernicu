# Command Patterns

All commands inherit from `NHibernate{Project}GatewayCommand` (void) or `NHibernate{Project}GatewayCommand<T>` (returns result). Parameters are passed via **primary constructor**.

## Base classes

| Base class | Use when |
|---|---|
| `NHibernateCommand` | Command that returns void |
| `NHibernateGenericCommand<TResult>` | Command that returns a result |

When called standalone, both auto-create a session, begin a transaction, call `OnExecute()`, commit, and dispose. When called with `.UseExternalSession(session)`, they skip session/transaction creation and delegate that responsibility to the caller.

Project-specific variants:

```csharp
public abstract class NHibernateAppGatewayCommand : NHibernateCommand
{
    protected override ISession CreateSession() => NHibernateAppGateway.OpenSession();
}

public abstract class NHibernateAppGatewayCommand<T> : NHibernateGenericCommand<T>
{
    protected override ISession CreateSession() => NHibernateAppGateway.OpenSession();
}
```

---

## Pattern 1: Generic save/update (reusable one-liner)

For simple single-entity persistence, use the built-in `SaveOrUpdateCommand`:

```csharp
public class SaveOrUpdateCommand : NHibernateAppGatewayCommand
{
    private object _entity;
    public static SaveOrUpdateCommand For(object entity) => new() { _entity = entity };
    protected override void OnExecute() => Session.SaveOrUpdate(_entity);
}

// Usage:
SaveOrUpdateCommand.For(workflow).Execute();
```

---

## Pattern 2: Entity update command

When you need to modify properties before persisting:

```csharp
public class CancelWorkflowCommand(Workflow workflow) : NHibernateAppGatewayCommand
{
    protected override void OnExecute()
    {
        workflow.IsCancelled = true;
        workflow.ModifiedAt = DateTime.UtcNow;
        Session.Update(workflow);
    }
}

// Usage:
new CancelWorkflowCommand(workflow).Execute();
```

---

## Pattern 3: Batch save (multiple entities, single transaction)

All saves within `OnExecute()` share the same session and transaction. The transaction commits once at the end.

```csharp
public class SaveAuditEntriesCommand(IEnumerable<AuditEntry> entries)
    : NHibernateAppGatewayCommand
{
    protected override void OnExecute()
    {
        var utcNow = DateTime.UtcNow;
        foreach (var entry in entries)
        {
            entry.CreatedAt = utcNow;
            Session.Save(entry);
        }
    }
}
```

---

## Pattern 4: Mixed operations (save + delete in one transaction)

```csharp
public class SaveDocumentArchiveCommand(IList<ArchiveFile> files, Job queueItem)
    : NHibernateAppGatewayCommand
{
    protected override void OnExecute()
    {
        var now = DateTime.UtcNow;
        var archive = new DocumentArchive
        {
            WorkflowType = queueItem.WorkflowType,
            ExternalRequestId = queueItem.ExternalRequestId,
            User = queueItem.User,
            UniqueCode = queueItem.UniqueCode,
            CreatedAt = now
        };
        Session.Save(archive);

        foreach (var file in files)
        {
            Session.Save(file.Payload);
            file.Archive = archive;
            file.CreatedAt = now;
            Session.Save(file);
        }

        Session.Delete(queueItem);
    }
}
```

---

## Session Operations Reference

| Operation | Method | Use in |
|---|---|---|
| Insert new entity | `Session.Save(entity)` | Command |
| Update existing entity | `Session.Update(entity)` | Command |
| Insert or update | `Session.SaveOrUpdate(entity)` | Command |
| Delete entity | `Session.Delete(entity)` | Command |
| Read by criteria | `Session.QueryOver<T>()...` | Query |

For composing multiple commands in a shared transaction, see `execution-modes.md`.
