# P&L — Aplicația completă

*PRD Narativ v1.1 — actualizat cu detalii din prototipul Figma Make*

---

## Ce este P&L?

P&L este o aplicație SaaS pentru firmele românești care vor să-și țină cheltuielile sub control. Fiecare firmă (tenant) are propriul spațiu izolat — nu vede datele altei firme.

Aplicația face 4 lucruri mari:
1. **Înregistrează cheltuieli** — manual, din bon scanat (OCR), sau automat (recurente)
2. **Organizează și aprobă** — categorii, subcategorii, flux de aprobare, roluri
3. **Planifică bugete** — buget lunar pe fiecare categorie, import din Excel
4. **Raportează** — P&L Statement lunar, comparații an la an, export Excel

**An fiscal:** Anul fiscal este de 13 luni, **August → August** (nu anul calendaristic). Toate rapoartele, bugetele și comparațiile delta folosesc această perioadă. Luna curentă e evidențiată vizual în tabele.

---

## Cine folosește?

| Rol | Ce face | Exemplu |
|-----|---------|---------|
| **Admin** | Totul: setări firmă, categorii, bugete, aprobări, echipă | CEO, Director financiar |
| **Approver** | Vede toate cheltuielile, aprobă/respinge | Manager departament |
| **Member** | Adaugă cheltuieli proprii, le trimite la aprobare | Angajat obișnuit |
| **Accounting Viewer** | Vede toate cheltuielile, nu poate modifica | Contabil extern |
| **Super-Admin** | Administrare platformă (toate firmele) | Echipa BONO |

---

## Modulele aplicației

### 1. Autentificare

Utilizatorul se loghează în două moduri:
- **Magic Link** — introduce email-ul, primește un link pe email, click pe link și e logat (fără parolă)
- **Google** — se loghează cu contul Google

După logare, primește un token JWT valid 60 de minute. Când expiră, se reîmprospătează automat (refresh token, valid 7 zile).

Nu există parolă clasică.

---

### 2. Firma (Company)

Fiecare echipă/firmă are un profil cu:
- **Datele firmei:** Nume, CUI, Registrul Comerțului, adresă, județ, oraș
- **Date bancare:** Bancă, IBAN
- **Contact:** Telefon, email
- **Brand:** Logo (upload în S3), culori brand (6 culori hex — pentru email-uri și interfață)
- **Setări:** Domenii permise, flux de aprobare activat/dezactivat

Când cineva creează o echipă nouă, devine automat Admin.

---

### 3. Echipa (Members & Invites)

Adminul poate:
- **Invita colegi** — trimite invitație pe email prin Mandrill
- **Seta roluri** — Admin, Approver, Member, Accounting Viewer
- **Scoate membri** din echipă

Invitațiile au statusuri: pending → accepted/rejected/expired.

Există și o **White List** — admin-ul poate pre-aproba accesul anumitor utilizatori (prin email sau token de invitație).

---

### 4. Categorii de cheltuieli

Categoriile sunt **ierarhice** — au un nivel de categorii și un nivel de subcategorii.

Exemplu:
```
Salarii (categorie)
  ├── Salarii brute
  ├── Contribuții angajator
  └── Bonusuri

Marketing (categorie)
  ├── Facebook Ads
  ├── Google Ads
  └── Influenceri
```

Fiecare categorie are: Nume, Părinte (opțional), Ordine sortare, Activ/Inactiv, Tip (label opțional).

**Reguli:**
- Numele e unic per echipă + părinte (nu pot fi două subcategorii cu același nume sub același părinte)
- Ștergerea e în cascadă — dacă ștergi o categorie, subcategoriile se șterg
- Există un endpoint de **seed** — creează categorii default pentru o echipă nouă
- Se pot înlocui toate categoriile printr-un **batch replace**

---

### 5. Cheltuieli (Expenses) — modulul central

Aici se petrece 80% din activitate.

#### Cum adaugă cineva o cheltuială?

**Manual:** Completează un formular cu:
- Sumă (cu/fără TVA, rata TVA, TVA deductibil)
- Moneda (RON, EUR, USD, GBP) — conversia se face automat pe baza cursului BNR
- Furnizor (autocomplete din furnizori folosiți anterior) + CUI furnizor
- Categorie + subcategorie
- Dată cheltuială, număr document, tip document
- Descriere, responsabil, tags
- Atașamente (bon, factură — upload S3)

