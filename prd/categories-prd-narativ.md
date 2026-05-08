# Categorii de Cheltuieli — PRD Narativ

*Versiunea 1.0 — pentru confirmare de către Bogdan*

---

## Ce este?

Categoriile de cheltuieli sunt etichetele pe care fiecare companie le folosește ca să-și organizeze banii care ies. Gândește-te la ele ca la niște dosare: "Salarii", "Chirie", "Marketing", "Transport". Fiecare cheltuială trebuie pusă într-un dosar.

Acest modul le permite utilizatorilor să-și creeze, editeze și șteargă propriile categorii.

---

## Cine folosește?

**Accountant-ul sau administratorul firmei** — persoana care introduce cheltuielile și vrea să le vadă organizate pe categorii în rapoarte și dashboard.

Un utilizator obișnuit (ex: angajat care trimite un receipt) doar alege o categorie dintr-o listă când adaugă o cheltuială. Nu creează categorii noi.

---

## De ce contează?

Fără categorii, cheltuielile sunt o grămadă neorganizată. Cu categorii:
- Dashboard-ul P&L poate arăta "ai cheltuit 40% pe salarii, 15% pe marketing"
- Rapoartele pot fi filtrate: "arată-mi toate cheltuielile pe transport din Q1"
- Comparații lună-la-lună: "marketing a crescut cu 20% față de luna trecută"

Categoriile sunt fundația pe care se construiesc toate rapoartele.

---

## Ce vede utilizatorul?

### Ecranul principal: Lista de categorii

Când utilizatorul deschide pagina "Categorii", vede:
- **Un tabel** cu toate categoriile firmei sale
- Fiecare rând arată: **numele** categoriei, **culoarea** (un cerculet colorat), și **butoanele** Edit / Șterge
- **Un câmp de căutare** în partea de sus — scrie "sal" și rămân doar categoriile care conțin "sal"
- **Un buton "Categorie nouă"** în dreapta sus

Dacă firma nu are nicio categorie (utilizator nou), vede un mesaj: "Nu există categorii. Creează prima categorie."

### Crearea unei categorii

Utilizatorul apasă "Categorie nouă". Se deschide un dialog (fereastră mică suprapusă) cu:
- **Nume** (obligatoriu, max 100 caractere) — ex: "Salarii"
- **Descriere** (opțional) — ex: "Salarii brute + contribuții angajator"
- **Culoare** (opțional) — un color picker, se alege o culoare care va apărea în grafice

Apasă "Salvează" → categoria apare instant în tabel. Apasă "Anulează" → se închide fără să salveze nimic.

**Regulă de business:** Nu pot exista două categorii cu același nume în aceeași firmă. Dacă încearcă, primește eroare: "Există deja o categorie cu acest nume."

### Editarea unei categorii

Utilizatorul apasă "Edit" pe un rând. Se deschide același dialog, pre-completat cu datele existente. Modifică ce vrea, apasă "Salvează" → se actualizează instant.

### Ștergerea unei categorii

Utilizatorul apasă "Șterge" pe un rând. Apare un dialog de confirmare: "Ești sigur că vrei să ștergi categoria «Salarii»?" cu butoanele "Anulează" / "Șterge".

**Important:** Ștergerea este "soft" — categoria dispare din listă dar rămâne în baza de date. De ce? Pentru că cheltuielile vechi care aveau această categorie trebuie să-și păstreze referința. În rapoartele istorice, categoria va apărea în continuare.

---

## Categorii default

Când o firmă nouă se înregistrează, primește automat un set de categorii de start:

1. Salarii
2. Chirie
3. Utilități
4. Transport
5. Marketing
6. IT & Software
7. Altele

Utilizatorul le poate edita, șterge, sau adăuga altele noi. Sunt doar un punct de pornire ca să nu înceapă de la zero.

---

## Ce NU face acest modul

- **Nu gestionează sub-categorii.** Nu avem "Marketing > Facebook Ads > Campania X". Doar un nivel de categorii. Dacă va fi nevoie în viitor, e o extensie separată.
- **Nu are buget per categorie.** Nu setezi "Marketing = max 5000 lei/lună". Asta e un modul separat (Budget Tracking).
- **Nu are permisiuni pe categorie.** Toți utilizatorii din firmă văd toate categoriile. Dacă va fi nevoie de restricții, e o extensie separată.
- **Nu importă categorii din alte sisteme.** Nu avem import CSV/Excel pentru categorii.

---

## Întrebări deschise pentru Bogdan

1. **Ordinea categoriilor.** Am pus un câmp `sort_order` în baza de date. Vrei ca utilizatorul să poată reordona categoriile prin drag & drop? Sau sunt sortate alfabetic și gata?

2. **Iconițe.** Pe lângă culoare, vrei ca fiecare categorie să aibă și o iconiță? (ex: 💰 pentru Salarii, 🏠 pentru Chirie). Ar arăta mai bine în dashboard dar adaugă complexitate.

3. **Categorii default.** Lista de 7 categorii de mai sus e ok? Sau vrei altele/mai multe?

4. **Ce se întâmplă la ștergere dacă categoria are cheltuieli?** Opțiuni:
   - A) Se șterge normal (cheltuielile rămân orfane, apar ca "Fără categorie" în rapoarte)
   - B) Nu se poate șterge dacă are cheltuieli atașate (utilizatorul trebuie să le mute mai întâi)
   - C) La ștergere, te întreabă "Mută cheltuielile existente în:" și alegi altă categorie

5. **Limita de categorii.** Punem o limită? (ex: max 50 categorii per firmă) Sau nelimitat?

---

## Rezumat

| Aspect | Decizie |
|--------|---------|
| Cine folosește | Accountant / admin firmă |
| CRUD complet | Da (create, read, update, soft-delete) |
| Multi-tenant | Da (fiecare firmă vede doar categoriile ei) |
| Categorii default | 7 categorii create automat la signup |
| Câmpuri | Nume (obligatoriu), Descriere, Culoare |
| Unicitate | Nume unic per firmă |
| Sub-categorii | Nu (v1) |
| Buget per categorie | Nu (modul separat) |
| Permisiuni pe categorie | Nu (toți văd tot) |
