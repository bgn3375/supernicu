# Nicu Specs — Reguli acumulate

Regulile se adaugă după fiecare retrospectivă, cu aprobarea utilizatorului.

---

## Reguli inițiale (2026-05-10)

**R1-UI**: Orice componentă non-standard (nu input/select/textarea) primește micro-spec cu toate proprietățile CSS: container, dimensiuni, culori, border, radius, font, iconuri, stări (activ/inactiv/hover/disabled).

**R2-ORDINE**: Câmpurile se numerotează strict 1..N. Ordinea din tabel = ordinea din pagină. Verificare câmp cu câmp, de sus în jos. Orice diferență = blocker.

**R3-SPACING**: Fiecare distanță se notează în pixeli: "ElementA → ElementB: Npx". Se includ: padding container, gap-uri, margin-uri, width-uri fixe, height-uri.

**R4-STATE**: Orice schimbare de state care afectează alt câmp se documentează: trigger → efect → valoare nouă. Include: pre-fill, reset, disable, show/hide, toggle.

**R5-CALCUL**: Orice auto-calcul: trigger (eveniment), condiție (câte câmpuri), formulă exactă, câmpuri afectate, stare inițială (ce e pre-filled).

**R6-DS-MAP**: Fiecare element primește referința DS exactă (.input, .btn.primary) sau "NON-STANDARD" cu spec completă. Nu "similar cu" — exact sau specificat complet.

**R7-TABEL**: Coloane numerotate, aliniament notat, lățimi specificate, truncare marcată, row height, hover, border-uri.
