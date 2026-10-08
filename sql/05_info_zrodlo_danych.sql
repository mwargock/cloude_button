-- =====================================================================
-- 5. Informacja w GUI: dane ze ZRZUTU czy ONLINE
--
--    Region: Page 90 > Body (nad IR "od 01.2025") > Create Region
--      Title:            Źródło danych
--      Type:             Classic Report
--      Source:           SQL Query (poniżej)
--      Page Items to Submit: P90_YEAR,P90_MONTH
--      Appearance > Template: Blank with Attributes
--      Attributes: Pagination Type = No Pagination Selected,
--                  Heading Type = None, "When No Data Found" puste
--      Kolumna KOMUNIKAT: Security > Escape special characters = No
--
--    Odświeżanie przy zmianie filtra:
--      Dynamic Action: Event Change, Items P90_YEAR,P90_MONTH
--        True action: Refresh -> Region "Źródło danych"
--      (jeśli strona i tak robi submit przy zmianie filtra - nic nie trzeba)
-- =====================================================================
select
  case
    when h.snap_id is not null then
      '<div style="padding:8px 12px;border-radius:4px;border-left:5px solid #2e7d32;'
   || 'background:#e8f5e9;color:#1b5e20;font-weight:600">'
   || '&#128274; ZRZUT (dane zamrożone) z ' || to_char(h.utworzono, 'dd-mm-yyyy hh24:mi')
   || ' &middot; ' || apex_escape.html(h.utworzyl)
   || ' &middot; ' || h.ilosc_wierszy || ' wierszy</div>'
    else
      '<div style="padding:8px 12px;border-radius:4px;border-left:5px solid #ef6c00;'
   || 'background:#fff3e0;color:#e65100;font-weight:600">'
   || '&#9889; DANE BIEŻĄCE (online) &middot; brak zrzutu za '
   || lpad(:P90_MONTH, 2, '0') || '-' || :P90_YEAR || '</div>'
  end as komunikat
from dual
left join fs_noclegi_snap_hdr h
       on h.rok     = to_number(:P90_YEAR)
      and h.miesiac = to_number(:P90_MONTH)
