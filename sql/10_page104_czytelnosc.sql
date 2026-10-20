-- =====================================================================
-- 10. Page 104 - czytelniejszy układ
-- =====================================================================

-- ---------------------------------------------------------------------
-- 10a. Nagłówek: region "Pracownik" -> Type: Dynamic Content
--      (PL/SQL Function Body returning a CLOB), Template: Blank with Attributes
-- ---------------------------------------------------------------------
declare
    l_html    clob;
    l_mies    varchar2(30) := to_char(to_date(lpad(:P104_MONTH, 2, '0'), 'MM'),
                                      'FMMonth', 'NLS_DATE_LANGUAGE=POLISH');
begin
    for r in (
        select max(imie) || ' ' || max(nazwisko)       as osoba,
               max(num_dok)                            as dok,
               nvl(sum(suma_oryg), 0)                  as oryg,
               nvl(sum(suma), 0)                       as teraz
          from fs_noclegi_snap
         where geid    = :P104_GEID
           and rok     = to_number(:P104_YEAR)
           and miesiac = to_number(:P104_MONTH)
    ) loop
        l_html :=
            '<div style="display:flex;flex-wrap:wrap;gap:24px;align-items:center;'
         || 'padding:12px 16px;border-radius:6px;background:#f4f6f9;border-left:5px solid #2e7d32">'
         || '<div><div style="font-size:18px;font-weight:700">' || apex_escape.html(r.osoba) || '</div>'
         || '<div style="color:#666">' || apex_escape.html(:P104_GEID) || ' &middot; '
         || apex_escape.html(r.dok) || '</div></div>'
         || '<div><div style="color:#666">Okres</div><div style="font-weight:600">'
         || initcap(l_mies) || ' ' || :P104_YEAR || ' &middot; &#128274; zrzut</div></div>'
         || '<div><div style="color:#666">Kwota w zrzucie</div><div style="font-weight:600">'
         || to_char(r.oryg, 'FM999G999G990') || '</div></div>'
         || '<div><div style="color:#666">Kwota po zmianach</div><div style="font-weight:700;font-size:18px">'
         || to_char(r.teraz, 'FM999G999G990') || '</div></div>'
         || '<div><div style="color:#666">Różnica</div><div style="font-weight:700;color:'
         || case when r.teraz - r.oryg < 0 then '#c62828' when r.teraz - r.oryg > 0 then '#2e7d32' else '#666' end
         || '">' || to_char(r.teraz - r.oryg, 'FMS999G999G990') || '</div></div>'
         || '</div>';
    end loop;
    return l_html;
end;


-- ---------------------------------------------------------------------
-- 10b. Nowe źródło siatki "Wiersze w zrzucie"
--      (kolumny MPK i SPOLKA usunięte - trigger i tak je ustawia z projektu)
-- ---------------------------------------------------------------------
select id,
       geid,
       rok,
       miesiac,
       korekta,
       case when korekta = 'KOREKTA' then 'Korekta' else 'Nocleg' end as typ,
       projekt,
       mpk || ' / ' || spolka                  as mpk_spolka,
       lokal,
       ilosc_nocl_umowa,
       suma,
       suma_oryg,
       suma - nvl(suma_oryg, 0)                as zmiana,
       zmodyfikowal,
       zmodyfikowano
  from fs_noclegi_snap
 where geid    = :P104_GEID
   and rok     = to_number(:P104_YEAR)
   and miesiac = to_number(:P104_MONTH)
 order by case when korekta = 'KOREKTA' then 1 else 0 end, projekt, id


-- ---------------------------------------------------------------------
-- 10c. Kolumny (kolejność = Layout > Sequence)
-- ---------------------------------------------------------------------
--  Kolumna            Type          Heading          Uwagi
--  ID                 Hidden        -                Primary Key = Yes
--  GEID, ROK, MIESIAC Hidden        -                Default: Item P104_*
--  KOREKTA            Hidden        -                Default: Static KOREKTA
--  TYP                Display Only  Typ              Query Only = Yes, szer. 90
--  PROJEKT            Popup LOV     Projekt          edytowalna, szer. 260
--  MPK_SPOLKA         Display Only  MPK / Spółka     Query Only = Yes
--  LOKAL              Display Only  Lokal            Query Only = Yes, szer. 220
--  ILOSC_NOCL_UMOWA   Display Only  Noclegi          Query Only = Yes, do prawej
--  SUMA               Number Field  Kwota            edytowalna, do prawej,
--                                                    Format Mask 999G999G990
--  SUMA_ORYG          Display Only  Kwota w zrzucie  Query Only = Yes, do prawej
--  ZMIANA             Display Only  Zmiana           Query Only = Yes, do prawej
--  ZMODYFIKOWAL       Display Only  Zmienił          Query Only = Yes
--  ZMODYFIKOWANO      Display Only  Kiedy            Query Only = Yes,
--                                                    Format Mask DD-MM-YYYY HH24:MI
--
--  Szerokości: uruchom stronę, ustaw myszką, potem jako developer
--  Czynności > Raport > Zapisz (Primary Default).


-- ---------------------------------------------------------------------
-- 10d. Pasek narzędzi siatki (region > Attributes > Toolbar)
-- ---------------------------------------------------------------------
--   Controls: Search Field = off, Actions Menu = off, Reset Button = off,
--             Save Button = off (zapis jest przyciskiem w stopce)
--   Add Row zostaje ("Dodaj korektę": Attributes > Edit > Add Row Label?
--     -> w APEX: Toolbar > "Add Row" etykietę zmienisz przez
--        Shared Components > Text Messages: APEX.IG.ADD_ROW)
--   Columns > APEX$ROW_SELECTOR: Enable Multi Select = No, Show Select All = No
--   Attributes > Pagination: Show Total Count = No


-- ---------------------------------------------------------------------
-- 10e. Przyciski do stopki okna
-- ---------------------------------------------------------------------
--   Dialog Footer > Create Region "Przyciski"
--     Type: Static Content, Template: Buttons Container
--   ANULUJ: Region "Przyciski", Slot: Close (lewa strona)
--   ZAPISZ: Region "Przyciski", Slot: Create / Next (prawa strona), Hot
--
--   Page 104 > Appearance > Dialog: Width 1100, Height auto
