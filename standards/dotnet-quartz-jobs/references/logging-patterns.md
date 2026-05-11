# Logging patterns for Quartz jobs

Extended examples for when `SafeJobAsync`'s built-in start/stop/duration logs are not enough. For simple single-shot jobs, skip `ILogger<T>` entirely — the base class already logs start, completion, duration, and exceptions.

`ILogger<T>` is used here (not the static NLog logger inside `SafeJobAsync`) because structured per-event logs benefit from the category name and structured-fields pipeline that `ILogger` provides, and `SafeJobAsync`'s own logger is reserved for start/stop/duration markers — mixing the two is what keeps the two layers legible in the log stream.

## Pattern A — Per-item resilience in a batch loop

Use this shape when `OnExecute` iterates a collection and one bad item must not abort the rest of the batch. Wrap each unit-of-work in its own try/catch and inject `ILogger<{Job}>` to record per-item outcomes.

```csharp
using {Project}.ScheduledTasks.Scheduler;
using Microsoft.Extensions.Logging;
using Quartz;

namespace {Project}.ScheduledTasks.Tasks
{
    [DisallowConcurrentExecution]
    internal class {Job} : SafeJobAsync
    {
        private readonly ILogger<{Job}> _logger;

        public {Job}(ILogger<{Job}> logger)
        {
            _logger = logger;
        }

        protected override async Task OnExecute(IJobExecutionContext context)
        {
            var items = /* load work */;
            _logger.LogInformation("Found {Count} item(s) to process", items.Count);

            foreach (var item in items)
            {
                try
                {
                    await ProcessOne(item);
                    _logger.LogInformation("Processed {Id}", item.Id);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to process {Id}", item.Id);
                    // continue — one bad item should not abort the batch
                }
            }
        }
    }
}
```

## Pattern B — Status logging for non-critical downstream failures

Use this shape when the job has a **single unit of work** whose success is desired but whose failure is not fatal to the schedule — typically a downstream side effect like sending an email, posting a webhook, or writing to an external audit sink. The downstream call returns a status (not an exception) and the job records it and returns normally.

The distinction from Pattern A: there is no loop and no exception to catch. The downstream API signals partial failure through a return value (e.g., `result.IsSent == false`). Throwing would mark the entire Quartz run as failed for a secondary concern; silently ignoring would lose the signal. Logging at `Error` level threads the needle — monitoring sees it, the schedule stays green.

```csharp
using {Project}.ScheduledTasks.Scheduler;
using Microsoft.Extensions.Logging;
using Quartz;

namespace {Project}.ScheduledTasks.Tasks
{
    [DisallowConcurrentExecution]
    internal class {Job} : SafeJobAsync
    {
        private readonly IMailSender _mailSender;
        private readonly ILogger<{Job}> _logger;

        public {Job}(IMailSender mailSender, ILogger<{Job}> logger)
        {
            _mailSender = mailSender;
            _logger = logger;
        }

        protected override async Task OnExecute(IJobExecutionContext context)
        {
            // 1. Gather data — exceptions here are real failures and should bubble up
            var payload = await BuildPayload();
            if (payload is null)
            {
                _logger.LogWarning("Nothing to send for {Date:yyyy-MM-dd}, skipping", DateTime.Today);
                return;
            }

            // 2. Send — downstream status is informational, not fatal to the schedule
            var result = await _mailSender.SendEmailAsync(payload, context.CancellationToken);

            if (!result.IsSent)
                _logger.LogError("{Job}: downstream rejected the message: {Status}", nameof({Job}), result.StatusCode);
        }
    }
}
```

Guidelines for Pattern B:

- **Do not throw** on the non-critical failure. Throwing defeats the whole point — `SafeJobAsync` will log it as a job failure, alerts fire, and the next scheduled run is the only remedy anyway.
- **Do log at `Error` level**, not `Warning`, when the downstream failure means the intended side effect did not happen. This is the signal monitoring should catch.
- **Use `Warning`** for expected short-circuits (insufficient data, nothing to process), not for downstream failures.
- **Always include the status / reason** from the downstream response as a structured field so it is queryable in the log pipeline.
- **Let pre-send exceptions bubble up.** Data-fetch failures, template load errors, and the like are real bugs — do not wrap them in try/catch. Only the terminal downstream call is treated as non-critical.
