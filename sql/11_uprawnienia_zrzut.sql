-- =====================================================================
-- 11. Edycja zrzutu tylko dla MWARGOCKI i WGLADKI
-- =====================================================================

-- 11a. Shared Components > Authorization Schemes > Create (From scratch)
--      Name:   KOREKTA_ZRZUTU
--      Type:   PL/SQL Function Returning Boolean
--      Error:  Brak uprawnień do edycji danych zamrożonych.
--      Validate: Once per session
return upper(:APP_USER) in ('MWARGOCKI', 'WGLADKI');

-- 11b. Page 104 > Security > Authorization Scheme: KOREKTA_ZRZUTU
--      (blokuje stronę nawet przy ręcznie wklejonym linku)

-- 11c. Page 90 > ikona w wierszach zrzutu: plik 03
--      (URL tylko dla tych loginów + Link Attributes data-url="#ACTIONS#"
--       + CSS a[data-url=""] { display: none; })

-- 11d. Page 90 > przycisk CORRECT_2_SNAP > Security > Authorization Scheme:
--      KOREKTA_ZRZUTU (warunek "jest zrzut" zostaje w Server-side Condition)
