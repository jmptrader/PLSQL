--drop table req_balances$;
--drop table requests$;
--drop table req_templates$;
--drop sequence rqtm$_seq;
--drop sequence rqst$_seq;


create table req_templates$
(
  rqtm_id        number primary key,
  rqtm_text      varchar2(2000) not null
);

create table requests$
(
  rqst_id          number not null,
  rqst_num         number not null,
  rqst_name        varchar2(50),
  rqst_rqtm_id     number not null,
  rqst_type        char(1) not null,
  rqst_dst         varchar2(50) not null,
  rqst_account     varchar2(50),
  rqst_add_params  varchar2(2000),
  rqst_status      number not null,
  rqst_priority    number default 1 not null,
  rqst_dt_status   date not null,
  rqst_response    varchar2(2000)
);

alter table requests$ add rqst_date date default sysdate ;


create table req_balances$
(
  balance          number not null,
  bal_dt           date not null,
  prev_balance     number,
  prev_bal_dt      date,
  abon_num         number not null,
  rqbl_rqst_id     number,
  is_blocked       number
);


create index req_balances$_abon_num_i on req_balances$ (abon_num);

create index requests$_rqst_status_i on requests$ (rqst_status);
create index requests$_rqst_account_i on requests$ (rqst_account);

create sequence rqtm$_seq minvalue 0 maxvalue 999999999999999999999999999 start with 1000 increment by 1 nocache;
create sequence rqst$_seq minvalue 0 maxvalue 999999999999999999999999999 start with 100 increment by 1 nocache;

alter table requests$ add constraint rqst_pk primary key (rqst_id, rqst_num);
alter table requests$ add constraint rqst_rqtm_fk foreign key (rqst_rqtm_id) references req_templates$ (rqtm_id);

-- �������
insert into req_templates$ values (0,'��������� �������! �� ��� ������� ���� $account �������� ������ $sum ���. ������ ����� $servname  $balance ���.');
insert into req_templates$ values (1,'��������� �������! �� ��� ������� ���� $account �������� ������ $sum ���. ������ ����� $servname  $balance ���. ������ �������.');
insert into req_templates$ values (2,'��������� �������! �� ��� ������� ���� $account �������� ������ $sum ���. ������ ����� $servname  $balance ���. ������ ������������. ���. ��� �������  (495) 777-7-000.');
insert into req_templates$ values (3,'��������� �������! �� ��� ������� ���� $account �������� ������ $sum ���. ������ ����� $servname  $balance ���. ������ ����� ����������� � ��������� �����.');
-- ������
insert into req_templates$ values (4,'��������� �������! ������ ������ �������� ����� $servname  $balance ���. ����������, ��������� ���� $account');
insert into req_templates$ values (5,'��������� �������! ������ ������ �������� ����� $servname  $balance ���. ������  ������������. ����������, ��������� ���� $account');
insert into req_templates$ values (6,'��������� �������! ������ ������ �������� ����� $servname  $balance ���. ��� ��������� ������ �� �������� ��������� ���� $account');
-- �����
insert into req_templates$ values (7,'��������� �������! ��� ��������� ���� �� ������ $servname �� ����� $invsum ���. ����������, �� �������� ������ ����������� ����� �� ��� ���� $account ���. ��� ������� (495) 777-7-000');
insert into req_templates$ values (8,'��������� �������! ��� ��� ��������� ���� �� ������ $servname �� ����� $invsum ���. ����������, ��������� ��� ������� ���� $account �� 20 �����. ���. ��� ������� (495) 777-7-000');
-- �������
insert into req_templates$ values (9,'��������� �������! ������ �� �������� ����� $servname $account �����������. ���������� ��� �� ����������� ��������.');
insert into req_templates$ values (10,'��������� �������! ������ ������ �������� ����� ������ $servname $balance ���. ������ �������� ������������. ����������, ��������� ������� ���� $account. ���. ��� �������  (495) 777-7-000');
-- ������ ������ ��� �������
insert into req_templates$ values (150,'$repsql');


-- 
create or replace view balances$ as
 select nvl(sum(pab.pay_saldo),0) balance,
        pab.pay_abon_num          abon_num,
        info_p_$procedures.get_service_status(pab.pay_abon_num) is_blocked
   from cifra.pay_abonent pab,
        cifra.ao_abonent ab 
  where pab.pay_inf_num = cifra.m2_clc.currentinformationnumber
    and ab.id = pab.pay_abon_num
    and ab.state_id not in (2, 5) -- ��������� ���������  � �������� ���������
    and ab.telzone_id <> 20       -- ��������� �������� ��������
    and ab.cardtype_id = 0        -- ������ ���������� ����
  group by pab.pay_abon_num;
--  
create or replace view invoices$ as
  select * from
  (select inv.balance        invsum,
          inv.abon_num       abon_num,
          nvl(pay.pay_sum,0) paysum 
     from ( select nvl(sum(pab.pay_saldo),0)    balance,
                   pab.pay_abon_num             abon_num
              from cifra.pay_abonent pab,
                   cifra.ao_abonent ab 
             where pab.pay_inf_num = cifra.m2_clc.previousinformationnumber
               and ab.id = pab.pay_abon_num
               and ab.state_id = 0        -- ������ �����������
               and ab.telzone_id <> 20    -- ��������� �������� ��������
               and ab.cardtype_id = 0     -- ������ ���������� ����
             group by pab.pay_abon_num ) inv,
          ( select nvl(sum(op.o_fullsumma), 0) pay_sum,
                   op.ab_num abon_num
              from cifra.operations op, 
                   cifra.documents doc
             where op.o_id = doc.o_id
               and op.inf_num = cifra.m2_clc.currentinformationnumber
               and op.lvo_cod = 6
               and op.lso_cod not in (1431,1433)
               and nvl(doc.d_kassa,0) <> 28
               and op.o_fullsumma > 0 
               and op.lcr_cod <> 15
             group by op.ab_num ) pay
    where inv.abon_num = pay.abon_num(+)) aivc
   where invsum < 0      -- ����� �� ����� �������� �������
     and invsum + paysum < 0; -- �� ������� �� ����� � ������� ������� 
