-- =====================================================================
-- 4. (opcjonalnie) informacja "skąd są dane" + warunki przycisków
-- =====================================================================

-- 4a. Item P90_ZRODLO (Display Only, w regionie Filtr pod P90_DZM)
--     Source: SQL Query (return single value), Used: Always...
--     Page Items to Submit nie dotyczy - odśwież go Dynamic Action
--     (Change P90_YEAR,P90_MONTH -> Set Value = to samo zapytanie,
--      Items to Submit: P90_YEAR,P90_MONTH) albo submit strony.
select coalesce(
         max('ZRZUT z ' || to_char(utworzono, 'dd-mm-yyyy hh24:mi')
             || ' (' || utworzyl || ', ' || ilosc_wierszy || ' wierszy)'),
         'DANE BIEŻĄCE (online) - brak zrzutu')
from fs_noclegi_snap_hdr
where rok = to_number(:P90_YEAR)
  and miesiac = to_number(:P90_MONTH);

-- 4b. Przycisk USUN_ZRZUT (opcjonalny) - powrót do widoku online
--     Server-side Condition: Rows returned
select 1 from fs_noclegi_snap_hdr
where rok = to_number(:P90_YEAR) and miesiac = to_number(:P90_MONTH);

--     Proces USUN_ZRZUT (When Button Pressed: USUN_ZRZUT):
begin
    delete from fs_noclegi_snap_hdr
     where rok = to_number(:P90_YEAR)
       and miesiac = to_number(:P90_MONTH);
end;

-- 4c. Przycisk "Korekta kwoty obciążenia" - korekty dodane PO zrzucie nie
--     będą widoczne (zrzut jest zamrożony). Najprościej ukryć go dla
--     zamrożonych miesięcy: Server-side Condition: No Rows returned
select 1 from fs_noclegi_snap_hdr
where rok = to_number(:P90_YEAR) and miesiac = to_number(:P90_MONTH);
