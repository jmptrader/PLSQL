create or replace package utl_p_$repgui is
/*
  Author  : V.ERIN
  Created : 07.06.2015 12:00:00
  Purpose : Объекты для обеспечения работы GUI
  Version : 1.0.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    07/06/2015     Создание пакета
  -------------------------------------------------------------------------------------------------
*/
  --
  --  Отправка отчета по email
  --
  procedure send_report(p_title in varchar2, p_address in varchar2, p_sql in varchar2);
  --
  --  Добавить отчет
  --
  procedure add_report(p_type_id in varchar2, p_title in varchar2, p_sql in varchar2);
  --
end utl_p_$repgui;
/
create or replace package body utl_p_$repgui is
  --
  --  Отправка отчета по email
  --
  procedure send_report(p_title in varchar2, p_address in varchar2, p_sql in varchar2) is
    v_code integer;
  begin
    v_code := reqmon.utl_p_$mail_reports.send_report(p_address, p_title, p_sql);
    if (v_code <> 0) then
      raise_application_error(-20000, 'Код: '||v_code||' SQL: '||p_sql);
    end if;
  end;
  --
  --  Добавить отчет
  --
  procedure add_report(p_type_id in varchar2, p_title in varchar2, p_sql in varchar2) is
  begin
    insert into reports$ (rpts_id, rpts_rptp_id, rpts_name, rpts_body)
                  values (rpts$_seq.nextval, p_type_id, p_title, p_sql);
  end;
  --  
begin
  null;
end utl_p_$repgui;
/
