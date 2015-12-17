create or replace function get_f_$abo_first_charge(p_account_id in number, p_observ_date in date)return date is
/*
  Author  : V.ERIN
  Created : 11.07.2015 12:00:00
  Purpose : Функция для первой даты начисления абонента
  Version : 1.1.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    11.07.2015    Создание 
  -------------------------------------------------------------------------------------------------
*/
  -- возвращаемое значение
  v_retval date;
begin
  select trunc(min(ops.o_bdate)) into v_retval 
    from cifra.operations ops
   where ops.ab_num = p_account_id
     and ops.lvo_cod in (1, 2, 3, 4, 5, 8, 9, 10, 14); -- только начисления     
  return v_retval;
end get_f_$abo_first_charge;
/
