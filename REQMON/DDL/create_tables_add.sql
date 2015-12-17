-- Платежи
insert into req_templates$ values (11,'Na Vash licevoj schet $account postupil platezh v $sum rub. Balans schjota $servname $balance rub.');
insert into req_templates$ values (12,'Na Vash licevoj schet $account postupil platezh v $sum rub. Balans schjota $servname $balance rub. Servis aktiven');
insert into req_templates$ values (13,'Na Vash licevoj schet $account postupil platezh v $sum rub. Balans schjota $servname $balance rub. Servis zablokirovan. Tel. dlja spravok  (495) 777-7-000');
insert into req_templates$ values (14,'Na Vash licevoj schet $account postupil platezh v $sum rub. Balans schjota $servname $balance rub. Servis budet aktivirovan v blizhajshee vremja');
-- Баланс
insert into req_templates$ values (15,'Balans Vashego licevogo schjota $servname $balance rub. Pozhalujsta, popolnite schet $account');
insert into req_templates$ values (16,'Balans Vashego licevogo schjota $servname $balance rub. Servis zablokirovan. Pozhalujsta, popolnite schet $account');
insert into req_templates$ values (17,'Balans Vashego licevogo schjota $servname $balance rub.  Dlja prodlenija uslugi ne zabud''te popolnit'' schet $account');
-- Счета
insert into req_templates$ values (18,'Vam vystavlen schet za uslugi $servname na summu $invsum rub. Vnesite neobhodimuju summu na vash schet $account Tel. dlja spravok (495) 777-7-000');
insert into req_templates$ values (19,'Vam byl vystavlen schet za uslugi $servname na $invsum rub. Popolnite vash schet $account do 20 chisla. Tel. dlja spravok  (495) 777-7-000');
-- Сервисы
insert into req_templates$ values (20,'Servis po licevomu schetu $servname $account aktivirovan. Blagodarim vas za pol''zovanie uslugami');
insert into req_templates$ values (21,'Balans schjota uslugi $servname $balance rub. Servis vremenno otkljuchen. Popolnite schet $account Tel. dlja spravok  (495) 777-7-000');
-- Тестовые сообщения
insert into req_templates$ values (200,'Тестовое сообщение');
insert into req_templates$ values (201,'Test message');

-- Представления
create or replace view req_detail_view$ as
select rq.rqst_id,
       rq.rqst_num,
       decode(rq.rqst_account,-1,'NONE', rq.rqst_account) account,
       rq.rqst_dst,
       req_p_$process.prepare_message(rt.rqtm_text, rq.rqst_add_params, rq.rqst_account) msg,
       rq.rqst_name,
       decode(rq.rqst_type,'S','SMS','M','MAIL','R','RPT','P','PLSQL','T','IPTV','UNKN') type,
       rq.rqst_date,
       rq.rqst_dt_status,
       decode(rq.rqst_status,0,'DONE',1,'NEW',2,'WORK',3,'CNCL','ERR') status,
       decode(rq.rqst_priority,0,'HI',1,'MD',2,'LO','UN') priority,
       rq.rqst_response
  from requests$ rq,
       req_templates$ rt
 where rq.rqst_rqtm_id = rt.rqtm_id
   and trunc(rq.rqst_dt_status) = trunc(sysdate)
 order by rq.rqst_id desc, rq.rqst_num asc;
-- 
create or replace view req_all_detail_view$ as
select rq.rqst_id,
       rq.rqst_num,
       rq.rqst_name,
       rq.rqst_rqtm_id,
       rq.rqst_type,
       rq.rqst_dst,
       rq.rqst_account,
       rq.rqst_add_params,
       rq.rqst_status,
       rq.rqst_priority,
       rq.rqst_dt_status,
       rq.rqst_response,
       rq.rqst_date,
       req_p_$process.prepare_message(rt.rqtm_text, rq.rqst_add_params, rq.rqst_account) msg
  from requests$ rq,
       req_templates$ rt
 where rq.rqst_rqtm_id = rt.rqtm_id;
 
