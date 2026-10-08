# APEX – zrzuty miesięczne raportu „Koszty noclegów pracowniczych” (App 102, Page 90)

Przycisk **Zrób zrzut** zapisuje wynik zapytania dla wybranego roku/miesiąca do tabeli.
Przy wyborze miesiąca raport pokazuje dane ze zrzutu (jeśli istnieje), a w przeciwnym razie dane bieżące (online).

| Plik | Co to jest |
|---|---|
| `sql/00_zapytanie_online.sql` | Oryginalne zapytanie (punkt odniesienia) |
| `sql/01_tabele.sql` | DDL: `FS_NOCLEGI_SNAP_HDR` (nagłówek) + `FS_NOCLEGI_SNAP` (dane) |
| `sql/02_proces_zrzut.sql` | Proces PL/SQL dla przycisku `ZRZUT` |
| `sql/03_zrodlo_raportu.sql` | Nowe źródło regionu IR: zrzut **albo** online |
| `sql/04_status_zrzutu.sql` | Opcjonalnie: info o źródle danych, usuwanie zrzutu, blokada korekt |

## Kroki w APEX

1. **SQL Workshop → SQL Commands**: uruchom `01_tabele.sql`.
2. **Przycisk**: Page 90 → region *Filtr* → Create Button
   - Name `ZRZUT`, Label `Zrób zrzut miesiąca`, Action: *Submit Page*
   - (opcjonalnie) Dynamic Action na kliknięcie → *Confirm* „Zapisać zrzut za wybrany miesiąc? Istniejący zrzut zostanie nadpisany.” → *Submit Page* (request `ZRZUT`).
3. **Proces**: Processing → Create Process `ZRZUT_MIESIACA`, typ *Execute Code*, kod z `02_proces_zrzut.sql`,
   Server-side Condition *When Button Pressed = ZRZUT*.
4. **Region IR** „od 01.2025”: Source → SQL Query → wklej `03_zrodlo_raportu.sql`
   (Page Items to Submit: `P90_YEAR,P90_MONTH,P90_SPOLKA`). Aliasy kolumn są takie same, więc kolumny/zapisane raporty IR zostają.
5. (opcjonalnie) `04_status_zrzutu.sql` – item z informacją „ZRZUT z … / DANE BIEŻĄCE”, przycisk usuwania zrzutu, ukrycie „Korekta kwoty obciążenia” dla zamrożonych miesięcy.

## Uwagi
- Zrzut zawsze obejmuje **wszystkie spółki**; filtr spółki działa przy odczycie.
- Dla wierszy korekt (`KOREKTA`) online filtruje po `proj.ENTITY`, a zrzut po wyliczonej spółce (z projektem zastępczym) – korekty bez projektu są w zrzucie widoczne przy filtrze ich spółki.
- Korekty dodane po zrzucie nie wejdą do zrzutu, dopóki nie zrobisz go ponownie.
- Z zapytania usunięto tylko zakomentowane linie i wewnętrzne `ORDER BY` (nie wpływały na wynik).
