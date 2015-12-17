create or replace package utl_p_$lotus_api is
/*
  Author  : V.ERIN
  Created : 23.11.2015 12:00:00
  Purpose : Объекты для обеспечения работы API для взаимодейсткия с CRM Lotus
  Version : 1.0.01
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    23/11/2015     Создание пакета
  -------------------------------------------------------------------------------------------------
*/
  --
  -- Константы
  --
  c_not_found  constant number  := -1;  -- физическое лицо
  c_person     constant number  := 0;   -- физическое лицо
  c_company    constant number  := 1;   -- юридическое лицо
  c_no_special constant number  := 0;   -- контрагент не является специальным
  c_user       constant number  := 3;   -- пользовтаель, от имени которого производятся действия
  c_prepaid    constant number  := 0;   -- предоплатный абонент
  c_work       constant number  := 0;   -- действующий абонент
  c_limit      constant number  := 0;   -- лимит долга по умолчанию
  c_face       constant number  := 0;   -- контактное лицо
  c_no_vip     constant number  := 0;   -- обычный абонент
  c_reg_zone   constant number  := 100000;  -- зона регистрации
  c_srv_state  constant number  := 2129650; -- состояние услуги "Отключена"
  c_ctr_type   constant number  := 8;   -- Контракт "Интернет"
  c_ctr_state  constant number  := 1;   -- Контракт "Заключен"  
  c_agent_type constant number  := 17;  -- Доп. параметр "Агент"   
  -- Exceptions
  dublicate_record exception;
  pragma exception_init(dublicate_record, -1);
  record_locked exception;
  pragma exception_init(record_locked, -54);
   --
  -- 
  -- Функция поиска кода дома М2000 по коду дома Лотуса
  --
  function get_m2_house(p_lotus_code in varchar2) return number;
  -- 
  -- Процедура "линковки" адресов в Лотус и М2000
  --
  procedure link_address(p_loutus_code in varchar2,
                         p_m2000_code  in varchar2);
  -- 
  -- Процедура "разлинковки" адресов в Лотус и М2000
  --
  procedure del_link_address(p_loutus_code in varchar2);
  --
  --  Функция заведения ТП на абонента
  --
  function add_abonent_plan(p_srv_plan in number,
                            p_abonent  in number) return number;
  -- 
  -- Функция заведения клиента в М2000
  --
  function add_client(p_fio           in varchar2,
                      p_zone          in number,
                      p_type          in number,
                      p_j_address     in varchar2,
                      p_j_kvartira    in varchar2,
                      p_r_address     in varchar2,
                      p_r_kvartira    in varchar2,
                      p_inn           in varchar2,
                      p_plan          in number,
                      p_srv_type      in number,
                      p_contact_email in varchar2,
                      p_contact_phone in varchar2,
                      p_mobil_phone   in varchar2,
                      p_home_phone    in varchar2,
                      p_homepage      in varchar2,
                      p_birthdate     in date,
                      p_ps_series     in varchar2,
                      p_ps_number     in varchar2,
                      p_ps_date       in date,
                      p_ps_give       in varchar2,
                      p_contract_num  in varchar2,
                      p_agent         in varchar2
                      ) return number;
  --
