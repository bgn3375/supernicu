---
name: dotnet-quartz-jobs
description: Canonical pattern for adding periodic jobs to a .NET scheduled-tasks service that uses Quartz.NET and runs as a Windows Service. Use this skill whenever the user asks to add a new recurring/background/scheduled job, create a new Quartz job, schedule a periodic worker, wire up a new CRON-driven task, or asks about the conventions of the scheduled-tasks project — even when they do not name Quartz explicitly. Also use when the user mentions "run every X minutes/hours", "recurring job", "background worker", "cron job in .NET", or similar phrasing.
---

# Scheduled Tasks Blueprint (Quartz.NET + Windows Service)

Opinionated pattern for adding periodic jobs to a .NET scheduled-tasks service. The host already exists and provides the infrastructure: a `SafeJobAsync` base class, `Schedule<T>()` / `RunNow<T>()` configurator extensions, and a `JobRegistry` that switches between Dev and Prod schedules. Your job is to add new `IJob` implementations and plug them into the registry — follow this pattern exactly, deviations cost more than they save.

## Before generating code

Confirm the `{Project}` root name with the user if it is not already known from the conversation or repository. Placeholders used throughout:

- `{Project}` → solution root name (e.g., `Acme.ServiceGateway`)
- `{Job}` → job name in `PascalCase`, must end with `Job` (e.g., `PurgeStaleSessionsJob`)

## What the project already gives you

Before writing anything, assume these pieces exist and read them if you need confirmation:

- `Scheduler/SafeJobAsync.cs` — abstract base class. Wraps execution with a stopwatch, structured logging, a max-runtime threshold, and top-level exception containment. Every job inherits from it.
- `Scheduler/QuartzConfiguratorExtensions.cs` — provides `Schedule<T>(cron)` and `RunNow<T>()` extension methods on `IServiceCollectionQuartzConfigurator`. One-line job registration.
- `Scheduler/JobRegistry.cs` — routes between `RunDevelopmentTests` (manual, run-on-start) and `RunProductionSchedule` (full CRON) based on `AppSettings:SchedulerMode` in config.
- `Configuration/DependencyInjection.cs` — central place to register app services (database, HTTP clients, domain services, options).
- `Program.cs` — Generic Host + `UseWindowsService()` + Quartz hosted service with `WaitForJobsToComplete = true`. Do not modify.

### Prerequisite check

Before touching any job code, verify the infrastructure is actually there. Run these Globs from the repository root:

```
**/ScheduledTasks/Scheduler/SafeJobAsync.cs
**/ScheduledTasks/Scheduler/QuartzConfiguratorExtensions.cs
**/ScheduledTasks/Scheduler/JobRegistry.cs
**/ScheduledTasks/Configuration/DependencyInjection.cs
**/ScheduledTasks/Program.cs
```

Expected outcome:

