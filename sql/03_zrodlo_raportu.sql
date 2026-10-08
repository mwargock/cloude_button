-- =====================================================================
-- 3. Nowe źródło (SQL Query) regionu IR "Koszty noclegów pracowniczych od 01.2025"
--    - jeśli dla :P90_YEAR/:P90_MONTH istnieje zrzut -> dane z fs_noclegi_snap
--    - jeśli nie -> dotychczasowe zapytanie online
--    Aliasy kolumn są identyczne jak wcześniej, więc kolumny IR, zapisane
--    raporty, linki i "actions" zostają bez zmian.
--    Page Items to Submit regionu: P90_YEAR,P90_MONTH,P90_SPOLKA
-- =====================================================================
select
    s.miesiac_rok        as "Miesiąc-Rok",
    s.geid               as "Geid",
    s.imie               as "Imię",
    s.nazwisko           as "Nazwisko",
    s.num_dok            as "Num dok",
    s.mpk                as "MPK",
    s.projekt            as "Projekt",
    s.spolka             as "Spółka",
    s.typ_umowy          as "Typ umowy",
    s.lokal              as "Lokal",
    s.ilosc_nocl         as "Ilosc noclegow w lokalu",
    s.ilosc_nocl_umowa   as "Ilosc noclegow w lokalu z umową",
    s.obciazenie_proj    as "Obciążenie na projekcie",
    s.kwota_dzien        as "Kwota za dzień",
    s.info               as "Info",
    s.kwota_zakwat       as "KWOTA OBCIĄŻENIA (zakwaterowanie)",
    s.kwota_zakwat_umowa as "KWOTA OBCIĄŻENIA (zakwaterowanie+umowa)",
    s.korekta            as "Korekta",
    s.suma               as "SUMA - koszt zakwaterowania",
    null                 as actions
from fs_noclegi_snap s
where s.rok     = to_number(:P90_YEAR)
  and s.miesiac = to_number(:P90_MONTH)
  and (
        :P90_SPOLKA = 'Wszystkie'
        or s.spolka in (
               select trim(regexp_substr(:P90_SPOLKA, '[^,]+', 1, level))
               from dual
               connect by level <= regexp_count(:P90_SPOLKA, ',') + 1
           )
      )
union all
select online.*
from (
-- >>>>>>>>>> zapytanie online (bez zmian) >>>>>>>>>>
select 
LPAD(:P90_MONTH, 2, '0') || '-' || :P90_YEAR AS "Miesiąc-Rok",
a2.GEID "Geid",
a2.FIRST_NAME "Imię",
a2.LAST_NAME "Nazwisko",
a2.DOCUMENT_ID "Num dok",
a2.COST_CENTER "MPK",
a2.projekt "Projekt",
a2.spolka "Spółka",
a2.typ_um "Typ umowy", 
a2.hotel "Lokal",
a2.OC_DATE "Ilosc noclegow w lokalu",
a2.umowa_aktywna "Ilosc noclegow w lokalu z umową",
a2.kwota_obciazenia "Obciążenie na projekcie",
a2.dzien "Kwota za dzień",
case when a2.Info='Ucieczka' and a2.umowa_aktywna <= 7 then 'Ucieczka<=7dni' else a2.Info end as "Info",
case when a2.Info='Ucieczka' and a2.umowa_aktywna <= 7 then 0 else a2.zakwat end as "KWOTA OBCIĄŻENIA (zakwaterowanie)",
case when a2.Info='Ucieczka' and a2.umowa_aktywna <= 7 then 0 else a2.zakwat_umow end as "KWOTA OBCIĄŻENIA (zakwaterowanie+umowa)",
a2.Korekta "Korekta",
case when a2.Info='Ucieczka' and a2.umowa_aktywna <= 7 then 0 else nvl(a2.suma,0) end as "SUMA - koszt zakwaterowania",
null as actions
from (
select
a1.GEID ,
a1.FIRST_NAME ,
a1.LAST_NAME ,
a1.DOCUMENT_ID ,
a1.COST_CENTER ,
a1.projekt ,
a1.spolka ,
a1.typ_um, 
a1.hotel ,
a1.miesiac ,
count(distinct OC_DATE) OC_DATE,
count(umowa_aktywna) umowa_aktywna,
a1.kwota_obciazenia kwota_obciazenia,
round(a1.kwota_obciazenia/a1.dni_w_miesiacu,2) dzien,
case when a1.kod_uci ='BLOCK' and a1.data_uci BETWEEN to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM') AND LAST_DAY(to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM'))
then 'Ucieczka' end as Info,
case when a1.kod_uci ='BLOCK' and a1.data_uci BETWEEN to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM') AND LAST_DAY(to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM'))
then (kwota.kwota_ucieczka_projekt) else (round(round(a1.kwota_obciazenia/a1.dni_w_miesiacu,2)*(count(distinct OC_DATE)))) end as zakwat,
case when a1.kod_uci ='BLOCK' and a1.data_uci BETWEEN to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM') AND LAST_DAY(to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM'))
then (kwota.kwota_ucieczka_projekt) else (round(round(a1.kwota_obciazenia/a1.dni_w_miesiacu,2)*(count(umowa_aktywna))))
end as zakwat_umow,
'0' Korekta,
(case when a1.kod_uci ='BLOCK' and a1.data_uci BETWEEN to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM') AND LAST_DAY(to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM'))
    then (kwota.kwota_ucieczka_projekt)
    else (round(round(a1.kwota_obciazenia/a1.dni_w_miesiacu,2)*(count(umowa_aktywna))))
