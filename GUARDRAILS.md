# GUARDRAILS.md

Pattern-uri de eroare cunoscute. Fiecare agent citește acest fișier înainte de a produce output. Nicu-specs adaugă noi entries după fiecare retrospectivă.

Format per entry: **Trigger** (ce context precede eroarea) → **Instrucțiune** (cum previi) → **Motiv** (de ce contează)

---

## G1: Auth bypass prin endpoint fără autorizare

**Trigger:** Creare controller nou sau endpoint nou.
**Instrucțiune:** Folosește `FallbackPolicy` care cere autentificare pe toate endpoint-urile by default. Doar `[AllowAnonymous]` explicit deschide un endpoint. Fiecare `[AllowAnonymous]` trebuie documentat cu motiv.
**Motiv:** Un endpoint uitat fără auth e accesibil de oricine pe internet. Deny-by-default inversează riscul: uiți să adaugi ceva = endpoint-ul e protejat.

## G2: IDOR — acces la datele altui utilizator prin ghicirea ID-ului

**Trigger:** Orice query care accesează o entitate prin ID (GetById, Update, Delete).
**Instrucțiune:** Derivă `teamId`/`userId` din sesiunea autentificată (JWT claims), NICIODATĂ din request params. Fiecare query filtrează pe `team_id` + `entity_id`. Nu expune ID-uri secvențiale (auto-increment) în API — folosește UUID.
**Motiv:** Un utilizator logat care schimbă `id=17` cu `id=18` în URL accesează datele altuia. Dacă ID-urile sunt secvențiale, nici măcar nu trebuie să ghicească.

## G3: Admin și customer pe același API

**Trigger:** Funcții administrative (user management, system config, data export bulk) în aceeași aplicație cu funcții customer.
**Instrucțiune:** Customer API și Admin API sunt ÎNTOTDEAUNA separate: controller-e separate, prefix de rută separat (`/api/v1/` vs `/api/admin/v1/`), politici de autorizare diferite. Admin API nu e expus public (VPN/rețea internă).
**Motiv:** Un singur API = un singur punct de breach. Dacă admin și customer sunt pe același API, un customer logat care găsește URL-urile admin poate chema funcții administrative. Separarea elimină suprafața de atac.

## G4: Security theater — headere custom ca mecanism de autorizare

**Trigger:** Folosire headere custom (ex: `RequestBy`, `X-Admin`, `X-Source`) pentru a decide dacă un request e autorizat.
**Instrucțiune:** Autorizarea se face EXCLUSIV prin JWT claims validate server-side. Headerele custom sunt metadata, nu securitate — oricine le poate seta la orice valoare.
**Motiv:** Un header custom `RequestBy: admin-app` oferă zero protecție. Atacatorul setează headerul identic și obține acces.

## G5: Sensitive data in logs

**Trigger:** Logging de request-uri, login attempts, erori cu context.
**Instrucțiune:** Nu logha NICIODATĂ: parole, tokens, API keys, PII (email, telefon, CNP). Loghează EVENIMENTE (cine, ce acțiune, când, de unde), nu DATE (ce parolă, ce token). Configurează redactare automată pe field names: Password, Secret, Token, ApiKey, Authorization.
**Motiv:** Log-urile ajung în sisteme de monitoring, sunt accesibile echipei, pot fi exportate. O parolă în logs e la fel de expusă ca una hardcodată în cod.

## G6: Ownership validation lipsă pe file upload/download

**Trigger:** Endpoint de upload sau download fișiere.
**Instrucțiune:** Path-urile de stocare includ `team_id` ca prefix. Download-ul verifică că fișierul aparține tenant-ului curent. Nu permite path traversal (`../`).
**Motiv:** Fără ownership check, un utilizator poate descărca fișierele altui tenant dacă ghicește path-ul.

## G7: Background opac șterge tăcut grid-dot pattern-ul (BUG RECURENT)

**ISTORIC:** Bogdan a raportat acest bug în multiple sesiuni (2026-05-08, 2026-05-09, 2026-05-13). DEVENIT REGULĂ ABSOLUTĂ.

**Trigger:** Pagină din dashboard care setează `background` / `backgroundColor` opac pe containerul rădăcină al paginii. Pattern-uri specifice care declanșează bug-ul:
- `style={{ backgroundColor: 'var(--background)' }}` ❌
- `style={{ background: 'var(--c-bej-0)' }}` ❌
- `className="bg-[var(--background)]"` ❌
- `className="bg-background"` ❌
- `className="min-h-screen bg-[var(--c-bej-0)]"` ❌
- Orice inline `bg-*` cu culoare opacă pe outermost element al paginii ❌

**Instrucțiune:**
1. **Paginile dashboard NU setează background.** Lasă transparent — pattern-ul vine din `.has-grid::before` la nivelul `SidebarLayout`.
2. **Defense in depth la nivel CSS:** `globals.css` are `.has-grid > * { background: transparent !important }` ca safety net — dar acest CSS NU înlocuiește instrucțiunea, doar e backup pentru greșeli accidentale.
3. **Excepții (background propriu permis):** doar pagini FĂRĂ `SidebarLayout` — `/login`, `/register`, `/request-access`, `/auth/*`. Aceste pagini sunt centrate, full-viewport, fără sidebar. Și acolo: doar dacă designul cere bg explicit.
4. **Pre-commit check OBLIGATORIU:** grep pattern-urile interzise de mai sus în fișierele modificate. Dacă găsești → fix imediat + verifică vizual în browser.

