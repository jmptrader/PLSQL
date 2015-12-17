create or replace function get_f_$abonent_address(p_account_id in integer)return varchar2 is
/*
  Author  : V.ERIN
  Created : 17.07.2015 12:00:00
  Purpose : Функция для определения имени абонента M2000
  Version : 1.1.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    17.07.2015     Создание 
  -------------------------------------------------------------------------------------------------
*/
  c_no_address constant varchar2(50) := '<NO>'; 
  -- возвращаемое значение
  v_retval varchar2(256);
begin
  begin
    select nvl(replace(cifra.ao_adr.get_addressf(nvl(ac.adr_real_id, ac.adr_id)),'''','"'), c_no_address) into v_retval
      from cifra.ao_abonent ab, cifra.ao_contragent ac
     where ab.id = p_account_id
       and ab.contragent_id = ac.id(+);
  exception
    when no_data_found then v_retval := c_no_address;
  end;
  return v_retval;
end get_f_$abonent_address;
/
