create or replace view active_sessions$ as
select
   s.id,
   decode(s.is_active, 'Y', 'Да', 'N' ,'Нет', 'Неопределено') is_active,
   ab.card_num,
   ab.id abonent_id,
   un.name  unitname,
   tz.ltz_name,
   asv.ip nas_ip,
   s.session_timeout,
   s.user_name,
   s.bdate,
   s.interim_input_octets,
   s.interim_output_octets,
   s.interim_edate,
   decode(s.kill_status,'G','Гостевая', 'A', 'Обычная', 'Неопределено') status,
   s.mac_address
   from
      cifra.m3_dialup_sessions s,
      cifra.m3_access_servers asv,
      cifra.m3_units un,
      cifra.m3_common_lists dmn,
      cifra.ao_abonent ab,
      cifra.list_telzone tz
   where
      (s.nas_id = asv.id) and
      (asv.unit_id = un.id) and
      (s.domain_id = dmn.id) and
      (un.telzone_id = tz.ltz_cod(+)) and
       s.abonent_id = ab.id;
