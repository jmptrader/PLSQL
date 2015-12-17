create or replace function get_f_$abonent_name(p_account in varchar2)return varchar2 is
/*
  Author  : V.ERIN
  Created : 17.03.2015 12:00:00
  Purpose : Функция для определения имени абонента M2000
  Version : 1.1.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    17.03.2015     Создание 
  -------------------------------------------------------------------------------------------------
*/
  -- возвращаемое значение
  v_retval varchar2(256) := null;
begin
  v_retval := trim(v_retval);
  if v_retval is null then
    v_retval:= 'Клиент M2000';
  end if;
  return v_retval;
end get_f_$abonent_name;
/
