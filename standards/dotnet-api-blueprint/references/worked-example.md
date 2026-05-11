# Worked End-to-End Example: OrderSubmission

Complete files for a realistic feature. Read this when generating a feature for the first time in a session, or when the step-by-step pattern in the core skill leaves any ambiguity about how the files fit together.

**Feature:** `OrderSubmission` — accept an order, return a confirmation number.

---

## `Api.ServiceInterface/OrderSubmission/IOrderSubmissionService.cs`

```csharp
namespace {Project}.Api.ServiceInterface.OrderSubmission
{
    public interface IOrderSubmissionService
    {
        /// <summary>Submit an order for processing.</summary>
        ValueTask<OrderSubmissionResponse> Submit(OrderSubmissionRequest request);
    }
}
```

## `Api.ServiceInterface/OrderSubmission/Models/OrderSubmissionRequest.cs`

```csharp
namespace {Project}.Api.ServiceInterface.OrderSubmission.Models
{
    public record OrderSubmissionRequest
    {
        public required string CustomerId { get; set; }
        public List<OrderLine> Lines { get; set; } = [];
    }

    public record OrderLine
    {
        public required string Sku { get; set; }
        public int Quantity { get; set; }
    }
}
```

## `Api.ServiceInterface/OrderSubmission/Models/OrderSubmissionResponse.cs`

```csharp
namespace {Project}.Api.ServiceInterface.OrderSubmission.Models
{
    public record OrderSubmissionResponse
    {
        public string ConfirmationNumber { get; set; } = "";
        public OrderSubmissionStatus Status { get; set; } = OrderSubmissionStatus.Unknown;
    }

    public enum OrderSubmissionStatus { Unknown, Accepted, Rejected }
}
```

## `Api.ServiceInterface/OrderSubmission/OrderSubmissionServiceClient.cs`

```csharp
using {Project}.Api.ServiceInterface.OrderSubmission.Models;
using {Project}.Api.ServiceInterface.Shared;
using System.Net.Http.Json;

namespace {Project}.Api.ServiceInterface.OrderSubmission
{
    public class OrderSubmissionServiceClient : IOrderSubmissionService
    {
        private readonly HttpClient _httpClient;

        public OrderSubmissionServiceClient(HttpClient httpClient) => _httpClient = httpClient;

        /// <inheritdoc/>
        public async ValueTask<OrderSubmissionResponse> Submit(OrderSubmissionRequest request)
        {
            using var response = await _httpClient.PostAsJsonAsync("order-submission/submit", request);
            return await response.ReadAsync<OrderSubmissionResponse>();
        }
    }
}
```

## `Api.ServiceAdapters/OrderSubmission/OrderSubmissionServiceAdapter.cs`

```csharp
using {Project}.Api.ServiceInterface.OrderSubmission;
using {Project}.Api.ServiceInterface.OrderSubmission.Models;
using Microsoft.Extensions.Logging;

namespace {Project}.Api.ServiceAdapters.OrderSubmission
{
    public class OrderSubmissionServiceAdapter(
        IOrderRepository orders,
        ILogger<OrderSubmissionServiceAdapter> logger) : IOrderSubmissionService
    {
        public async ValueTask<OrderSubmissionResponse> Submit(OrderSubmissionRequest request)
        {
            if (request.Lines.Count == 0)
                return new OrderSubmissionResponse { Status = OrderSubmissionStatus.Rejected };

            try
            {
                var confirmation = await orders.Create(request);
                return new OrderSubmissionResponse
                {
                    ConfirmationNumber = confirmation,
                    Status = OrderSubmissionStatus.Accepted,
                };
            }
            catch (HttpRequestException hrx) when (hrx.StatusCode == System.Net.HttpStatusCode.Conflict)
            {
                logger.LogWarning("Order conflict for customer {CustomerId}", request.CustomerId);
                return new OrderSubmissionResponse { Status = OrderSubmissionStatus.Rejected };
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to submit order for customer {CustomerId}", request.CustomerId);
                return new OrderSubmissionResponse();
            }
        }
    }
}
```

## `Api/Controllers/OrderSubmissionApiController.cs`

```csharp
using {Project}.Api.ServiceInterface.OrderSubmission;
using {Project}.Api.ServiceInterface.OrderSubmission.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace {Project}.Api.Controllers;

/// <summary>Order submission endpoints.</summary>
[ApiController]
[Route("order-submission")]
public class OrderSubmissionApiController : ControllerBase
{
    private readonly IOrderSubmissionService _orderSubmissionService;

    public OrderSubmissionApiController(IOrderSubmissionService orderSubmissionService)
    {
        _orderSubmissionService = orderSubmissionService;
    }

    /// <summary>Submit an order for processing.</summary>
    [HttpPost("submit")]
    [ProducesResponseType(typeof(OrderSubmissionResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Submit(OrderSubmissionRequest request)
    {
        var response = await _orderSubmissionService.Submit(request);
        return Ok(response);
    }
}
```

## `Api/Configuration/DependencyInjection.cs` (addition)

```csharp
services.AddScoped<IOrderSubmissionService, OrderSubmissionServiceAdapter>();
```

---

## Things to notice in this example

- The `OrderSubmissionServiceClient` (HTTP client) and the `OrderSubmissionServiceAdapter` both implement `IOrderSubmissionService` — the contract is defined once.
- The controller's route `[Route("order-submission")]` + `[HttpPost("submit")]` matches the client's URL `"order-submission/submit"` exactly.
- The adapter returns a "safe" `OrderSubmissionResponse` with `Status = Rejected` or `Status = Unknown` rather than throwing, so the controller never needs try-catch.
- The adapter uses a `when` filter to translate a specific HTTP status code (`Conflict`) into a business outcome (`Rejected`); unexpected exceptions fall through to the generic catch and return a neutral response.
- The controller uses `Task<IActionResult>` even though the service method returns `ValueTask<T>`. `await` bridges the two — this is the correct mix.
