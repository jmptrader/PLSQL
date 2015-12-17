create or replace function get_f_$servstate(p_account_id in number)return integer is
/*
  Author  : V.ERIN
  Created : 21.02.2015 12:00:00
  Purpose : Функция для определения состояния услуги IPTV
  Version : 1.1.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    01.05.2015     Создание 
  -------------------------------------------------------------------------------------------------
*/
  -- константы 
  c_iptv_serv_id constant integer := 72;
  c_iptv_serv_on constant integer := 100003;
  -- возвращаемое значение
  v_retval integer := 1;
  v_srv_state number;
begin
  begin
    -- Для услуги IPTV определяем ее сосояние
    begin
      select srv.state_id into v_srv_state 
        from cifra.m3_services srv 
       where srv.abonent_id = p_account_id 
         and srv.type_id = c_iptv_serv_id
         and (srv.bdate <= sysdate and nvl(srv.edate, to_date('31.12.2999','dd.mm.yyyy')) > sysdate);
    exception
      when too_many_rows then null;
    end;
    if (v_srv_state = c_iptv_serv_on) then
      v_retval := 1;
    else
      v_retval := 0;
    end if;
    -- Для "услуг по ТП" всегда "включена"
  exception
    when no_data_found then v_retval := 1;
  end;
  return v_retval;
end get_f_$servstate;
/
