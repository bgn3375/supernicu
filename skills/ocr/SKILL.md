---
name: ocr
description: Document scanning via Conspectare (external OCR). Invoice/receipt processing with HMAC-SHA256 webhook callback. Fires on "OCR", "scan document", "upload invoice", "receipt scanning".
---

# OCR — Conspectare Integration

Scanare documente (facturi, bonuri) prin Conspectare, serviciu extern de OCR.

## Provider

**Conspectare** — serviciu extern. NU Azure AI, NU Google Vision, NU Tesseract.

## Flow

```
1. User upload atașament pe cheltuială (S3)
2. Backend trimite URL-ul S3 la Conspectare API
3. Conspectare procesează asincron
4. Conspectare trimite rezultat via webhook (HMAC-SHA256)
5. Backend salvează datele extrase pe cheltuială
6. Frontend afișează datele pentru confirmare de user
```

## Date extrase

- Furnizor (nume)
- CUI furnizor
- Sumă totală
- TVA
- Dată document
- Număr document
- Tip document (factură/bon)

## Backend

### Controller

```csharp
[ApiController]
[Route("api/[controller]")]
public class OcrController : ControllerBase
{
    [HttpPost("submit")]
    [Authorize]
    public async Task<IActionResult> Submit([FromBody] OcrSubmitRequest request)
    {
        var teamId = Request.Headers["X-Team-Id"].ToString();
        var result = await _ocrService.SubmitAsync(teamId, request);
        return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
    }

    [HttpPost("webhook")]
    [AllowAnonymous]
    public async Task<IActionResult> Webhook([FromBody] OcrWebhookPayload payload)
    {
        // Validează HMAC-SHA256 signature
        // Salvează datele extrase
    }
}
```

- `OcrController` (nu `OcrApiController`)
- `OperationResult<T>` (nu custom OcrResult)
- Webhook endpoint e `[AllowAnonymous]` dar validat cu HMAC

### Service

```csharp
public interface IOcrService
{
    ValueTask<OperationResult<OcrSubmission>> SubmitAsync(string teamId, OcrSubmitRequest request);
    ValueTask<OperationResult<OcrResult>> ProcessWebhookAsync(OcrWebhookPayload payload);
}
```

## Frontend

```typescript
// app/actions/ocr.ts
'use server'

export async function submitForOcr(teamId: string, expenseId: string, attachmentId: string) {
  const token = await getAccessToken();
  const res = await fetch(`${API_URL}/api/ocr/submit`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'X-Team-Id': teamId,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ expenseId, attachmentId }),
  });
  return res.json();
}
```

Server action, NU httpClient direct din componentă.

## Timeout recovery

Job background (la fiecare 5 minute): dacă procesarea durează > 30 min → marchează "failed" + loghează timeout.

## Reguli

1. Provider: **Conspectare** (nu altceva).
2. Webhook validat cu **HMAC-SHA256**.
3. **OperationResult<T>**, nu custom result types.
4. **Server actions** pe frontend, nu API calls directe.
5. Controller: `OcrController` (fără "Api" în nume).
6. NHibernate + tenantFilter pe team_id.
