---
name: dotnet-api-blueprint
description: Canonical pattern for adding HTTP API features to an ASP.NET Core solution using a 4-layer architecture (service interface + HTTP client + adapter + controller) with a split between Api, Api.ServiceInterface, and Api.ServiceAdapters projects. Use this skill whenever the user asks to add a new endpoint, build a service vertical, create a controller, wire up a new API feature, scaffold a request/response flow, or asks about the conventions of a .NET solution that follows this three-project split — even when they do not name the pattern explicitly.
---

# API Architecture Blueprint

Opinionated pattern for building API features in an ASP.NET Core solution where the service contract is shared between the server-side adapter and a distributable HTTP client. Follow this pattern exactly when adding new feature verticals — deviations cost more than they save.

## Before generating code

Confirm the `{Project}` root name with the user if it is not already known from the conversation or the repository. Placeholders used throughout:

- `{Project}` → solution/namespace root (e.g., `Acme.ServiceGateway`)
- `{Feature}` → feature name in `PascalCase` (e.g., `OrderSubmission`)
- `{feature-route}` → feature URL segment in `kebab-case` (e.g., `order-submission`)
- `{action-route}` → action URL segment in `kebab-case` (e.g., `submit`)

### Prerequisite check

Before writing feature code, verify the host project already provides the shared utilities this skill depends on. Run these Globs from the repository root (adjust the `{Project}` segment if the solution root is known):

```
**/Api.ServiceInterface/Shared/HttpClientExtensions.cs   # provides ReadAsync<T>()
**/Api/*GlobalExceptionHandler*.cs                       # global ProblemDetails handler
**/Api/Configuration/DependencyInjection.cs              # RegisterAppServices entry point
**/Api.ServiceInterface/Shared/DateTimeConverter.cs      # string ↔ DateTime helper (only if feature uses dates)
```

Expected outcome:

- **All present** → proceed with the 6-step pattern below.
- **Any missing** → stop and surface the gap to the user. Re-scaffolding these shared pieces is out of scope for this skill; creating a parallel copy per-feature silently diverges from the pattern. If the user confirms the file really should not exist (e.g., a brand-new solution), ask whether they want to bootstrap the shared pieces first.

Do not assume these files exist based on the examples in this skill — the examples presume the conventional layout but a given repo may deviate.

## Solution structure

```
{Project}/
├── {Project}.Api                   # ASP.NET Core host: controllers, DI, security, startup
├── {Project}.Api.ServiceInterface  # Contracts: interfaces, DTOs, HTTP clients (distributable)
├── {Project}.Api.ServiceAdapters   # Business logic: adapter classes implementing the interfaces
├── {Project}.DomainModel           # Domain entities + ORM mappings
├── {Project}.DomainServices        # Queries, commands, domain logic
└── {Project}.Infrastructure.*      # Infrastructure concerns
```

External consumers reference **only** `Api.ServiceInterface`. They get the interface, DTOs, and a ready-to-use HTTP client without any server dependencies (no ORM, no business logic, no infrastructure).

## The 4-layer pattern

Both the HTTP client and the adapter implement the same `I{Feature}Service` interface. The controller injects the interface; on the server the adapter is wired, consumers wire the HTTP client instead. One contract, two implementations, zero duplication.

```
Consumer → HTTP Client ──HTTP──> Controller → Service Adapter
           (ServiceInterface)    (Api)        (ServiceAdapters)
           implements I{F}S                   implements I{F}S
```

## Step-by-step: adding a new API feature

### Step 1 — Define the service interface

**Project:** `{Project}.Api.ServiceInterface`
**Location:** `{Feature}/I{Feature}Service.cs`

```csharp
namespace {Project}.Api.ServiceInterface.{Feature}
{
    public interface I{Feature}Service
    {
        /// <summary>
        /// Description of what this operation does.
        /// </summary>
        ValueTask<{Feature}Response> DoSomething({Feature}Request request);
    }
}
```

**Rules:**

- Return `ValueTask<T>` (not `Task<T>`) for all async methods. Many calls complete synchronously through adapter fast paths (cache hits, validation-fail early returns), so `ValueTask` avoids unnecessary `Task` allocations. Never `await` a `ValueTask` twice.
- Add XML doc comments on every method — they flow into the generated OpenAPI description.
- Place the interface in the feature folder root, not in `Models/`.
- Use one interface per feature vertical. Split only if the feature has two genuinely unrelated responsibilities.

### Step 2 — Define request/response DTOs

**Default location:** `{Feature}/Models/`

The shape of the DTOs is whatever the feature needs. The rules below govern their *form*, not their content.

**Rules:**

- Use `record` types (not `class`). Value-based equality is useful for caching, diffing, and test assertions.
- Use the `required` modifier on mandatory fields — the compiler enforces initialization at construction.
- Initialize collections with `= []`. Never return `null` for a collection.
- Place status/result enums in their own file within `Models/`.
- Enum values serialize as string names (configured globally via `StringEnumConverter`).
- Store date fields as `string` with `DateTimeConverter` helper methods when cross-system date-format pain is a concern.

