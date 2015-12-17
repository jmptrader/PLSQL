create or replace package req_p_$process is
/*
  Author  : V.ERIN
  Created : 21.09.2014 12:00:00
  Purpose : ������� ��� ������ �������� ��������� ������.
  Version : 1.1.03
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    17/10/2014     �������� ������
  -------------------------------------------------------------------------------------------------
  V.ERIN    07/01/2015     ��������� � Oracle 12.1
  -------------------------------------------------------------------------------------------------
  V.ERIN    08/01/2015     ���������� ������ ��� ��������� ��������� �������
  -------------------------------------------------------------------------------------------------
  V.ERIN    08/01/2015     ���������� ������ ��� ��������� ����������� ������������
  -------------------------------------------------------------------------------------------------
  V.ERIN    08/02/2015     ������� ����� ������� �������� email
  -------------------------------------------------------------------------------------------------
  V.ERIN    25/02/2015     ������ ��������� �������� ��� ������ 
  -------------------------------------------------------------------------------------------------
*/
  -- ���������
  c_ok_req        constant number  :=  0;
  c_new_req       constant number  :=  1;
  c_wrk_req       constant number  :=  2;
  c_cncl_req      constant number  :=  3;
  c_sms_req       constant char(1) := 'S';
  c_mail_req      constant char(1) := 'M';
  c_plsql_req     constant char(1) := 'P';
  c_iptv_req      constant char(1) := 'T';
  c_rep_req       constant char(1) := 'R';
  c_req_errcode   constant number  := -20010;
  c_req_job_name  constant varchar2(256) := 'REQ_MONITOR_';
  c_req_test_name constant varchar2(256) := 'TEST_REQ_INFO';
  c_one_min       constant number  := 1/(24*60);
  c_new_req_id    constant integer := -1;
  c_no_account    constant integer := -1;
  c_sms_err_tmpl  constant varchar2(256)  := '%<response method=''ErrorSMS''>%';
  c_srv_err_tmpl  constant varchar2(256)  := '%������ �������� � �������������� ������%';
  c_iptv_err_tmpl constant varchar2(256)  := '%<result>1</result>%';
  c_max_try       constant integer := 2;
  -- ����������
  c_prty_low      constant integer := 2;
  c_prty_med      constant integer := 1;
  c_prty_hi       constant integer := 0;
  -- ���������
  c_is_stoped_p   constant varchar2(256) :='IS_STOPED';
  c_step          integer := 5;
  c_req_job_max   integer := 3;
  c_req_hijob_max integer := 2;
  -- ���������
  c_invalid_req   constant varchar2(256) := '����������� ��� ������';
  c_is_stop_req   constant varchar2(256) := '���������� ���� ��������� ';
  c_info          constant varchar2(256) := 'INFO';
  c_duplicate     constant varchar2(256) := 'DUPLICATE';
  c_cancel        constant varchar2(256) := 'CANCEL';
  c_nexttime      constant varchar2(256) := 'POSTPONED';
  c_processing    constant varchar2(256) := '��������������';
  c_mail_subj     constant varchar2(256) := '���������';
  -- Exceptions
  record_locked exception;
  pragma exception_init(record_locked, -54);
  -- ����
  type t_text is table of varchar2(256);
  --
  -- ������� �������� ����� ������� ������
  --
  function get_reqst_name(p_rqst_status in integer) return varchar2;
  --
  -- ������� ���������� ���������
  --
  function prepare_message(p_text in varchar2, p_parameters in varchar2, p_account in varchar2) return varchar2;
  --
  -- ������� ��������� ������� xml �����
  --
  function get_xml_value(p_xml_text in varchar2, p_xml_key in varchar2) return t_text pipelined;
  --
  -- ��������� ��������� ������ (�����)
  --
  procedure req_process;
  --
  -- ��������� ��������� ������ (������� ���������)
  --
  procedure req_hi_process;
  --
  -- ��������� �������� ����������� ������
  --
  procedure create_req_jobs;
  --
  -- ��������� �������� ����������� ������
  --
  procedure drop_req_jobs;
  --
  -- ��������� ������� ����������� ������
  --
  procedure start_req_jobs;
  --
  -- ��������� ��������� ����������� ������
  --
  procedure stop_req_jobs;
  --
  -- ��������� �������� ������
  --
  function req_create( p_rqst_name        in varchar2 default null,
                       p_rqst_id          in number,
                       p_rqst_num         in number ,
                       p_rqst_rqtm_id     in number,
                       p_rqst_type        in char,
                       p_rqst_dst         in varchar2,
                       p_rqst_account     in varchar2,
                       p_rqst_add_params  in varchar2 default null,
                       p_rqst_dt_status   in date default sysdate,
                       p_rqst_priority    in number default c_prty_med) return number;
  --
  -- ��������� �������� ������� ������
  --
  function req_template_create(p_rqtm_text in varchar2) return number;
  --
  -- ������� ��������� �������� ���������
  --
  function get_param_value(p_rqpm_id in varchar2, def_value in varchar2 default null) return varchar2;
  --
  -- ������� ��������� ����� ��� ������� �������� ��������� ������
  --
  function get_req_job_name return varchar2;
  --
