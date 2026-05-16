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


---

## G10: Secrets cu fallback hardcoded — "?? default" pattern

**Trigger:** Cod care încarcă secret/cheie/parolă din config cu fallback hardcoded:
```csharp
var jwtKey = jwtOptions.SecretKey ?? "dev-secret-key-min-32-characters!!";  // ❌
var dbPass = config["Db:Password"] ?? "changeme";                            // ❌
var apiKey = Env.Get("STRIPE_KEY") ?? "sk_test_default";                     // ❌
```

**Instrucțiune:**
Secrets sunt OBLIGATORII din config — nu există fallback. Dacă lipsesc, aplicația crashează la startup, NU continuă cu valoare default:

```csharp
var secretKey = jwtOptions.SecretKey;
if (string.IsNullOrEmpty(secretKey))
    throw new InvalidOperationException(
        "Jwt:SecretKey MUST be set in env. No fallback.");
var jwtKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
```

Aplicabil pentru: JWT keys, DB passwords, third-party API keys (Stripe, Mandrill, Sentry), encryption keys, OAuth client secrets.

**Excepție:** valori care NU sunt secrets (timeouts, max retries, feature flags) pot avea fallback. Regula se aplică DOAR la `*Secret*`, `*Key*`, `*Password*`, `*Token*`, `*Pass*` (case-insensitive).

**Detecție:** hook `hooks/secrets-scan.sh` flag-ează pattern-ul `?? "..."` în Program.cs / Startup.cs / fișiere de configurare DI.

**Motiv:** Dacă repo-ul devine public (accidental sau breach), atacatorul vede cheia default. Production care nu setează env var-ul folosește default-ul. JWT-uri pot fi forjate, DB poate fi accesat, third-party services pot fi abuzate. Fallback-ul nu e „defensive coding" — e backdoor permanent în production.

## G11: Auth tokens în URL query string

**Trigger:** Endpoint care primește token de auth (magic link, password reset, email verify, accept invitation) din URL query string:
```csharp
[HttpGet("accept")]
public async Task<IActionResult> Accept([FromQuery] string token) { ... }  // ❌
```

Sau în frontend:
```typescript
apiFetch(`/api/admin/v1/whitelist/accept?token=${token}`)  // ❌
```

**Instrucțiune:**
Tokens de auth se transmit ÎN BODY POST sau în header `Authorization`, niciodată în URL (query, path, fragment):

```csharp
[HttpPost("accept")]
public async Task<IActionResult> Accept([FromBody] AcceptRequest req) { ... }  // ✓

public record AcceptRequest(string Token);
```

```typescript
apiFetch("/api/admin/v1/whitelist/accept", {
    method: "POST",
    body: JSON.stringify({ token })
})  // ✓
```

**Detecție:** hook `hooks/secrets-scan.sh` flag-ează:
- Backend: `[FromQuery]\s+string\s+(token|otp|code|magic|verify|reset)`
- Frontend: `?token=`, `?otp=`, `?code=` în calls API

**Motiv:** URL-urile sunt logate peste tot: access logs (server + reverse proxy + CDN), browser history, `Referer` header către third-party (analytics, fonts CDN), bookmarks, share buttons. Token one-time-use din magic link **e mortal dacă e capturat înainte de utilizare**. Plus: query strings ajung uneori în error tracking (Sentry) cu URL-ul complet.

## G12: Public-auth endpoint fără rate limit + timing oracle

**Trigger:** Endpoint cu `[AllowAnonymous]` care validează un secret/token/credentiale (login, magic-link validate, accept invitation, password reset request, email verify).

**Instrucțiune:**
Toate endpoint-urile public-auth necesită TREI elemente:

1. **Rate limiting** — `[EnableRateLimiting("public-auth")]` cu policy comună (ex: 10 req/min per IP):
```csharp
[HttpPost("validate")]
[AllowAnonymous]
[EnableRateLimiting("public-auth")]
public async Task<IActionResult> Validate([FromBody] ValidateRequest req) { ... }
```

2. **Răspuns unified** — toate cazurile invalide returnează același status + mesaj generic. NU distinge între „not found", „expired", „already used", „malformed":
```csharp
// ❌ leak info atacatorului
if (token == null) return NotFound("Token not found");
if (token.ExpiresAt < DateTime.UtcNow) return BadRequest("Token expired");
if (token.UsedAt != null) return Conflict("Token already used");

// ✓ unified
if (token == null || token.IsInvalid())
    return NotFound(new { error = "Invalid or expired token" });
```

