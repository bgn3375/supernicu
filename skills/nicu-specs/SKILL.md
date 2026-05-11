# nicu-specs

Owner-ul contractului dintre Bruce (PRD + prototip) și SuperNicu (implementare). Produce specificații complete și verificabile per pagină/feature.

## Când se activează

**Moment 1 — PRE-IMPLEMENTARE**: Imediat după ce primește PRD + prototip, ÎNAINTE ca nicu-frontend sau nicu-backend să scrie cod.

**Moment 2 — POST-IMPLEMENTARE**: După ce nicu-qa confirmă că build-ul e ok. Analizează procesul și propune reguli noi.

---

## MOMENT 1: Analiza și specificații

### Input

1. PRD funcțional
2. Prototip UI (fișiere TSX din prototype-reference)
3. Design System (`shared/bono-ds.css` — tokeni, clase, componente)
4. Cod existent (pentru a ști ce există deja)

### Ce face Nicu Specs

1. **Citește prototipul** — fișier cu fișier, componentă cu componentă
2. **Măsoară totul** — ca un plan tehnic de arhitectură cu cote
3. **Mapează la Design System** — fiecare element primește referința DS sau notarea "non-standard". Dacă prototipul diferă de DS, SPEC-ul documentează ce e în prototip (prioritar) și notează diferența
4. **Identifică ambiguități** — ce nu e clar din PRD sau prototip
5. **Produce SPEC per pagină** — document structurat, fiecare linie verificabilă
6. **Cere clarificări** — prezintă lista de întrebări utilizatorului ÎNAINTE de implementare

### Output: SPEC-[pagina].md

Fiecare SPEC are secțiunile de mai jos. Documentul poate fi lung — de aceea are **structură duală**:

1. **Spec detaliat** — explicații complete, context, referințe DS, micro-specs. Brain (nicu-frontend) citește asta ca să înțeleagă ce construiește.
2. **CHECKLIST per secțiune** — extras scurt, concret, bifabil. Imediat după fiecare secțiune de spec. Brain bifează pe măsură ce implementează. Hands (nicu-review) bifează independent la verificare.

### Regula output-ului dual

La SFÂRȘITUL fiecărei secțiuni din spec, Nicu produce un bloc `### ✓ CHECKLIST S[N]` cu items scurte (max 1 linie fiecare). Acest checklist:
- **Brain** îl primește ca ToDo — implementează și bifează fiecare item
- **Hands** îl primește ca verificare — bifează independent, fără să vadă ce a bifat Brain
- Dacă Brain bifează 10/10 dar Hands găsește un item nebifat → discrepanță = fix necesar

Format checklist:
```markdown
### ✓ CHECKLIST S3: Câmpuri formular
- [ ] #1 Descriere = textarea h=60, placeholder "Descriere cheltuiala"
- [ ] #2 Tags = input text, placeholder "#tags"
- [ ] #3 Cont = select, placeholder "Alege cont"
- [ ] #6 TVA Deductibil = pill toggle dark (NU select nativ)
- [ ] Ordine strictă: 1→2→3→4→5→6→7→8→9→10
- [ ] Niciun câmp lipsă, niciun câmp în plus
```

Checklist-ul repetă esențialul din spec, nu detaliile. E "lista de control rapid" — dacă ceva nu e clar, agentul se duce la secțiunea detaliată de spec.

---

## FORMAT SPEC

### Secțiunea 1: Layout pagină

Schema vizuală ASCII cu secțiunile principale și cotele între ele.

```markdown
## 1. Layout pagină

- [ ] Fundal pagină: `bej-0` (#FBFAF7)
- [ ] Container: maxWidth=1200, margin=0 auto
- [ ] Padding pagină: 8px 64px 24px

### Secțiuni (ordine sus → jos):
- [ ] S1: Header bar — card-hairline, marginBottom=8
- [ ] S2: Câmpuri document — card-tonal, marginBottom=8
- [ ] S3+S4: Două coloane flex, gap=24
  - [ ] S3 stânga: Formular — card-tonal, flex=1
  - [ ] S4 dreapta: Upload — card-tonal, flex=1
```

Imediat după spec, checklist-ul:

```markdown
### ✓ CHECKLIST S1: Layout pagină
- [ ] bg = bej-0
- [ ] maxWidth = 1200, centrat
- [ ] Padding = 8px 64px 24px
- [ ] S1 header = card-hairline, mb=8
- [ ] S2 document = card-tonal, mb=8
- [ ] S3+S4 = flex coloane, gap=24
```

