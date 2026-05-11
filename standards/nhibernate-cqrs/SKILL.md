---
name: nhibernate-cqrs
description: Data-access conventions for .NET/C# projects using NHibernate with CQRS. Use when writing queries or commands (Load*Query, Find*Query, Save*Command, Cancel*Command), working with QueryOver<T>, ISession, session composition, adding entities or .hbm.xml mappings, or any NHibernate-based refactoring. Apply these conventions consistently — even for small edits or when "NHibernate" is only mentioned in passing.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(dotnet:*)
---

<!-- Version: 1.0.0 | Last updated: 2026-04-17 -->

# NHibernate CQRS — Query and Command Patterns

Instructions for implementing data access using NHibernate with the Command/Query Responsibility Segregation pattern. All database operations are encapsulated in self-contained query or command classes. Each class manages its own session lifecycle by default, but supports shared sessions for composition scenarios.

**Key principle**: Queries and commands are the unit of work. Instantiate them, optionally pass a shared session, and call `.Execute()`.

---

## Adapting to your project

This skill uses `{Project}` as a placeholder for the application's short name. In a new project, replace `{Project}` with your own (e.g. `Portal`, `Billing`, `Crm`, `App`). Concrete examples in the reference files use `App` (e.g. `NHibernateAppGateway`).

**What's reusable vs. what's project-specific:**

- **Reusable (any project)**: The base classes in `Infrastructure.NHibernate` — `NHibernateGenericQuery<T>`, `NHibernateCommand`, `NHibernateGenericCommand<T>`, `INHibernateHelper`, the concrete helper, and extensions. Copy this assembly as-is.
- **Project-specific (three files only)**: `NHibernate{Project}Gateway`, `NHibernate{Project}GatewayQuery<T>`, `NHibernate{Project}GatewayCommand` / `NHibernate{Project}GatewayCommand<T>`. These are thin wiring classes that bind the session factory to a specific application.

Entity names used in examples (`User`, `Workflow`, `DocumentArchive`, etc.) are illustrative — substitute your own domain types.

---

## Architecture

```
Infrastructure.NHibernate/          ← Reusable base classes (any project)
├── Helpers/
│   ├── INHibernateHelper.cs        ← Interface: OpenSession(), OpenStatelessSession()
│   └── MySqlNHibernateHelper.cs    ← SessionFactory builder, singleton, thread-safe
│                                     (one concrete impl per dialect — swap for SqlServerNHibernateHelper, etc.)
├── Commands/
│   ├── NHibernateCommand.cs        ← Base: void commands with session + transaction
│   └── NHibernateGenericCommand.cs ← Base: commands returning TResult
├── Queries/
│   ├── NHibernateGenericQuery.cs   ← Base: query with auto-dispose in Execute()
│   └── QueryOverExtensions.cs      ← Projection and sorting helpers
└── Extensions/
    └── BatchLoader.cs              ← Chunked batch loading for large ID lists

DomainServices/Core/Database/       ← Project-specific wiring (rename {Project})
├── NHibernate{Project}Gateway.cs        ← Static facade: Configure(), OpenSession()
├── NHibernate{Project}GatewayCommand.cs ← Binds CreateSession() to the gateway
└── NHibernate{Project}GatewayQuery.cs   ← Binds CreateSession() to the gateway

DomainModel/                        ← Entities + XML mappings (one assembly)
├── <Folder>/
│   ├── <Entity>.cs                 ← POCO
│   └── <Entity>.hbm.xml            ← sibling XML mapping, embedded resource
└── {Project}.DomainModel.csproj    ← <EmbeddedResource> entry per mapping
```

---

## When to read which reference

Before writing or editing code, read the relevant reference file. Each file is focused and compact — read only the ones relevant to the current task.

| Task | Read first |
|---|---|
| Adding or editing an entity, `.hbm.xml` mapping, or debugging `MappingException` | `references/entity-mappings.md` |
| Writing a new `Load*Query` or `Find*Query` | `references/query-patterns.md` |
| Writing a new `Save*Command` or `[Verb]*Command` | `references/command-patterns.md` |
| Composing multiple queries/commands in a shared session or transaction | `references/execution-modes.md` |
| Looking up QueryOver API (filtering, joins, eager loading, projections) | `references/queryover-reference.md` |

If the task touches more than one area (e.g. adding an entity AND writing its first query), read the mapping reference first, then the query reference.

---

## Naming Conventions

| Type | Prefix | Examples |
|---|---|---|
| Query by known key/identifier | `Load*Query` | `LoadUserQuery`, `LoadDocumentArchiveQuery` |
| Query by search criteria | `Find*Query` | `FindActiveUserQuery`, `FindAllPendingJobsQuery` |
| Save/create command | `Save*Command` | `SaveDocumentArchiveCommand`, `SaveAuditEntriesCommand` |
| Update/action command | `[Verb]*Command` | `CancelWorkflowCommand`, `ApproveRequestCommand`, `ArchiveJobCommand` |
| Generic save | `SaveOrUpdateCommand.For(entity)` | Reusable helper (see `references/command-patterns.md`, Pattern 1) |

- One class per file
- File name matches class name
- Namespace matches folder structure under `DomainServices`

