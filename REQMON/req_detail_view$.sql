create or replace view req_detail_view$ as
select rq.rqst_id,
       rq.rqst_num,
       decode(rq.rqst_account,-1,'NONE', rq.rqst_account) account,
       rq.rqst_dst,
       req_p_$process.prepare_message(rt.rqtm_text, rq.rqst_add_params, rq.rqst_account) msg,
       rq.rqst_name,
       decode(rq.rqst_type,'S','SMS','M','MAIL','R','RPT','P','PLSQL','T','IPTV','UNKN') type,
       to_char(rq.rqst_date,'dd.mm.yyyy hh24:mi:ss') ins_date,
       to_char(rq.rqst_dt_status,'dd.mm.yyyy hh24:mi:ss') dt_status,
       rq.rqst_date,
       rq.rqst_dt_status,
       decode(rq.rqst_status,0,'DONE',1,'NEW',2,'WORK',3,'CNCL','ERR') status,
       decode(rq.rqst_priority,0,'HI',1,'MD',2,'LO','UN') priority,
       rq.rqst_response responce
  from requests$ rq,
       req_templates$ rt
 where rq.rqst_rqtm_id = rt.rqtm_id;
