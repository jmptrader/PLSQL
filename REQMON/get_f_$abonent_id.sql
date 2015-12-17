create or replace function get_f_$abonent_id(p_account in number)return integer is
/*
  Author  : V.ERIN
  Created : 21.02.2015 12:00:00
  Purpose : Функция для определения ID абонета по его лицевому счету
  Version : 1.1.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    05.03.2015     Создание 
  -------------------------------------------------------------------------------------------------
*/
  -- возвращаемое значение
  v_retval integer := -1;
begin
  begin
    select id into v_retval from cifra.ao_abonent ab where ab.card_num = p_account;
  exception
    when no_data_found or too_many_rows then null;
  end;
  return v_retval;
end get_f_$abonent_id;
/