end) suma
from(
    select
    distinct ho.GEID,
    prac.FIRST_NAME,
    prac.LAST_NAME,
    prac.DOCUMENT_ID,
    rej.ACTION kod_uci,
    prac.BROKEN_ACC_RULE_DATE_EFFECT data_uci,
    ho.OC_DATE,
    case when ho.OC_DATE BETWEEN umowy.FROM_DATE and umowy.TILL_DATE
                    and proj.COST_CENTRE=umowy.COST_CENTRE_CODE
                    and umowy.IS_ACTIVE='Y'
                    and proj.ENTITY=umowy.ENTITY
                    then 'Y' else null end as umowa_aktywna,
    proj.ENTITY spolka_proj,
    proj.COST_CENTRE,
    umowy.ENTITY spolka_umowa,
    umowy.TYPE typ_um,
    umowy.COST_CENTRE_CODE,
    to_char(LAST_DAY(OC_DATE),'dd') dni_w_miesiacu,
    to_char(OC_DATE, 'mm') miesiac,
    proj.COST_CENTRE COST_CENTER,
    ho.PROJECT_ID,
    proj.CODE projekt,
    proj.COST_CENTRE mpk,
    proj.ENTITY spolka,
    oc_status.NAME,
    booking_typ.NAME typ,
    hotels.CODE hotel,
    hotels.PRINCIPAL dyrektor,
    hotels.SUPERVISOR kierownik,
    hotels.LEADER lider,
    hotels.TYPE typ,
    case when pch.AMOUNT is null then pch2.AMOUNT else  pch.AMOUNT end as kwota_obciazenia
    from apt.HOTELS_OCCUPANCY  ho
    left join APT.PROJECTS proj on proj.id=ho.PROJECT_ID
    left join APT.HOTELS_ROOMS rooms on rooms.id=ho.room_id
    left join APT.HOTELS hotels on hotels.id=rooms.HOTEL_ID
    left join APT.EMPLOYEES prac on prac.geid=ho.GEID
    left join apt.EMPLOYEES_EMPLOYMENT umowy on umowy.geid=ho.GEID
    left join apt.HOTELS_BOOKING_REQUESTS booking on booking.ID=ho.BOOKING_ID
    left join apt.HOTELS_EMPLOYEES_FOR_BOOKING_TYPES booking_typ on booking_typ.CODE=booking.TYPE
    left join apt.HOTELS_OCCUPANCY_STATUSES oc_status on oc_status.code=ho.STATUS
    left join apt.REJECTION_REASONS rej on rej.CODE=prac.BROKEN_ACC_RULE_CODE
    left join 
    (
    SELECT PROJECT_ID,TILL_DATE data_ten_miesiac,AMOUNT
    FROM PROJECTS_EMPLOYEES_CHARGE
    WHERE  LAST_DAY(to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM')) >= TRUNC(CREATED_ON)
      AND LAST_DAY(to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM')) <= NVL(TILL_DATE, DATE '2099-12-31')
    )pch on pch.PROJECT_ID=ho.PROJECT_ID
    left join 
    (
        select PROJECT_ID,max(TILL_DATE) data_aktywny,AMOUNT from apt.PROJECTS_EMPLOYEES_CHARGE 
        where TILL_DATE = to_date('2099-12-31', 'YYYY-MM-DD') 
        group by PROJECT_ID,AMOUNT 
    )pch2 on pch2.PROJECT_ID=ho.PROJECT_ID
    where ho.oc_date BETWEEN to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM') AND LAST_DAY(to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM'))
    and hotels.CODE not in ('IMPORT Mieszkanie własne _ ul._ _')
    and oc_status.NAME='Potwierdzony'
    and booking_typ.NAME ='Normalny'
	)a1
