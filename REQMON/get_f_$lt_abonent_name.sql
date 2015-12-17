create or replace function get_f_$lt_abonent_name(p_account in varchar2)return varchar2 is
/*
  Author  : V.ERIN
  Created : 25.02.2015 12:00:00
  Purpose : Функция для определения имени абонента Лотус
  Version : 1.1.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    25.02.2015     Создание 
  -------------------------------------------------------------------------------------------------
*/
  -- возвращаемое значение
  v_retval varchar2(256) := null;
begin
  begin
    select la.last_name||' '||la.first_name||' '||la.middle_name into v_retval from lt_abonents$ la where la.pin = p_account;
  exception
    when no_data_found or too_many_rows then null;
  end;
  v_retval := trim(v_retval);
  if v_retval is null then
    v_retval:= 'Клиент ДПФЛ';
  end if;
  return v_retval;
end get_f_$lt_abonent_name;
/
