---
name: export
description: Report export skill — Excel/PDF generation, download endpoints. Fires on "export", "download Excel", "generate PDF", "report download".
---

# Export — Excel & PDF Generation

Generare și download rapoarte în format .xlsx sau .pdf.

## Cazuri de uz

- **P&L Report** → .xlsx cu toate lunile, categorii, subcategorii
- **Budget template** → .xlsx pre-completat cu categorii
- **Expenses list** → .xlsx cu cheltuielile filtrate

## Backend

### Controller

```csharp
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ExportController : ControllerBase
{
    [HttpGet("pnl")]
    [Authorize(Roles = "Admin,Approver,Accounting Viewer")]
    public async Task<IActionResult> ExportPnl([FromQuery] int year)
    {
        var teamId = Request.Headers["X-Team-Id"].ToString();
        var result = await _exportService.GeneratePnlExcelAsync(teamId, year);
        if (!result.IsSuccess) return BadRequest(result.Error);

        return File(result.Value.Bytes, result.Value.ContentType, result.Value.FileName);
    }
}
```

- `ExportController` (nu `ExportApiController`)
- `OperationResult<T>` (nu custom ExportResult)
- Returnează `File()` cu bytes, content type, filename

### Service

```csharp
public interface IExportService
{
    ValueTask<OperationResult<FileExport>> GeneratePnlExcelAsync(string teamId, int year);
    ValueTask<OperationResult<FileExport>> GenerateBudgetTemplateAsync(string teamId, int year);
}

public record FileExport
{
    public required byte[] Bytes { get; init; }
    public required string ContentType { get; init; }
    public required string FileName { get; init; }
}
```

### Query-uri

Fiecare query de export filtrează pe `team_id` (NHibernate tenantFilter + filtrare explicită).

## Frontend

### Server action (returnează bytes, rulează pe Node.js)

```typescript
// app/actions/export.ts
'use server'

export async function exportPnl(teamId: string, year: number) {
  const token = await getAccessToken();
  const res = await fetch(`${API_URL}/api/export/pnl?year=${year}`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'X-Team-Id': teamId,
    },
  });

  if (!res.ok) throw new Error('Export failed');

  const buffer = await res.arrayBuffer();
  const filename = res.headers.get('content-disposition')?.split('filename=')[1] ?? 'export.xlsx';
  return { buffer: Buffer.from(buffer).toString('base64'), filename };
}
```

### Client component (face download-ul în browser)

```typescript
// components/export/DownloadButton.tsx
'use client'

async function handleDownload() {
  const { buffer, filename } = await exportPnl(teamId, year);
  const blob = new Blob([Uint8Array.from(atob(buffer), c => c.charCodeAt(0))]);
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
```

Server action returnează base64. Componenta client face blob + download.

## Reguli

1. **OperationResult<T>**, nu custom result types.
2. **Server actions** pe frontend.
3. Controller: `ExportController` (fără "Api").
4. **NHibernate tenantFilter** pe toate query-urile de export.
5. An fiscal Aug-Aug în rapoartele P&L (13 coloane).
6. Multi-currency: coloane RON + EUR în export.
