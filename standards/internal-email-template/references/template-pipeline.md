# Email Template Pipeline

Internal Bono Fintech emails follow a similar 5-step pipeline:

```
Trigger (e.g. Quartz job fires)
     │
     ▼
DB query (e.g. NHibernate QueryOver)
     │   returns List<<DomainEntity>> (or any shape your builder needs)
     ▼
EmailBuilder.Build(...)
     │   returns Dictionary<string, object>  ← Handlebars model
     ▼
EmailTemplateLoader.Load(path)
     │   returns string (raw HTML with {{variables}})
     ▼
EmailMessageComposer (fluent)
     │   binds model to template, composes IMailMessage
     ▼
IMailSender.SendEmailAsync(message, ct)
     │   Mandrill API replaces {{variables}} server-side
     ▼
Email delivered
```

---

## Step 1 – Quartz job

Jobs inherit `SafeJobAsync` which provides built-in error handling and timing. The single method to override is `OnExecute(IJobExecutionContext context)`. Add `[DisallowConcurrentExecution]` for jobs that must not overlap.

```csharp
[DisallowConcurrentExecution]
public class <YourReport>Job(IMailSender mailSender, ILogger<<YourReport>Job> logger)
    : SafeJobAsync
{
    private static readonly string TemplatePath = Path.Combine("Resources", "Emails", "<your-template>.html");

    protected override async Task OnExecute(IJobExecutionContext context)
    {
        // 1. Determine any inputs the job needs (date range, identifiers, etc.)
        var today = DateTime.Today;

        var cultureInfo = new CultureInfo("ro-RO");
        var todayRo = today.ToString("dd MMMM", cultureInfo);   // ← Romanian locale for subject

        // 2. DB query — return whatever shape the builder needs
        var data = new <YourQuery>(/* parameters */).Execute();

        // Optional guard: skip the email when there's nothing meaningful to report
        if (/* not enough data */)
        {
            logger.LogWarning("Insufficient data, skipping send");
            return;
        }

        // 3. Build the Handlebars model
        var model = <YourReport>Builder.Build(data /*, any extra inputs */);

        // 4. Load the HTML template
        var htmlTemplate = EmailTemplateLoader.Load(TemplatePath);

        // 5. Compose and send
        var message = EmailMessageComposer.New()
            .SendTo("<recipient>@bono.ro")
            .HavingSubject($"Bono - <Subject text> / {todayRo}")
            .UsingHtmlTemplate(htmlTemplate)
            .UsingTemplateBindings(model)           // ← binds Dictionary<string, object>
            .WithTags("internal")
            .AsMessage();

        var result = await mailSender.SendEmailAsync(message, context.CancellationToken);

        if (!result.IsSent)
            logger.LogError("Failed to send: {Status}", result.StatusCode);
    }
}
```

---

## Step 2 – DB queries (NHibernate QueryOver)

Each project exposes its own NHibernate base query (e.g. `NHibernate<Project>Query<TResult>`) extending the shared `NHibernateQuery<TResult>`. Your job calls one or more of those queries and feeds the results into the builder. Queries are executed synchronously via `.Execute()`.

```csharp
var data = new <YourQuery>(/* constructor args */).Execute();
```

Queries typically return:
- A `List<<DomainEntity>>` — the records the email needs to render
- Or a `List<DateTime>` / `List<int>` / similar — for emails that report on missing or aggregate data

Use whatever query pattern the host project already exposes — the builder only cares about the shape of the data, not where it came from.

---

## Step 3 – EmailModelBuilder produces the Handlebars model

EmailModelBuilders are `public static` classes with a single `Build(...)` method returning `Dictionary<string, object>`. Mandrill's Handlebars engine accepts scalars and arrays of dictionaries.

### Conventions

```csharp
// Scalar values — always strings
["current_year"] = DateTime.Today.Year.ToString()
["some_date"]    = date.ToString("d MMM yyyy", CultureInfo.InvariantCulture)
["some_value_2d"]   = value.ToString("F2", CultureInfo.InvariantCulture)   // 2 decimal places
["some_value_4d"]   = value.ToString("F4", CultureInfo.InvariantCulture)   // 4 decimal places

// Array items — always List<Dictionary<string, object>>
// Every array item MUST include:
["is_last"] = (bool) i == list.Count - 1      // suppresses border-bottom on last row in HTML
["row_bg"]  = (string) i % 2 == 1 ? "background-color:#fafaf8;" : ""   // zebra striping
```

