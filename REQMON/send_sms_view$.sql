create or replace view sent_sms$ as
select sl.smlg_smfl_id fid,
       sl.rec_num      id ,
       sl.sms_name     name,
       sl.sms_phone    phone,
       sl.sms_text     text,
       'OK'            status,
       sl.sms_parts    parts,
       sl.sms_response response,
       sl.sms_date     send_date,
       slf.file_name   log_file
  from reports.sms_log$ sl, 
       reports.sms_log_files$ slf
 where sl.smlg_smfl_id = slf.smfl_id
union all
select sl.selg_smfl_id fid,
       sl.rec_num      id ,
       'SMS_ERROR'     name,
       'SMS_ERROR'     phone,
       sl.file_text    text,
       'ERR'           status,
       0               parts,
       sl.load_err     response,
       slf.processed_date - 1     send_date,
       slf.file_name   log_file
  from reports.sms_error_log$ sl, 
       reports.sms_log_files$ slf
 where sl.selg_smfl_id = slf.smfl_id
 