**Din OCR:** Upload-ezi un bon/factură → Conspectare (serviciu extern) extrage automat: furnizor, CUI, sumă, TVA, dată, număr document. Utilizatorul verifică și confirmă.

**Din recurring:** Cheltuielile recurente generează automat un placeholder lunar. Utilizatorul îl convertește în cheltuială finală.

#### Ciclul de viață al unei cheltuieli

```
Draft → Trimis la aprobare → Aprobat / Respins → Plătit
```

- **Draft** — salvat, nu e vizibil pentru aprobare
- **Submitted** — trimis la aprobare
- **Approved** — aprobat de un Approver sau Admin
- **Rejected** — respins (cu motiv)
- **Paid** — marcat ca plătit

Fiecare tranziție de status e logată în audit trail (cine, când, ce s-a schimbat).

#### Ștergerea

Soft delete — cheltuiala dispare din listă dar rămâne în bază. Dacă era legată de o cheltuială recurentă, la ștergere revine la status "recurent" (placeholder).

#### Duplicate Warning

Sistemul detectează cheltuieli potențial duplicate (pe baza furnizorului, sumei, datei) și afișează un warning.

---

### 6. Cheltuieli recurente (Recurring Expenses)

Un template care generează automat cheltuieli în fiecare lună (sau trimestru, sau an).

Exemplu: "Chiria — 5000 RON — în fiecare lună pe data de 1".

**Ce setezi pe un template:**
- Sumă, monedă, TVA
- Furnizor, categorie, subcategorie
- Tip recurență: lunar / trimestrial / anual
- Ziua lunii (1-28)
- Dată start, dată end (opțional)

**Cum funcționează:**
1. Un job în background (la fiecare oră) verifică toate template-urile active
2. Generează un **placeholder** în tabelul de cheltuieli pentru luna curentă
3. Utilizatorul vede placeholder-ul și îl poate converti în cheltuială finală (draft)
4. Statusuri lunare: inactive → expected → recurent → draft → final

**Versionare:** Când editezi un template, se creează o versiune nouă (versiunea veche rămâne pentru istoric). Poți vedea istoricul versiunilor.

**Match:** Când adaugi o cheltuială manuală, sistemul poate sugera "aceasta seamănă cu template-ul X" (pe baza furnizorului, subcategoriei, sumei ±20%).

---

### 7. Bugete (Budgets)

Fiecare categorie/subcategorie poate avea un buget lunar pe un an fiscal (13 luni, Aug-Aug).

Exemplu: "Marketing > Facebook Ads — 2025 — aug:5000, sep:5000, oct:7000..."

**Cum funcționează:**
- 13 câmpuri lunare (aug-aug) în RON + echivalent EUR calculat automat
- Total anual calculat automat
- Note opționale

**Template Excel:** Sistemul poate genera un fișier .xlsx pre-completat cu toate categoriile și subcategoriile. Utilizatorul îl descarcă, completează sumele offline, și îl re-uploadează.

**Import din Excel:** Upload-ezi un .xlsx (max 5MB), sistemul importă rândurile. Se salvează un audit: câte rânduri importate, câte eșuate, status.

**Batch:** Poți crea/actualiza până la 500 de bugete într-un singur request.

---

### 8. Venituri (Revenues)

O sumă per lună per sursă.

Exemplu: "Mai 2025 — 150,000 RON — Vânzări produse"

Câmpuri: An, lună, sumă, monedă, descriere, sursă.

Regula de unicitate: un singur rând per (echipă, an, lună, sursă).

**Editare inline:** Veniturile se pot edita direct din tabelul P&L (tab-ul Realizat). Click pe celula de venit → introduci suma → save. Nu e obligatoriu să mergi pe o pagină separată.

---

### 9. Raportul P&L (Profit & Loss)

Ecranul principal — "câți bani am câștigat, câți am cheltuit, cât e profitul/pierderea?"

Raportul are **3 tab-uri** pe aceeași pagină:

