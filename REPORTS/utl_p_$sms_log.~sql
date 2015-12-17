create or replace package utl_p_$sms_log is
/*
  Author  : V.ERIN
  Created : 29.03.2015 12:00:00
  Purpose : Пакет для добавления записей в журнал SMS для статистической обработки
  Version : 1.1.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    28.03.2015     Создание 
  -------------------------------------------------------------------------------------------------
  -- Пример получаемой строки
  --
  -- 01.04.2015 09:32:02 ;PAY_REQ_INFO; 79859685786;Тестовое сообщение.Test message № "Hello";["491181709186826268"]
  --
*/
  -- Глобальные переменные
  type t_string is table of varchar2(32000);
  --
  -- Константы
  --
  c_log_error  constant number := -20500;
  --
  -- Функция разбиения строки на подстроки по разделителю
  --
  function split_string(p_str in varchar2,p_delim in varchar2) return t_string pipelined;
  --
  -- Функция начала обработки файла
  --
  function start_file(p_file_name in varchar2) return number;
  --
  -- Процедура окончания обработки файла
  --
  procedure stop_file(p_file_name in varchar2);
  --
  -- Процедура добавления записи в лог SMS
  --
  procedure add_sms_log(p_file_id    in varchar2,
                        p_rec_num    in varchar2, 
                        p_log_string in varchar2);
  --
end utl_p_$sms_log;
/
create or replace package body utl_p_$sms_log is
  --
  -- Функция разбиения строки на подстроки по разделителю
  --
  function split_string(p_str in varchar2,p_delim in varchar2) return t_string pipelined is
    l_b number := 1;
    l_e number := 1;
  begin
    while (l_e > 0) loop
        l_e := instr(p_str, p_delim, l_b);
        if (l_e > 0) then
          pipe row(substr(p_str, l_b, l_e-l_b));
          l_b := l_e+1;
        else
          pipe row(substr(p_str, l_b));
        end if;
    end loop;
    return; -- для конвеерной функции просто заканчиваем работу
  end ;
  --
  -- Функция начала обработки файла
  --
  function start_file(p_file_name in varchar2) return number is
    v_cnt    number;
    v_retval number;
  begin
    select count(1) into v_cnt from sms_log_files$ slf where slf.file_name = p_file_name;
    if (v_cnt > 0) then
      raise_application_error(c_log_error, 'Файл '||p_file_name||' был обработан ранее.');
    else
      select smfl$_seq.nextval into v_retval from dual;
      insert into sms_log_files$ (smfl_id, file_name, start_date) values (v_retval, p_file_name, sysdate);
      commit;
    end if;
    return v_retval;
  end;
  --
  -- Процедура окончания обработки файла
  --
  procedure stop_file(p_file_name in varchar2) is
    v_file_id   number;
    v_processed number;
    v_error     number;
  begin
    begin
      select slf.smfl_id into v_file_id from sms_log_files$ slf where slf.file_name = p_file_name;
      -- Обрабоатано
      select count(1) into v_processed from sms_log$ sl where sl.smlg_smfl_id = v_file_id;
      -- Ошибки
      select count(1) into v_error from sms_error_log$ sel where sel.selg_smfl_id = v_file_id;
      --
      update sms_log_files$ slf set slf.processed_date = sysdate, slf.processed_rec = v_processed,slf.error_rec = v_error where slf.smfl_id = v_file_id;
      commit;
    exception
      when no_data_found then raise_application_error(c_log_error, 'Файл '||p_file_name||' еще не обрабатывался.');
    end;
  end;
  --
  -- Процедура добавления записи в лог ошибок SMS
  --
  procedure add_err_log(p_file_id    in number,
                        p_rec_num    in number, 
                        p_log_string in varchar2,
                        p_err_string in varchar2) is
  begin
    insert into sms_error_log$ (selg_smfl_id, rec_num, file_text, load_err) values(p_file_id, p_rec_num, substr(p_log_string,1,4000), p_err_string);
    commit;
  end;
  --
  -- Процедура добавления записи в лог SMS
  --
  procedure add_sms_log(p_file_id    in varchar2,
                        p_rec_num    in varchar2, 
                        p_log_string in varchar2) is
    c_group_div     constant char(1) := ';';
    v_sms_name      varchar2(50);
    v_sms_phone     varchar2(50);
    v_sms_text      varchar2(4000);
    v_sms_response  varchar2(4000);
    v_resp          varchar2(256);
    v_sms_date      date;
    v_parts         number;
    i               integer := 0;
    j               integer := 0;
  begin
    begin
      -- Разбиваем строку на поля
      for val_r in (select strings.column_value str
                      from table(split_string(p_log_string, c_group_div)) strings) loop
          i := i + 1;
          case i
             when 1 then v_sms_date      := to_date(trim(val_r.str), 'dd.mm.yyyy hh24:mi:ss');
             when 2 then v_sms_name      := val_r.str;
             when 3 then v_sms_phone     := val_r.str;
             when 4 then v_sms_text      := substr(val_r.str, 1, 4000);
             when 5 then v_sms_response  := substr(val_r.str, 1, 4000);
             else   exit;
          end case; 
      end loop;
      if (v_sms_response is null) or (v_sms_response like '{"Code":%') then
        if (v_sms_response is null) then
          v_sms_response := 'Не обнаружен результат отправки SMS';
        end if;
        add_err_log(p_file_id, p_rec_num, p_log_string, v_sms_response);  
      else
        v_sms_response := replace(replace(v_sms_response,'[',''),']','');
        -- Разбираем ответ на составные части
        for resp_r in (select trim(regexp_substr(str, '[^,]+', 1, level)) str
                         from (select v_sms_response str from dual) t 
                      connect by instr(str, ',', 1, level - 1) > 0) loop
          j := j + 1;
          v_resp := resp_r.str;
        end loop;
        v_parts := j;
        -- Вставляем данные в таблицу статистики
        insert into sms_log$(smlg_smfl_id, rec_num, sms_name, sms_phone, sms_text, sms_response, sms_parts, sms_date)
                      values(p_file_id, p_rec_num, v_sms_name, v_sms_phone, v_sms_text, v_resp, v_parts, v_sms_date);
        commit;
      end if;
    exception
       when others then add_err_log(p_file_id, p_rec_num, p_log_string, sqlerrm);
    end;
  end;
  --
begin
  null;
end utl_p_$sms_log;
/
