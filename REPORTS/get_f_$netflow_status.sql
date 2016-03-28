create or replace function get_f_$netflow_status(p_balance     in number,
                                                 p_serv_status in number)return number is
/*
  Author  : V.ERIN
  Created : 25.02.2016 12:00:00
  Purpose : Функция для определения состояния услуги netflow
  Version : 1.1.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    25.02.2016     Создание 
  -------------------------------------------------------------------------------------------------
*/
   v_retval  number := 0;
begin
   if (p_serv_status = 2129587) or (p_serv_status = 100003) then
     v_retval := 1;
   end if;
   return v_retval;
end get_f_$netflow_status;