### Secțiunea 2: Per secțiune — container și padding

```markdown
## 2. Secțiuni

### S1: Header bar
- [ ] Tip: `card-hairline` (white bg, 1px solid rule-card, r-md)
- [ ] Padding: 12px 20px
- [ ] Layout: flex, alignItems=center, gap=20, flexWrap=wrap
- [ ] MarginBottom: 8px
```

Imediat după spec, checklist-ul:

```markdown
### ✓ CHECKLIST S2: Secțiuni
- [ ] S1: card-hairline, p=12px 20px, flex center gap=20
- [ ] S2: card-tonal, p=20px 48px, flex gap=12
- [ ] S3: card-tonal, p=20px 48px
- [ ] S4: card-tonal, p=40px, centrat vertical
```

### Secțiunea 3: Câmpuri — tabel verificabil

Fiecare câmp = un rând verificabil. **Ordinea e strictă — # = poziția reală.**

```markdown
## 3. Câmpuri formular (ordine STRICTĂ)

Layout rând:
- [ ] Gap label → input: 20px
- [ ] Label width: 100px, flexShrink=0, paddingLeft=0
- [ ] Gap între rânduri: marginBottom=16
- [ ] AlignItems: center (excepție: Descriere = flex-start)

| # | Label | Componentă | Placeholder | Default | Vizibil când |
|---|-------|-----------|-------------|---------|-------------|
| 1 | Descriere | textarea .input h=60 | "Descriere cheltuiala" | "" | mereu |
| 2 | Tags | input text .input | "#tags" | "" | mereu |
| 3 | Cont | select .input | "Alege cont" | "" | mereu |
| ...

Verificare ordine:
- [ ] Câmpul #1 (Descriere) este primul din pagină
- [ ] Câmpul #2 (Tags) este imediat sub #1
- [ ] ...
- [ ] Niciun câmp lipsă față de tabel
- [ ] Niciun câmp în plus față de tabel
```

Imediat după spec, checklist-ul:

```markdown
### ✓ CHECKLIST S3: Câmpuri formular
- [ ] #1 Descriere = textarea h=60, placeholder "Descriere cheltuiala"
- [ ] #2 Tags = input text, placeholder "#tags"
- [ ] #3 Cont = select, placeholder "Alege cont"
- [ ] #4 Subcont = select, disabled când Cont gol
- [ ] #5 Perioadă = MonthPicker, default luna curentă
- [ ] #6 TVA Deductibil = PILL TOGGLE (nu select nativ!)
- [ ] #7 Sumă cu TVA = MoneyInput + LeiBadge
- [ ] #8 Sumă fără TVA = MoneyInput + LeiBadge (doar când Da)
- [ ] #9 TVA = MoneyInput + RateBadge + LeiBadge (doar când Da)
- [ ] #10 Salvează = btn primary centered, mt=24
- [ ] Ordine strictă: 1→2→3→4→5→6→7→8→9→10
- [ ] Niciun câmp lipsă, niciun câmp în plus
- [ ] Layout rând: label w=100, gap=20, mb=16
```

### Secțiunea 4: Micro-spec componente non-standard

Orice componentă care NU e un simplu input/select/textarea primește o micro-spec completă.

```markdown
## 4. Componente non-standard

### 4.1 TVA Deductibil — pill toggle
- [ ] Container: flex=1, h=42, p=4, bg=white, border=1px rule-soft, r=pill
- [ ] Buton activ: flex=1, h=34, bg=dark, color=white, r=pill, fontSize=14, fw=400
- [ ] Buton "Da" activ: include CheckCircle size=15 color=success
- [ ] Buton "Nu" activ: fără icon
- [ ] Buton inactiv: bg=transparent, color=fog
- [ ] Tranziție: all 140ms
- [ ] NU este select nativ

### 4.2 MoneyInput
- [ ] Bază: .input (h=40, r-lg)
- [ ] Text: textAlign=right, paddingRight=88
- [ ] Format: "1.234,56" românesc (punct mii, virgulă decimale)
- [ ] Decimale overlay: fontSize=10, color=mist
- [ ] Câmp calculat: bg=bej-0
- [ ] InputMode: decimal
```

