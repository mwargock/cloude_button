-- =====================================================================
-- 9. Page 104 "Korekta w zrzucie" - od zera (zastępuje page 96)
--    Edycja kwoty (SUMA) i projektu wierszy zrzutu dla GEID / rok / miesiąc
--    (+ opcjonalnie dodanie wiersza KOREKTA).
--    Wymaga: kolumny ID/SUMA_ORYG/ZMODYFIKOWAL/ZMODYFIKOWANO i triggera
--    FS_NOCLEGI_SNAP_BIU z pliku 08.
-- =====================================================================

-- Kontrola po zapisie strony (czy itemy są w aplikacji głównej):
select item_name
  from apex_application_page_items
 where application_id = 102
   and page_id = 104;

-- Źródło Interactive Grid "Wiersze w zrzucie":
select id,
       geid,
       rok,
       miesiac,
       projekt,
       mpk,
       spolka,
       lokal,
       ilosc_nocl_umowa,
       info,
       korekta,
       suma,
       suma_oryg,
       zmodyfikowal,
       zmodyfikowano
  from fs_noclegi_snap
 where geid    = :P104_GEID
   and rok     = to_number(:P104_YEAR)
   and miesiac = to_number(:P104_MONTH);

-- LOV kolumny PROJEKT:
select code d, code r
  from apt.projects
 order by code;

-- Nagłówek regionu "Pracownik" (Static Content, HTML Code):
--   <b>&P104_GEID.</b> &middot; &P104_MONTH./&P104_YEAR. &middot; dane ze zrzutu

-- =====================================================================
-- KROK PO KROKU
-- =====================================================================
-- 1. SQL Commands: trigger FS_NOCLEGI_SNAP_BIU z pliku 08 (część 8a).
--
-- 2. Create Page > Blank Page: Number 104, Name "Korekta w zrzucie",
--    Page Mode: Modal Dialog.
--
-- 3. Content Body > Create Region "Pracownik" (Static Content,
--    Template: Blank with Attributes, HTML Code - jak wyżej).
--    W nim 3 itemy Hidden: P104_GEID, P104_YEAR, P104_MONTH. Save.
--    KONTROLA: zapytanie z góry pliku musi zwrócić 3 wiersze.
--
-- 4. Content Body > Create Region "Wiersze w zrzucie", Interactive Grid,
--    SQL Query - jak wyżej. Page Items to Submit:
--    P104_GEID,P104_YEAR,P104_MONTH.
--    Attributes > Edit: Enabled, Update Row (+ ew. Add Row).
--
-- 5. Kolumny:
--    ID        Hidden, Primary Key = Yes
--    GEID      Hidden, Default: Item P104_GEID
--    ROK       Hidden, Default: Item P104_YEAR
--    MIESIAC   Hidden, Default: Item P104_MONTH
--    KOREKTA   Display Only, Default: Static KOREKTA
--    PROJEKT   Popup LOV / Select List, LOV - jak wyżej, Display Extra Values = Yes
--    SUMA      Number Field, Heading "Kwota"
--    MPK, SPOLKA, LOKAL, ILOSC_NOCL_UMOWA, INFO, SUMA_ORYG,
--    ZMODYFIKOWAL, ZMODYFIKOWANO  Display Only, Query Only = Yes
--
-- 6. Przyciski w regionie "Wiersze w zrzucie":
--    ZAPISZ  - Submit Page (Hot)
--    ANULUJ  - Dynamic Action > Cancel Dialog
--
-- 7. Processing:
--    "Save Interactive Grid Data": Target Type Table/View FS_NOCLEGI_SNAP,
--      Primary Key ID, When Button Pressed = ZAPISZ
--    Close Dialog (pod nim), When Button Pressed = ZAPISZ
--
-- 8. Page 90:
--    - SQL raportu (plik 03): link ze zrzutu na page 104
--    - kolumna ACTIONS: Link > URL = #ACTIONS#
--    - przycisk CORRECT_2_SNAP: Page 104, Set Items P104_GEID/YEAR/MONTH
--      (albo ukryć - edycja z ikony w wierszu)
--    - Dynamic Action "Dialog Closed" na regionie raportu > Refresh
--
-- 9. Test: miesiąc ze zrzutem > ikona w wierszu > zmień kwotę/projekt > Zapisz.
