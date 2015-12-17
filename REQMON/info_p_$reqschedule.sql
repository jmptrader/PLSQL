create or replace package info_p_$reqschedule is
/*
  Author  : V.ERIN
  Created : 29.11.2014 12:00:00
  Purpose : ������� ��� �������� ������������� (����������) ������ �� �������������� ���������.
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    29/11/2014     �������� ������
  -------------------------------------------------------------------------------------------------
  V.ERIN    26/02/2015     ��������� �������� �� ���������
  -------------------------------------------------------------------------------------------------
*/
  -- ���������
  c_sms_req       constant char(1) := reqmon.req_p_$process.c_sms_req;
  c_mail_req      constant char(1) := reqmon.req_p_$process.c_mail_req;
  c_plsql_req     constant char(1) := reqmon.req_p_$process.c_plsql_req;
  --
  c_inv_req_name  constant varchar2(50) := 'INV_REQ_INFO';
  c_deb_req_name  constant varchar2(50) := '����������� � ������������� �� Cifra1';
  -- ������
  c_inet_nserv    constant number := info_p_$procedures.c_inet_nserv;
  c_tv_nserv      constant number := info_p_$procedures.c_tv_nserv;
  c_phone_nserv   constant number := info_p_$procedures.c_phone_nserv;
  c_multy_nserv   constant number := info_p_$procedures.c_multy_nserv;
  c_no_nserv      constant number := info_p_$procedures.c_no_nserv;
  -- �����
  c_rqtm_inv_no       constant number := -1; -- ��� ���������
  c_rqtm_inv_init     constant number := 18; -- C�������� � ������������ �����
  c_rqtm_inv_remind   constant number := 19; -- ����������� � ������������ �����
  -- ���� ���������
  c_b2b    constant integer := 1; -- ��. ����
  c_b2c    constant integer := 0; -- ���. ����
  -- ���������
  c_rqtm_b2b_msg     constant number := 30; -- C�������� � ����� ��� ��. ���
  c_rqtm_b2c_msg     constant number := 31; -- ����������� � ����� ��� ���. ���
  -- ��������
  c_deb_rep_mail     constant varchar2(256) := 'i.shahova@cifra1.ru;v.erin@cifra1.ru';
  -- �������
  c_inv_job_name          constant varchar(50) := 'INVOICE_SCAN';
  c_deb_job_name          constant varchar(50) := 'DEBIT_SCAN';
  --
  -- ������� ��������� ����� ��������
  --
  function get_abonent_name(p_account_id  in number) return varchar2;
  --
  -- ������� ��������� ���� ��������
  --
  function get_abonent_type(p_account_id  in number) return number;
  --
  -- ������� ��������� ����� �������� �� �������� � ������� �������
  --
  function get_payment_sum(p_account_id  in number) return number;
  --
  -- ��������� ������������ ������� ���������
  --
  procedure deb_scan;
  --
  -- ��������� ������������ ������� ������
  --
  procedure inv_scan;
  --
  -- ��������� �������� �������� ����������� ���������
  --
  procedure create_deb_scan_jobs;
  --
  -- ��������� �������� �������� ����������� ������
  --
  procedure create_inv_scan_jobs;
  --
  -- ��������� �������� �������� ������������ ���������
  --
  procedure drop_deb_scan_jobs;
  --
  -- ��������� �������� �������� ������������ ������
  --
  procedure drop_inv_scan_jobs;
  --
  -- ������� �������� ������ �� ����� �� �������� ��������� ���������
  --
  function req_deb_rep_create return number;
  --