Imediat după spec, checklist-ul:

```markdown
### ✓ CHECKLIST S4: Componente non-standard
- [ ] TVA Deductibil = pill toggle (container h=42 p=4 white, buton activ h=34 dark)
- [ ] Buton "Da" activ are CheckCircle verde
- [ ] MoneyInput = textAlign right, paddingRight=88, format românesc
- [ ] LeiBadge = absolute right=8, pill, "Lei 🇷🇴"
- [ ] RateBadge = absolute left=8, pill, clickable, toggle 11/21%
- [ ] Decimale overlay = fontSize=10, color=mist
```

### Secțiunea 5: Stare inițială și pre-fill

```markdown
## 5. Stare și comportament

### Pre-fill la acțiuni:
- [ ] Când TVA Deductibil → "Da": cotaTVA = "21", marcat ca user-edited
- [ ] Când TVA Deductibil → "Nu": sumaFarăTVA="", tva="", cotaTVA="" — golite
- [ ] Când se selectează Cont: Subcont se resetează la ""
- [ ] Perioadă: default = luna curentă

### Vizibilitate condiționată:
- [ ] Sumă fără TVA: vizibil doar când tvaDeductibil=Da
- [ ] TVA + RateBadge: vizibil doar când tvaDeductibil=Da
- [ ] Subcont: disabled (opacity=0.5) când Cont=""
```

Imediat după spec, checklist-ul:

```markdown
### ✓ CHECKLIST S5: Stare și comportament
- [ ] Da → cotaTVA pre-fill "21", marcat user-edited
- [ ] Nu → golește sumaFarăTVA, tva, cotaTVA
- [ ] Selectare Cont → resetează Subcont
- [ ] Perioadă default = luna curentă
- [ ] Sumă fără TVA vizibil doar când Da
- [ ] TVA vizibil doar când Da
- [ ] Subcont disabled când Cont gol
```

### Secțiunea 6: Auto-calcul și formule

```markdown
## 6. Auto-calcul

### Trigger:
- [ ] Se declanșează la blur pe orice câmp din {sumaCuTVA, sumaFaraTVA, tva, cotaTVA}
- [ ] Condiție: cel puțin 2 câmpuri au valoare (inclusiv cotaTVA pre-filled)

### Formule:
- [ ] sumaCuTVA + cotaTVA → sumaFaraTVA = sumaCuTVA / (1 + rata), tva = sumaCuTVA - sumaFaraTVA
- [ ] sumaFaraTVA + cotaTVA → tva = sumaFaraTVA * rata, sumaCuTVA = sumaFaraTVA + tva
- [ ] sumaCuTVA + sumaFaraTVA → tva = sumaCuTVA - sumaFaraTVA, rata = tva / sumaFaraTVA

### Rate valide:
- [ ] Doar 11% sau 21%
- [ ] RateBadge click: toggle între 11 și 21, recalculează imediat
- [ ] Rată invalidă: mesaj eroare sub câmpul TVA
```

Imediat după spec, checklist-ul:

```markdown
### ✓ CHECKLIST S6: Auto-calcul
- [ ] Trigger = blur pe sumaCuTVA / sumaFaraTVA / tva / cotaTVA
- [ ] Condiție = minim 2 câmpuri cu valoare
- [ ] cotaTVA pre-filled la "Da" contează ca câmp cu valoare
- [ ] sumaCuTVA + rata → calculează celelalte 2
- [ ] Rate valide: doar 11% sau 21%
- [ ] RateBadge click = toggle + recalcul imediat
- [ ] Rată invalidă = mesaj eroare
```

### Secțiunea 7: Culori și tipografie (mapare DS)

**Prioritate: Prototip > Design System.** Dacă prototipul folosește o culoare/dimensiune diferită de DS, SPEC-ul documentează valoarea din prototip și notează diferența. Implementarea urmează prototipul.