#### DTO folder layout — simple vs. composite features

Pick **one** of two layouts per feature. Do not mix them.

**Simple feature (default)** — one vertical with a handful of related DTOs. Everything flat in `Models/`:

```
{Feature}/
├── I{Feature}Service.cs
├── {Feature}ServiceClient.cs
└── Models/
    ├── {Feature}Request.cs
    ├── {Feature}Response.cs
    └── {Feature}Status.cs
```

**Composite feature** — the feature has two or more genuinely distinct sub-flows (e.g., "status check" vs. "documents download" under a `CompanyIncorporation` umbrella) whose DTOs do not overlap. Use one PascalCase sub-folder per sub-flow, plus a `Shared/` folder at the feature root for DTOs used by two or more sub-flows. `Models/` is omitted:

```
{Feature}/
├── I{Feature}Service.cs
├── {Feature}ServiceClient.cs
├── {SubFeatureA}/
├── {SubFeatureB}/
└── Shared/
```

Rules specific to the composite layout:

- A sub-feature folder exists **only** when its DTOs are not shared. The moment a DTO is used by a second sub-flow, it moves to `Shared/`.
- `Shared/` at the feature root is for feature-internal reuse. Cross-feature reuse still lives in the top-level `Api.ServiceInterface/Shared/`.
- Namespaces mirror the folder: `{Project}.Api.ServiceInterface.{Feature}.{SubFeature}` and `{Project}.Api.ServiceInterface.{Feature}.Shared`.
- Do not use the composite layout to pre-empt hypothetical future sub-flows. Start with `Models/`; split only when a second sub-flow actually arrives.
- Do not nest a `Models/` folder inside a sub-feature folder — the sub-feature folder *is* the models folder.

**When in doubt, pick `Models/`.** The composite layout has a higher navigation cost and should only appear when flat organization would force unrelated DTOs to sit together.

### Step 3 — Create the HTTP client

**Location:** `{Feature}/{Feature}ServiceClient.cs` (same folder as the interface)

```csharp
using {Project}.Api.ServiceInterface.{Feature}.Models;
using {Project}.Api.ServiceInterface.Shared;
using System.Net.Http.Json;

namespace {Project}.Api.ServiceInterface.{Feature}
{
    public class {Feature}ServiceClient : I{Feature}Service
    {
        private readonly HttpClient _httpClient;

        public {Feature}ServiceClient(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

        /// <inheritdoc/>
        public async ValueTask<{Feature}Response> DoSomething({Feature}Request request)
        {
            using var response = await _httpClient.PostAsJsonAsync(
                "{feature-route}/{action-route}", request);
            return await response.ReadAsync<{Feature}Response>();
        }
    }
}
```

**Rules:**

- Implement the same `I{Feature}Service` interface as the adapter.
- Take `HttpClient` in the constructor. Consumers set `BaseAddress` externally via `services.AddHttpClient<I{Feature}Service, {Feature}ServiceClient>(c => c.BaseAddress = …)`.
- Use `PostAsJsonAsync` for POST, `GetAsync` for GET.
- Always use `using var response` so the response is disposed.
- Deserialize via `response.ReadAsync<T>()` (extension in `Shared/HttpClientExtensions.cs`). This extension calls `EnsureSuccessStatusCode()` internally — non-2xx responses throw `HttpRequestException` with the status code attached, which the adapter catches.
- Relative URL must match the controller route exactly: `[Route("{feature-route}")]` + `[HttpPost("{action-route}")]`.
- For GET with route parameters: `$"{feature-route}/{action-route}/{parameter}"`.
- No try-catch in the client. Failures propagate as `HttpRequestException`; only the adapter decides how to translate them.

### Step 4 — Create the service adapter

**Project:** `{Project}.Api.ServiceAdapters`
**Location:** `{Feature}/{Feature}ServiceAdapter.cs`

```csharp
using {Project}.Api.ServiceInterface.{Feature};
using {Project}.Api.ServiceInterface.{Feature}.Models;
using Microsoft.Extensions.Logging;

namespace {Project}.Api.ServiceAdapters.{Feature}
{
    public class {Feature}ServiceAdapter(
        ILogger<{Feature}ServiceAdapter> logger) : I{Feature}Service
    {
        public async ValueTask<{Feature}Response> DoSomething({Feature}Request request)
        {
            // 1. Validate input — return a safe response for invalid input.
            if (/* input invalid */)
                return /* safe default response for this scenario */;

            try
            {
                // 2. Business logic here.
                return new {Feature}Response { /* ... */ };
            }
            catch (HttpRequestException hrx) when (hrx.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                logger.LogWarning("Resource not found: {Detail}", hrx.Message);
                return /* safe default response */;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to process {Feature} request");
                return /* safe default response */;
            }
        }
    }
}
```

**Rules:**