end info_p_$reqschedule;
/
create or replace package body info_p_$reqschedule is
  --
  -- ������� ��������� ���� ��������
  --
  function get_abonent_type(p_account_id  in number) return number is
    v_ret number := null;
  begin
    select ab.cardtype_id 
      into v_ret
      from cifra.ao_abonent ab
     where ab.id = p_account_id;
    return v_ret;
  exception
    when no_data_found or too_many_rows then null;  
  end;  
  --
  -- ������� ��������� ����� ��������
  --
  function get_abonent_name(p_account_id  in number) return varchar2 is
    v_ret varchar2(256) := null;
  begin
    select nvl(ab.name, ac.socrname) 
      into v_ret
      from cifra.ao_abonent ab,
           cifra.ao_contragent ac
     where ab.contragent_id = ac.id
       and ab.id = p_account_id;
    return v_ret;
  exception
    when no_data_found or too_many_rows then null;  
  end;  
  --
  -- ������� ��������� ����� �������� �� �������� � ������� �������
  --
  function get_payment_sum(p_account_id  in number) return number is
    v_ret number;
  begin
    select nvl(sum(op.o_fullsumma), 0) pay_sum
      into v_ret
      from cifra.operations op, 
           cifra.documents doc
     where op.ab_num = p_account_id 
       and op.o_id = doc.o_id
       and op.inf_num = cifra.m2_clc.currentinformationnumber
       and op.lvo_cod = 6
       and op.lso_cod not in (1431,1433)
       and nvl(doc.d_kassa,0) <> 28
       and op.o_fullsumma > 0 
       and op.lcr_cod <> 15; 
    return v_ret;
  end;  
  --
  -- ������� �������� ������ �� ����� �� �������� ��������� ���������
  --
  function req_deb_rep_create return number is
    v_req      number         := -1;
    v_rep_sgl  varchar2(2000) := 'select t.account "ACCOUNT", t.rqst_dst "EMAIL", t.dt_status "����������", t.status "��������� ��������", t.responce "����� �������" '|| 
                                 '  from req_detail_view$ t '|| 
                                 ' where t.rqst_name = ''����������� � ������������� �� Cifra1''  '||  
                                 '   and trunc(t.rqst_dt_status,''MM'') = trunc(sysdate,''MM'')';
  begin
    v_req := reqmon.req_p_$process.req_create( p_rqst_name       => '�������� ����������� � ������������� �� '||to_char(sysdate,'mm.yyyy'),
                                               p_rqst_id         => v_req,
                                               p_rqst_num        => 1,
                                               p_rqst_rqtm_id    => 150,
                                               p_rqst_type       => reqmon.req_p_$process.c_rep_req,
                                               p_rqst_dst        => c_deb_rep_mail,
                                               p_rqst_account    => reqmon.req_p_$process.c_no_account,
                                               p_rqst_add_params => v_rep_sgl,
                                               p_rqst_priority   => reqmon.req_p_$process.c_prty_low);
    return v_req;
  end;
  --
  -- ������� �������� ������ �� �������� ��������� ���������
  --
  function req_deb_create(p_account_id  in number) return number is
    v_rqst_dst varchar2(50)   := info_p_$procedures.get_email(p_account_id);
    v_account  varchar2(50)   := info_p_$procedures.get_account(p_account_id);
    v_serv     number         := info_p_$procedures.get_service_num(p_account_id);
    v_name     varchar2(256)  := get_abonent_name(p_account_id);
    v_ab_type  number         := get_abonent_type(p_account_id);
    v_params   varchar2(2000) := 'customer:'||v_name;
    v_req      number         := -1;
    v_msg_id   number         := null;
  begin
    if (v_ab_type = c_b2b) then
      v_msg_id := c_rqtm_b2b_msg;
    else
      v_msg_id := c_rqtm_b2c_msg;
    end if;
    -- ������� ������ ��� ��������� ���� ���� �� ������� ������ ������ ����� �������� � ������� �������
    if (v_serv = c_phone_nserv) and (v_rqst_dst is not null) then
        v_req := reqmon.req_p_$process.req_create( p_rqst_name       => c_deb_req_name,
                                                   p_rqst_id         => v_req,
                                                   p_rqst_num        => 1,
                                                   p_rqst_rqtm_id    => v_msg_id,
                                                   p_rqst_type       => c_mail_req,
                                                   p_rqst_dst        => v_rqst_dst,
                                                   p_rqst_account    => v_account,
                                                   p_rqst_add_params => v_params,
                                                   p_rqst_priority   => reqmon.req_p_$process.c_prty_low);
    end if;
    return v_req;
  end;
  --
  -- ������� �������� ������ �� �������� ��������� � ������
  --
  function req_inv_create(p_account_id  in number,
                          p_invsum      in number,
                          p_rqtm_id     in number                
                          ) return number is
    v_rqst_dst varchar2(50)   := info_p_$procedures.get_phone(p_account_id);
    v_account  varchar2(50)   := info_p_$procedures.get_account(p_account_id);
    v_serv     number         := info_p_$procedures.get_service_num(p_account_id);
    v_params   varchar2(2000) := 'invsum:'||to_char(p_invsum * -1)||';servname:'||info_p_$procedures.get_service_name(v_serv);
    v_req      number         := -1;
  begin
    -- ������� ������ ��� ��������� ���� ���� �� ������� ������ ������ ����� �������� � ������� �������
    if (v_serv = c_phone_nserv) and (v_rqst_dst is not null) then
        v_req := reqmon.req_p_$process.req_create( p_rqst_name       => c_inv_req_name,
                                                   p_rqst_id         => v_req,
                                                   p_rqst_num        => 1,
                                                   p_rqst_rqtm_id    => p_rqtm_id,
                                                   p_rqst_type       => c_sms_req,
                                                   p_rqst_dst        => v_rqst_dst,
                                                   p_rqst_account    => v_account,
                                                   p_rqst_add_params => v_params,
                                                   p_rqst_priority   => reqmon.req_p_$process.c_prty_low);
    end if;
    return v_req;
  end;
  --
  -- ��������� ������������ ������� ���������
  --
  procedure deb_scan is
    v_req     number;
  begin
    -- �� ���� ��������� ������� ������ � ������� ������
    if (req_p_$process.get_param_value('DEB_LAST_RUN','01.2000') = to_char(sysdate,'mm.yyyy')) then
      raise_application_error(-20000,'������� ���������� ������� ��������� � ������� �������� ������');
    else
      req_p_$process.upd_param_value('DEB_LAST_RUN', to_char(sysdate,'mm.yyyy'), null);
    end if;   
    -- �������� �� ���� ��������� �� �������� ������
    for inv_rec in ( select abon_num from debit_abonents$ ) loop
        -- ������� ������ �� �������� ���������
        v_req := req_deb_create(inv_rec.abon_num);
        commit;
    end loop;
    -- ������� ������ �� �������� ������
    v_req := req_deb_rep_create;
    commit;
  end; 
  --
  -- ��������� ������������ ������� ������
  --
  procedure inv_scan is
    v_req     number;
    v_rqtm_id number;
    today     number := to_number(to_char(sysdate,'dd'));
  begin
    -- �� ���� ��������� ������� ������ � ������� ������
    if (req_p_$process.get_param_value('INV_LAST_RUN','01.2000') = to_char(sysdate,'mm.yyyy')) then
      raise_application_error(-20000,'������� ���������� ������� ��������� � ������� �������� ������');
    else
      req_p_$process.upd_param_value('INV_LAST_RUN', to_char(sysdate,'mm.yyyy'), null);
    end if;   
    -- �������� ��������� ��� ��������
    if (today <= 10) then
      v_rqtm_id := c_rqtm_inv_init;
    elsif (today <= 19) then
      v_rqtm_id := c_rqtm_inv_remind;
    else 
      v_rqtm_id := c_rqtm_inv_no;
    end if;
    if (v_rqtm_id <> c_rqtm_inv_no) then
      -- �������� �� ���� ������ �� �������� ������ ���� ��������� ���������
      for inv_rec in ( select invsum, abon_num, paysum from invoices$ ) loop
          -- ������� ������ �� �������� ���������
          v_req := req_inv_create(inv_rec.abon_num, inv_rec.invsum, v_rqtm_id);
          commit;
      end loop;
    end if;
  end; 
  --
  -- ��������� �������� �������� ����������� ���������
  --
  procedure create_deb_scan_jobs is
    v_job_start_date date;
  begin
    -- ������� ������� 
    v_job_start_date := to_date('04.12.2014 11:00','dd.mm.yyyy hh24:mi');
    dbms_scheduler.create_job(job_name            => c_deb_job_name,
                              job_type            => 'PLSQL_BLOCK',
                              job_action          => 'begin info_p_$reqschedule.deb_scan; end; ',
                              start_date          => v_job_start_date,
                              repeat_interval     => 'freq=monthly;interval=1;bymonthday=21',
                              end_date            => to_date(null),
                              job_class           => 'DEFAULT_JOB_CLASS',
                              enabled             => false,
                              auto_drop           => false,
                              comments            => '������� �������� �� ����������');
    commit;
  end;
  --
  -- ��������� �������� �������� ����������� ������
  --
  procedure create_inv_scan_jobs is
    v_job_start_date date;
  begin
    -- ������� ������� 
    v_job_start_date := to_date('04.12.2014 11:00','dd.mm.yyyy hh24:mi');
    dbms_scheduler.create_job(job_name            => c_inv_job_name,
                              job_type            => 'PLSQL_BLOCK',
                              job_action          => 'begin info_p_$reqschedule.inv_scan; end; ',
                              start_date          => v_job_start_date,
                              repeat_interval     => 'freq=monthly;interval=1;bymonthday=17',
                              end_date            => to_date(null),
                              job_class           => 'DEFAULT_JOB_CLASS',
                              enabled             => false,
                              auto_drop           => false,
                              comments            => '������� �������� �� �������');
    commit;
  end;
  --
  -- ��������� �������� �������� ������������ ���������
  --
  procedure drop_deb_scan_jobs is
  begin  
    dbms_scheduler.drop_job(c_deb_job_name);
  end;
  --
  -- ��������� �������� �������� ������������ ������
  --
  procedure drop_inv_scan_jobs is
  begin  
    dbms_scheduler.drop_job(c_inv_job_name);
  end;
begin
  null;
end info_p_$reqschedule;
/