```markdown
## 7. Culori și tipografie

### Culori suprafețe (din prototip — diferențele față de DS sunt notate):
- [ ] Pagină bg: bej-0 (#FBFAF7)
- [ ] Card hairline: white bg + 1px rule-card
- [ ] Card tonal: bej-1 bg, fără border
- [ ] Input bg: white
- [ ] Input border: rule-card (ink @ 12%)
- [ ] Elementele care lipsesc din prototip folosesc tokeni DS
- [ ] Niciun gradient

### Tipografie:
- [ ] Titlu pagină: .t48
- [ ] Label câmp formular: .field-label (12px/550, 0.04em, fog) cu paddingLeft=0
- [ ] Label câmp document: .field-label standard (cu paddingLeft=16)
- [ ] Label header meta: 10px/500, 0.04em, fog
- [ ] Valori header: 13px, ink, greutate variabilă
- [ ] Placeholder input: mist (#ABA59E)
- [ ] Fonturi: doar Inter (excepție: Fraunces italic pe em în titluri)
```

Imediat după spec, checklist-ul:

```markdown
### ✓ CHECKLIST S7: Culori și tipografie
- [ ] bg pagină = bej-0, carduri tonal = bej-1, carduri hairline = white
- [ ] Input bg = white, border = rule-card
- [ ] Zero culori hardcoded, zero gradienturi
- [ ] Titlu = .t48
- [ ] Labels formular = .field-label cu paddingLeft=0
- [ ] Labels document = .field-label standard (paddingLeft=16)
- [ ] Placeholder = mist
- [ ] Font = Inter (Fraunces doar pe em în titluri)
```

### Secțiunea 8: Spacing — planul cu cote

Cea mai importantă secțiune. Fiecare distanță măsurată și verificabilă.

```markdown
## 8. Spacing (cote)

### Pagină:
- [ ] Padding pagină: 8px sus, 64px lateral, 24px jos
- [ ] maxWidth: 1200px
- [ ] margin: 0 auto

### Între secțiuni:
- [ ] Header → Document fields: 8px (marginBottom)
- [ ] Document fields → Coloane: 8px (marginBottom)
- [ ] Coloana stânga ↔ dreapta: 24px (gap)

### Interior card document:
- [ ] Padding: 20px 48px
- [ ] Gap între câmpuri: 12px (flex gap)
- [ ] Flex ratios: Furnizor=2, CUI=1.5, Nr.Doc=1.5, Data=1.5

### Interior card formular:
- [ ] Padding: 20px 48px
- [ ] Label width: 100px (fix)
- [ ] Gap label → input: 20px
- [ ] Gap între rânduri: 16px (marginBottom)
- [ ] Buton Salvează: marginTop=24, centered

### Interior card upload:
- [ ] Padding: 40px
- [ ] Gap interior: 12px
- [ ] Icon container: 48×48px

### Header bar:
- [ ] Padding: 12px 20px
- [ ] Gap între elemente: 20px
- [ ] Separator: w=1, h=20
- [ ] Select Tip: w=110, h=28

### Componente:
- [ ] Input height: 40px
- [ ] Input padding: 0 16px
- [ ] Input border-radius: r-lg (20px)
- [ ] Buton primary: h=44, p=0 40px (Salvează)
- [ ] Pill toggle container: h=42, p=4
- [ ] Pill toggle buton: h=34
- [ ] LeiBadge: right=8, p=3px 10px
- [ ] RateBadge: left=8, p=3px 10px
- [ ] MoneyInput paddingRight: 88 (pt LeiBadge)
- [ ] MoneyInput TVA paddingLeft: 90 (pt RateBadge)
```

Imediat după spec, checklist-ul:

```markdown
### ✓ CHECKLIST S8: Spacing (cote)
- [ ] Padding pagină = 8/64/24
- [ ] maxWidth = 1200
- [ ] Gap între secțiuni = 8px
- [ ] Gap coloane = 24px
- [ ] Card document padding = 20px 48px, gap câmpuri = 12
- [ ] Card formular padding = 20px 48px
- [ ] Label w=100, gap label-input=20, gap rânduri=16
- [ ] Salvează mt=24
- [ ] Card upload padding=40, gap=12
- [ ] Header padding=12 20, gap=20
- [ ] Input h=40, p=0 16, r=20px
- [ ] Pill toggle h=42/34
- [ ] LeiBadge right=8, RateBadge left=8
- [ ] MoneyInput pr=88, TVA pl=90
```

### Secțiunea 9: Tabel (dacă pagina are tabel)

