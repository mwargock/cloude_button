-- =====================================================================
-- 7. Page 96 "Korekta kwoty obciążenia pracownika snap" (kopia page 24)
--    Zamiast INSERT do APT.FS_EMPLOYEES_EXTRA_CHARGE dopisuje korektę
--    do zrzutu FS_NOCLEGI_SNAP (wiersz KOREKTA, sumowany per GEID+projekt
--    - tak jak gałąź KOREKTA w zapytaniu online).
--
--    Nazwy itemów poniżej są PRZYKŁADOWE - podmień na te, które są na
--    page 96 po skopiowaniu (Page Search: "P24_" - nie wszystkie
--    odwołania w kodzie kopiarka zmienia automatycznie).
--      :P96_YEAR, :P96_MONTH  - rok/miesiąc (z przycisku na page 90)
--      :P96_GEID              - pracownik
--      :P96_PROJECT_ID        - projekt (APT.PROJECTS.ID), może być pusty
--      :P96_AMOUNT            - kwota korekty
--      :P96_REASON            - powód (opcjonalnie)
--
--    Processing na page 96:
--      - stary proces zapisu do FS_EMPLOYEES_EXTRA_CHARGE (Form - Automatic
--        Row Processing / Execute Code) -> USUŃ albo Condition = Never
--      - nowy proces "Korekta w zrzucie", Execute Code, When Button Pressed
--        = przycisk zapisu (np. CREATE / SAVE), kod poniżej
--      - proces Close Dialog zostaje (po nowym procesie)
-- =====================================================================
declare
    l_snap_id  fs_noclegi_snap_hdr.snap_id%type;
    l_mpk      fs_noclegi_snap.mpk%type;
    l_projekt  fs_noclegi_snap.projekt%type;
    l_spolka   fs_noclegi_snap.spolka%type;
begin
    -- 'Koszt dowozu' nie wchodzi do raportu (jak w zapytaniu online)
    if :P96_REASON = 'Koszt dowozu' then
        return;
    end if;

    begin
        select snap_id into l_snap_id
          from fs_noclegi_snap_hdr
         where rok     = to_number(:P96_YEAR)
           and miesiac = to_number(:P96_MONTH);
    exception
        when no_data_found then
            raise_application_error(-20002,
                'Brak zrzutu za ' || :P96_MONTH || '/' || :P96_YEAR
                || ' - użyj zwykłej korekty.');
    end;

    -- projekt z formularza, a gdy pusty - bieżący projekt pracownika
    select p.cost_centre, p.code, p.entity
      into l_mpk, l_projekt, l_spolka
      from apt.employees e
      left join apt.projects p
             on p.id = coalesce(to_number(:P96_PROJECT_ID), e.curr_project_id)
     where e.geid = :P96_GEID;

    merge into fs_noclegi_snap s
    using (select :P96_GEID geid from dual) n
       on (    s.snap_id = l_snap_id
           and s.korekta = 'KOREKTA'
           and s.geid    = n.geid
           and nvl(s.projekt, '#') = nvl(l_projekt, '#'))
    when matched then update
        set s.suma = nvl(s.suma, 0) + to_number(:P96_AMOUNT)
    when not matched then insert (
        snap_id, rok, miesiac, miesiac_rok, geid, mpk, projekt, spolka,
        ilosc_nocl, ilosc_nocl_umowa, obciazenie_proj, kwota_dzien,
        kwota_zakwat, kwota_zakwat_umowa, korekta, suma
    ) values (
        l_snap_id, to_number(:P96_YEAR), to_number(:P96_MONTH),
        lpad(:P96_MONTH, 2, '0') || '-' || :P96_YEAR,
        n.geid, l_mpk, l_projekt, l_spolka,
        0, 0, 0, 0, 0, 0, 'KOREKTA', to_number(:P96_AMOUNT)
    );
    -- imię / nazwisko / num dok uzupełnia trigger FS_NOCLEGI_SNAP_BIU (plik 06)
end;
