---
name: email-ingest
description: Email processing skill — forward email to create expense, attachment extraction, auto-categorization. Fires on "email processing", "forward email", "email to expense".
---

# Email Ingest — Email to Expense

Procesare email-uri forwarded pentru a crea cheltuieli automat.

## Flow

```
1. User forwarded un email (cu factură atașată) la adresa dedicată
2. Mandrill primește email-ul și trimite webhook
3. Backend procesează: extrage atașamente, metadata
4. Creează cheltuială draft cu datele extrase
5. Trimite atașamentul la OCR (Conspectare) pentru extragere date
6. User verifică și confirmă cheltuiala
```

## Backend

### Controller

```csharp
[ApiController]
[Route("api/[controller]")]
public class EmailIngestController : ControllerBase
{
    [HttpPost("webhook")]
    [AllowAnonymous]
    public async Task<IActionResult> IngestWebhook([FromBody] MandrillWebhookPayload payload)
    {
        // Validează Mandrill webhook signature
        var result = await _emailIngestService.ProcessAsync(payload);
        return result.IsSuccess ? Ok() : BadRequest(result.Error);
    }
}
```

- `EmailIngestController` (nu `EmailIngestApiController`)
- `OperationResult<T>` (nu custom EmailIngestResult)
- Webhook `[AllowAnonymous]` dar validat cu Mandrill signature

### Service

```csharp
public interface IEmailIngestService
{
    ValueTask<OperationResult<EmailIngestResult>> ProcessAsync(MandrillWebhookPayload payload);
}
```

### Procesare

1. Extrage sender email → caută user + team în DB
2. Setează `team_id` pe baza user-ului (NHibernate tenantFilter)
3. Extrage atașamente → upload în S3
4. Creează cheltuială draft
5. Trimite atașamentul la OCR (Conspectare)

## Frontend

Nu are UI dedicat — cheltuielile create din email apar în lista normală de cheltuieli cu status "Draft" și un badge "Din email".

## Reguli

1. **OperationResult<T>**, nu custom result types.
2. **NHibernate tenantFilter** — team_id setat din user-ul sender.
3. **Conspectare** pentru OCR pe atașamente.
4. Controller: `EmailIngestController` (fără "Api").
5. Mandrill webhook validat cu signature.
6. Cheltuiala creată e always Draft — user confirmă manual.
