# APEX – zrzuty miesięczne raportu „Koszty noclegów pracowniczych” (App 102, Page 90)

Przycisk **Zrób zrzut** zapisuje wynik zapytania dla wybranego roku/miesiąca do tabeli.
Przy wyborze miesiąca raport pokazuje dane ze zrzutu (jeśli istnieje), a w przeciwnym razie dane bieżące (online).

| Plik | Co to jest |
|---|---|
| `sql/00_zapytanie_online.sql` | Oryginalne zapytanie (punkt odniesienia) |
| `sql/01_tabele.sql` | DDL: `FS_NOCLEGI_SNAP_HDR` (nagłówek) + `FS_NOCLEGI_SNAP` (dane) |
| `sql/02_proces_zrzut.sql` | Proces PL/SQL dla przycisku `ZRZUT` |
| `sql/03_zrodlo_raportu.sql` | Nowe źródło regionu IR: zrzut **albo** online |
| `sql/04_status_zrzutu.sql` | Opcjonalnie: usuwanie zrzutu |
| `sql/05_info_zrodlo_danych.sql` | Pasek w GUI: ZRZUT / DANE BIEŻĄCE |
| `sql/06_korekta_w_zrzucie.sql` | DDL: klucz `ID`, `SUMA_ORYG`, audyt (część 6a) – reszta nieaktualna, zastąpiona przez 08/09 |
| `sql/07_page96_korekta_snap.sql` | (nieaktualne – page 96 zastąpiona przez 97) |
| `sql/08_page96_edycja_wierszy.sql` | Trigger `FS_NOCLEGI_SNAP_BIU` (aktualna wersja, część 8a) |
| `sql/09_page97_korekta_w_zrzucie.sql` | Page 97: edycja kwoty i projektu w wierszach zrzutu (IG) |

## Kroki w APEX

1. **SQL Workshop → SQL Commands**: uruchom `01_tabele.sql`.
2. **Przycisk**: Page 90 → region *Filtr* → Create Button
   - Name `ZRZUT`, Label `Zrób zrzut miesiąca`, Action: *Submit Page*
   - (opcjonalnie) Dynamic Action na kliknięcie → *Confirm* „Zapisać zrzut za wybrany miesiąc? Istniejący zrzut zostanie nadpisany.” → *Submit Page* (request `ZRZUT`).
3. **Proces**: Processing → Create Process `ZRZUT_MIESIACA`, typ *Execute Code*, kod z `02_proces_zrzut.sql`,
   Server-side Condition *When Button Pressed = ZRZUT*.
4. **Region IR** „od 01.2025”: Source → SQL Query → wklej `03_zrodlo_raportu.sql`
   (Page Items to Submit: `P90_YEAR,P90_MONTH,P90_SPOLKA`). Aliasy kolumn są takie same, więc kolumny/zapisane raporty IR zostają.
5. Pasek „ZRZUT / DANE BIEŻĄCE”: region Classic Report z `05_info_zrodlo_danych.sql`.
6. Edycja zrzutu: DDL 6a z `06_…`, trigger z `08_…` (8a), page 97 wg `09_…`. Kolumna ACTIONS: Link → URL `#ACTIONS#`.

## Uwagi
- Zrzut zawsze obejmuje **wszystkie spółki**; filtr spółki działa przy odczycie.
- Dla wierszy korekt (`KOREKTA`) online filtruje po `proj.ENTITY`, a zrzut po wyliczonej spółce (z projektem zastępczym) – korekty bez projektu są w zrzucie widoczne przy filtrze ich spółki.
- Dla miesiąca ze zrzutem korekty robi się w samym zrzucie (page 97); ponowne kliknięcie „Zrób zrzut” nadpisuje też te ręczne zmiany.
- Z zapytania usunięto tylko zakomentowane linie i wewnętrzne `ORDER BY` (nie wpływały na wynik).
