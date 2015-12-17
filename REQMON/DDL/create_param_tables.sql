--drop table req_parameters$;

create table req_parameters$
(
  rqpm_id        varchar2(50)   primary key,
  rqpm_value     varchar2(256)  not null,
  rqpm_text      varchar2(2000) not null
);

-- Add/modify columns 
alter table req_parameters$ add rqpm_data blob;

insert into req_parameters$ values ('IS_STOPED','0','���� ��������� ��������� �������� ��������� ��������.',null); 
insert into req_parameters$ values ('BAL_THRESHOLD','50','����� �������������� � ������� (��������� ��������� ���� ������ ������ ����� ��������).',null); 
--
insert into req_parameters$ values ('RQTM_PAY_DFLT','11','C�������� � �������',null);
insert into req_parameters$ values ('RQTM_PAY_STND','12','��������� ����� �� ����������',null);
insert into req_parameters$ values ('RQTM_PAY_DNSRV','13','������� ������� �� ���������� ��� ��������� �����',null);
insert into req_parameters$ values ('RQTM_PAY_UPSRV','14','������� ������� ���������� ��� ��������� �����',null);
-- ������
insert into req_parameters$ values ('RQTM_BAL_ZERO','15','C�������� � ������� �������',null);
insert into req_parameters$ values ('RQTM_BAL_DNSRV','16','C�������� �� ������������� �������',null);
insert into req_parameters$ values ('RQTM_BAL_REMIND','17','C�������� � ����������� � 0',null);
-- ������
insert into req_parameters$ values ('RQTM_SERV_UPSRV','20','C�������� � ����������� �����',null);
insert into req_parameters$ values ('RQTM_SERV_DNSRV','21','C�������� �� ���������� �����',null);
--
insert into req_parameters$ values ('IPTV_SERV_ID_1','69','ID ������ IPTV',null);
-- ����������
insert into req_parameters$ values ('STEP',5,'��� ������� ������� ������� �� ������������',null);
insert into req_parameters$ values ('REQ_JOB_MAX',3,'���������� ������� ������� ��������� ������',null);
insert into req_parameters$ values ('REQ_HIJOB_MAX',2,'���������� ������� ��� ��������� ������ �������� ����������',null);
-- ���������
--insert into req_parameters$ values ('SMTP_SERVER','212.34.32.22','����� SMTP �������',null);
--insert into req_parameters$ values ('SMTP_PORT','25','���� SMTP �������',null);
--insert into req_parameters$ values ('SMTP_USER','informer@cifra1.ru','������������ SMTP �������',null);
--insert into req_parameters$ values ('SMTP_PASSWORD','erin_1970','������ SMTP �������',null);
--insert into req_parameters$ values ('SMSC_URL','gate.mobilmoney.ru','����� ������� ��� �������� SMS',null);
-- ������ ��� PDF
insert into req_parameters$ values ('PDF_FONT_ARIAL','FONT','����� ��� �������� � PDF ��������',null);

