---
name: internal-email-template
description: Generate a new Bono Fintech branded HTML email template for any Bono backend project. Use when the user asks to create a new email notification, report, or alert, or requests a new transactional email following the Bono brand for internal usage. Make sure to use this skill whenever the user mentions creating, scaffolding, or designing a new branded email, report, alert, or notification template for any Bono Fintech project, even if they don't explicitly say "email template".
---

# Bono Email Template Generator

When invoked, generate a complete, on-brand Bono Fintech HTML email template and describe the corresponding C# builder model.

## Step 1 – Read all references first

Before writing a single line of HTML, Read these three files:

- `references/template-pipeline.md`
- `assets/weekly-eur-ron-report.html`
- `assets/missing-exchange-rates-alert.html`

Use them as the ground truth for structure, styling, and conventions. The two HTML samples are concrete reference emails from a real project — copy the brand shell, layout patterns, and Handlebars conventions; the exchange-rate content is illustrative only.

---

## Step 2 – Understand the fixed shell

Every email shares an identical outer structure. Copy the following elements verbatim — never change these values:

### Document / head
```html
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title><!-- VARIABLE --></title>
  <!--[if mso]>
  <style type="text/css">
    table, td { font-family: Arial, sans-serif !important; }
  </style>
  <![endif]-->
</head>
```

### Body and outer wrapper
```html
<body style="margin:0; padding:0; background-color:#f4f1ec; font-family:Arial, Helvetica, sans-serif; -webkit-text-size-adjust:100%; -ms-text-size-adjust:100%;">
  <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="background-color:#f4f1ec;">
    <tr>
      <td align="center" style="padding:24px 12px;">
        <!-- Main container: 600px max-width -->
        <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="600"
               style="max-width:600px; width:100%; background-color:#ffffff; border-radius:8px; overflow:hidden; border:1px solid #e0dbd3;">
```

### Header (3 variable text values, everything else fixed)
```html
<tr>
  <td style="background-color:#ee4379; padding:28px 32px 24px 32px;">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
      <tr>
        <td>
          <!-- VARIABLE 1: category label -->
          <p style="margin:0 0 4px 0; font-size:11px; letter-spacing:2.5px; text-transform:uppercase; color:rgba(255,255,255,0.7); font-family:Arial, Helvetica, sans-serif;">
            <!-- e.g. "Weekly FX Report" / "Exchange Rate Alert" -->
          </p>
          <!-- VARIABLE 2: main title -->
          <h1 style="margin:0; font-size:28px; font-weight:700; color:#ffffff; font-family:Georgia, 'Times New Roman', serif; line-height:1.2;">
            <!-- e.g. "EUR → RON" / "Missing Rates" -->
          </h1>
          <!-- VARIABLE 3: period subtitle — always a Handlebars variable -->
          <p style="margin:8px 0 0 0; font-size:13px; color:rgba(255,255,255,0.7); font-family:Arial, Helvetica, sans-serif;">
            {{period_variable}}
          </p>
        </td>
      </tr>
    </table>
  </td>
</tr>
```

### Source / disclaimer
```html
<tr>
  <td style="padding:16px 32px; background-color:#f8f6f2; border-top:1px solid #e8e4de;">
    <p style="margin:0; font-size:11px; color:#999; font-family:Arial, Helvetica, sans-serif; line-height:1.6;">
      <!-- VARIABLE: disclaimer/source sentence -->
    </p>
  </td>
</tr>
```

### Footer (never changes)
```html
<tr>
  <td style="padding:20px 32px; background-color:#ee4379;">
    <p style="margin:0; font-size:11px; color:rgba(255,255,255,0.7); font-family:Arial, Helvetica, sans-serif;">
      &copy; {{current_year}} Bono Fintech
    </p>
  </td>
</tr>
```

---

## Step 3 – Content section (variable)

Design all `<tr>` rows that sit between the header and the disclaimer to match the email's purpose. Reuse these established patterns from the asset examples:

| Pattern | When to use |
|---|---|
| Summary stat row (3 cols) | Key numeric metrics at a glance |
| Summary stat row (2 cols) | Two-metric summaries |
| Data table with header row | Listing items with labels and values |
| Bar chart row | Visual rate comparison over time |

**Content colour palette:**
- Dark navy for values/headings: `#1a2744`
- Muted labels: `#999`
- Table header background: `#f8f6f2`
- Row separator: `1px solid #eee`
- Alternate row background (odd rows, inline style string): `background-color:#fafaf8;`
- Positive/OK green: `#27864e`
- Negative/alert red: `#c0392b`
- Neutral grey: `#888888`

**Handlebars conventions:**
- Use `{{#unless is_last}} border-bottom:1px solid #eee;{{/unless}}` to suppress the last row's border
- Use `{{#if row_bg}} style="{{row_bg}}"{{/if}}` on `<tr>` for zebra striping
- For arrays use `{{#each items}}…{{/each}}`
- For Outlook-incompatible `<div>` heights (e.g. bar charts) always add an MSO conditional comment

---

## Step 4 – Output

### 4a. HTML file
- Filename: kebab-case`.html`
- If working in a project that has a dedicated Resources\Emails folder, add it there

### 4b. Builder model description
After producing the HTML, output a plain-text description of the `Dictionary<string, object>` that the C# builder class must return. Reference `template-pipeline.md` for the exact builder pattern.

Include:
- All top-level scalar keys with their C# type and example value
- All array keys with the property names for each array-item dictionary
- Any formatting conventions (`F4` decimals, `CultureInfo.InvariantCulture`, Romanian locale for subjects, `is_last` boolean, `row_bg` inline-style string or empty string)