3. **Audit log per attempt** — IP + timestamp + outcome (success/fail), pentru detection post-factum a brute-force attempts:
```csharp
await _audit.LogPublicAuthAttempt(ip: ctx.Connection.RemoteIpAddress,
                                  endpoint: "whitelist/validate",
                                  outcome: AuditOutcome.TokenInvalid);
```

**Detecție:** hook `hooks/secrets-scan.sh` listează endpoint-uri `[AllowAnonymous]` și verifică prezența `[EnableRateLimiting]` pe aceeași metodă.

**Motiv:** Fără rate limit, atacator testează mii de tokens UUID/min — chiar dacă spațiul e mare, sample suficient + brute force paralel. Timing diferit între not-found/expired/used = enumeration oracle (atacatorul deduce care UUID-uri au existat vreodată). Lipsa audit log = nu detectezi atacul nici post-factum.

## G13: Long-lived credentials externe în memorie

**Trigger:** Inițializare de client pentru serviciu extern (AWS S3, Stripe, Mandrill, third-party API) cu chei permanent valide din config, fără rotation/expiry:

```csharp
var accessKey = config["Storage:AccessKey"] ?? "";
var secretKey = config["Storage:SecretKey"] ?? "";
return new AmazonS3Client(accessKey, secretKey, s3Config);  // ❌ keys live forever
```

**Instrucțiune:**
Pentru fiecare serviciu extern, Faza 2 ARCHITECT documentează **explicit** alegerea:

**Opțiune A — IAM Instance Role / Workload Identity (preferat):**
```csharp
return new AmazonS3Client(s3Config);  // SDK detectează automat din metadata
```
Credentials sunt injectate de Railway/AWS/GCP prin instance metadata. Rotație automată.

**Opțiune B — STS Short-lived Tokens:**
```csharp
var sts = new AmazonSecurityTokenServiceClient(...);
var creds = await sts.AssumeRoleAsync(new AssumeRoleRequest {
    RoleArn = config["Storage:S3RoleArn"],
    RoleSessionName = "pnl-api-session",
    DurationSeconds = 3600  // 1h
});
return new AmazonS3Client(creds.Credentials, s3Config);
```
Token valid 15min-1h, regenerat la expirare.

**Opțiune C — Long-lived keys (justificat scris):**
Doar dacă A și B nu sunt suportate de platforma de deploy. Documentează:
- De ce A/B nu funcționează
- Politica de rotation (cât de des, automat sau manual)
- Cum sunt revocate la breach

**Faza 2 ARCHITECT — secțiune nouă „External Services Credentials":**
Tabel obligatoriu cu o linie per serviciu extern:

| Serviciu | Mecanism | Rotation | Justificare (dacă C) |
|----------|----------|----------|---------------------|
| AWS S3 | IAM Role | Automat | — |
| Mandrill | API Key | Manual la 90 zile | Mandrill nu suportă STS |

**Motiv:** RCE pe pod → heap dump → extragere keys. Long-lived keys = blast radius mare (atacatorul are credentials valide până la rotation manual). STS/IAM Role = blast radius mic (15min-1h valabilitate). În production fintech, asta e diferența între incident contained și breach raportat la ANSPDCP.


---

## G14: Match the gate to the decision — fail-open negation

**Trigger:** Gate logic pentru feature opt-in sau write, scrisă cu negație:
```csharp
if (companyType != "PFA") { AssignDefaultLawyer(); }   // ❌ fail-open
if (role != Role.Customer) { ApplyAdminPolicy(); }      // ❌ fail-open
if (!entity.IsDeleted) { Process(entity); }             // contextual — vezi mai jos
```

**Instrucțiune:**
Folosește **positive equality** pentru opt-ins, write, decisive actions:
```csharp
if (companyType == "PFI") { AssignDefaultLawyer(); }   // ✓ explicit opt-in
if (role == Role.Admin) { ApplyAdminPolicy(); }         // ✓
```

