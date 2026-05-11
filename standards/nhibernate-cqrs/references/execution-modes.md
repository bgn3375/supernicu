# Execution Modes

There are two ways to execute queries and commands: **single execution** (default) and **composition** (shared session).

---

## Single execution

Each query or command opens its own session, executes, and disposes it. Commands also manage their own transaction. This is the default and most common mode.

```csharp
// Single query — auto session, auto dispose
var products = new LoadActiveProductsQuery().Execute();

// Single command — auto session, auto transaction, auto dispose
new CancelWorkflowCommand(workflow).Execute();
```

**Use this when:**
- The operation is self-contained
- You don't need atomicity across multiple operations
- You don't need to share a database connection between queries

---

## Composition: shared session across multiple queries

When multiple queries should share a single database connection, open a session explicitly and pass it to each query via `.UseExternalSession(session)`. The caller is responsible for disposing the session.

```csharp
// Open a shared session
using var session = NHibernateAppGateway.OpenSession();

// Multiple queries share the same connection
var products = new LoadActiveProductsQuery()
    .UseExternalSession(session)
    .Execute();

var docTypes = session.QueryOver<DocumentType>().List();

var activeUser = new FindActiveUserQuery(KnownRoles.Approver)
    .UseExternalSession(session)
    .Execute();
```

Note: you can mix query classes with direct `session.QueryOver<T>()` calls on the shared session.

---

## Composition: shared transaction across multiple commands

When multiple commands must commit or rollback atomically, open a session and transaction explicitly. Pass the session to each command via `.UseExternalSession(session)`. The caller is responsible for committing the transaction and disposing the session.

```csharp
// Open shared session and transaction
using var session = NHibernateAppGateway.OpenSession();
using var tran = session.BeginTransaction();

// Multiple commands enlist in the same transaction
new CancelWorkflowCommand(workflow1).UseExternalSession(session).Execute();
new CancelWorkflowCommand(workflow2).UseExternalSession(session).Execute();

// Commit all changes atomically
tran.Commit();
```

**Important**: When using `.UseExternalSession(session)`, the command skips its internal session and transaction creation. The caller must manage `BeginTransaction()`, `Commit()`, and disposal.

---

## Checklist for composing multiple operations

1. Open a session: `using var session = NHibernateAppGateway.OpenSession();`
2. For commands, also open a transaction: `using var tran = session.BeginTransaction();`
3. Chain `.UseExternalSession(session)` before `.Execute()` on each query/command
4. You can mix query/command classes with direct `session.QueryOver<T>()` calls
5. For commands, commit the transaction explicitly: `tran.Commit();`
6. The `using` keyword ensures cleanup on both success and exception paths
