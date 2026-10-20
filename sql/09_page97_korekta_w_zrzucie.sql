-- =====================================================================
-- 9. Page 97 "Korekta w zrzucie" - od zera (zastępuje page 96)
--    Edycja kwoty (SUMA) i projektu wierszy zrzutu dla GEID / rok / miesiąc
--    (+ opcjonalnie dodanie wiersza KOREKTA).
--    Wymaga: kolumny ID/SUMA_ORYG/ZMODYFIKOWAL/ZMODYFIKOWANO i triggera
--    FS_NOCLEGI_SNAP_BIU z pliku 08.
-- =====================================================================

-- Kontrola po zapisie strony (czy itemy są w aplikacji głównej):
select item_name
  from apex_application_page_items
 where application_id = 102
   and page_id = 97;

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
 where geid    = :P97_GEID
   and rok     = to_number(:P97_YEAR)
   and miesiac = to_number(:P97_MONTH);

-- LOV kolumny PROJEKT:
select code d, code r
  from apt.projects
 order by code;

-- Nagłówek regionu "Pracownik" (Static Content, HTML Code):
--   <b>&P97_GEID.</b> &middot; &P97_MONTH./&P97_YEAR. &middot; dane ze zrzutu