Rezervă negația DOAR pentru polymorphic fall-through unde default branch trebuie să accepte orice tip nou (ex: serializare generică, switch-default care delegă la PFA „safety net").

**Detecție pre-edit:**
- În Faza 2 (ARCHITECT): pentru fiecare decizie nouă în Authorization Matrix și Strategy Factory, confirm explicit „positive equality?" sau „polymorphic fall-through cu motiv?".
- Grep regex (post-edit, în Faza 4 Stratul B): `if\s*\([^)]+!=\s*["\w]+\)` în fișiere de business logic — fiecare match cere justificare.

**Motiv:** Negația fail-opens silent. Când adaugi un tip nou (`companyType = "Microenterprise"`), branch-ul negat îl înghite tăcut — comportament schimbat fără modificare de cod. Bug-ul nu apare la teste pentru valorile cunoscute, apare doar când business-ul adaugă un caz nou peste 6 luni. „Behavior change without code change" e cel mai greu de debuggat — nu există commit care să dea direcția.

## G15: Fail loudly at category boundaries — no benign default for misuse

**Trigger:** Funcție/metodă care returnează benign default (empty list, null, zero, false, empty string) când e apelată într-un context unde NU se aplică logic:
```csharp
public class PfaRegistrationStrategy : IRegistrationFlowStrategy
{
    // PFI strategy implementează asta; PFA nu — n-are documente semnabile separate
    public string[] GetSignableDocumentCodes() => Array.Empty<string>();  // ❌
}
```

**Instrucțiune:**
Aruncă `NotSupportedException` / `InvalidOperationException` / domain-specific exception la „shouldn't be reachable":
```csharp
public string[] GetSignableDocumentCodes()
    => throw new NotSupportedException(
        "PFA flow doesn't use separate signable documents — check strategy resolution");
```

Rezervă benign defaults DOAR pentru outcomes care sunt **răspunsuri valide de domeniu**:
- ✓ `FindActiveExpenses()` → empty list (zero expense-uri active e răspuns valid)
- ✓ `GetUserById(id)` → null (user not found e răspuns valid)
- ❌ `GetSignableDocumentCodes()` pe strategy unde nu se aplică → empty (caller crede că nu are documente, dar de fapt era pe strategy greșită)

**Test:** poate same return value să însemne SIMULTAN „no data", „operation not applicable" și „error happened"? Dacă da → throw, nu return.

**Motiv:** Caller-ul nu poate distinge `Array.Empty` „nu sunt documente" de `Array.Empty` „strategy greșită" de `Array.Empty` „config missing". Bug-ul arată identic cu comportamentul așteptat. Silent corruption beats loud failure — debug-ul costă ore în loc de secunde.

## G16: Contract change fără exhaustive call-site audit

**Trigger:** Modifică signature/return type/contract semantics al unei metode publice sau response DTO. Exemple:
- Adaugă param obligatoriu la metodă publică
- Schimbă sursa lui `nextPageCode` din hardcoded în strategy-driven
- Redenumește field în response DTO
- Schimbă semantica unui flag (era nullable, devine non-null)

**Instrucțiune (pre-edit, MANDATORY):**

ÎNAINTE de a edita signature-ul:
```bash
grep -rn "MethodName\|FieldName\|nextPageCode" --include="*.cs" --include="*.ts" --include="*.tsx" .
```

1. Listează **toate** call sites în output.
2. Editează signature + ALL call sites în **același commit**, sau split explicit:
   - Commit 1: „Add new contract (backward compat)"
   - Commit 2: „Migrate all callers"
   - Commit 3: „Remove old contract"
3. NICIODATĂ commit cu signature schimbat + 2 call sites updated + 5 stale.

**Detecție post-hoc:** Compounding Trigger (Faza 3) prinde recurența — dar costul e mai mare (smoke testing surfaces gaps separat pe 3-4 tickete).

**Motiv:** Primul call site găsit e rareori singurul. AI patch-uiește unul-două, ratează restul. Bug-urile apar separat în săptămâni — o oră de smoke test fiecare, plus context-switching. Pre-edit grep transformă „găsim bug-urile pe rând" în „edităm toate locațiile o dată". Diferența: 1h vs 8h pe aceeași schimbare.

**Anti-pattern:** „edit incremental — repar fiecare loc când îl găsesc". Nu funcționează — pierderile se acumulează silent în smoke testing.

## G17: Overloaded flag inheritance — intent vs mechanism

**Trigger:** Flag existent (boolean / enum / status / nullable field) folosit de **multiple consumers cu intent diferit**. Flow nou auto-satisface flag-ul mecanic, dar nu intenționa să opt-in pe TOATE comportamentele.

Exemplu real (PFI-FE-8):
```csharp
// PFA: lawyer-ul a verificat user-ul offline → skip Veriff KYC
if (isCompanyLawyer && hasAcceptedCollaboration) {
    SkipVeriffCheck();
}

// PFI: auto-assigned lawyer cu auto_approve=true setează AMÂNDOUĂ flag-urile by design
// (motivul: skip „așteaptă lawyer să accepte" gate, NU skip Veriff KYC)
// Rezultat: PFI users inherit Veriff skip silent → IdCard null → crash la BuildIdentityDocument
```

**Instrucțiune:**
Când flow nou setează un flag existent, audit fiecare consumer pentru **INTENT** (de ce a fost adăugat flag-ul) vs **MECHANISM** (ce face setarea lui):

1. Grep toate consumer-ele flag-ului:
   ```bash
   grep -rn "isCompanyLawyer\|hasAcceptedCollaboration" --include="*.cs"
   ```
2. Pentru fiecare consumer, întreabă: „flow-ul meu nou vrea explicit acest comportament?"
3. Dacă răspunsul e NU pe vreun consumer → refactor:
   - Split flag-ul în 2 (`lawyerVerifiedUserOffline` + `lawyerAcceptedCollaboration`), sau
   - Add explicit opt-in (`skipVeriffOnLawyer=true`), sau
   - Inverse-check pe noul flow (`if (companyType != "PFI" && isCompanyLawyer && ...)`)

**Detecție:** nu se poate detecta cu hook generic — necesită human audit per flag. Faza 2 ARCHITECT include în Authorization Matrix coloana „Flags utilizate" cu trigger pentru reaudit la fiecare flow nou.

**Motiv:** Cel mai scump bug pe care AI îl scrie — fast to introduce (one-line change în flow nou), slow to find (null ref în BuildIdentityDocument ore mai târziu, fără legătură aparentă cu flow-ul nou). Numele flag-ului reflectă intent-ul autorului, nu interpretarea fiecărui consumer. La PFI: 6h manual debug pentru un single-line fix.

## G18: Refactor care „simplifică" hides side effects

**Trigger:** Propunere de refactor care „simplifică" un switch / chain de conditionals / branch complex în abstracție clean. Reducere semnificativă de linii (200 → 20).

Exemplu real (PFI-3.2):
```csharp
// PFA's existing 200-line switch în GetWorkflowPath
switch (currentStep) {
    case "BUSAC":
        var marketing = InjectMarketingHints(...);  // side effect 1
        next = "CMHQ"; break;
    case "CMHQ":
        if (does_need_physical_address) next = "LAWYR";  // branching
        else next = "ABNM"; break;
    case "PAYMT":
        if (paymentState == "completed") next = "KYC";  // payment gating
        else next = "PAYMT"; break;
    // ... + 6 alte cazuri cu side effects subtile
}

// Refactor propus „simplifică":
public StepCode GetNextStep(StepCode current) =>
    _steps.SkipWhile(s => s != current).Skip(1).FirstOrDefault();  // ❌ DROPS toate side-effects
```

**Instrucțiune:**
ÎNAINTE de a accepta refactor-ul, audit explicit ce protejează messiness-ul:

1. Listează fiecare:
   - Injection point (logging, marketing, telemetry inserate în branch)
   - Branching condition (decizii care nu apar în signature)
   - Side-effect emit (event raise, cache invalidate, audit log)
   - Special-case fallback (codul care prinde edge case-uri nedocumentate)

2. Pentru fiecare item: confirm că abstracția propusă îl preserves explicit.

3. Dacă abstracția nu poate → **narrow abstraction-ul** (mai puține responsabilități), nu drop messiness-ul.

Exemplu narrow:
```csharp
// Nu „GetNextStep" generic — prea ambitios.
// Doar „GetStepNeighbors" pentru flow-uri liniare (PFI, viitoare).
// PFA's 200-line switch RĂMÂNE intact pentru că are messiness real.
public (StepCode? Prev, StepCode? Next) GetStepNeighbors(StepCode current);
```

**Motiv:** „A clean abstraction that hides side effects is worse than a messy switch that shows them." Codul mizerabil care funcționează > codul curat care silent regressses. Cele 180 linii „eliminate" conțin probabil 30 linii de logică reală pe care nimeni nu le va detecta lipsa până la production. „Simplification" e tentation, nu mereu îmbunătățire — întreabă „de ce a fost scris așa?" înainte să decizi că autorul a greșit.

**Anti-pattern:** „codul vechi e urât, deci e greșit." Codul urât e adesea urât pentru că realitatea pe care o modelează e urâtă. Refactor-ul nu schimbă realitatea.
