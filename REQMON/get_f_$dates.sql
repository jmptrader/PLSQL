create or replace function get_f_$dates(p_start_date in date,
                                        p_end_date in date) return date pipelined is
/*
  Author  : V.ERIN
  Created : 11.07.2015 12:00:00
  Purpose : Конвеерная функция возвращающая последовательность дат
  Version : 1.1.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    11.07.2015    Создание 
  -------------------------------------------------------------------------------------------------
*/
    -- Переменная для курсора
  v_curr_date  date;
begin
  v_curr_date := p_start_date;
  loop
    pipe row (v_curr_date);
    v_curr_date := v_curr_date + 1;
    exit when (v_curr_date = p_end_date+1);
  end loop;
  return; -- для конвеерной функции просто заканчиваем работу
end get_f_$dates;
/