- Use a C# 12 primary constructor for dependency injection — less ceremony. Inject dependencies as the scenario requires (empty constructor is fine if none are needed).
- Implement `I{Feature}Service`.
- Put ALL business logic here. Controllers and clients stay thin.
- Avoid throwing from adapter methods. Return a safe response (empty collections, a default status value — whatever "nothing happened" means for this feature).
- Use the `ILogger` dependency to log expected exceptions per the scenario spec.
- Use structured logging only: `logger.LogError(ex, "Message {Param}", param)`. Never string-concatenate.
- Validate inputs early and return a safe response for invalid data.

### Step 5 — Create or extend a controller

**Project:** `{Project}.Api`
**Location:** `Controllers/{Feature}ApiController.cs`

```csharp
using {Project}.Api.ServiceInterface.{Feature};
using {Project}.Api.ServiceInterface.{Feature}.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace {Project}.Api.Controllers;

/// <summary>Description of this controller's domain.</summary>
[ApiController]
[Route("{feature-route}")]
public class {Feature}ApiController : ControllerBase
{
    private readonly I{Feature}Service _{feature}Service;

    public {Feature}ApiController(I{Feature}Service {feature}Service)
    {
        _{feature}Service = {feature}Service;
    }

    /// <summary>Description of the endpoint.</summary>
    [HttpPost("{action-route}")]
    [ProducesResponseType(typeof({Feature}Response), StatusCodes.Status200OK)]
    public async Task<IActionResult> ActionName({Feature}Request request)
    {
        var response = await _{feature}Service.DoSomething(request);
        return Ok(response);
    }
}
```

**Rules:**

- Put `[ApiController]` + `[Route("{feature-route}")]` on every controller.
- Use `kebab-case` for route prefixes and action routes.
- Put `[ProducesResponseType]` on every action — feeds OpenAPI/Swagger.
- Return `Task<IActionResult>` from controller methods (not `ValueTask`). The MVC pipeline awaits `Task` natively; inside the method the service's `ValueTask<T>` is awaited normally.
- Keep controllers thin — delegate to the service interface and wrap in `Ok()`.
- Add XML doc comments on the class and every action.
- A single controller may inject multiple service interfaces if they share a domain.
- All endpoints require API key auth by default (global fallback policy). Use `[AllowAnonymous]` only on health/infrastructure endpoints.
- Do not use try-catch in controllers. The `GlobalExceptionHandler` catches anything the adapter surprisingly lets through and returns `ProblemDetails`.

### Step 6 — Register in DI

**File:** `{Project}.Api/Configuration/DependencyInjection.cs`

Add to `RegisterAppServices`:

```csharp
services.AddScoped<I{Feature}Service, {Feature}ServiceAdapter>();
```

**Rules:**

- Always use `AddScoped` lifetime for service adapters — one instance per HTTP request.
- If the adapter needs an external HTTP client, register it with `services.AddHttpClient<IClient, Client>()`.
- Bind configuration objects via `services.Configure<TSettings>(config.GetSection("SectionName"))`.

## Naming quick reference

| Element | Convention | Example |
|---------|-----------|---------|
| Interface | `I{Feature}Service` | `IOrderSubmissionService` |
| HTTP Client | `{Feature}ServiceClient` | `OrderSubmissionServiceClient` |
| Adapter | `{Feature}ServiceAdapter` | `OrderSubmissionServiceAdapter` |
| Controller | `{Feature}ApiController` | `OrderSubmissionApiController` |
| Request DTO | `{Feature}Request` or `{Action}Request` | `OrderSubmissionRequest` |
| Response DTO | `{Feature}Response` or `{Action}Response` | `OrderSubmissionResponse` |
| Route prefix | `kebab-case` | `order-submission` |

For the full conventions reference (namespaces, folder structure diagrams, shared utilities, serialization settings, async return-type rules, error-handling rules), read `references/conventions.md`.

For a complete worked end-to-end example showing every file for a realistic feature (`OrderSubmission`), read `references/worked-example.md`. Consult it when generating a feature for the first time in a session, or when the steps above leave any ambiguity about how the files fit together.

## Checklist for a new API feature

- [ ] Interface defined in `Api.ServiceInterface/{Feature}/`
- [ ] DTOs as `record` types — in a flat `Models/` folder (simple feature) **or** in sub-feature folders with a `Shared/` sibling for reused DTOs (composite feature); never both in the same feature
- [ ] HTTP client in same folder as interface, implements the interface
- [ ] Client URLs match controller routes exactly
- [ ] Client uses `ReadAsync<T>()` extension method
- [ ] Adapter in `Api.ServiceAdapters/{Feature}/`, implements the interface
- [ ] Controller in `Api/Controllers/`, thin delegation only
- [ ] Controller has `[ApiController]`, `[Route]`, `[ProducesResponseType]` for success and relevant error codes
- [ ] XML doc comments on interface, DTOs, controller, and actions
- [ ] Registered in `DependencyInjection.cs` with `AddScoped`
- [ ] Solution builds without warnings; OpenAPI doc generates