**Detection automată:**
```bash
# Pre-commit hook recomandat (în .husky/pre-commit sau equivalent):
grep -rn "min-h-screen bg-\[var(--background)\]\|min-h-screen bg-\[var(--c-bej-0)\]\|backgroundColor.*['\"]var(--background)['\"]\|backgroundColor.*['\"]var(--c-bej-0)['\"]" \
  app/dashboard/ components/ 2>/dev/null && echo "G7 VIOLATION DETECTED" && exit 1
```

**Motiv:** Bug invizibil la inspecție rapidă — culoarea pare identică (bej peste bej-cu-puncte), nu sparge teste, nu apare în screenshot-uri JPEG-comprimate. Diferența vizuală e doar pattern-ul de puncte la `rgba(17,13,16,0.15)` care dispare. Detectabil doar prin comparație side-by-side cu prototipul SAU prin atenție la screenshot pixel-perfect. Bogdan **îl prinde mereu** pentru că e mai atent la brand decât majoritatea — repetarea acestui bug erodează încrederea.

**Pattern de raportare în SPEC-uri:** Orice SPEC pentru o pagină dashboard nouă trebuie să includă explicit în S7 (Culori): "Page bg: TRANSPARENT (NU setezi — grid-dot vine din SidebarLayout)."

## G8: Indirect tenant-scoped entities — query fără JOIN pe parent.team_id

**Trigger:** Query pe entitate care NU are coloană `team_id` directă, dar e logic legată de un tenant prin parent (ex: `ExpenseAttachment` → `Expense.TeamId`, `ExpenseAuditLog` → `Expense.TeamId`, `InvoiceLine` → `Invoice.TeamId`).

Pattern tipic eșuat:
```csharp
return Session.QueryOver<ExpenseAttachment>()
    .Where(a => a.Id == attachmentId)   // ❌ doar PK, fără tenant scope
    .SingleOrDefault();
```

**Instrucțiune:**
Queries pe entități indirect tenant-scoped TREBUIE să facă JOIN explicit pe parent + filtru `parent.team_id`:

```csharp
ExpenseAttachment att = null;
TeamExpense expense = null;
return Session.QueryOver(() => att)
    .JoinAlias(() => att.Expense, () => expense)
    .Where(() => att.Id == attachmentId && expense.TeamId == teamId)
    .SingleOrDefault();
```

Service-layer check (`if (expense.TeamId != teamId) throw`) NU e suficient — e single line of defense. Defense-in-depth cere ca **query-ul însuși să refuze să returneze datele altui tenant**, indiferent de cine îl apelează.

**Clasificare obligatorie în Faza 2 (ARCHITECT):** fiecare entitate primește verdict explicit (vezi „Query Safety Matrix" în SKILL.md Faza 2):
- `Direct tenant-scoped` — are `team_id` → `TenantFilter` în mapping
- `Indirect tenant-scoped` — fără `team_id`, are parent cu `team_id` → query MUST JOIN
- `Global by design` — nu e tenant data (currency rates, user whitelist) → comentariu în mapping

**Motiv:** Service-layer check e fragil — orice cod nou care apelează query-ul direct (skipping service) leak-uiește datele altui tenant. Defense-in-depth la query layer înseamnă că entitatea e protejată prin construcție, nu prin convenție de apelare. Bug-ul nu apare în testele de behavior la endpoint (HTTP-ul răspunde corect pentru cazurile testate), dar e o suprafață de atac latentă pe care nimeni nu o vede.


---

## G9: Cascade behavior pierdut tăcut la conversie soft-delete

### Simptom
La conversia unei entități de la hard-delete la soft-delete, copiii rămân "orphan active" în loc să fie șterși împreună cu părintele. Bug-ul nu apare la build/lint/teste superficiale — apare doar când utilizatorul observă "părintele e șters dar copiii încă apar".

### Cauză
- `Cascade.AllDeleteOrphan`, `Cascade.Delete` în mappings NHibernate triggerează DOAR la `Session.Delete()`
- `ON DELETE CASCADE` în schema SQL triggerează DOAR la DELETE fizic
- Soft-delete (`entity.DeletedAt = NOW; Session.Update`) NU activează niciuna dintre acestea
- Service layer "uită" să șteargă copiii pentru că cascade-ul "era automat"

### Prevenire
- Înainte de orice conversie hard-delete → soft-delete, Faza 2 ARCHITECT trebuie să producă **Cascade Impact Analysis** (vezi SKILL.md §C.5)
- Pentru fiecare relație cu cascade: decide BUSINESS cascade (loop explicit în service) vs păstrează HARD pe copii (rar acceptabil)
- Faza 2 §C.6 **Schema Preflight** rulează automat `hooks/schema-preflight.sh` care identifică toate `Cascade.*` în mappings și `ON DELETE CASCADE` în schema.sql

### Detecție
- Test automat: după soft-delete pe părinte, query pe copii returnează 0 rezultate
- Code review: grep `Cascade.*` în mappings + `ON DELETE` în schema afectate
- Hook automat: `hooks/schema-preflight.sh` flag-ează toate cascade chains la fiecare schimbare de schemă

### Aplicare retroactivă
Pentru fiecare entitate soft-delete existentă, verifică ce cascade chains era afectată anterior și asigură-te că comportamentul e replicat business-side.
