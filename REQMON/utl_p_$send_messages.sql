create or replace package utl_p_$send_messages is
/*
  Author  : V.ERIN
  Created : 21.09.2014 12:00:00
  Purpose : Объекты для отправки информации отчетов по почте 
  Version : 1.1.07
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    17/10/2014     Создание пакета
  -------------------------------------------------------------------------------------------------
  V.ERIN    07/01/2015     Адаптация к Oracle UTF-8
  -------------------------------------------------------------------------------------------------
  V.ERIN    08/01/2015     Устранена ошибка при получении большого ответа от сервера
                           и добавлена работа с unicode
  -------------------------------------------------------------------------------------------------
  V.ERIN    08/02/2015     Доработана отправка вложений, работа с двоичными файлами и encode64
  -------------------------------------------------------------------------------------------------
  V.ERIN    14/02/2015     Убрано encode64 при передачи текстового файла
  -------------------------------------------------------------------------------------------------
  V.ERIN    15/02/2015     Сделаны настройки на сервер SMTP
  -------------------------------------------------------------------------------------------------
  V.ERIN    26/03/2015     Доработка отправки SMS для нового провайдера
  -------------------------------------------------------------------------------------------------
  V.ERIN    26/03/2015     Добавлена функция отправки GET запроса
  -------------------------------------------------------------------------------------------------
*/
  -- Константы
  c_win_cp   constant varchar2(50) := 'windows-1251';
  c_utf_cp   constant varchar2(50) := 'utf-8';
  c_utf_sign constant varchar2(50) := 'UTF8';
  --
  -- Глобальные переменные
  --
  --  SMTP
  nls_charset     varchar2(256)  := '';
  smtp_server     varchar2(256)  := '';
  smtp_port       integer        := 25;
  smtp_user       varchar2(256)  := '';
  smtp_password   varchar2(256)  := '';
  smtp_sender     varchar2(256)  := '';
  -- SMS
  smsc_login      varchar2(256)  :='cifra1';
  smsc_password   varchar2(256)  :='7304050';
  smsc_url        varchar2(256)  := '';
  smsc_url_d      varchar2(256)  := '';
  -- HTTP
  c_codepage      varchar2(256)  := c_win_cp;
  -- Error
  c_mail_error    number         := -20199;

  --
  -- Глобальные типы данных
  --
  -- Текстовая таблица 
  type text_table_t is table of varchar2(32767); 
  -- Тип для возврата ответа от SMSC
  type http_resp_t is record (
       resp_code integer,
       resp_msg  varchar2(2000));
  --
  -- Функция получения значения параметра
  --
  function get_param_value(p_rqpm_id in varchar2, def_value in varchar2) return varchar2;
  --
  -- функция простого почтового сообщения
  --
  function send_mail(p_mail_receiver in varchar2, 
                     p_mail_subject  in varchar2,
                     p_mail_message  in varchar2) return integer;
  --
  -- функция отправки почтового сообщения с двоичным вложением
  --
  function send_mail(p_mail_receiver in varchar2, 
                     p_mail_subject  in varchar2,
                     p_mail_message  in varchar2,
                     p_att_filename  in varchar2,
                     p_att_data      in blob) return integer;
  --
  -- Функция отправки почтового сообщения c текстовым вложением
  --
  function send_mail(p_mail_receiver in varchar2, 
                     p_mail_subject  in varchar2,
                     p_mail_message  in varchar2,
                     p_att_filename  in varchar2,
                     p_att_data      in text_table_t) return integer;
  --
  -- Функция отправки SMS сообщения
  --
  function send_sms(p_sms_receiver in varchar2, 
                    p_sms_message  in varchar2,
                    p_sms_name     in varchar2 default null) return http_resp_t;
  --
  -- Функция отправки SMS сообщения "MobilMany"
  --
  function send_sms_m(p_sms_receiver in varchar2, 
                      p_sms_message  in varchar2) return http_resp_t;

  --
  -- Функция отправки SMS сообщения "DevinoTelecom"
  --
  function send_sms_d(p_sms_receiver in varchar2, 
                      p_sms_message  in varchar2,
                      p_sms_name     in varchar2) return http_resp_t;
  --
  -- Функция отправки POST запроса 
  --
  function post_send(p_url in varchar2, p_post_message in varchar2) return http_resp_t;
  --
  -- Функция отправки GET запроса 
  --
  function get_send(p_url in varchar2, p_get_message in varchar2) return http_resp_t;
  --
