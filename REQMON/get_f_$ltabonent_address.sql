create or replace function get_f_$ltabonent_address(p_account in varchar2)return varchar2 is
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
  v_retval  varchar2(256);
  r_abonent reqmon.lt_abonents$%rowtype;
  function get_field(p_field in varchar2) return varchar2 is
    v_ret varchar2(256) := null;
  begin
    if (p_field is not null) then
      v_ret := replace(p_field, '''', '"')||', ';
    end if;
    return v_ret; 
  end;
begin
  begin
    select * into r_abonent
      from reqmon.lt_abonents$ lab
     where lab.pin = p_account;
     v_retval := get_field(r_abonent.p_index)||get_field(r_abonent.city)||get_field(r_abonent.street)||get_field(r_abonent.house_k)||
                 get_field(r_abonent.house_n)||r_abonent.kvartira;
  exception
    when no_data_found then v_retval := c_no_address;
  end;
  return v_retval;
end get_f_$ltabonent_address;
/