end utl_p_$lotus_api;
/
create or replace package body utl_p_$lotus_api is
  -- 
  -- Функция поиска кода дома М2000 по коду дома Лотуса
  --
  function get_m2_house(p_lotus_code in varchar2) return number is
    v_ret number := c_not_found;
  begin
    begin
      select to_number(lta.m2000_code) into v_ret from reqmon.lt_m2_addresses$ lta where lta.lotus_code = p_lotus_code;
    exception 
      when no_data_found then null;
    end;
    return v_ret;
  end;
  -- 
  -- Функция поиска банка по коррсчету
  --
  function get_bank(p_corraccount in varchar2) return number is
    v_ret number := c_not_found;
  begin
    -- Ищем банк в справочнике по коррсчету
    begin
      select abk.id into v_ret from cifra.ao_bank abk where abk.kschet = p_corraccount;
    exception 
      when no_data_found or too_many_rows then null;
    end;
    return v_ret;
  end;
  -- 
  -- Функция поиска абонента (ID) по лицевому счету
  --
  function get_abonent(p_account in number) return number is
    v_ret number := c_not_found;
  begin
    begin
      select ab.id into v_ret from cifra.ao_abonent ab where ab.card_num = p_account; 
    exception
      when no_data_found or too_many_rows then null;
    end;
    return v_ret;
  end;
  --
  --  Функция получения лицевого счета(абонента) по ID
  --
  function get_account(p_abonent in number) return number is
    v_ret number := c_not_found;
  begin
    begin
      select ab.card_num into v_ret from cifra.ao_abonent ab where ab.id = p_abonent;
    exception
      when no_data_found or too_many_rows then null;
    end;
    return v_ret;
  end;
  --
  --  Функция заведения ТП на абонента
  --
  function add_abonent_plan(p_srv_plan in number,
                            p_abonent  in number) return number is
    v_ret number := c_not_found;
  begin
    insert into cifra.tarplan(tp_id, tp_date, tp_cod,  tp_abid, tp_telid, tp_bt)
                      values(cifra.gen_tarplan.nextval, sysdate, p_srv_plan, p_abonent, null, null)
    returning tp_id into v_ret;   
    return v_ret;           
  end;
  --
  --  Функция заведения лицевого счета(абонента) в М2000
  --
  function add_abonent (p_fio           in varchar2,
                        p_zone          in number,
                        p_type          in number,
                        p_contragent    in number,
                        p_contr_face    in number
                        ) return number is
    v_ret number := c_not_found;
    v_card_num number := c_not_found;
    function get_account_number return number is
      v_res number;
      cursor r_cards is select card_num from cifra.ao_abonent where card_num < 4990000000 and ao_abonent.telzone_id = p_zone for update nowait;
    begin
      -- Блокируем записи
      open r_cards;
      select nvl(max(card_num), 0) account
        into v_res 
        from cifra.ao_abonent 
       where card_num < 4990000000 and ao_abonent.telzone_id = p_zone;
      -- Закрываем курсор, но блокировка остается до commit;
      close r_cards;
      if (v_res = 0) then
        v_res := to_number(rpad(p_zone,10, '0'));
      end if;
      return v_res + 1;
    exception
      when record_locked then raise_application_error(-20000, 'Ресурс добавления ЛС абонета занят дуругим процессом. Попробуйте позже.');
    end;
  begin
    v_card_num := get_account_number;
    insert into cifra.ao_abonent
                (id, contragent_id, cardtype_id, category_id, telzone_id, card_num, bdate, state_id, user_id, plan_id, name, limit, face_id, vip_id)  
         values (cifra.ao_abonent_seq.nextval, p_contragent, p_type, c_prepaid, p_zone, v_card_num, sysdate, c_work, c_user, null, p_fio, c_limit, p_contr_face, c_no_vip)
    returning id into v_ret;
    return v_ret;
  end;
  -- 
  -- Функция заведения контрагента в М2000
  --
  function add_contragent(p_fio       in varchar2,
                          p_zone      in number,
                          p_type      in number,
                          p_email     in varchar2,
                          p_homepage  in varchar2,
                          p_inn       in varchar2
                          ) return number is
    v_ret number := c_not_found;
  begin
    insert into cifra.ao_contragent
                (id, type_c, bdate, user_id, is_spec, socrname, inn, adr_id, adr_real_id, basetrust, trust, parent_id, email, homepage, edate, remm, telzone_id, old_id)
         values (cifra.ao_contragent_seq.nextval, p_type, sysdate, c_user, c_no_special, p_fio, p_inn, null, null, null, null, null, p_email, p_homepage, null, null, p_zone, null)
    returning id into v_ret;
    return v_ret;
  end;
  -- 
  -- Функция заведения контактных лиц абонента
  --
  function add_contragent_face(p_fio           in varchar2,
                               p_contragent    in number,
                               p_contact_email in varchar2,
                               p_contact_phone in varchar2,
                               p_mobil_phone   in varchar2,
                               p_home_phone    in varchar2,
                               p_birthdate     in date,
                               p_ps_series     in varchar2,
                               p_ps_number     in varchar2,
                               p_ps_date       in date,
                               p_ps_give       in varchar2
                               ) return number is
    v_ret number := c_not_found;
  begin
    insert into cifra.ao_contragent_face
                (id, contragent_id, face_id, ask_order, nameface, fio, email, worktelnum, mobiltelnum, 
                 hometelnum, birthdate, remm, ps_series, ps_number, ps_date, ps_give, adr_id)
          values(cifra.ao_contragent_face_seq.nextval, p_contragent, c_face, 0, null, p_fio, p_contact_email, p_contact_phone, p_mobil_phone,
                 p_home_phone, p_birthdate, null, p_ps_series, p_ps_number, p_ps_date, p_ps_give, null)
    returning id into v_ret;
    return v_ret;
  end;
  -- 
  -- Процедура "линковки" адресов в Лотус и М2000
  --
  procedure link_address(p_loutus_code in varchar2,
                         p_m2000_code  in varchar2) is
  begin
    insert into reqmon.lt_m2_addresses$(lotus_code, m2000_code) values (p_loutus_code, p_m2000_code);
    -- Фиксируем изменения
    commit;
  exception
    when dublicate_record then raise_application_error(-20000, 'Адрес с кодом: '||p_loutus_code||' или '||p_m2000_code||' уже имеет действующую связь');
  end;
  -- 
  -- Процедура "разлинковки" адресов в Лотус и М2000
  --
  procedure del_link_address(p_loutus_code in varchar2) is
  begin
    delete from reqmon.lt_m2_addresses$ t where t.lotus_code = p_loutus_code;
    -- Фиксируем изменения
    commit;
  end;
  -- 
  -- Процедура добавления адреса абонента
  --
  function add_address(p_loutus_code in varchar2,
                       p_kvartira    in varchar2) return number is
    v_house number := get_m2_house(p_loutus_code);                      
    v_ret number := c_not_found;
    function getaddr_id return number is
      addr_id number := c_not_found;
    begin
      begin
        select t.id into addr_id from cifra.ao_address t where t.house_id = v_house and t.apart = nvl(p_kvartira,'.');
      exception 
        when no_data_found then null;
      end;
      return addr_id;
    end; 
  begin
    if (v_house = c_not_found) then
      raise_application_error(-20000, 'Адрес с кодом: '||p_loutus_code||' не имеет действующую связь с М2000');
    else
      -- Прверяем существование адреса, если нет то создаем
      v_ret := getaddr_id;
      if (v_ret = c_not_found) then
        insert into cifra.ao_address
                    (id, house_id, apart)
             values (cifra.ao_address_seq.nextval, v_house, nvl(p_kvartira,'.'))
          returning id into v_ret;
      end if;
    end if;
    return v_ret;
  end;
  -- 
  -- Процедура добавления услуги абонента
  --
  procedure add_service(p_srv_type in number,
                        p_plan     in number,
                        p_abonent  in number,
                        p_zone     in number) is
  begin
    insert into cifra.m3_services
                (id, type_id, telzone_id, registration_zone_id, in_type_id, out_type_id, parent_id, address_id, resource_id, resource_uid,
                 state_id, state_dt, bdate,  edate, plan_id, abonent_id, package_id, remm, quantity, scratch_id)
         values (cifra.m3_services_seq.nextval, p_srv_type, p_zone, c_reg_zone, null, null, null, null, null, null,
                 c_srv_state, sysdate, sysdate, null, p_plan, p_abonent, null, null, 1, null);
  end;
  -- 
  -- Процедура добавления договора
  --
  procedure add_contract(p_contract_num in varchar2,
                         p_abonent      in number) is
  begin
    -- Создаем контракт
    insert into cifra.ao_contracts
                (id, bdate, contract_no, abonent_id, type_id, state_id, edate, remm, service_id)
          values(cifra.ao_contracts_seq.nextval, sysdate, p_contract_num, p_abonent, c_ctr_type, c_ctr_state, null, null, null);
  end;
  -- 
  -- Процедура добавления информации об агенте
  --
  procedure add_agent(p_abonent  in number,
                      p_agent    in varchar2) is
  begin
    insert into cifra.ao_attrib_values
                (id, attrib_type_id, rec_id, value)
          values(cifra.ao_attrib_values_seq.nextval, c_agent_type, p_abonent, p_agent);
  end;
  -- 
  -- Функция заведения клиента в М2000
  --
  function add_client(p_fio           in varchar2,
                      p_zone          in number,
                      p_type          in number,
                      p_j_address     in varchar2,
                      p_j_kvartira    in varchar2,
                      p_r_address     in varchar2,
                      p_r_kvartira    in varchar2,
                      p_inn           in varchar2,
                      p_plan          in number,
                      p_srv_type      in number,
                      p_contact_email in varchar2,
                      p_contact_phone in varchar2,
                      p_mobil_phone   in varchar2,
                      p_home_phone    in varchar2,
                      p_homepage      in varchar2,
                      p_birthdate     in date,
                      p_ps_series     in varchar2,
                      p_ps_number     in varchar2,
                      p_ps_date       in date,
                      p_ps_give       in varchar2,
                      p_contract_num  in varchar2,
                      p_agent         in varchar2
                      ) return number is
    v_contragent number;
    v_contr_face number;
    v_abonent    number;
    v_address    number;
    v_r_address  number;
  begin
    -- Создаем контрагента
    v_contragent := add_contragent(p_fio, p_zone, p_type, p_contact_email, p_homepage , p_inn);
    -- Добавляем адреса
    v_address := add_address(p_j_address, p_j_kvartira);
    -- Если реальный адрес не задан, то он равен фактичесвому
    if (p_r_address is null) then
      v_r_address := v_address;
    else
      v_r_address := add_address(p_r_address, p_r_kvartira);
    end if;
    update cifra.ao_contragent t set t.adr_id = v_r_address, t.adr_real_id = v_r_address where t.id = v_contragent;
    -- Создаем контактное лицо
    v_contr_face := add_contragent_face(p_fio, v_contragent, p_contact_email, p_contact_phone, p_mobil_phone, p_home_phone, p_birthdate,
                                        p_ps_series, p_ps_number, p_ps_date, p_ps_give );
    -- Создаем абонента
    v_abonent := add_abonent (p_fio, p_zone, p_type, v_contragent, v_contr_face);
    -- Добавляем ТП
    update cifra.ao_abonent t set t.plan_id = add_abonent_plan(p_plan, v_abonent);
    -- Добавляем услугу
    add_service(p_srv_type, p_plan, v_abonent, p_zone);
    -- Создаем контракт
    add_contract(p_contract_num, v_abonent);
    -- Создаем информацию об агенте
    add_agent(v_abonent, p_agent);
    -- Фиксируем изменения
    commit;
    -- Возвращаем ЛС
    return get_account(v_abonent);
  exception
    when others then 
      begin
        rollback;
        raise;
      end;
  end;
  --
begin
  null;
end utl_p_$lotus_api;
/
