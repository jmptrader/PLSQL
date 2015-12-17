--drop table reports$;
--drop sequence rpts$_seq;
--drop table rep_types$;

create table rep_types$
(
  rptp_id        number primary key,
  rptp_tp_text   varchar2(256) not null
);

insert into rep_types$ values (1, 'Абоненты');
insert into rep_types$ values (2, 'Услуги');
insert into rep_types$ values (3, 'Платежи');

create table reports$
(
  rpts_id          number not null,
  rpts_rptp_id     number not null,
  rpts_name        varchar2(50),
  rpts_create_dt   date default sysdate not null,
  rpts_body        varchar2(2000),
  rpts_is_deleted  char(1) default 'N'
);

create index reports$_rpts_rptp_i on reports$ (rpts_rptp_id);

create sequence rpts$_seq minvalue 0 maxvalue 999999999999999999999999999 start with 1000 increment by 1 nocache;

alter table reports$ add constraint rpts_rptp_fk foreign key (rpts_rptp_id) references rep_types$ (rptp_id);

