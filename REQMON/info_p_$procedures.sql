create or replace package info_p_$procedures is
/*
  Author  : V.ERIN
  Created : 21.09.2014 12:00:00
  Purpose : Объекты для создания заявок по информаированию абонентов.
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    20/10/2014     Создание пакета
  -------------------------------------------------------------------------------------------------
*/
  -- Константы
  c_sms_req       constant char(1) := reqmon.req_p_$process.c_sms_req;
  c_mail_req      constant char(1) := reqmon.req_p_$process.c_mail_req;
  c_plsql_req     constant char(1) := reqmon.req_p_$process.c_plsql_req;
  --
  c_nfmt          constant varchar2(50) := '99999999990D99';
  --
  c_pay_req_name  constant varchar2(50) := 'PAY_REQ_INFO';
  c_bal_req_name  constant varchar2(50) := 'BAL_REQ_INFO';
  c_srv_req_name  constant varchar2(50) := 'SRV_REQ_INFO';
  -- Услуги
  c_inet_nserv    constant number := 1;
  c_tv_nserv      constant number := 2;
  c_phone_nserv   constant number := 3;
  c_multy_nserv   constant number := 4;
  c_no_nserv      constant number := 0;
  -- Состояние услуги 
  c_srv_up        constant number := 0;
  c_srv_dn        constant number := 1;
  -- Сообщения
  c_rqtm_unknown      constant number := -1; -- Cообщение не определено
  -- Платежи
  c_rqtm_pay_dflt     constant number := req_p_$process.get_param_value('RQTM_PAY_DFLT',   11); -- Cообщение о платеже
  c_rqtm_pay_stnd     constant number := req_p_$process.get_param_value('RQTM_PAY_STND',   12); -- Состояние услуг не изменились
  c_rqtm_pay_dnsrv    constant number := req_p_$process.get_param_value('RQTM_PAY_DNSRV',  13); -- Средств платежа не достаточно для включения услуг
  c_rqtm_pay_upsrv    constant number := req_p_$process.get_param_value('RQTM_PAY_UPSRV',  14); -- Средств платежа достаточно для включения услуг
  -- Баланс
  c_rqtm_bal_dflt     constant number := req_p_$process.get_param_value('RQTM_BAL_ZERO',   15); -- Cообщение о балансе
  c_rqtm_bal_dnsrv    constant number := req_p_$process.get_param_value('RQTM_BAL_DNSRV',  16); -- Cообщение об отрицательном балансе
  c_rqtm_bal_remind   constant number := req_p_$process.get_param_value('RQTM_BAL_REMIND', 17); -- Cообщение о приближении к 0
  -- Услуга
  c_rqtm_serv_upsrv   constant number := req_p_$process.get_param_value('RQTM_SERV_UPSRV', 20); -- Cообщение о подключении услуг
  c_rqtm_serv_dnsrv   constant number := req_p_$process.get_param_value('RQTM_SERV_DNSRV', 21); -- Cообщение об отключении услуг
  --
  c_job_name          constant varchar2(50) := 'EVENT_SCAN';
  -- Пороги
  c_bal_threshold     constant number := req_p_$process.get_param_value('BAL_THRESHOLD', 50);
  -- Типы
  type t_bal_rec is record(
         balance  number,
         bal_dt   date);
  --
  -- Функция поиска e-mail абонента
  --
  function get_email(p_account_id in number) return varchar2;
  --
  -- Функция поиска номера телефона абонента
  --
  function get_phone(p_account_id in number) return varchar2;
  --
  -- Функция поиска account абонента
  --
  function get_account(p_account_id in number) return varchar2;
  --
  -- Функция получения текущего сальдо абонента
  --
  function get_balance(p_account_id in number) return number;
 --
  -- Функция получения услуги абонента (в виде цифры)
  --
  function get_service_num(p_account_id in number) return integer;
  --
  -- Функция получения статуса услуги 
  --
  function get_service_status(p_account_id in number) return number;
  --
  -- Функция получения услуги абонента
  --
  function get_service_name(v_serv_num in number) return varchar2;
  --
  -- Функция определения предоплатного абонента
  --
  function is_prepaid(p_account_id in number) return boolean;
  --
  -- Процедура создания заявки на отправку сообщений
  --
  function req_create(p_account_id in number, 
                      p_balance    in number,
                      p_serv_state in number) return number;
  --
  -- Процедура сканирования таблицы балансов
  --
  procedure scan_balances;
  --
  -- Процедура сканирования таблиц
  --
  procedure scan;
  --
  -- Процедура создания процесса сканировани таблиц
  --
  procedure create_scan_jobs;
  --
  -- Процедура удаления процесса сканирования таблиц
  --
  procedure drop_scan_jobs;
  --