end utl_p_$send_messages;
/
create or replace package body utl_p_$send_messages is
  --
  -- Функция получения значения параметра
  --
  function get_param_value(p_rqpm_id in varchar2, def_value in varchar2) return varchar2 is
    v_retval varchar2(50) := def_value;
  begin
    begin
      select rqp.rqpm_value into v_retval from req_parameters$ rqp where rqp.rqpm_id = p_rqpm_id;
    exception
      when no_data_found then null;
    end;
    return v_retval;
  end;
  --
  -- функция отправки почтового сообщения (внутренняя)
  --
  function send_mail_i(p_mail_receiver in varchar2, 
                       p_mail_subject  in varchar2,
                       p_mail_message  in varchar2,
                       p_att_filename  in varchar2,
                       p_att_text      in text_table_t,
                       p_att_data      in blob) return integer is
    c_group_div          constant char(1) := ';';
    -- дескриптор smtp-соединение
    v_mail_conn          utl_smtp.connection;
    -- возвращаемое значение
    v_retval             integer := 0;
    -- типы для MIME
    boundary             varchar2(256) := '------------020505050007030702030904';
    first_boundary       varchar2(256) := '--'||boundary;
    last_boundary        varchar2(256) := '--'||boundary||'--';
    multipart_mimetype   varchar2(256) := 'multipart/mixed; boundary="'||boundary||'"';
    text_mimetype        varchar2(256) := 'text/plain; charset='||c_codepage||';';
    v_len                integer       := 129*50; -- для нормальной обработки склеивания encode 64 кратно 129
    -- функция для подготовки закодированной строки для mime заголовков
    function mime_str(p_str in varchar) return varchar2 is
      v_buf      varchar2(256);
      v_template varchar2(256) := '=?'||c_codepage||'?B?<encoded text>?=';
    begin
      v_buf := replace(utl_encode.text_encode(p_str, nls_charset, utl_encode.base64),utl_tcp.crlf,'');
      v_buf := replace(v_template,'<encoded text>',v_buf);
      return v_buf;
    end;
  begin
    begin
      -- установка соединения
      v_mail_conn := utl_smtp.open_connection(smtp_server, smtp_port);
      -- подтверждение установки связи
      utl_smtp.helo(v_mail_conn, smtp_server);
      -- идентификация пользователя
      if smtp_password is not null then
        utl_smtp.command(v_mail_conn, 'auth login');
        utl_smtp.command(v_mail_conn, utl_encode.text_encode(smtp_user, nls_charset, 1));
        utl_smtp.command(v_mail_conn, utl_encode.text_encode(smtp_password, nls_charset, 1));
      end if;
      -- установка адреса отправителя
      utl_smtp.mail(v_mail_conn, smtp_sender);
      -- Разбиваем строку c получателями на составные части
      for val_r in (select trim(regexp_substr(str, '[^'||c_group_div||']+', 1, level)) str 
                      from (select p_mail_receiver str from dual) t 
                   connect by instr(str, c_group_div, 1, level - 1) > 0) loop
         if (val_r.str is not null) then
           -- установка адреса получателя
           utl_smtp.rcpt(v_mail_conn, val_r.str);
         end if;
      end loop; 
      -- отправка команды data, после которой можно начать передачу письма
      utl_smtp.open_data(v_mail_conn);
      -- отправка заголовков письма: дата, "от", "кому", "тема"
      utl_smtp.write_data(v_mail_conn, 'date: ' || to_char(sysdate,'dd mon yy hh24:mi:ss','NLS_DATE_LANGUAGE = AMERICAN') || utl_tcp.crlf);
      utl_smtp.write_data(v_mail_conn, 'from: ' || smtp_sender || utl_tcp.crlf);
      utl_smtp.write_data(v_mail_conn, 'to: '   || p_mail_receiver || utl_tcp.crlf);
      utl_smtp.write_data(v_mail_conn, 'subject:'||mime_str(p_mail_subject)|| utl_tcp.crlf);
      utl_smtp.write_data(v_mail_conn, 'mime-version: 1.0'||utl_tcp.crlf);
      if trim(p_att_filename) is null then
          -- передача простого письма
          utl_smtp.write_data(v_mail_conn, 'content-type: '||text_mimetype||utl_tcp.crlf);
          utl_smtp.write_data(v_mail_conn, 'content-transfer-encoding: 8 bit'||utl_tcp.crlf);
          utl_smtp.write_raw_data(v_mail_conn, utl_raw.cast_to_raw(utl_tcp.crlf || p_mail_message));
        else
          -- передача многосекционного письма
          utl_smtp.write_data(v_mail_conn, 'content-type: '||multipart_mimetype||utl_tcp.crlf);
          utl_smtp.write_data(v_mail_conn, utl_tcp.crlf);
          utl_smtp.write_data(v_mail_conn, 'this is a multi-part message in mime format.' || utl_tcp.crlf);
          utl_smtp.write_data(v_mail_conn, utl_tcp.crlf);
          -- передача тела письма
          utl_smtp.write_data(v_mail_conn, first_boundary||utl_tcp.crlf);
          utl_smtp.write_data(v_mail_conn, 'content-type: '||text_mimetype||utl_tcp.crlf);
          utl_smtp.write_data(v_mail_conn, 'content-transfer-encoding: 8 bit'||utl_tcp.crlf);
          utl_smtp.write_data(v_mail_conn, utl_tcp.crlf);
          utl_smtp.write_raw_data(v_mail_conn, utl_raw.cast_to_raw(utl_tcp.crlf || p_mail_message));
          utl_smtp.write_data(v_mail_conn, utl_tcp.crlf);
          -- передача вложения
          utl_smtp.write_data(v_mail_conn, first_boundary||utl_tcp.crlf);
          utl_smtp.write_data(v_mail_conn, 'content-type: application/octet-stream; name="'||mime_str(p_att_filename)||'"'||utl_tcp.crlf);
          if (p_att_text is null) and (p_att_data is not null) then
             utl_smtp.write_data(v_mail_conn, 'content-transfer-encoding: base64'||utl_tcp.crlf);
          end if;
          utl_smtp.write_data(v_mail_conn, 'content-disposition: attachment; filename="'||mime_str(p_att_filename)||'"'||utl_tcp.crlf);
          utl_smtp.write_data(v_mail_conn, utl_tcp.crlf);
          if (p_att_text is not null) and (p_att_data is null) then
            -- формируем данные вложения для текста
            for i in 1..p_att_text.last loop
              if p_att_text.exists(i) then
                 utl_smtp.write_raw_data(v_mail_conn, utl_raw.cast_to_raw(p_att_text(i)));
              end if;
            end loop; 
          elsif (p_att_text is null) and (p_att_data is not null) then
            -- формируем данные вложения для данных
            for i in 0 .. trunc( ( dbms_lob.getlength( p_att_data ) - 1 ) / v_len ) loop
              utl_smtp.write_raw_data(v_mail_conn, utl_encode.base64_encode(dbms_lob.substr( p_att_data , v_len, i * v_len + 1 )));
              --utl_smtp.write_data(v_mail_conn, utl_tcp.crlf);
            end loop;
            utl_smtp.write_raw_data(v_mail_conn, '3D3D');
          else
            raise_application_error(c_mail_error,'Attachment error');
          end if;
          utl_smtp.write_data(v_mail_conn, utl_tcp.crlf);
          utl_smtp.write_data(v_mail_conn, last_boundary);
      end if;
      -- передача сигнала о завершении передачи сообщения
      utl_smtp.close_data(v_mail_conn);
      -- завершение сессии и закрытие соединения с сервером
      utl_smtp.quit(v_mail_conn);
    exception
      -- если произошла ошибка передачи данных, закрыть соединение и вернуть
      -- ошибку передачи письма
      when utl_smtp.transient_error or utl_smtp.permanent_error then
        begin
           utl_smtp.quit(v_mail_conn);
        exception
           -- если smtp сервер недоступен, соединение с сервером отсутствует.
           -- вызов quit приводит к ошибке. обработка исключения позволяет
           -- игнорировать эту ошибку.
           when utl_smtp.transient_error or utl_smtp.permanent_error then null;
        end;
        v_retval := sqlcode;
    end;
    return v_retval;
  end;
  --
  -- функция простого почтового сообщения
  --
  function send_mail(p_mail_receiver in varchar2, 
                     p_mail_subject  in varchar2,
                     p_mail_message  in varchar2) return integer is
  begin
    return send_mail_i(p_mail_receiver => p_mail_receiver, 
                       p_mail_subject  => p_mail_subject,
                       p_mail_message  => p_mail_message,
                       p_att_filename  => null,
                       p_att_text      => null,
                       p_att_data      => null);
  end;
  --
  -- функция отправки почтового сообщения с двоичным вложением
  --
  function send_mail(p_mail_receiver in varchar2, 
                     p_mail_subject  in varchar2,
                     p_mail_message  in varchar2,
                     p_att_filename  in varchar2,
                     p_att_data      in blob) return integer is
  begin
    return send_mail_i(p_mail_receiver => p_mail_receiver, 
                       p_mail_subject  => p_mail_subject,
                       p_mail_message  => p_mail_message,
                       p_att_filename  => p_att_filename,
                       p_att_text      => null,
                       p_att_data      => p_att_data);
  end;
  --
  -- функция отправки почтового сообщения c текстовым вложением
  --
  function send_mail(p_mail_receiver in varchar2, 
                     p_mail_subject  in varchar2,
                     p_mail_message  in varchar2,
                     p_att_filename  in varchar2,
                     p_att_data      in text_table_t) return integer is
  begin
    return send_mail_i(p_mail_receiver => p_mail_receiver, 
                       p_mail_subject  => p_mail_subject,
                       p_mail_message  => p_mail_message,
                       p_att_filename  => p_att_filename,
                       p_att_text      => p_att_data,
                       p_att_data      => null);
  end;
  --
  -- Функция отправки SMS сообщения "MobilMany"
  --
  function send_sms_m(p_sms_receiver in varchar2, 
                      p_sms_message  in varchar2) return http_resp_t is
    sms_text      varchar2(32767) := '';
    sms_hdr       varchar2(256);
    sms_body      varchar2(4000);
    sms_ftr       varchar2(256);
    v_retval      http_resp_t;
  begin
    -- Заполняем заголовок POST сообщения
    sms_hdr  :=      '<?xml version="1.0" encoding="$smsc_codepage"?>'||utl_tcp.crlf||    
                     '<request method="sendSMS">'||utl_tcp.crlf|| 
                     '<login>$smsc_login</login>'||utl_tcp.crlf||  
                     '<pwd>$smsc_password</pwd>';  
    sms_hdr  := replace(sms_hdr, '$smsc_codepage', c_codepage);
    sms_hdr  := replace(sms_hdr, '$smsc_login', smsc_login);
    sms_hdr  := replace(sms_hdr, '$smsc_password', smsc_password);
    -- Создаем тело сообщения
    sms_body := '<originator>Cifra1</originator>'||utl_tcp.crlf||  
                '<phone_to>$sms_receiver</phone_to>'||utl_tcp.crlf||  
                '<message>$sms_message</message>'||utl_tcp.crlf||
                '<sync>0</sync>'; 
    sms_body := replace(sms_body, '$sms_receiver', p_sms_receiver);
    sms_body := replace(sms_body, '$sms_message',p_sms_message);
    -- Окончание сообщения
    sms_ftr  := '</request>';
    -- Создаем сообщение целиком
    sms_text := sms_hdr||utl_tcp.crlf||sms_body||utl_tcp.crlf||sms_ftr;
    -- Отправляем 
    v_retval := post_send(smsc_url, sms_text);
    return v_retval;
  end;
  --
  -- Функция отправки SMS сообщения "DevinoTelecom"
  --
  function send_sms_d(p_sms_receiver in varchar2, 
                      p_sms_message  in varchar2,
                      p_sms_name     in varchar2) return http_resp_t is
    v_post_message varchar2(32767) := 'phone=$phone&smstext=$smstext&smsname=$smsname';
  begin
    v_post_message  := replace(v_post_message, '$phone',   p_sms_receiver);
    v_post_message  := replace(v_post_message, '$smstext', p_sms_message);
    v_post_message  := replace(v_post_message, '$smsname', p_sms_name);
    return post_send(smsc_url_d, v_post_message);
  end;
  --
  -- Функция отправки SMS сообщения
  --
  function send_sms(p_sms_receiver in varchar2, 
                    p_sms_message  in varchar2,
                    p_sms_name     in varchar2) return http_resp_t is
  begin
    --return send_sms_m(p_sms_receiver, p_sms_message);
    return send_sms_d(p_sms_receiver, p_sms_message, p_sms_name);
  end;
  --
  -- Функция отправки POST запроса 
  --
  function post_send(p_url in varchar2, p_post_message in varchar2) return http_resp_t is
    http_req      utl_http.req;
    http_res      utl_http.resp;
    resp_msg      varchar2(32767);
    v_retval      http_resp_t;
    post_text     varchar2(32767) := p_post_message;
  begin
    v_retval.resp_code := 0;
    v_retval.resp_msg := '';
    begin
      utl_http.set_transfer_timeout(30);
      http_req := utl_http.begin_request(p_url, 'POST', utl_http.HTTP_VERSION_1_1);
      utl_http.set_body_charset(http_req, c_codepage);
      utl_http.set_header(http_req, 'Content-Type', 'application/x-www-form-urlencoded');
      utl_http.set_header(http_req, 'Content-Length', lengthb(post_text));
      utl_http.write_text(http_req, post_text);
      http_res := utl_http.get_response(http_req);
      utl_http.read_text(http_res, resp_msg);
      utl_http.end_response(http_res);
      -- Обрабатываем ответ сервера. 
      v_retval.resp_code := 0;
      v_retval.resp_msg  := substrb(resp_msg,0,2000);     
     exception
      when others then 
        v_retval.resp_code := sqlcode;
        v_retval.resp_msg  := sqlerrm;
        if (http_res.private_hndl is not null) then
           utl_http.end_response(http_res);
        end if;
    end;
    return v_retval;
  end;
  --
  -- Функция отправки GET запроса 
  --
  function get_send(p_url in varchar2, p_get_message in varchar2) return http_resp_t is
    http_req      utl_http.req;
    http_res      utl_http.resp;
    resp_msg      varchar2(32767);
    v_retval      http_resp_t;
  begin
    v_retval.resp_code := 0;
    v_retval.resp_msg := '';
    begin
      utl_http.set_transfer_timeout(30);
      http_req := utl_http.begin_request(p_url||'?'||p_get_message, 'GET', utl_http.HTTP_VERSION_1_1);
      utl_http.set_header(http_req, 'Content-Type', 'application/x-www-form-urlencoded');
      utl_http.set_body_charset(http_req, c_codepage);
      http_res := utl_http.get_response(http_req);
      utl_http.read_text(http_res, resp_msg);
      utl_http.end_response(http_res);
      -- Обрабатываем ответ сервера. 
      v_retval.resp_code := 0;
      v_retval.resp_msg  := substrb(resp_msg,0,2000);     
     exception
      when others then 
        v_retval.resp_code := sqlcode;
        v_retval.resp_msg  := sqlerrm;
        if (http_res.private_hndl is not null) then
           utl_http.end_response(http_res);
        end if;
    end;
    return v_retval;
  end;
  --
begin
  -- Инициализация параметров
  select value into nls_charset from nls_database_parameters where  parameter = 'NLS_CHARACTERSET';
  --
  smtp_server   := get_param_value('SMTP_SERVER','10.15.1.196');
  smtp_port     := get_param_value('SMTP_PORT',25);
  smtp_user     := get_param_value('SMTP_USER','informer@cifra1.ru');
  smtp_password := get_param_value('SMTP_PASSWORD',null);
  --
  smsc_url    := get_param_value('SMSC_URL','10.15.5.19/sms_gate/sms_gate.php');
  smsc_url_d  := get_param_value('SMSC_URL_D','10.15.5.19/sms_gate/sms_gate_d.php');
  smtp_sender := smtp_user;
  -- Если СУБД в unicode 
  if instr(nls_charset,c_utf_sign) > 0 then
    c_codepage := c_utf_cp;
  end if;
end utl_p_$send_messages;
/