#### Tab 1: Realizat
Tabelul cu cheltuieli reale — ce s-a cheltuit de fapt.
- **Coloane:** 13 luni (Aug-Aug) + Total anual
- **Rânduri:** Categorii (expandabile) → subcategorii → total categorie
- **Rândul de venituri:** editabil inline — click pe celulă, introduci suma, save
- **Rândul P&L:** venituri − cheltuieli, calculat automat
- **Luna curentă:** evidențiată vizual cu chenar/background special
- **Hover pe coloană:** evidențiază toată coloana

**Drill-down pe facturi:** Click pe o celulă de subcategorie → se deschide un popup cu lista facturilor individuale din acea lună și subcategorie (furnizor, sumă, dată, status).

#### Tab 2: Buget
Același grid, dar arată bugetele planificate pe fiecare categorie/subcategorie/lună.

#### Tab 3: Delta (an la an)
Compară anul curent cu anul trecut:
- Vezi creșteri/scăderi per categorie și per lună
- Diferențele sunt exprimate în sumă absolută și procent

**Toate sumele:** în RON și EUR.

**Export:** Download .xlsx cu tot raportul P&L pe un an.

---

### 10. Curs valutar (Forex)

Toate cheltuielile sunt automat convertite în RON, EUR, USD, GBP pe baza cursului BNR.

- **Sursa primară:** Bono Forex API (intern)
- **Fallback:** XML-ul public BNR
- **Sincronizare:** Automat zilnic la 08:00 UTC, backfill ultimele 7 zile
- **Regulă:** Cheltuielile draft fără curs sunt ignorate silențios. Cheltuielile non-draft fără curs dau eroare.

---

### 11. OCR (Scanare documente)

Utilizatorul upload-ează o factură/bon → sistemul trimite la Conspectare (serviciu extern de OCR) → primește înapoi datele extrase.

**Flux:**
1. Upload atașament pe cheltuială
2. Submit la Conspectare
3. Procesare asincronă (webhook callback cu HMAC-SHA256)
4. Datele extrase: furnizor, CUI, sumă, TVA, dată, tip document
5. Utilizatorul verifică și confirmă

**Recuperare:** Dacă procesarea durează > 30 min, un job (la fiecare 5 min) marchează documentul ca "failed" + logează timeout.

---

### 12. Furnizori (Suppliers)

Autocomplete — când scrii numele unui furnizor, sistemul sugerează din furnizorii folosiți anterior. Salvează și CUI-ul.

---

### 13. Atașamente (Attachments)

Fișiere atașate la cheltuieli (bonuri, facturi, contracte).
- Upload multipart în AWS S3
- Download prin URL pre-semnat (cu expirare)
- Ștergere

---

### 14. Admin (Super-Admin)

Panoul de administrare a platformei (nu al firmei, ci al BONO):
- Vezi toate firmele
- Creează/șterge firme
- Gestionează membri pe orice firmă
- Gestionează super-admini
- Sincronizează manual cursuri valutare
- Backfill cursuri pe un interval

---

### 15. Plan de Conturi (Chart of Accounts)

În secțiunea Profile/Settings, utilizatorul poate configura un **Plan de Conturi** — o structură contabilă standard pe care firma o folosește. Aceasta mapează categoriile de cheltuieli din aplicație pe conturile contabile oficiale.

---

### 16. Audit Trail

Fiecare modificare pe cheltuieli și pe firmă e logată:
- Cine a făcut modificarea
- Ce acțiune (create, update, approve, reject, delete, ocr_timeout)
- Ce s-a schimbat (JSON diff)
- Când

Logurile sunt imutabile — nu se pot modifica sau șterge.

---

## Design System — Apple Liquid Glass

Interfața urmează un design "frosted glass" inspirat de Apple, nu shadcn/ui default.

**Principii vizuale:**
- **Fundal:** gradient-uri subtile cu efect de sticlă mată (backdrop-filter: blur)
- **Carduri:** semi-transparente, cu umbre soft și border-radius generos
- **Culoare primară:** Teal — folosită pentru accente, calendare, luna curentă
- **Dark mode:** suportat complet prin next-themes
- **Tabele P&L:** grid cu highlighting pe coloana curentă, hover pe rânduri, celule editabile cu focus state vizibil

**Calendare și date-picker-e:** toate folosesc tema teal (nu default shadcn).

