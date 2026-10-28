-- ORDS - moduł CRM, szablon employee/import, handler POST (PL/SQL)
-- Daty (birth_date, planned_training_date) przyjmowane jako YYYY-MM-DD lub DD.MM.YYYY
declare
    l_auth_result      varchar2(10);
    l_geid             employees.geid%type;
    l_status_code      employees.status%type;
    l_status_name      varchar2(100);        -- przyjazna nazwa statusu
    l_body             clob := :body_text;

    l_birth_txt        varchar2(30);
    l_training_txt     varchar2(30);
    l_birth_date       date;
    l_training_date    date;
begin
    -- 1. Autoryzacja
    if :client_id is null or :client_secret is null then
        apex_json.open_object;
        apex_json.write('status', 'error');
        apex_json.write('message', 'Missing client_id or client_secret');
        apex_json.close_object;
        return;
    end if;

    l_auth_result := is_api_client_authorized(:client_id, :client_secret, 'crm.read');

    if l_auth_result != 'OK' then
        apex_json.open_object;
        apex_json.write('status', 'error');
        apex_json.write('message', 'Invalid credentials');
        apex_json.close_object;
        return;
    end if;

    -- 2. Parsowanie JSON
    apex_json.parse(p_source => l_body);

    -- 2a. Daty - YYYY-MM-DD (np. 2000-01-01) albo DD.MM.YYYY (np. 01.01.2000)
    l_birth_txt    := trim(apex_json.get_varchar2('birth_date'));
    l_training_txt := trim(apex_json.get_varchar2('planned_training_date'));

    l_birth_date := case
                        when l_birth_txt like '____-__-__%' then to_date(substr(l_birth_txt, 1, 10), 'YYYY-MM-DD')
                        when l_birth_txt is not null        then to_date(l_birth_txt, 'DD.MM.YYYY')
                    end;

    l_training_date := case
                           when l_training_txt like '____-__-__%' then to_date(substr(l_training_txt, 1, 10), 'YYYY-MM-DD')
                           when l_training_txt is not null        then to_date(l_training_txt, 'DD.MM.YYYY')
                       end;

    -- 3. Sprawdzenie czy DOCUMENT_ID już istnieje
    begin
        select a.geid,
               a.status,
               (select x."NAME" 
                  from "EMPLOYEES_STATUSES" x 
                 where x."CODE" = a."STATUS") as status_name
          into l_geid, l_status_code, l_status_name
          from employees_test a
         where a.document_id = apex_json.get_varchar2('document_id')
           and rownum = 1;

        -- Rekord istnieje
        apex_json.open_object;
        apex_json.write('status',           'exists');
        apex_json.write('geid',             l_geid);
        apex_json.write('employee_status',  l_status_name);        -- przyjazna nazwa
        apex_json.write('status_code',      l_status_code);        -- opcjonalnie kod
        apex_json.close_object;

        return;

    exception
        when no_data_found then
            null;   -- nie istnieje → INSERT
    end;

    -- 4. INSERT nowego rekordu
    insert into employees_test (
        last_name,
        first_name,
        document_type,
        document_id,
        citizenship,
        birth_date,
        email,
        mobile,
        mobile_local,
        accept1,
        accept2,
        accept_electronic_communication,
        sex,
        occupation,
        is_in_pl,
        stay_permit,
        send_to_enova,
        recruiter_id,
        created_by,
        recruitation_project_id,
        planned_training_date,
        imported_from_crm
    ) values (
        apex_json.get_varchar2('last_name'),
        apex_json.get_varchar2('first_name'),
        apex_json.get_varchar2('document_type'),
        apex_json.get_varchar2('document_id'),
        apex_json.get_varchar2('citizenship'),
        l_birth_date,
        apex_json.get_varchar2('email'),
        apex_json.get_varchar2('mobile'),
        apex_json.get_varchar2('mobile_local'),
        'Y',
        'Y',
        'Y',
        apex_json.get_varchar2('sex'),
        'INNY',
        'N',
        'ZZZ',
        'N',
        to_number(apex_json.get_varchar2('recruiter_id')),   -- działa dla "777" i 777
        'CRMFAST',
        apex_json.get_varchar2('recruitation_project_id'),
        l_training_date,
        'Y'
    ) 
    returning geid into l_geid;

    -- Pobierz przyjazną nazwę statusu po insercie
    select a.status,
           (select x."NAME" 
              from "EMPLOYEES_STATUSES" x 
             where x."CODE" = a."STATUS")
      into l_status_code, l_status_name
      from employees_test a
     where a.geid = l_geid;

    -- 5. Sukces
    apex_json.open_object;
    apex_json.write('status',           'created');
    apex_json.write('geid',             l_geid);
    apex_json.write('employee_status',  l_status_name);      -- przyjazna nazwa
    apex_json.write('status_code',      l_status_code);      -- opcjonalnie oryginalny kod
    apex_json.close_object;

exception
    when others then
        apex_json.open_object;
        apex_json.write('status', 'error');
        apex_json.write('message', sqlerrm);
        apex_json.close_object;
end;
