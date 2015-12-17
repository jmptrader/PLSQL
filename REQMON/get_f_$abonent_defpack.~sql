create or replace function get_f_$abonent_defpack(p_account_id in integer)return number is
/*
  Author  : V.ERIN
  Created : 19.11.2015 12:00:00
  Purpose : Функция для определения пакета ТВ по умолчанию 
  Version : 1.1.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    19.11.2015     Создание 
  -------------------------------------------------------------------------------------------------
*/
  -- Пакеты
  c_b2b constant number  := 504;
  c_b2c constant number  := 498;
  --
  v_cardtype_id  number;
  v_retval       number  := c_b2b;
begin
  begin
    select ab.cardtype_id into v_cardtype_id
      from cifra.ao_abonent ab
     where ab.id = p_account_id;
    -- Определяем сегмент рынка
    if (v_cardtype_id = 0) then 
      v_retval := c_b2c;
    end if;
  exception
    when no_data_found then v_retval := c_b2b;
  end;
  return v_retval;
end get_f_$abonent_defpack;
/