- **All present** → read `SafeJobAsync.cs` and `JobRegistry.cs` once for ground truth (the real signatures may have drifted from this skill's examples), then proceed with the three-edit flow below.
- **Any missing** → **do not re-scaffold.** Stop and tell the user exactly which files are missing. Bootstrapping the scheduler host is a bigger task than "add a new job" and belongs in a separate conversation — adding a parallel `IHostedService` or inline Quartz registration to paper over a missing `JobRegistry` is explicitly listed under *What not to do* below.

Do not assume these files exist based on the examples in this skill — the examples presume the conventional layout but a given repo may deviate.

## Project layout (reference)

```
{Project}.ScheduledTasks/
├── Program.cs
├── appsettings.json
├── Configuration/
│   └── DependencyInjection.cs
├── Scheduler/
│   ├── SafeJobAsync.cs                  (infrastructure — do not modify)
│   ├── QuartzConfiguratorExtensions.cs  (infrastructure — do not modify)
│   └── JobRegistry.cs
└── Tasks/
    ├── ExistingJob.cs
    └── {Job}.cs                         ← new file goes here
```

## Adding a new job — three edits

### Step 1 — Create the job class

**Location:** `Tasks/{Job}.cs`

```csharp
using {Project}.ScheduledTasks.Scheduler;
using Quartz;

namespace {Project}.ScheduledTasks.Tasks
{
    /// <summary>
    /// One-sentence description of what this job does and why.
    /// </summary>
    [DisallowConcurrentExecution]
    internal class {Job} : SafeJobAsync
    {
        // inject dependencies via constructor — Quartz resolves them from DI

        public {Job}()
        {
        }

        /// <summary>Override only if this job may legitimately run longer than 60s.</summary>
        protected override int GetMaxRunTime() => 60_000;

        protected override async Task OnExecute(IJobExecutionContext context)
        {
            // Perform the job's work. Exceptions propagate to SafeJobAsync, which logs them with timing.
            await Task.CompletedTask;
        }
    }
}
```

Key rules:

- **Always** inherit from `SafeJobAsync`. Never implement `IJob` directly — you lose the timing, the long-run threshold warning, and the top-level exception containment that keeps one bad run from crashing the scheduler.
- **Always** add `[DisallowConcurrentExecution]` unless you have a specific reason a job can safely overlap with itself. Overlapping runs are the most common source of duplicate work and deadlocks in scheduled systems.
- **Let exceptions bubble up.** `SafeJobAsync` catches at the top level and logs with timing. Do not add a blanket try/catch around `OnExecute`.
- **Internal visibility is fine.** Jobs are resolved by Quartz via DI; they don't need to be `public`.

### Step 1a — When the default `SafeJobAsync` logging is not enough

For single-shot jobs, skip `ILogger<T>` entirely and rely on `SafeJobAsync`'s built-in start/stop/duration logs. Only reach for `ILogger<{Job}>` when you need one of the following shapes:

- **Per-item resilience in a batch loop** — one bad item must not abort the rest.
- **Status logging for non-critical downstream failures** — a side effect (email, webhook, external sink) failed but the schedule should stay green.

See [references/logging-patterns.md](references/logging-patterns.md) for both examples and the rules for when to throw vs. log.

### Step 2 — Register dependencies

If the job needs new services (HTTP client, domain service, options class), add them to `Configuration/DependencyInjection.cs`:

```csharp
internal static void RegisterAppServices(IConfiguration config, IServiceCollection services)
{
    // ... existing registrations

    services.Configure<{Job}Options>(config.GetSection("{Job}Options"));
    services.AddScoped<IMyService, MyService>();
}
```

Quartz resolves the job from a scoped DI scope it creates per trigger firing, so `AddScoped` is the right lifetime for per-run dependencies.

### Step 3 — Schedule it

Edit `Scheduler/JobRegistry.cs` and add one line to `RunProductionSchedule`:

```csharp
private static void RunProductionSchedule(IServiceCollectionQuartzConfigurator quartz)
{
    // ... existing jobs
    quartz.Schedule<{Job}>("0 0/30 * * * ?");   // every 30 minutes
}
```

For local debugging, temporarily uncomment a matching line in `RunDevelopmentTests` so the job fires immediately on startup — `quartz.RunNow<{Job}>();`. Remove it before committing.

## CRON expression cheat sheet

Quartz CRON has **7 fields** (seconds, minutes, hours, day-of-month, month, day-of-week, optional year). This trips up people who know Unix cron. Common examples:

| Expression | Meaning |
|---|---|
| `0 0/5 * * * ?` | Every 5 minutes |
| `0 0/30 * * * ?` | Every 30 minutes |
| `0 0 * * * ?` | Every hour on the hour |
| `0 0 0/8 * * ?` | Every 8 hours starting at midnight |
| `0 0 2 * * ?` | Daily at 02:00 |
| `0 15 10 ? * MON-FRI` | 10:15 AM on weekdays |

Use `?` (not `*`) in exactly one of day-of-month / day-of-week — Quartz requires it, whereas Unix cron does not.

## What not to do

- **Do not use `services.AddHostedService<>`** for a periodic task in this project. Quartz is already wired — adding a separate hosted service loses the CRON schedule, the `[DisallowConcurrentExecution]` guarantee, the shared base class, and ends up running in parallel to the scheduler in confusing ways.
- **Do not put business logic in `Program.cs`.** It is host wiring only.
- **Do not register jobs inline in `Program.cs`.** Keep every registration in `JobRegistry.cs` so the full schedule is readable in one place.
- **Do not catch-and-swallow at the top of `OnExecute`.** That defeats `SafeJobAsync`. If you need per-item resilience (Step 1a), catch inside the loop; let the overall failure bubble up so the base class logs it with timing.
- **Do not rename a job class without checking monitoring.** Trigger identities are derived from `typeof(T).Name`, so renaming silently changes the trigger key. External dashboards or alerts that filter on the old name will go dark.