left join (
			select
			a11.geid,a11.COST_CENTRE,a11.hotel hotel,
			rounD(a11.AMOUNT_OF_CHARGE_EMPLOYEE * (a11.max_dni_proj/a2.max_dni)) kwota_ucieczka_projekt
			from (
				select ho.geid,
				case when pch.AMOUNT is null then pch2.AMOUNT else  pch.AMOUNT end as AMOUNT_OF_CHARGE_EMPLOYEE,
				proj.COST_CENTRE,hotels.CODE hotel,
				count(distinct OC_DATE) max_dni_proj
				from apt.HOTELS_OCCUPANCY  ho
				left join APT.PROJECTS proj on proj.id=ho.PROJECT_ID left join APT.HOTELS_ROOMS rooms on rooms.id=ho.room_id
				left join APT.HOTELS hotels on hotels.id=rooms.HOTEL_ID left join APT.EMPLOYEES prac on prac.geid=ho.GEID
				left join apt.EMPLOYEES_EMPLOYMENT umowy on umowy.geid=ho.GEID left join apt.HOTELS_BOOKING_REQUESTS booking on booking.ID=ho.BOOKING_ID
				left join apt.HOTELS_EMPLOYEES_FOR_BOOKING_TYPES booking_typ on booking_typ.CODE=booking.TYPE left join apt.HOTELS_OCCUPANCY_STATUSES oc_status on oc_status.code=ho.STATUS
				left join apt.REJECTION_REASONS rej on rej.CODE=prac.BROKEN_ACC_RULE_CODE
				left join 
				(
				select PROJECT_ID,max(TILL_DATE) data_ten_miesiac,AMOUNT from apt.PROJECTS_EMPLOYEES_CHARGE 
				where TILL_DATE BETWEEN to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM') AND LAST_DAY(to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM'))
				group by PROJECT_ID,AMOUNT
				)pch on pch.PROJECT_ID=ho.PROJECT_ID
				left join 
				(
				select PROJECT_ID,max(TILL_DATE) data_aktywny,AMOUNT from apt.PROJECTS_EMPLOYEES_CHARGE 
				where TILL_DATE = to_date('2099-12-31', 'YYYY-MM-DD') 
				group by PROJECT_ID,AMOUNT 
				)pch2 on pch2.PROJECT_ID=ho.PROJECT_ID
				where ho.oc_date BETWEEN to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM') AND LAST_DAY(to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM'))
				and prac.BROKEN_ACC_RULE_DATE_EFFECT BETWEEN to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM') AND LAST_DAY(to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM'))
				and rej.ACTION='BLOCK'
				and  ho.OC_DATE BETWEEN umowy.FROM_DATE and umowy.TILL_DATE
				and proj.COST_CENTRE=umowy.COST_CENTRE_CODE
				and umowy.IS_ACTIVE='Y'
				and proj.ENTITY=umowy.ENTITY
				and hotels.CODE not in ('IMPORT Mieszkanie własne _ ul._ _')
				and oc_status.NAME='Potwierdzony' and booking_typ.NAME ='Normalny' group by proj.COST_CENTRE,ho.geid,pch.AMOUNT,pch2.AMOUNT,hotels.CODE
			)a11
			left join 
			(
				select ho.geid,
				count(distinct OC_DATE) max_dni
				from apt.HOTELS_OCCUPANCY  ho
				left join APT.PROJECTS proj on proj.id=ho.PROJECT_ID left join APT.HOTELS_ROOMS rooms on rooms.id=ho.room_id
				left join APT.HOTELS hotels on hotels.id=rooms.HOTEL_ID left join APT.EMPLOYEES prac on prac.geid=ho.GEID
				left join apt.EMPLOYEES_EMPLOYMENT umowy on umowy.geid=ho.GEID left join apt.HOTELS_BOOKING_REQUESTS booking on booking.ID=ho.BOOKING_ID
				left join apt.HOTELS_EMPLOYEES_FOR_BOOKING_TYPES booking_typ on booking_typ.CODE=booking.TYPE left join apt.HOTELS_OCCUPANCY_STATUSES oc_status on oc_status.code=ho.STATUS
				left join apt.REJECTION_REASONS rej on rej.CODE=prac.BROKEN_ACC_RULE_CODE
				where ho.oc_date BETWEEN to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM') AND LAST_DAY(to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM'))
				and prac.BROKEN_ACC_RULE_DATE_EFFECT BETWEEN to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM') AND LAST_DAY(to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM'))
				and rej.ACTION='BLOCK'
				and  ho.OC_DATE BETWEEN FROM_DATE and TILL_DATE
				and proj.COST_CENTRE=umowy.COST_CENTRE_CODE
				and umowy.IS_ACTIVE='Y'
				and proj.ENTITY=umowy.ENTITY
				and hotels.CODE not in ('IMPORT Mieszkanie własne _ ul._ _')
				and oc_status.NAME='Potwierdzony' and booking_typ.NAME ='Normalny' 
				group by ho.geid
			)a2 on a2.geid=a11.geid
			) kwota on kwota.geid=a1.GEID and kwota.COST_CENTRE=a1.COST_CENTRE and a1.hotel=kwota.hotel
