declare
  max_speed varchar2(10);
  mt_vsa_speed constant number := utl_p_$redback.c_mt_vsa_attr_type;
begin
  for rec in (select dld.service_id, pt.id tp_id
                from (select dd.service_id
                        from cifra.m3_service_dialup_details dd
                       where dd.is_used_vsa = 'Y') dld,
                     (select vv.service_id, vv.value
                        from cifra.m3_vsa_values vv 
                       where vv.vsa_type_id = mt_vsa_speed) vsv,
                      cifra.m3_services srv,
                      cifra.m3_plan_types pt,
                      cifra.ao_abonent ab
               where dld.service_id = vsv.service_id(+)
                 and vsv.value is null
                 and srv.id = dld.service_id
                 and srv.edate is null
                 and ab.edate is null
                 and srv.plan_id = pt.id
                 and ab.id = srv.abonent_id
                 and ab.telzone_id in (15, 17)
                 and srv.type_id not in (44)) loop
     case rec.tp_id
       when 2232 then max_speed := '40M';
       when 1113 then max_speed := '20M';
       when 1114 then max_speed := '70M';
       else max_speed := '100M';
     end case;
    insert into cifra.m3_vsa_values (id, vsa_type_id, value, service_id) values (cifra.m3_vsa_values_seq.nextval, mt_vsa_speed, max_speed, rec.service_id);
    --dbms_output.put_line(max_speed||' '||rec.service_id);
  end loop;
end;
/*
select t1.service_id, t1.value, utl_p_$redback.convert_rate_vsa_attr(t1.value), t2.value, ab.card_num
                      from (select * from cifra.m3_vsa_values vv  where vv.vsa_type_id = 71) t1,
                           (select * from cifra.m3_vsa_values vv  where vv.vsa_type_id = 85) t2,
                           cifra.ao_abonent ab,
                           cifra.m3_services srv
                     where t1.service_id = t2.service_id(+) 
                       and (utl_p_$redback.convert_rate_vsa_attr(t1.value)) <> nvl(t2.value,'0')
                       and ab.id = srv.abonent_id
                       and t1.service_id = srv.id
*/
