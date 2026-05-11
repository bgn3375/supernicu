# Conventions Reference

Full reference for naming, namespaces, folder structure, shared utilities, serialization, async return types, and error handling. The core skill contains a short naming table and the step-by-step pattern; consult this file when the step-by-step leaves a detail ambiguous.

## Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Interface | `I{Feature}Service` | `IOrderSubmissionService` |
| HTTP Client | `{Feature}ServiceClient` | `OrderSubmissionServiceClient` |
| Adapter | `{Feature}ServiceAdapter` | `OrderSubmissionServiceAdapter` |
| Controller | `{Feature}ApiController` | `OrderSubmissionApiController` |
| Request DTO | `{Feature}Request` or `{Action}Request` | `OrderSubmissionRequest` |
| Response DTO | `{Feature}Response` or `{Action}Response` | `OrderSubmissionResponse` |
| Route prefix | `kebab-case` | `order-submission` |
| Action route | `kebab-case` | `submit`, `check-status` |

## Namespaces

```
{Project}.Api.ServiceInterface.{Feature}          # Interface + Client
{Project}.Api.ServiceInterface.{Feature}.Models   # DTOs (simple layout)
{Project}.Api.ServiceInterface.{Feature}.{SubF}   # DTOs (composite layout, per sub-flow)
{Project}.Api.ServiceInterface.{Feature}.Shared   # DTOs shared between sub-flows
{Project}.Api.ServiceAdapters.{Feature}           # Adapter
{Project}.Api.Controllers                         # All controllers
```

## Folder structure — simple feature

Flat `Models/`, the default choice.

```
Api.ServiceInterface/
└── {Feature}/
    ├── I{Feature}Service.cs
    ├── {Feature}ServiceClient.cs
    └── Models/
        ├── {Feature}Request.cs
        ├── {Feature}Response.cs
        └── {Feature}Status.cs          # (enum, if needed)

Api.ServiceAdapters/
└── {Feature}/
    └── {Feature}ServiceAdapter.cs

Api/Controllers/
└── {Feature}ApiController.cs
```

## Folder structure — composite feature

Sub-feature folders plus `Shared/`, no `Models/`. Use only when the feature has two or more genuinely distinct sub-flows whose DTOs do not overlap.

```
Api.ServiceInterface/
└── {Feature}/
    ├── I{Feature}Service.cs
    ├── {Feature}ServiceClient.cs
    ├── {SubFeatureA}/
    │   ├── {SubFeatureA}Request.cs
    │   └── {SubFeatureA}Response.cs
    ├── {SubFeatureB}/
    │   └── ...
    └── Shared/
        └── {Common}Request.cs

Api.ServiceAdapters/
└── {Feature}/
    └── {Feature}ServiceAdapter.cs

Api/Controllers/
└── {Feature}ApiController.cs
```

The rule for choosing between the two layouts is in Step 2 of the core skill. The short version: default to `Models/`, switch to the composite layout only when a second sub-flow actually arrives.

## Shared utilities (reuse these, do not duplicate)

| Utility | Location | Purpose |
|---------|----------|---------|
| `HttpClientExtensions.ReadAsync<T>()` | `Api.ServiceInterface/Shared/HttpClientExtensions.cs` | Deserialize HTTP response with `EnsureSuccessStatusCode` |
| `DateTimeConverter` | `Api.ServiceInterface/Shared/DateTimeConverter.cs` | String ↔ DateTime conversion (`yyyy-MM-dd` format) |
| Shared enums | `Api.ServiceInterface/Shared/` | Cross-feature enum types |

## Serialization (configured globally in Startup.cs)

- **Library:** Newtonsoft.Json for controller serialization.
- **Property casing:** PascalCase (member casing preserved as-is).
- **Enums:** Serialized as string names via `StringEnumConverter`.
- **Dates:** UTC timezone handling.
- **HTTP clients** use `System.Net.Http.Json` (`PostAsJsonAsync`, `ReadFromJsonAsync`), which uses `System.Text.Json` internally. Both ends of the wire must agree on enum-as-string — verify when adding new enums.

## Async return types

- **Service interfaces, adapters, and HTTP client methods:** `ValueTask<T>`.
- **Controller actions:** `Task<IActionResult>`.

## Error handling

- **Global:** `GlobalExceptionHandler` catches unhandled exceptions and returns `ProblemDetails`.
- **Adapters:** try-catch around external calls. Never throw — return a safe response defined by the scenario. Use `when` filters for specific HTTP status codes:
  ```csharp
  catch (HttpRequestException hrx) when (hrx.StatusCode == HttpStatusCode.NotFound)
  ```
- **Controllers:** no try-catch. The global handler covers anything the adapter surprisingly lets through.
- **HTTP clients:** no try-catch. `ReadAsync<T>` calls `EnsureSuccessStatusCode()` internally, so non-2xx responses throw `HttpRequestException`, which the adapter catches.

## OpenAPI / Swagger

- Every action declares `[ProducesResponseType(typeof(TResponse), StatusCodes.Status200OK)]`.
- XML doc comments on controllers, actions, DTOs, and service interface methods all flow into the generated spec. Enable `<GenerateDocumentationFile>true</GenerateDocumentationFile>` in every referenced project.
- Do not use `[Produces("application/json")]` on individual actions — configure it once globally.
