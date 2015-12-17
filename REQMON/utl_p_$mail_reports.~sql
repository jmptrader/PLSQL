create or replace package utl_p_$mail_reports authid current_user is
/*
  Author  : V.ERIN
  Created : 25.12.2014 12:00:00
  Purpose : Объекты для подготовки и отправки отчетов по почте 
  Version : 1.1.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    25/12/2014     Создание пакета
  -------------------------------------------------------------------------------------------------
  V.ERIN    09/01/2015     Косметические изменения
  -------------------------------------------------------------------------------------------------
*/
  --
  -- Константы
  --
  c_divider constant char(1) := chr(59);
  --
  -- Функция создания данных отчета
  --
  function make_data(p_rep_sql     in varchar2,
                     p_report_data in out utl_p_$send_messages.text_table_t)return integer;
  --
  -- Функция создания и отправки отчета
  --
  function send_report(p_mail_receiver in varchar2,
                       p_rep_name      in varchar2,
                       p_rep_sql       in varchar2,
                       p_mail_body     in varchar2 default null) return integer;
  --
  -- Процедура создания заявки на отправку отчета
  --
  procedure create_report_req;
  --
  -- Процедура установки "," в качестве разделителя дробной части числа
  --
  procedure set_comma;
  --
  -- Процедура установки "." в качестве разделителя дробной части числа
  --
  procedure set_dot;
  --
end utl_p_$mail_reports;
/
create or replace package body utl_p_$mail_reports is
  --
  -- Функция создания данных отчета
  --
  function make_data(p_rep_sql       in varchar2,
                     p_report_data   in out utl_p_$send_messages.text_table_t
                     )return integer is
  begin
    return make_f_$report(p_rep_sql, p_report_data, c_divider);
  end;
  --
  -- Функция создания и отправки отчета 
  --
  function send_report(p_mail_receiver in varchar2,
                       p_rep_name      in varchar2,
                       p_rep_sql       in varchar2,
                       p_mail_body     in varchar2) return integer is
    -- Таблица для данных отчета
    v_report_data   utl_p_$send_messages.text_table_t := utl_p_$send_messages.text_table_t(null);
    -- возвращаемое значение
    v_retval        integer := 0;
    -- Дата отчета
    v_rep_date      date := sysdate;
    -- Данные для сообщения
    v_mail_subject  varchar2(256) := p_rep_name;
    v_mail_message  varchar2(256) := 'Дата создания '||to_char(v_rep_date,'dd.mm.yyyy hh24:mi:ss'); 
  begin
    -- Устанавливаем запятую как разделитель дробной части числа
    set_comma;
    if (trim(v_mail_subject) is null) then
      v_mail_subject := 'Отчет';
    end if;
    -- Данные отчета
    v_report_data.delete;
    v_retval := make_data(p_rep_sql, v_report_data);
    v_mail_message := v_mail_message||utl_tcp.crlf||p_mail_body;
    -- Отправляем отчет
    if v_retval = 0 then             
       v_retval := utl_p_$send_messages.send_mail(p_mail_receiver, v_mail_subject, v_mail_message, p_rep_name||'.csv' , v_report_data);
    end if;
    -- Устанавливаем точку как разделитель дробной части числа
    set_dot;
    return v_retval;
  end;
  --
  -- Процедура создания заявки на отправку отчета
  --
  procedure create_report_req is
  begin
    null;
  end;
  --
  -- Процедура установки "," в качестве разделителя дробной части числа
  --
  procedure set_comma is
  begin
    execute immediate 'alter session set nls_numeric_characters='',.''';
  end;
  --
  -- Процедура установки "." в качестве разделителя дробной части числа
  --
  procedure set_dot is
  begin
    execute immediate 'alter session set nls_numeric_characters=''.,''';
  end;
  --
begin
  null;
end utl_p_$mail_reports;
/
