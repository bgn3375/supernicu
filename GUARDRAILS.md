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
