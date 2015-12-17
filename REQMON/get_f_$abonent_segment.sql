create or replace function get_f_$abonent_segment(p_account_id in integer)return varchar2 is
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
  c_b2g constant varchar2(3)  := 'B2G';
  c_b2o constant varchar2(3)  := 'B2O';
  --
  v_cardtype_id  number;
  v_finans_id    number;
  v_retval       varchar2(3) := c_b2c;
begin
  begin
    select ab.cardtype_id, nvl(aco.finans, -1) into v_cardtype_id, v_finans_id
      from cifra.ao_abonent ab, cifra.ao_contragent ac, cifra.ao_contragent_org aco
     where ab.id = p_account_id
       and ab.contragent_id = ac.id(+)
       and aco.contragent(+) = ac.id;
    -- Определяем сегмент рынка
    case
      when v_cardtype_id = 0 then v_retval := c_b2c;
      when v_finans_id = 1   then v_retval := c_b2g;
      when v_finans_id = 2   then v_retval := c_b2o;
      else v_retval := c_b2b;
    end case;
  exception
    when no_data_found then v_retval := null;
  end;
  return v_retval;
end get_f_$abonent_segment;
/