### Reference: example builders

The two examples below illustrate common patterns: a periodic data report (with deltas and a bar chart) and a multi-section alert (status grid + latest snapshot). They use a placeholder `<DomainEntity>` assumed to expose at least:

```csharp
public DateTime Date  { get; }
public decimal  Value { get; }
public string   Key   { get; }   // optional, for grouping/labeling
```

Substitute your own type and property names where appropriate.

#### Periodic report builder (data over a date range, with deltas + bar chart)

```csharp
public static Dictionary<string, object> Build(
    List<<DomainEntity>> records,
    DateTime periodStart,
    DateTime periodEnd)
{
    // Carry-forward baseline: latest record before the period starts
    var baselineValue = records
        .Where(r => r.Date.Date < periodStart.Date)
        .OrderByDescending(r => r.Date)
        .FirstOrDefault()?.Value ?? 0;

    var periodRecords = records
        .Where(r => r.Date.Date >= periodStart.Date && r.Date.Date <= periodEnd.Date)
        .OrderBy(r => r.Date)
        .ToList();

    // Bar heights: proportional, 4–140px range
    // Bar colors: darkest navy (#1a2744) for highest value, lightest blue (#6e9ed2) for lowest
    var values     = periodRecords.Select(r => r.Value).ToArray();
    var barHeights = ComputeBarHeights(values);
    var barColors  = ComputeBarColors(values);

    // Per-row dictionaries
    var rows = new List<Dictionary<string, object>>();
    var previousValue = baselineValue;
    for (var i = 0; i < periodRecords.Count; i++)
    {
        var record = periodRecords[i];
        var delta  = record.Value - previousValue;

        rows.Add(new Dictionary<string, object>
        {
            ["label"]             = record.Date.ToString("ddd",         CultureInfo.InvariantCulture),
            ["full_label"]        = record.Date.ToString("dddd, d MMM", CultureInfo.InvariantCulture),
            ["value"]             = record.Value.ToString("F4", CultureInfo.InvariantCulture),
            ["bar_height"]        = barHeights[i],                                                  // int (px)
            ["bar_color"]         = barColors[i],                                                   // "#rrggbb"
            ["value_label_color"] = barColors[i],
            ["delta"]             = FormatDelta(delta),                                             // "▲ +0.0012" / "▼ −0.0012" / "— 0.0000"
            ["delta_color"]       = GetDeltaColor(delta),                                           // "#27864e" / "#c0392b" / "#888888"
            ["is_last"]           = i == periodRecords.Count - 1,
            ["row_bg"]            = i % 2 == 1 ? AlternateRowBg : ""
        });

        previousValue = record.Value;
    }

    var openValue  = periodRecords.First().Value;
    var closeValue = periodRecords.Last().Value;
    var changePct  = openValue != 0 ? (closeValue - openValue) / openValue * 100 : 0;

    return new Dictionary<string, object>
    {
        ["date_range"]   = $"{periodStart:d MMM} – {periodEnd:d MMM yyyy}",
        ["open_value"]   = openValue.ToString("F4", CultureInfo.InvariantCulture),
        ["close_value"]  = closeValue.ToString("F4", CultureInfo.InvariantCulture),
        ["change"]       = FormatChange(changePct),                                                 // "▲ +0.12%" / "▼ −0.12%"
        ["change_color"] = GetDeltaColor(changePct),
        ["current_year"] = DateTime.Today.Year.ToString(),
        ["rows"]         = rows
    };
}
```

#### Alert builder (status grid + latest snapshot)