end info_p_$procedures;
/
create or replace package body info_p_$procedures is
  --
  -- Функция поиска e-mail абонента
  --
  function get_email(p_account_id in number) return varchar2 is
    v_retval varchar2(250) := '';
  begin
    -- ищем сначала у контрагента
    begin
      select ac.email
        into v_retval
        from cifra.ao_abonent ab,
             cifra.ao_contragent ac
       where ab.contragent_id = ac.id
         and ab.id = p_account_id
         and regexp_like (ac.email, '.*@.*\..*'); 
    exception
      when no_data_found then null;
      when too_many_rows then null;
    end;
    -- если нет у контрагента ищем у контактов
    if v_retval is null then
      begin
        select acf.email
          into v_retval
          from cifra.ao_abonent ab,
               cifra.ao_contragent_face acf 
         where ab.contragent_id = acf.contragent_id
           and ab.id = p_account_id
           and regexp_like (acf.email, '.*@.*\..*'); 
      exception
        when no_data_found then null;
        when too_many_rows then null;
      end;
    end if;
    return v_retval;
  end;
  --
  -- Функция поиска номера телефона абонента
  --
  function get_phone(p_account_id in number) return varchar2 is
    v_retval varchar2(50) := '';
  begin
    begin
      select acf.mobiltelnum
        into v_retval
        from cifra.ao_abonent ab,
             cifra.ao_contragent_face acf 
       where ab.contragent_id = acf.contragent_id
         and ab.id = p_account_id
         and regexp_like (acf.mobiltelnum, '^\+79\d\d\d\d\d\d\d\d\d$'); 
    exception
      when no_data_found then null;
      when too_many_rows then null;
    end;
    return v_retval;
  end;
  --
  -- Функция поиска account абонента
  --
  function get_account(p_account_id in number) return varchar2 is
    v_retval varchar2(50) := '';
  begin
    begin
      select ab.card_num
        into v_retval
        from cifra.ao_abonent ab 
       where ab.id = p_account_id; 
    exception
      when no_data_found then null;
    end;
    return v_retval;
  end;
  --
  -- Функция получения предыдущего статуса услуги
  --
  function get_last_status(p_account_id in number) return number is
    v_retval number := null;
  begin
     begin
      select nvl(rqb.is_blocked,0)
        into v_retval
        from req_balances$ rqb 
       where rqb.abon_num = p_account_id; 
    exception
      when no_data_found then null;
    end;
    return v_retval;
  end;
  --
  -- Процедура изменения предыдущего статуса услуги
  --
  procedure change_last_status(p_account_id in number, p_status in number) is
  begin
    update req_balances$ rqb 
       set rqb.is_blocked = p_status
     where rqb.abon_num = p_account_id; 
  end;
  --
  -- Функция получения текущего сальдо абонента
  --
  function get_balance(p_account_id in number) return number is
    v_retval number := 0;
  begin
     begin
      select nvl(qb.balance,0)
        into v_retval
        from balances$ qb 
       where qb.abon_num = p_account_id; 
    exception
      when no_data_found then null;
    end;
    return v_retval;
  end;
  --
  -- Функция получения предыдущего сальдо абонента
  --
  function get_last_balance(p_account_id in number) return t_bal_rec is
    v_retval t_bal_rec;
  begin
    v_retval.balance := null;
    v_retval.bal_dt  := null;
    begin
      select nvl(rqb.balance,0), 
             rqb.bal_dt
        into v_retval
        from req_balances$ rqb 
       where rqb.abon_num = p_account_id; 
    exception
      when no_data_found then null;
    end;
    return v_retval;
  end;
  --
  -- Процедура изменения предыдущего сальдо абонента
  --
  procedure change_last_balance(p_account_id in number, p_balance in number) is
  begin
    update req_balances$ rqb 
       set rqb.prev_balance = rqb.balance,
           rqb.prev_bal_dt = rqb.bal_dt,
           rqb.balance = p_balance,
           rqb.bal_dt = sysdate
     where rqb.abon_num = p_account_id; 
  end;
  --
  -- Процедура вставки предыдущего сальдо абонента
  --
  procedure insert_last_balance(p_account_id in number, p_balance in number, p_serv_state in number) is
  begin
    insert into req_balances$(balance, bal_dt, abon_num, is_blocked) values(p_balance, sysdate, p_account_id, p_serv_state); 
  end;
  --
  -- Функция получения статуса услуги 
  --
  function get_service_status(p_account_id in number) return number is
     v_retval integer := 0;
     v_cnt    integer := 0;
  begin
    if get_service_num(p_account_id) = c_inet_nserv then
      v_retval := 0;
    else
      select count(1) 
        into v_cnt
        from cifra.phonework phw, cifra.cusl sv  
       where phw.ph_cusl_ucod = sv.cusl_ucod 
         and sv.cusl_abon_num = p_account_id 
         and (phw.ph_edate is null or phw.ph_edate > sysdate)
         and phw.ph_who = 2;
      if v_cnt > 0 then
        v_retval := 1;
      end if;
    end if;
    return v_retval;
  end;
  --
  -- Функция получения услуги абонента
  --
  function get_service_name(v_serv_num in number) return varchar2 is
     v_retval   varchar2(50) := '';
  begin
    -- Выбор абонентской услуги
    case v_serv_num
      when c_no_nserv    then v_retval := '*';
      when c_multy_nserv then v_retval := 'Multiservis';
      when c_phone_nserv then v_retval := 'Telefonija';
      when c_tv_nserv    then v_retval := 'Cifrovoe TV';
      when c_inet_nserv  then v_retval := 'Internet';
    end case;     
    return v_retval;
  end;
  --
  -- Функция получения услуги абонента (в виде цифры)
  --
  function get_service_num(p_account_id in number) return integer is
    v_retval   integer;
    v_services char(3) := '';
    -- Проверка на телефонию
    function is_phone_serv return char is
      v_retval char(1) := '0';
      v_count integer;
    begin
      select count(1) into v_count from cifra.cusl cu where cu.cusl_vid = 1 and cu.cusl_abon_num = p_account_id;
      if v_count > 0 then
        v_retval := '1';
      end if;
      return v_retval; 
    end;
    -- Проверка на ЦТ
    function is_tv_serv return char is
      v_retval char(1) := '0';
      v_count integer;
    begin
      select count(1) into v_count from cifra.cusl cu where cu.cusl_vid = 17 and cu.cusl_abon_num = p_account_id;
      if v_count > 0 then
        v_retval := '1';
      end if; 
      return v_retval; 
    end;
    -- Проверка на интернет
    function is_inet_serv return char is
      v_retval char(1) := '0';
      v_count integer;
    begin
      select count(1) into v_count
        from cifra.m3_services srv
       where srv.type_id in (44, 51, 54, 64, 65, 70) and srv.edate is null and srv.abonent_id = p_account_id;
      if v_count > 0 then
        v_retval := '1';
      end if; 
      return v_retval; 
    end;
  begin
    v_services := is_phone_serv||is_tv_serv||is_inet_serv; 
    -- Выбор абонентской услуги
    case v_services
      when '000' then v_retval := c_no_nserv;
      when '100' then v_retval := c_phone_nserv;
      when '010' then v_retval := c_tv_nserv;
      when '001' then v_retval := c_inet_nserv;
      else v_retval := c_multy_nserv; 
    end case;     
    return v_retval;
  end;
  --
  -- Функция определения абонента netflow
  --
  function is_netflow(p_account_id in number) return boolean is
    v_cnt integer;
  begin
    select count(1) into v_cnt
      from cifra.m3_services srv
     where srv.type_id in (54, 65) and srv.edate is null and srv.abonent_id = p_account_id;
    return v_cnt > 0;
  end;
  --
  -- Функция определения предоплатного абонента
  --
  function is_prepaid(p_account_id in number) return boolean is
    v_cnt integer;
  begin
    select count(1) into v_cnt from cifra.ao_abonent ab where ab.id = p_account_id and ab.category_id = 0;
    return v_cnt > 0;
  end;
  --
  -- Процедура создания заявки на отправку сообщений об изменении состояния услуги
  --
  function req_srv_create(p_account_id  in number,
                          p_balance     in number,
                          p_serv_state  in number                     
                          ) return number is
    v_rqtm_id  number         := c_rqtm_unknown;
    v_rqst_dst varchar2(50)   := get_phone(p_account_id);
    v_account  varchar2(50)   := get_account(p_account_id);
    v_serv     number         := get_service_num(p_account_id);
    v_params   varchar2(2000) := 'balance:'||trim(to_char(p_balance,c_nfmt))||';servname:'||get_service_name(v_serv);
    v_req      number         := req_p_$process.c_new_req_id;
  begin
    if (v_rqst_dst is null) then
      return v_req; -- Если нет адресата, то ничего не посылаем
    end if;
    if (p_serv_state = c_srv_dn) then
       v_rqtm_id := c_rqtm_serv_dnsrv;  -- отключение
    else
       v_rqtm_id := c_rqtm_serv_upsrv;  -- включение
    end if;
    -- Создаем заявку
    if (v_rqtm_id <> c_rqtm_unknown) and (v_rqst_dst is not null) then
      v_req := req_p_$process.req_create( p_rqst_name       => c_srv_req_name,
                                          p_rqst_id         => v_req,
                                          p_rqst_num        => 1,
                                          p_rqst_rqtm_id    => v_rqtm_id,
                                          p_rqst_type       => c_sms_req,
                                          p_rqst_dst        => v_rqst_dst,
                                          p_rqst_account    => v_account,
                                          p_rqst_add_params => v_params);
    end if;
    return v_req;
  end;
  --
  -- Процедура создания заявки на отправку сообщений об изменении баланса
  --
  function req_chg_create(p_account_id      in number, 
                          p_balance         in number,
                          p_last_balance    in t_bal_rec) return number is
    v_rqtm_id  number         := c_rqtm_unknown;
    v_rqst_dst varchar2(50)   := get_phone(p_account_id);
    v_account  varchar2(50)   := get_account(p_account_id);
    v_serv     number         := get_service_num(p_account_id);
    v_prepaid  boolean        := is_prepaid(p_account_id);
    v_netflow  boolean        := is_netflow(p_account_id);
    v_params   varchar2(2000) := 'balance:'||trim(to_char(p_balance,c_nfmt))||';servname:'||get_service_name(v_serv);
    v_req      number         := req_p_$process.c_new_req_id;
  begin
    if (v_rqst_dst is null) then
      return v_req; -- Если нет адресата, то ничего не посылаем
    end if;
    if (v_serv <> c_phone_nserv) and (not v_netflow) then -- не для телефонии и не для netflow
      if (p_balance < 0) and (p_last_balance.balance > 0) then
        v_rqtm_id := c_rqtm_bal_dnsrv; -- баланс был положительный, а сейчас отрицательный - услуги будут оключены
      elsif (p_balance < c_bal_threshold) and (p_last_balance.balance > c_bal_threshold) then
        v_rqtm_id := c_rqtm_bal_remind; -- баланс был больше порога, а сейчас меньше порога - шлем напоминание
      end if;
    end if;
    if (v_netflow) and (p_balance < c_bal_threshold) then
       v_rqtm_id := c_rqtm_bal_dflt; -- Простое сообщение о балансе для абонетов netflow если меньше порога
    end if; 
    if (not v_prepaid) or (p_balance = 0) then
      v_rqtm_id := c_rqtm_unknown; -- для кредитных абонентов не посылаем сообщение или если баланс равен 0
    end if;                        -- поскольку не понятно, работает ли клиент при нулевом балансе
    -- Создаем заявку
    if (v_rqtm_id <> c_rqtm_unknown) then
      v_req := req_p_$process.req_create( p_rqst_name       => c_bal_req_name,
                                          p_rqst_id         => v_req,
                                          p_rqst_num        => 1,
                                          p_rqst_rqtm_id    => v_rqtm_id,
                                          p_rqst_type       => c_sms_req,
                                          p_rqst_dst        => v_rqst_dst,
                                          p_rqst_account    => v_account,
                                          p_rqst_add_params => v_params);
    end if;
    return v_req;
  end;
  --
  -- Процедура создания заявки на отправку сообщений о платежах
  --
  function req_pay_create(p_account_id      in number, 
                          p_balance         in number,
                          p_last_balance    in t_bal_rec) return number is
    v_rqtm_id  number         := c_rqtm_unknown;
    v_rqst_dst varchar2(50)   := get_phone(p_account_id);
    v_account  varchar2(50)   := get_account(p_account_id);
    v_serv     number         := get_service_num(p_account_id);
    v_prepaid  boolean        := is_prepaid(p_account_id);
    v_params   varchar2(2000) := '';
    v_req      number         := reqmon.req_p_$process.c_new_req_id;
    v_req_num  number         := 1;
    v_cur_bal  number         := p_balance;
  begin
    if (v_rqst_dst is null) then
      return v_req; -- Если нет адресата, то ничего не посылаем
    end if;
    for pay_rec in (select op.o_fullsumma pay_sum
                      from cifra.operations op, 
                           cifra.documents doc
                     where op.ab_num = p_account_id 
                       and op.o_id = doc.o_id
                       and op.inf_num = cifra.m2_clc.currentinformationnumber
                       and op.lvo_cod = 6
                       and op.lso_cod not in (1431,1433)
                       and nvl(doc.d_kassa,0) <> 28
                       and op.o_fullsumma > 0 
                       and op.lcr_cod <> 15 
                       and op.o_bdate between p_last_balance.bal_dt and sysdate
                     order by op.o_bdate desc) loop
        v_params := 'balance:'||trim(to_char(v_cur_bal,c_nfmt))||';sum:'||trim(to_char(pay_rec.pay_sum,c_nfmt))||';servname:'||get_service_name(v_serv);
        if (v_cur_bal = 0) then --  баланс 0
           v_rqtm_id := c_rqtm_pay_dflt; -- не пишем состояние услуги
        elsif (v_cur_bal <= 0) then --  баланс отрицательный
           v_rqtm_id := c_rqtm_pay_dnsrv;
        else -- баланс положительный
           if (v_cur_bal - pay_rec.pay_sum <= 0) then 
              v_rqtm_id := c_rqtm_pay_upsrv; -- до платежа баланс был отрицательный, но сейчас положительный услуги будут активированы
           else
              v_rqtm_id := c_rqtm_pay_stnd; -- до платежа баланс был положительный, и сейчас положительный  с услугами ничего не произойдет
           end if;
        end if;
        if (v_serv = c_phone_nserv) or (not v_prepaid) then
          v_rqtm_id := c_rqtm_pay_dflt; -- для телефонии и кредитных абонентов не пишем состояние услуги в сообщении
        end if;
        -- Создаем заявку
        v_req := req_p_$process.req_create( p_rqst_name       => c_pay_req_name,
                                            p_rqst_id         => v_req,
                                            p_rqst_num        => v_req_num,
                                            p_rqst_rqtm_id    => v_rqtm_id,
                                            p_rqst_type       => c_sms_req,
                                            p_rqst_dst        => v_rqst_dst,
                                            p_rqst_account    => v_account,
                                            p_rqst_add_params => v_params,
                                            p_rqst_priority   => req_p_$process.c_prty_med );
        v_req_num := v_req_num + 1;
        v_cur_bal := v_cur_bal - pay_rec.pay_sum;
    end loop;
    return v_req;
  end;
  --
  -- Процедура создания заявки на отправку сообщений
  --
  function req_create(p_account_id in number, 
                      p_balance    in number,
                      p_serv_state in number) return number is
    v_balance  t_bal_rec      := get_last_balance(p_account_id); -- предыдущий баланс
    v_delta    number         := p_balance - v_balance.balance;
    v_req      number         := req_p_$process.c_new_req_id;
    v_status   number         := get_last_status(p_account_id);
  begin
    -- Проверка на изменение баланса
    if (v_balance.balance is null) or (v_status is null) then 
      insert_last_balance(p_account_id, p_balance, p_serv_state);
    else
      -- Отправляем сообщение, если было изменение баланса
      if not (v_delta = 0) then
         if v_delta > 0 then  -- Баланс увеличился. были платежи
            v_req := req_pay_create(p_account_id, p_balance, v_balance);
         else -- Баланс уменьшился. было начисление
            v_req := req_chg_create(p_account_id, p_balance, v_balance);
         end if;
         -- Изменяем значение последнего баланса
         change_last_balance(p_account_id, p_balance);
      end if;
    end if;
    -- Проверка на состояние статуса услуги
    if p_serv_state <> v_status then
      v_req := req_srv_create(p_account_id, p_balance, p_serv_state); 
      change_last_status(p_account_id, p_serv_state);
    end if;
    return v_req;
  end;
  --
  -- Процедура сканирования таблицы балансов
  --
  procedure scan_balances is
    v_req number;
    procedure set_rqst(p_id in number, p_account_id in number) is
    begin
      update req_balances$ rqb set rqb.rqbl_rqst_id = p_id where rqb.abon_num = p_account_id; 
    end;
  begin
    -- Проходим по всем балансам за открытый период
    for bal_rec in ( select balance, abon_num, is_blocked from balances$ ) loop
        -- Проверка на флаг остановки
        if req_p_$process.get_param_value(req_p_$process.c_is_stoped_p) <> 0 then
          raise_application_error (req_p_$process.c_req_errcode,req_p_$process.c_is_stop_req);
        end if;
        -- Создаем заявку на отправку сообщений
        v_req := req_create(bal_rec.abon_num, bal_rec.balance, bal_rec.is_blocked);
        if v_req <> req_p_$process.c_new_req_id then
          set_rqst(v_req, bal_rec.abon_num); -- Запоминаем сообщение, если посылали
        end if;
        commit;
    end loop;
  end; 
  --
  -- Процедура сканирования таблиц
  --
  procedure scan is
  begin
    -- Обрабатываем балансы  
    scan_balances;
  end;
  --
  -- Процедура создания процесса сканировани таблиц
  --
  procedure create_scan_jobs is
    v_job_start_date date;
  begin
    -- Актуализируем таблицу слежения за балансами
    delete from req_balances$;
    insert into req_balances$(balance, bal_dt, abon_num, is_blocked) select balance, sysdate, abon_num, get_service_status(abon_num) from balances$;
    -- Создаем процесс 
    v_job_start_date := sysdate+((1/(24*60)));
    dbms_scheduler.create_job(job_name            => c_job_name,
                              job_type            => 'PLSQL_BLOCK',
                              job_action          => 'begin info_p_$procedures.scan; end; ',
                              start_date          => v_job_start_date,
                              repeat_interval     => 'freq=minutely;interval=10;byhour=9,10,11,12,13,14,15,16,17,18,19,20,21,22',
                              end_date            => to_date(null),
                              job_class           => 'DEFAULT_JOB_CLASS',
                              enabled             => true,
                              auto_drop           => false,
                              comments            => 'Процесс слежения за балансами');
    commit;
  end;
  --
  -- Процедура удаления процесса сканирования таблиц
  --
  procedure drop_scan_jobs is
  begin  
    dbms_scheduler.drop_job(c_job_name);
  end;
  --
begin
 null;
end info_p_$procedures;
/
