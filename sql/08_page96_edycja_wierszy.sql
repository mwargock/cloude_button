-- =====================================================================
-- 8. Page 96 - edycja wierszy zrzutu (kwota + projekt) dla GEID / rok / miesiąc
--    Interactive Grid nad formularzem dodawania korekty.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 8a. Trigger (zastępuje wersję z pliku 06): przy zmianie projektu
--     MPK i spółka ustawiają się same z APT.PROJECTS
-- ---------------------------------------------------------------------
create or replace trigger fs_noclegi_snap_biu
before insert or update on fs_noclegi_snap
for each row
declare
    l_user varchar2(255) := coalesce(sys_context('APEX$SESSION','APP_USER'), user);

    procedure ustaw_projekt is
    begin
        select p.cost_centre, p.entity
          into :new.mpk, :new.spolka
          from apt.projects p
         where p.code = :new.projekt
           and rownum = 1;
    exception
        when no_data_found then null;
    end;
begin
    if inserting then
        if nvl(v('REQUEST'), '#') <> 'ZRZUT' then
            :new.zmodyfikowal  := l_user;
            :new.zmodyfikowano := sysdate;
            :new.korekta       := nvl(:new.korekta, 'KOREKTA');

            if :new.snap_id is null then
                select snap_id into :new.snap_id
                  from fs_noclegi_snap_hdr
                 where rok = :new.rok and miesiac = :new.miesiac;
            end if;
            :new.miesiac_rok := nvl(:new.miesiac_rok, lpad(:new.miesiac, 2, '0') || '-' || :new.rok);

            -- projekt wybrany ręcznie -> MPK i spółka z projektu
            if :new.projekt is not null and :new.mpk is null then
                ustaw_projekt;
            end if;

            if :new.geid is not null and :new.nazwisko is null then
                begin
                    select e.first_name, e.last_name, e.document_id,
                           nvl(:new.mpk, p.cost_centre), nvl(:new.projekt, p.code), nvl(:new.spolka, p.entity)
                      into :new.imie, :new.nazwisko, :new.num_dok,
                           :new.mpk, :new.projekt, :new.spolka
                      from apt.employees e
                      left join apt.projects p on p.id = e.curr_project_id
                     where e.geid = :new.geid;
                exception
                    when no_data_found then null;
                end;
            end if;
        else
            :new.suma_oryg := :new.suma;
        end if;
    elsif updating then
        :new.zmodyfikowal  := l_user;
        :new.zmodyfikowano := sysdate;
        if nvl(:new.projekt, '#') <> nvl(:old.projekt, '#') then
            ustaw_projekt;
        end if;
    end if;
end;
/


-- ---------------------------------------------------------------------
-- 8b. Region na page 96
--     Name:  Wiersze w zrzucie        Type: Interactive Grid
--     Slot:  Content Body, Sequence mniejsze niż region formularza (np. 30)
--     Static ID: snap_ig
--     Source: SQL Query (poniżej)
--     Page Items to Submit: P96_GEID,P96_YEAR,P96_MONTH
-- ---------------------------------------------------------------------
select id,
       projekt,
       mpk,
       spolka,
       lokal,
       ilosc_nocl_umowa,
       korekta,
       info,
       suma,
       suma_oryg,
       zmodyfikowal,
       zmodyfikowano
  from fs_noclegi_snap
 where geid    = :P96_GEID
   and rok     = to_number(:P96_YEAR)
   and miesiac = to_number(:P96_MONTH)
--
--     Attributes:
--       Edit > Enabled = Yes, Allowed Operations = Update Row (+ ew. Delete Row)
--       Toolbar: można wyłączyć (Show = No), zapis idzie przyciskiem ZAPISZ
--
--     Kolumny:
--       ID          -> Hidden, Primary Key = Yes
--       PROJEKT     -> Type: Select List, LOV (SQL Query poniżej), edytowalna
--       SUMA        -> Type: Number Field, edytowalna, Heading "Kwota"
--       MPK, SPOLKA, LOKAL, ILOSC_NOCL_UMOWA, KOREKTA, INFO,
--       SUMA_ORYG, ZMODYFIKOWAL, ZMODYFIKOWANO
--                   -> Type: Display Only, Source > Query Only = Yes
--
--     LOV dla PROJEKT:
select code d, code r
  from apt.projects
 order by code
--
-- ---------------------------------------------------------------------
-- 8c. Zapis
--     Processing: przy włączonej edycji APEX tworzy proces
--       "Wiersze w zrzucie - Save Interactive Grid Data"
--       (Interactive Grid - Automatic Row Processing (DML)).
--       Settings > Target Type: Table / View, Table Name: FS_NOCLEGI_SNAP,
--       Primary Key: ID
--       Server-side Condition: When Button Pressed = ZAPISZ
--
--     Przycisk ZAPISZ (Dialog Footer > Next, obok CREATE):
--       Label "Zapisz zmiany", Action: Submit Page
--
--     Proces Close Dialog (już jest po kopii): Server-side Condition ->
--       Request is contained in Value: CREATE,ZAPISZ
--
--     Walidacje formularza korekty (np. wymagane P96_AMOUNT) ->
--       Server-side Condition: When Button Pressed = CREATE,
--       inaczej "Zapisz zmiany" zablokuje się na pustej kwocie.
--     Items z "Value Required = Yes" -> zmień na walidację z warunkiem CREATE.
-- ---------------------------------------------------------------------