```csharp
public static Dictionary<string, object> Build(
    List<DateTime>       flaggedDates,
    List<DateTime>       checkedDates,
    List<<DomainEntity>> latestRecords)
{
    var flaggedSet  = flaggedDates.Select(d => d.Date).ToHashSet();
    var sortedDates = checkedDates.OrderBy(d => d).ToList();

    // Section 1: status grid — one row per checked date
    var checkedDays = new List<Dictionary<string, object>>();
    for (var i = 0; i < sortedDates.Count; i++)
    {
        var isFlagged = flaggedSet.Contains(sortedDates[i].Date);
        checkedDays.Add(new Dictionary<string, object>
        {
            ["day_label"]    = sortedDates[i].ToString("dddd, d MMM yyyy", CultureInfo.InvariantCulture),
            ["status"]       = isFlagged ? "Missing" : "OK",
            ["status_color"] = isFlagged ? "#c0392b" : "#27864e",
            ["is_last"]      = i == sortedDates.Count - 1,
            ["row_bg"]       = i % 2 == 1 ? AlternateRowBg : ""
        });
    }

    // Section 2: latest snapshot — one row per record
    var sortedRecords = latestRecords.OrderBy(r => r.Key).ToList();
    var snapshotRows  = new List<Dictionary<string, object>>();
    for (var i = 0; i < sortedRecords.Count; i++)
    {
        snapshotRows.Add(new Dictionary<string, object>
        {
            ["label"]   = sortedRecords[i].Key,
            ["value"]   = sortedRecords[i].Value.ToString("F4", CultureInfo.InvariantCulture),
            ["is_last"] = i == sortedRecords.Count - 1,
            ["row_bg"]  = i % 2 == 1 ? AlternateRowBg : ""
        });
    }

    var lastSyncDate = latestRecords.Count > 0
        ? latestRecords.First().Date.ToString("d MMM yyyy", CultureInfo.InvariantCulture)
        : "N/A";

    return new Dictionary<string, object>
    {
        ["alert_date"]         = DateTime.Today.ToString("d MMM yyyy", CultureInfo.InvariantCulture),
        ["flagged_days_count"] = flaggedDates.Count.ToString(),
        ["last_sync_date"]     = lastSyncDate,
        ["checked_days"]       = checkedDays,
        ["latest_snapshot"]    = snapshotRows,
        ["current_year"]       = DateTime.Today.Year.ToString()
    };
}
```

---

## Step 4 – Template loader

```csharp
// EmailTemplateLoader.cs
// Resolves path relative to the application base directory
var htmlTemplate = EmailTemplateLoader.Load(
    Path.Combine("Resources", "Emails", "<your-template>.html")
);
```

HTML files live in a relative `Resources/Emails/` folder and are included in the build output.

---

## Step 5 – Compose and send (Mandrill)

```csharp
var message = EmailMessageComposer.New()
    .SendTo("<recipient>@bono.ro")
    .HavingSubject($"Bono - <Subject text> / {todayRo}")  // todayRo = Romanian-locale "dd MMMM"
    .UsingHtmlTemplate(htmlTemplate)
    .UsingTemplateBindings(model)                         // Dictionary<string, object>
    .WithTags("internal")                                 // all internal emails use this tag
    .AsMessage();

var result = await mailSender.SendEmailAsync(message, cancellationToken);
if (!result.IsSent)
    logger.LogError("Failed to send: {Status}", result.StatusCode);
```

Mandrill replaces all `{{variable}}` tokens in the HTML at send time using the bindings dictionary. Nested arrays (`List<Dictionary<string, object>>`) are iterated with `{{#each arrayKey}}`.

---

## Adding a new email — checklist

1. **Create the HTML template** in the relative folder `Resources/Emails/` wherever the project has all the other email templates
   - Ask if unsure where this folder is found or there is another convention in the project
2. **Create a builder class** `<YourReport>Builder.cs` wherever the project hosts its scheduled-task code
   - `public static Dictionary<string, object> Build(...)` returning all Handlebars bindings
   - Ask if unsure where the current task code should be placed
3. **Create the job class** `<YourReport>Job.cs` in the same folder
   - Inherit `SafeJobAsync`, inject `IMailSender`
   - Run the DB query, call the builder, load the template, compose and send
4. **Document** the new cron in the project's integrations / cron documentation, if it tracks one
