create or replace function get_f_$ltabonent_segment(p_account in varchar2)return varchar2 is
/*
  Author  : V.ERIN
  Created : 17.07.2015 12:00:00
  Purpose : Функция для определения сегмента абонента 
  Version : 1.1.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    17.07.2015     Создание 
  -------------------------------------------------------------------------------------------------
*/
  -- Сегменты рынка
  c_b2b constant varchar2(3)  := 'B2B';
  c_b2c constant varchar2(3)  := 'B2C';
  --c_b2g constant varchar2(3)  := 'B2G';
  --c_b2o constant varchar2(3)  := 'B2O';
  c_b2c_text constant varchar2(50) := 'Юридическое Лицо';
  -- возвращаемое значение
  v_retval varchar2(256) := null;
  v_user_status varchar2(50);
begin
  begin
    select lab.user_status into v_user_status
      from reqmon.lt_abonents$ lab
     where lab.pin = p_account;
    -- Определяем сегмент рынка
    if (v_user_status = c_b2c_text) then
      v_retval := c_b2b;
    else
      v_retval := c_b2c;
    end if;
  exception
    when no_data_found then v_retval := null;
  end;
  return v_retval;
end get_f_$ltabonent_segment;
/
