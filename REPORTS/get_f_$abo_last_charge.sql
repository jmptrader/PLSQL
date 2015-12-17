create or replace function get_f_$abo_last_charge(p_account_id in number, p_observ_date in date)return date is
/*
  Author  : V.ERIN
  Created : 11.07.2015 12:00:00
  Purpose : Функция для последней даты начисления абонента
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
  select max(ch_date) into v_retval 
  from ( select trunc(ops.o_bdate) ch_date
           from cifra.operations ops
          where ops.ab_num = p_account_id
            and ops.lvo_cod in (1, 2, 3, 4, 5, 8, 9, 10, 14) -- только начисления
            and ops.o_bdate <= trunc(p_observ_date)
          union
         select trunc(ope.o_edate) ch_date 
           from cifra.operations ope
          where ope.ab_num = p_account_id
            and ope.lvo_cod in (1, 2, 3, 4, 5, 8, 9, 10, 14) -- только начисления
            and ope.o_edate <= trunc(p_observ_date));
  return v_retval;
end get_f_$abo_last_charge;
/