group by a1.GEID,a1.FIRST_NAME,
a1.LAST_NAME,
a1.DOCUMENT_ID,
a1.COST_CENTER,
a1.projekt,
a1.spolka,
a1.hotel,
a1.typ_um, 
a1.dni_w_miesiacu,
a1.miesiac,
a1.kwota_obciazenia,a1.kod_uci,a1.data_uci,kwota.kwota_ucieczka_projekt
)a2
WHERE a2.umowa_aktywna > 0
and (
        :P90_SPOLKA = 'Wszystkie' 
        OR 
        a2.spolka IN (
                         SELECT TRIM(REGEXP_SUBSTR(:P90_SPOLKA, '[^,]+', 1, LEVEL))
                         FROM DUAL
                         CONNECT BY LEVEL <= REGEXP_COUNT(:P90_SPOLKA, ',') + 1
                       )
      )
union all
select
LPAD(:P90_MONTH, 2, '0') || '-' || :P90_YEAR AS "Miesiąc-Rok",
ec.GEID  "Geid",
prac.FIRST_NAME "Imię",
prac.LAST_NAME "Nazwisko",
prac.DOCUMENT_ID "Num dok",
case when proj.COST_CENTRE is null then  projekt_null.COST_CENTRE else proj.COST_CENTRE end as "MPK",
case when proj.CODE is null then  projekt_null.CODE else proj.CODE end as "Projekt",
case when proj.ENTITY is null then  projekt_null.ENTITY else proj.ENTITY end as "Spółka",
'' "Typ umowy", 
'' "Lokal",
0 "Ilosc noclegow w lokalu",
0 "Ilosc noclegow w lokalu z umową",
0 "Obciążenie na projekcie",
0 "Kwota za dzień",
'' "Info",
0 "KWOTA OBCIĄŻENIA (zakwaterowanie)",
0 "KWOTA OBCIĄŻENIA (zakwaterowanie+umowa)",
'KOREKTA' "Korekta",
sum(ec.AMOUNT) "SUMA - koszt zakwaterowania",
null as actions
from apt.FS_EMPLOYEES_EXTRA_CHARGE ec
left join APT.EMPLOYEES prac on prac.geid=ec.GEID
left join APT.PROJECTS proj on proj.id=ec.PROJECT_ID
left join 
(
    select emp.geid, pro_e.COST_CENTRE,pro_e.CODE,pro_e.ENTITY
    from APT.EMPLOYEES emp 
    left join APT.PROJECTS pro_e on pro_e.id=emp.CURR_PROJECT_ID
)projekt_null on projekt_null.geid=ec.GEID
where ec.DATE_EFFECT BETWEEN to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM') AND LAST_DAY(to_date(:P90_YEAR||'/'||LPAD(:P90_MONTH,2,'0'), 'YYYY/MM'))
AND (
        :P90_SPOLKA = 'Wszystkie' 
        OR 
        proj.ENTITY IN (
                         SELECT TRIM(REGEXP_SUBSTR(:P90_SPOLKA, '[^,]+', 1, LEVEL))
                         FROM DUAL
                         CONNECT BY LEVEL <= REGEXP_COUNT(:P90_SPOLKA, ',') + 1
                       )
      )
and ec.REASON <> 'Koszt dowozu'
group by 
ec.GEID,
prac.FIRST_NAME,
prac.LAST_NAME,
prac.DOCUMENT_ID,
proj.COST_CENTRE,projekt_null.COST_CENTRE,
proj.CODE,projekt_null.CODE,
proj.ENTITY,projekt_null.ENTITY
-- <<<<<<<<<< koniec zapytania online <<<<<<<<<<
) online
-- gałąź online działa tylko gdy NIE ma zrzutu (Oracle sprawdza to raz, na starcie)
where not exists (
    select 1
    from fs_noclegi_snap_hdr h
    where h.rok     = to_number(:P90_YEAR)
      and h.miesiac = to_number(:P90_MONTH)
)
