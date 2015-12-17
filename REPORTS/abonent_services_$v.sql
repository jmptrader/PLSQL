create or replace view abon_radius_serv_$v as
select ab.id                         account_id,
       ab.card_num                   account,
       ab.telzone_id                 telzone_id,
       srv.id                        service_id,
       srv.type_id                   servtype_id,
       srv.state_id                  servstate_id,
       ln.user_name                  username,
       ln.password                   password,
       ln.is_password_crypted        is_crypted,
       sdd.auth_method               auth_method,
       sdd.ip_addr                   ip_addr,
       asp.value                     value,
       asp.attribute_name            attr_name,
       get_f_$abonent_balance(ab.id) balance
  from cifra.m3_logins ln,
       cifra.m3_services srv,
       cifra.ao_abonent ab,
       cifra.m3_service_dialup_details sdd,
       reports.abon_serv_params_$v asp
where srv.id = ln.service_id
  and srv.abonent_id = ab.id
  and srv.edate is null
  and srv.id = sdd.service_id
  and asp.service_id(+) = srv.id
  and ln.is_password_crypted = 'N';
