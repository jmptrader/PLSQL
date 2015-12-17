--drop table req_iptv_abonents$;

create table req_iptv_abonents$
(
  abon_num         varchar2(20) not null,
  pswd             varchar2(20),
  params           varchar2(256)
);

--alter table req_iptv_abonents$ add constraint rqip_pk primary key (abon_num);

--
--insert into req_parameters$ values ('IPTV_TP_ID_1','2769','Первый IPTV');
--insert into req_parameters$ values ('IPTV_TP_ID_2','2770','Второй IPTV');
--insert into req_parameters$ values ('IPTV_TP_ID_3','2771','Супер IPTV');
-- Шаблон заявки для IPTV
insert into req_templates$ values (50,'reqtype=$reqtype&account=$account&password=$password&mac=$mac&packages=$packages');
insert into req_templates$ values (51,'utl_p_$iptv_commands.set_add_param($account,$reqtype); commit;');
--
-- Add/modify columns 
--alter table req_iptv_abonents$ add params_s VARCHAR2(256);
alter table req_iptv_abonents$ add state NUMBER(1);

--
-- Lotus
--

/*
create table lt_iptv_abonents$
(
  pin          VARCHAR2(100),
  p_password   VARCHAR2(100),
  tarif_name   VARCHAR2(256),
  first_name   VARCHAR2(256),
  middle_name  VARCHAR2(256),
  last_name    VARCHAR2(256),
  busines_name VARCHAR2(256),
  icc          VARCHAR2(100),
  vip          VARCHAR2(100),
  user_status  VARCHAR2(100),
  p_index      VARCHAR2(256),
  city         VARCHAR2(256),
  street       VARCHAR2(256),
  house_k      VARCHAR2(256),
  house_n      VARCHAR2(256),
  podezd       VARCHAR2(256),
  flover       VARCHAR2(256),
  kvartira     NUMBER(10),
  jur_adres    VARCHAR2(512),
  is_blocked   VARCHAR2(100),
  sversion     VARCHAR2(256)
);

create table lt_abon_phones$
(
  pin      varchar2(20),
  prfix    varchar2(20),
  phonenum varchar2(30),
  is_type  varchar2(30),
  is_sms   varchar2(30)
);

*/

create index lt_iptv_abonents$_pin_i on lt_iptv_abonents$ (pin);
create index lt_abon_phones$_pin_i on lt_abon_phones$ (pin);