```markdown
## 9. Tabel

### Container:
- [ ] card-hairline, overflow=hidden, padding=0

### Coloane (ordine STRICTĂ):
| # | Header | Align | Width | Conținut | Font |
|---|--------|-------|-------|----------|------|
| 1 | Status | left | auto | StatusBadge | badge 11px |
| 2 | Data | left | auto | data formatată | .date 13px fog |
| ...

### Specificații:
- [ ] thead: 11px/500, uppercase, ls=0.10em, fog, bg=bej-1, p=10px 22px
- [ ] tbody: h=48px, p=0 22px, 14px, ink, border-bottom rule-soft
- [ ] Ultima linie: fără border-bottom
- [ ] Hover: bg=bej-0
- [ ] Cursor: pointer
- [ ] Truncare: ellipsis pe coloanele cu maxWidth
```

Imediat după spec, checklist-ul:

```markdown
### ✓ CHECKLIST S9: Tabel
- [ ] Container = card-hairline, overflow=hidden, p=0
- [ ] Coloane ordine: Status → Data → Tip → Furnizor → Descriere → Suma/TVA → Plată
- [ ] thead: 11px uppercase fog, bg=bej-1, p=10 22
- [ ] tbody: h=48, p=0 22, 14px ink
- [ ] Hover = bej-0, cursor pointer
- [ ] Truncare ellipsis pe Furnizor (maxW=200) și Descriere (maxW=280)
- [ ] Suma/TVA = right aligned
- [ ] Plată = center aligned
```

### Secțiunea 10: Raport Prototip vs Design System (OBLIGATORIU)

Secțiune separată, prezentată utilizatorului pentru confirmare expresă ÎNAINTE de implementare.

```markdown
## 10. Raport Prototip vs Design System

### A. Diferențe Prototip vs DS
Elemente din prototip care diferă de Design System. Implementarea urmează prototipul (prioritar), dar diferențele sunt documentate pentru decizie.

| # | Element | Prototip | Design System | Diferență |
|---|---------|----------|---------------|-----------|
| 1 | Buton "Salvează" | bg=#3B82F6, r=8px | .btn.primary: bg=pink, r=pill | Culoare și radius diferite |
| 2 | Card header | shadow: 0 2px 8px | .card-hairline: no shadow | Shadow custom |

### B. Elemente lipsă din prototip
Stări și componente necesare care nu apar în prototip. Se vor construi din Design System.

| # | Element lipsă | Unde apare | Propunere DS |
|---|---------------|------------|--------------|
| 1 | Empty state tabel | Pagina tranzacții, tabel gol | card-tonal + text fog centered |
| 2 | Loading skeleton | Toate componentele cu date | bg=bej-1 animate pulse |
| 3 | Error toast | După submit eșuat | error-bg + error text |

### ⚠️ NECESITĂ CONFIRMARE UTILIZATOR

Înainte de implementare, utilizatorul trebuie să confirme:
- [ ] **Diferențele (A)**: "Implementez conform prototipului" SAU "Corectez elementul X conform DS"
- [ ] **Completările (B)**: "Adaug aceste elemente din DS" SAU "Modifică/elimină elementul X"

**BLOCKER** — implementarea NU începe până utilizatorul nu confirmă ambele secțiuni.
```

Imediat după spec, checklist-ul:

```markdown
### ✓ CHECKLIST S10: Prototip vs DS
- [ ] Toate diferențele Prototip vs DS documentate
- [ ] Toate elementele lipsă identificate cu propunere DS
- [ ] Confirmare expresă utilizator pe diferențe (A)
- [ ] Confirmare expresă utilizator pe completări (B)
- [ ] BLOCKER respectat — implementare pornește doar după confirmare
```

---

## MOMENT 2: Retrospectivă post-implementare

### Când se activează

După ce implementarea e completă și nicu-qa confirmă build ok.

### Ce face

1. **Compară SPEC-ul cu implementarea** — fiecare linie din checklist, bifată sau nu
2. **Identifică discrepanțe** — ce a fost greșit, ce a lipsit din spec
3. **Analizează cauza** — de ce spec-ul nu a prevenit problema (spec incomplet? ambiguu? ignorat?)
4. **Propune reguli noi** — organizate pe categorie
5. **Sugerează completări DS** — elemente recurente care lipsesc din Design System și ar trebui adăugate

### Output: RETROSPECTIVE-[proiect].md