**Componentele specifice:** popup-ul de facturi (drill-down), formularul inline de revenue, badge-urile de status pe cheltuieli — toate urmează stilul frosted glass cu umbre și transparențe.

---

## Stack-ul real (din cod, nu din presupuneri)

**Backend** (`SRV.Bono.PnL`):
- .NET 10 + ASP.NET Core 10
- NHibernate 5.6 + FluentNHibernate 3.4
- MariaDB 10.x+ (utf8mb4)
- AWS S3 (atașamente, logo-uri)
- Mandrill (email-uri)
- Conspectare (OCR)
- Bono Forex API + BNR (cursuri valutare)
- CQRS pattern, OperationResult<T>

**Frontend** (`WEB.Bono.PnL`):
- Next.js 15 (App Router, standalone)
- React 19 + TypeScript 5
- Tailwind CSS 3.4 + shadcn/ui (New York) + Radix UI
- TanStack React Query 5
- Recharts 2.15
- next-themes (dark mode)
- Design System "The Edge" (Bono Fintech tokens)
- Playwright (E2E tests)

**Rute frontend** (din `app/dashboard/[teamId]/`):
- `/` — Dashboard principal
- `/expenses` — Lista cheltuieli
- `/expenses/new` — Cheltuială nouă
- `/expenses/[id]` — Detaliu cheltuială
- `/expenses/recurring/new` — Recurring nou
- `/expenses/recurring/[id]` — Detaliu recurring
- `/expenses/categories` — Categorii
- `/budget` — Bugete
- `/pnl` — Raport P&L
- `/delta` — Comparație an la an (în prototip apare ca tab pe pagina P&L, nu pagină separată — de clarificat)
- `/company` — Setări firmă
- `/company/roles` — Roluri
- `/company/settings` — Configurare
- `/team` — Echipă
- `/profile` — Profil utilizator
- `/settings` — Setări

---

## Ce am aflat diferit față de testul SuperNicu

| Aspect | Ce am presupus în test | Ce e de fapt |
|--------|----------------------|--------------|
| Baza de date | PostgreSQL + RLS | **MariaDB** + NHibernate filter pe team_id |
| Framework frontend | React + Vite (SPA) | **Next.js 15** (App Router, SSR) |
| Categorii | Flat (un nivel) | **Ierarhice** (categorie + subcategorie) |
| Multi-tenant | RLS pe tenant_id | **X-Team-Id header** + NHibernate tenantFilter |
| Roluri | Implicit admin/user | **5 roluri** cu matrice de permisiuni |
| Bugete | Nu exista | **Buget lunar per categorie** cu import Excel |
| Recurring | Nu exista | **Template-uri cu versionare** + auto-generare |
| OCR | Nu exista | **Conspectare integration** cu webhook |
| Venituri | Nu exista | **Revenue per lună per sursă** |
| Monedă | Single currency | **Multi-currency** (RON/EUR/USD/GBP) + BNR |
| Server actions | httpClient direct | **Next.js server actions** (app/actions/) |
| An fiscal | Implicit calendar (jan-dec) | **13 luni Aug-Aug** |
| Design System | shadcn/ui default | **Apple Liquid Glass** (frosted, blur, teal) |
| P&L view | Pagină simplă | **3 tab-uri** (Realizat/Buget/Delta) cu inline edit |

---

## Întrebări pentru Bogdan

1. **PRD-ul ăsta acoperă tot?** Am extras din ambele repo-uri (backend + frontend). Lipsește ceva din perspectiva ta de produs?

2. **Prioritizare module.** Dacă SuperNicu generează aplicația, în ce ordine? Eu aș zice:
   - P0: Auth + Company + Categories + Expenses (core)
   - P1: Recurring + Budgets + P&L Statement
   - P2: OCR + Forex + Export

3. **Skills SuperNicu.** Testul pe Categories a presupus un stack diferit (Vite, PostgreSQL, RLS). Realitatea e Next.js 15 + MariaDB + NHibernate. Skills-urile trebuie rescrise înainte de a genera cod real. Asta e pasul următor?

4. **Ce e scopul SuperNicu?** Generează module noi pe aplicația existentă? Sau reconstruiește tot de la zero?
