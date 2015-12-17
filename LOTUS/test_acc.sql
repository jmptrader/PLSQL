declare
  account number;
begin
  account := utl_p_$lotus_api.add_client(p_fio => 'Иванов Иван Петрович',
                              p_zone => 18, -- utl_v_$zones
                              p_type => 0, -- 0 - физ. 1- юр.
                              p_j_address => 'b-286808575104', -- код дома в Лотус
                              p_j_kvartira => '2',
                              p_r_address => null, -- код дома в лотус или null если совпадает с юридическим адресом
                              p_r_kvartira => null,
                              p_inn => '7036039963',
                              p_plan => 2907, -- utl_v_$tariff_plans
                              p_srv_type => 70,
                              p_contact_email => 'v.erin@mail.com',
                              p_contact_phone => '79267892312',
                              p_mobil_phone => null,
                              p_home_phone => null,
                              p_homepage => null,
                              p_birthdate => to_date('01.01.1917','dd.mm.yyyy'),
                              p_ps_series => '2256',
                              p_ps_number => '4143431243',
                              p_ps_date => to_date('01.01.1917','dd.mm.yyyy'),
                              p_ps_give => 'УФМС 1',
                              p_contract_num => 'DS-123',
                              p_agent => 'Вася Пупкин'                             
                              );
  dbms_output.put_line(account);
end;