```markdown
## Retrospectivă [Proiect]

### Discrepanțe găsite
| # | Spec linia | Ce trebuia | Ce s-a implementat | Cauză |
|---|-----------|------------|-------------------|-------|
| 1 | S3 câmp #6 | pill toggle | select nativ | spec nu detaliat |

### Reguli noi propuse

#### Design/UI
- R1: [descriere regulă] — Cauză: [ce s-a întâmplat]

#### UX/Interacțiune
- R2: ...

#### Logică/Calcul
- R3: ...

### Sugestii completare Design System

Elemente care au lipsit din DS și au fost construite ad-hoc. Dacă sunt recurente, merită adăugate în `shared/bono-ds.css`.

| # | Element | Folosit în | Propunere token/clasă | Prioritate |
|---|---------|------------|----------------------|------------|
| 1 | Empty state ilustrație | Tabel tranzacții, Tabel facturi | `.empty-state` — centered, fog text, icon 48px | High — apare în orice pagină cu tabel |
| 2 | Loading skeleton | Formular, Tabel | `.skeleton` — bej-1 bg, pulse animation | High — necesar peste tot |

### Status: PROPUS → așteaptă aprobare utilizator
```

### Ciclul de aprobare

1. Nicu prezintă regulile propuse + sugestiile DS utilizatorului
2. Utilizatorul aprobă, modifică sau respinge fiecare regulă și sugestie DS
3. Regulile aprobate se adaugă în `nicu-specs/RULES.md`
4. Sugestiile DS aprobate se adaugă în `shared/bono-ds.css` (tokeni/clase noi)
5. La următorul proiect, Nicu aplică regulile acumulate și DS-ul completat

---

## REGULI ACUMULATE

Se stochează în `nicu-specs/RULES.md`. Se încarcă la fiecare activare.

### Reguli inițiale:

**R1-UI**: Orice componentă care NU e input/select/textarea standard trebuie micro-spec cu toate proprietățile CSS. Exemplu: pill toggle, badge inline, money input.

**R2-ORDINE**: Câmpurile se numerotează strict. Ordinea din tabel = ordinea din pagină. Verificare: câmp cu câmp, de sus în jos.

**R3-SPACING**: Fiecare distanță se notează în pixeli cu referință la elementele între care se măsoară. Format: "ElementA → ElementB: Npx (token)".

**R4-STATE**: Orice schimbare de state care afectează alt câmp (pre-fill, reset, disable, show/hide) se documentează explicit cu: trigger → efect → valoare nouă.

**R5-CALCUL**: Orice auto-calcul se documentează cu: trigger (ce eveniment), condiție (câte câmpuri trebuie), formulă exactă, câmpuri afectate.

**R6-DS-MAP**: Fiecare element vizual primește referința DS (.input, .btn.primary, .field-label) sau notarea "NON-STANDARD: [detalii]". Dacă prototipul diferă de DS, se documentează valoarea din prototip (prioritară) cu nota "PROTOTIP ≠ DS: [detalii]". Implementarea urmează prototipul.

**R7-TABEL**: Coloanele se numerotează, aliniamentul se notează (left/right/center), lățimile se specifică, truncarea se marchează.

---

## PROCES

```
Bruce livrează PRD + Prototip
        ↓
   NICU SPECS (Moment 1)
   - Citește prototipul câmp cu câmp
   - Măsoară toate cotele
   - Mapează la DS
   - Identifică ambiguități
   - Produce SPEC-[pagina].md (spec detaliat + checklist per secțiune)
   - Produce Raport Prototip vs DS (S10): diferențe + elemente lipsă
   - Cere clarificări utilizatorului
        ↓
   Utilizatorul aprobă SPEC-ul + confirmă S10 (BLOCKER)
   - Diferențe: "implementez ca prototipul" sau "corectez conform DS"
   - Completări: "adaug din DS" sau "modific/elimin"
        ↓
   nicu-frontend implementează
   - Primește SPEC-ul + checklist-urile ca ToDo
   - Implementează și bifează fiecare item din checklist
   - La final: toate checklist-urile bifate = gata de review
        ↓
   nicu-qa verifică build
        ↓
   nicu-review verifică
   - Primește aceleași checklist-uri (copie nebifată)
   - Bifează independent fiecare item
   - Discrepanță = fix necesar
        ↓
   NICU SPECS (Moment 2)
   - Retrospectivă: ce items au fost ratate și de ce
   - Reguli noi → aprobare utilizator
   - Sugestii completare DS → aprobare utilizator → update bono-ds.css
   - Update RULES.md
```