end req_p_$process;
/
create or replace package body req_p_$process is
  --
  -- ������� �������� ����� ������� ������
  --
  function get_reqst_name(p_rqst_status in integer) return varchar2 is
    v_name varchar2(256);
  begin
    case p_rqst_status 
      when  c_ok_req   then  v_name :=  '����������';
      when  c_new_req  then  v_name :=  '�������';
      when  c_wrk_req  then  v_name :=  '��������������';
      when  c_cncl_req then  v_name :=  '��������';
                       else  v_name :=  '������ ���������';
    end case;
    return v_name;
  end;
  --
  -- ������� ���������� ���������
  --
  function prepare_message(p_text in varchar2, p_parameters in varchar2, p_account in varchar2) return varchar2 is
    c_group_div  constant char(1) := ';';
    c_value_div  constant char(1) := ':';
    v_text       varchar2(4000) := p_text;
    v_key        varchar2(2000) := '';
    v_key_value  varchar2(2000) := '';
    
  begin
    -- ��������� ������ ���������� �� ���� "����������:��������"
    for val_r in (select trim(regexp_substr(str, '[^'||c_group_div||']+', 1, level)) str 
                    from (select p_parameters str from dual) t 
                 connect by instr(str, c_group_div, 1, level - 1) > 0) loop
      -- �������� � ������� ���������� �� �� ��������
      if (val_r.str is not null) then
        v_key := substr(val_r.str,0,instr(val_r.str, c_value_div)-1);
        v_key_value := substr(val_r.str,instr(val_r.str, c_value_div)+1);
        v_text := replace(v_text,'$'||v_key,v_key_value);
      end if;
    end loop; 
    v_text := replace(v_text,'$account',p_account);
    return v_text;     
  end;
  --
  -- ������� ��������� ������� xml �����
  --
  function get_xml_value(p_xml_text in varchar2, p_xml_key in varchar2) return t_text pipelined is
  begin
    for xml_rec in (select extractvalue(XMLTYPE(p_xml_text),p_xml_key) txt from dual) loop
      pipe row(xml_rec.txt);
    end loop;
    return;     
  end;
  --
  -- ��������� ��������� ������� ������
  --
  procedure set_req_status(p_id in number,
                           p_num in number,
                           p_status in varchar2,
                           p_responce in varchar2) is
    v_rqst_status number;
  begin
    if p_status = c_wrk_req then
      -- ��������� ������
      select rq.rqst_status into v_rqst_status from requests$ rq where rq.rqst_id = p_id and rq.rqst_num = p_num for update nowait;
      if v_rqst_status = c_new_req then
         update requests$ rq set rq.rqst_status = p_status, rq.rqst_response = p_responce, rq.rqst_dt_status = sysdate where rq.rqst_id = p_id and rq.rqst_num = p_num; 
          -- ������� ����������
         commit;
      else
         raise record_locked;
      end if;
    else
      -- ��������� ������ ������������ ������
      update requests$ rq set rq.rqst_status = p_status, rq.rqst_response = p_responce, rq.rqst_dt_status = sysdate where rq.rqst_id = p_id and rq.rqst_num = p_num; 
      commit;
    end if;
  end;
  --
  -- ��������� ���������� PL\SQL ������
  --
  function req_execute_plsql(p_req_text in varchar2) return number is
    v_req_text varchar(2000) := 'begin $req_text end;';
    v_retval   number := 0;
  begin 
    begin
      v_req_text := replace(v_req_text, '$req_text', p_req_text);
      execute immediate v_req_text;
    exception 
      when others then v_retval := sqlcode;
    end;
    return v_retval;
  end; 
  --
  -- ��������� ���������� ������
  --
  procedure req_execute(p_mreq_r in requests$%rowtype) is
    v_message    req_templates$.rqtm_text%type;
    resp         utl_p_$send_messages.http_resp_t;
    is_cncl_next     boolean := false;
    --is_postpone_next boolean := false;
    --v_try_count      integer := 0;
    -- ������� �������� �� ������������. � ������� ����� �� ���������� ���� � �� �� ���������
    function is_dublicate(p_req_r in requests$%rowtype) return boolean is
      v_cnt integer;
    begin
      select count(1) 
        into v_cnt
        from requests$ rq 
       where nvl(rq.rqst_add_params,'1') = nvl(p_req_r.rqst_add_params,'1') 
         and rq.rqst_account = p_req_r.rqst_account
         and rq.rqst_dst = p_req_r.rqst_dst
         and rq.rqst_name = p_req_r.rqst_name
         and rq.rqst_type = p_req_r.rqst_type
         and rq.rqst_rqtm_id = p_req_r.rqst_rqtm_id
         and not ((rq.rqst_id = p_req_r.rqst_id) and (rq.rqst_num = p_req_r.rqst_num))
         and trunc(rq.rqst_dt_status) = trunc(sysdate);
      return v_cnt > 0;   
    end;
    /*
    function try_count(msg in varchar2) return number is
      divider constant char(1) := ':';
      retval  integer;
      int_str varchar2(10);
    begin
      int_str := substr(msg,0,instr(msg, divider)-1);
      if int_str is null then
        retval := 1;
      else
        retval := to_number(int_str);
      end if;
      return retval;
    end;
    procedure repeat(msg in varchar2) is
    begin
      if (resp.resp_code in (-29273, -29266)) then
        v_try_count := try_count(msg);
        if v_try_count < c_max_try then
           v_try_count := v_try_count + 1;
           resp.resp_code := c_new_req;
           resp.resp_msg  := v_try_count||':'||c_nexttime;
           is_postpone_next := true;
        end if;
      end if;
    end;*/
  begin
    for p_req_r in (select * 
                      from requests$ rq 
                     where rq.rqst_id = p_mreq_r.rqst_id 
                       and rq.rqst_status = c_new_req
                     order by rq.rqst_num ) loop
      -- ����� � ��������� 
      set_req_status(p_req_r.rqst_id, p_req_r.rqst_num, c_wrk_req, c_processing);
      -- ��������� ������ ���������
      select rm.rqtm_text into v_message from req_templates$ rm where rm.rqtm_id = p_req_r.rqst_rqtm_id;
      -- "�����������" ��������� � �������
      v_message := prepare_message(v_message, p_req_r.rqst_add_params, p_req_r.rqst_account);
      begin
        if (is_cncl_next) then
           -- �������� ������ ���� ���������� ����
           resp.resp_code := c_cncl_req;
           resp.resp_msg := c_cancel;      
        --elsif (is_postpone_next) then
           -- ����������� ������ ���� ���������� ����
           --resp.resp_code := c_new_req;
           --resp.resp_msg  := c_nexttime;
        elsif (p_req_r.rqst_dst = c_info) then
             -- ��� �������������� ������ ������������� ������� � ����������
           resp.resp_code := c_cncl_req;
           resp.resp_msg := c_info;      
        else
          if p_req_r.rqst_type = c_sms_req then
             -- ���������� SMS
             if is_dublicate(p_req_r) then
               -- �������� �� ������������, ��� �� �� ��������� ��������
               resp.resp_code := c_cncl_req;
               resp.resp_msg  := c_duplicate; 
             else
               resp := utl_p_$send_messages.send_sms(p_req_r.rqst_dst,v_message);
               -- ������ ��������� ������� ��������, ���� �� ������� � ������� ����
               --repeat(p_req_r.rqst_response);
               -- ����������� ����� ��� �������� ���
               if (resp.resp_msg like c_sms_err_tmpl) or (resp.resp_msg like c_srv_err_tmpl) then
                 resp.resp_code := c_req_errcode;
               end if;
             end if;
          elsif  p_req_r.rqst_type = c_mail_req then
             -- ���������� e-mail
             resp.resp_code := utl_p_$send_messages.send_mail(p_req_r.rqst_dst,c_mail_subj||' - '||p_req_r.rqst_name, v_message);
             resp.resp_msg := sqlerrm(resp.resp_code);      
          elsif  p_req_r.rqst_type = c_plsql_req then
             -- ��������� ���� PL\SQL
             resp.resp_code := req_execute_plsql(v_message);
             resp.resp_msg := sqlerrm(resp.resp_code);      
          elsif  p_req_r.rqst_type = c_iptv_req then
             -- ���������� ������� �� ������ IPTV
             resp:= utl_p_$send_messages.post_send(p_req_r.rqst_dst, v_message);
             -- ������ ��������� ������� ��������, ���� �� ������� � ������� ����
             --repeat(p_req_r.rqst_response);
             -- ����������� ����� ��� ���������� �������
             if (resp.resp_msg like c_iptv_err_tmpl) then
               resp.resp_code := c_req_errcode;
             end if;
          elsif  p_req_r.rqst_type = c_rep_req then
             -- ��������� �����
             resp.resp_code := utl_p_$mail_reports.send_report(p_req_r.rqst_dst, p_req_r.rqst_name, v_message);
             resp.resp_msg := sqlerrm(resp.resp_code);      
          else
             raise_application_error (c_req_errcode,c_invalid_req);
          end if;
          -- ���� ��������� ������, ������������� ����
          if (resp.resp_code < 0) then
            is_cncl_next := true;
          end if;
        end if;
        -- �������� ������ ������
        set_req_status(p_req_r.rqst_id, p_req_r.rqst_num, resp.resp_code, resp.resp_msg);
      exception 
        when others then 
          set_req_status(p_req_r.rqst_id, p_req_r.rqst_num, sqlcode, sqlerrm);
          is_cncl_next := true;
      end;
    end loop;
  end;
  --
  -- ��������� ��������� ������ (�����)
  --
  procedure req_process is
  begin
    -- �������� ��� ����� ������ � ��������� �� ����������
    for req_r in (select * 
                    from requests$ rq 
                   where rq.rqst_status = c_new_req 
                     and rq.rqst_dt_status <= sysdate
                     and rq.rqst_num = 1
                     /*
                     and rq.rqst_num = (select min(rqst_num) 
                                          from requests$ q 
                                         where q.rqst_status = c_new_req
                                           and q.rqst_id = rq.rqst_id)
                     and not exists (select q1.rqst_id 
                                       from requests$ q1 
                                      where ((q1.rqst_status = c_wrk_req) or (q1.rqst_status < 0))
                                        and q1.rqst_id = rq.rqst_id)
                      */
                     and rq.rqst_priority = c_prty_med
                   order by rq.rqst_priority, rq.rqst_id ) loop
      begin
        -- �������� �� ���� ���������
        if get_param_value(c_is_stoped_p) <> 0 then
          raise_application_error (c_req_errcode,c_is_stop_req);
        end if;
        req_execute(req_r);
      exception 
        when record_locked then null;
      end;
    end loop;
  end;
  --
  -- ��������� ��������� ������ (������� ���������)
  --
  procedure req_hi_process is
  begin
    -- �������� ��� ����� ������ � ��������� �� ����������
    for req_r in (select * 
                    from requests$ rq 
                   where rq.rqst_status = c_new_req 
                     and rq.rqst_dt_status <= sysdate
                     and rq.rqst_num = 1
                     /*
                     and rq.rqst_num = (select min(rqst_num) 
                                          from requests$ q 
                                         where q.rqst_status = c_new_req
                                           and q.rqst_id = rq.rqst_id)
                     and not exists (select q1.rqst_id 
                                       from requests$ q1 
                                      where ((q1.rqst_status = c_wrk_req) or (q1.rqst_status < 0))
                                        and q1.rqst_id = rq.rqst_id)
                     */
                     and rq.rqst_priority = c_prty_hi
                   order by rq.rqst_priority, rq.rqst_id ) loop
      begin
        -- �������� �� ���� ���������
        if get_param_value(c_is_stoped_p) <> 0 then
          raise_application_error (c_req_errcode,c_is_stop_req);
        end if;
        req_execute(req_r);
      exception 
        when record_locked then null;
      end;
    end loop;
  end;
  --
  -- ��������� �������� ����������� ������
  --
  procedure create_req_jobs is
    v_job_start_date date;
    v_job_name varchar2(256);
  begin
    -- ������� �������� ���������� ������� 
    for i in 1 .. c_req_job_max loop
      v_job_start_date := sysdate+(c_one_min*i);
      v_job_name := c_req_job_name||to_char(i);
      dbms_scheduler.create_job(job_name            => v_job_name,
                                job_type            => 'PLSQL_BLOCK',
                                job_action          => 'begin req_p_$process.req_process; end; ',
                                start_date          => v_job_start_date,
                                repeat_interval     => 'Freq=Minutely;Interval='||to_char(c_step),
                                end_date            => to_date(null),
                                job_class           => 'DEFAULT_JOB_CLASS',
                                enabled             => true,
                                auto_drop           => false,
                                comments            => '������� ��������� ������.��������� '||to_char(i));
    end loop;
    --
    for i in 1 .. c_req_hijob_max loop
      v_job_start_date := sysdate+(c_one_min*i);
      v_job_name := c_req_job_name||'HI_'||to_char(i);
      dbms_scheduler.create_job(job_name            => v_job_name,
                                job_type            => 'PLSQL_BLOCK',
                                job_action          => 'begin req_p_$process.req_hi_process; end; ',
                                start_date          => v_job_start_date,
                                repeat_interval     => 'Freq=Minutely;Interval=1',
                                end_date            => to_date(null),
                                job_class           => 'DEFAULT_JOB_CLASS',
                                enabled             => true,
                                auto_drop           => false,
                                comments            => '������� ��������� ������.��������� ��� ������ �������� ���������� '||to_char(i));
    end loop;
  end;
  --
  -- ��������� �������� ����������� ������
  --
  procedure drop_req_jobs is
  begin  
    for job_r in (select * from user_scheduler_jobs where job_name like c_req_job_name||'%') loop
      dbms_scheduler.drop_job(job_r.job_name);
    end loop;
  end;
  --
  -- ��������� �������� ������
  --
  function req_create( p_rqst_name        in varchar2,
                       p_rqst_id          in number,
                       p_rqst_num         in number,
                       p_rqst_rqtm_id     in number,
                       p_rqst_type        in char,
                       p_rqst_dst         in varchar2,
                       p_rqst_account     in varchar2,
                       p_rqst_add_params  in varchar2,
                       p_rqst_dt_status   in date,
                       p_rqst_priority    in number ) return number is
    v_retval    number;
    v_rqst_name varchar2(256) := p_rqst_name;
    v_rqst_num  number := p_rqst_num;
  begin
    -- ��������� ��� ����������� ������
    if p_rqst_type not in (c_sms_req, c_mail_req, c_plsql_req, c_iptv_req, c_rep_req) then
      raise_application_error(c_req_errcode, c_invalid_req);
    end if;
    -- �������� ������
    if p_rqst_name is null then
      v_rqst_name := c_req_test_name;
    end if;
    -- ��������� ������
    if (p_rqst_id = c_new_req_id) or (p_rqst_id is null) then
      select rqst$_seq.nextval into v_retval from dual;
      v_rqst_num := 1;
    else
      v_retval := p_rqst_id;
    end if;
    insert into requests$ (rqst_id, rqst_num, rqst_name, rqst_rqtm_id, rqst_type, rqst_dst, rqst_account, rqst_add_params, rqst_status, rqst_dt_status, rqst_response, rqst_priority)
                   values (v_retval, v_rqst_num, v_rqst_name, p_rqst_rqtm_id, p_rqst_type, p_rqst_dst, p_rqst_account, p_rqst_add_params, c_new_req, p_rqst_dt_status, null, p_rqst_priority);
    return v_retval;
  end;
  --
  -- ��������� �������� ������� ������
  --
  function req_template_create(p_rqtm_text in varchar2) return number is
    v_retval number;
  begin
    select rqtm$_seq.nextval into v_retval from dual;
    insert into req_templates$ values (v_retval, p_rqtm_text);
    return v_retval;
  end;
  --
  -- ������� ��������� �������� ���������
  --
  function get_param_value(p_rqpm_id in varchar2, def_value in varchar2) return varchar2 is
  begin
    return utl_p_$send_messages.get_param_value(p_rqpm_id, def_value);
  end;
  --
  -- ��������� ������� ����������� ������
  --
  procedure start_req_jobs is
  begin  
    update req_parameters$ rp set rp.rqpm_value = 0 where rp.rqpm_id = c_is_stoped_p;
    commit;
  end;
  --
  -- ��������� ��������� ����������� ������
  --
  procedure stop_req_jobs is
  begin  
    update req_parameters$ rp set rp.rqpm_value = 1 where rp.rqpm_id = c_is_stoped_p;
    commit;
  end;
  --
  -- ������� ��������� ����� ��� ������� �������� ��������� ������
  --
  function get_req_job_name return varchar2 is
  begin
    return c_req_job_name;
  end;
  --
begin
  c_step          := get_param_value('STEP',5);
  c_req_job_max   := get_param_value('REQ_JOB_MAX',3);
  c_req_hijob_max := get_param_value('REQ_HIJOB_MAX',2);
end req_p_$process;
/