---

## Anti-Patterns — Do NOT

These apply universally across every query, command, mapping, and composition. Keep them in mind on every change.

1. **Use raw sessions for standalone operations.** If a single query or command does the job, use the class — don't open a session and write inline QueryOver. Reserve opening sessions explicitly for composition scenarios.

2. **Use LINQ `.Query<T>()`** instead of QueryOver. This project uses QueryOver exclusively for type-safe, criteria-based queries.

3. **Execute queries inside loops without batching.** If you need data for N items, write a single query that loads all N results at once, then match in memory.
   ```csharp
   // WRONG — N+1 sessions
   foreach (var id in requestIds)
       results.Add(new LoadItemQuery(id).Execute());

   // CORRECT — single session, single query
   var allItems = new LoadItemsByIdsQuery(requestIds).Execute();
   ```

4. **Mix reads and writes in one class.** Keep queries and commands separate. A query should never call `Session.Save()`.

5. **Manage transactions inside `OnExecute()`.** The base command class handles transactions in single execution mode. In composition mode, the caller handles them. `OnExecute()` never calls `BeginTransaction()` or `Commit()`.

6. **Forget to add eager loading for known associations.** If you know the consumer needs a related entity, use `.Fetch(SelectMode.Fetch, ...)` or `.JoinAlias()` to avoid lazy loading N+1.

7. **Return detached entities and modify them later without a session.** If you need to update an entity loaded by a query, pass it to a command that calls `Session.Update()`.

8. **Forget to dispose shared sessions.** When using composition mode, always wrap the session in `using var session = ...` to ensure cleanup.

9. **Put mappings in a separate `Mappings/` folder.** Co-locate `.hbm.xml` with its `.cs` entity — see `references/entity-mappings.md`.

10. **Forget the `<EmbeddedResource>` entry.** The build will succeed and the first real query will throw `MappingException` at runtime — see `references/entity-mappings.md`.

---

## Session and Transaction Rules

These are binding rules — read before composing operations.

1. **Commands always run in a transaction.** In single execution mode, the base class handles `BeginTransaction()` and `Commit()`. In composition mode, the caller handles this. Either way, `OnExecute()` never manages transactions.

2. **Queries never use explicit transactions.** Read operations run without transaction wrapping, both in single and composition mode.

3. **Single execution is the default.** Each `Execute()` call opens a fresh, short-lived session. Use this for isolated operations.

4. **Use composition for shared connections or atomicity.** Open a session via `NHibernate{Project}Gateway.OpenSession()` and pass it with `.UseExternalSession(session)` when:
   - Multiple queries need to share a connection (efficiency)
   - Multiple commands must commit/rollback together (atomicity)
   - You need to mix query classes with direct `session.QueryOver<T>()` calls

5. **`UseExternalSession` is the method on both queries and commands.** It returns the instance for fluent chaining: `new Query().UseExternalSession(session).Execute()`.

6. **The caller owns the external session lifecycle.** When you open a session with `using var session = ...`, you are responsible for disposing it. Queries and commands will not dispose an external session.

Full patterns and examples live in `references/execution-modes.md`.

---

## Quick Checklists

These summarize the steps — detailed examples are in the referenced files.

### Creating a new query — see `references/query-patterns.md`

1. Class inherits from `NHibernate{Project}GatewayQuery<TResult>`
2. Parameters via primary constructor
3. Override `OnExecute()` — use `Session.QueryOver<T>()`
4. Add `.Fetch()` or `.JoinAlias()` for associations the consumer will need
5. `SingleOrDefault()` for single entity, `List()` for collections
6. Name it `Load*Query` (known key) or `Find*Query` (search criteria)

### Creating a new command — see `references/command-patterns.md`

1. Class inherits from `NHibernate{Project}GatewayCommand` (void) or `NHibernate{Project}GatewayCommand<T>` (returns result)
2. Parameters via primary constructor
3. Override `OnExecute()` — use `Session.Save()`, `Session.Update()`, `Session.Delete()`
4. Never call `BeginTransaction()` or `Commit()` inside `OnExecute()`
5. For single-entity saves, prefer `SaveOrUpdateCommand.For(entity).Execute()` — no custom class needed
6. Name it `[Verb]*Command`

### Adding a new entity — see `references/entity-mappings.md`

1. Create `DomainModel/<Folder>/<Entity>.cs` (POCO, `virtual` properties if lazy loading needed)
2. Create `DomainModel/<Folder>/<Entity>.hbm.xml` next to it
3. Set `assembly` and `namespace` attributes on `<hibernate-mapping>` to match
4. Add `<EmbeddedResource Include="<Folder>\<Entity>.hbm.xml" />` to the DomainModel `.csproj`
5. Build and verify via `Session.QueryOver<Entity>()`

### Composing multiple operations — see `references/execution-modes.md`

1. Open a session: `using var session = NHibernate{Project}Gateway.OpenSession();`
2. For commands, also open a transaction: `using var tran = session.BeginTransaction();`
3. Chain `.UseExternalSession(session)` before `.Execute()` on each query/command
4. For commands, commit explicitly: `tran.Commit();`
