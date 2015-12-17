select t1.*, t2.*, utl_p_$redback.convert_rate_vsa_attr(t1.value) rt
  from (select * from cifra.m3_vsa_values vv  where vv.vsa_type_id = 71) t1,
       (select * from cifra.m3_vsa_values vv  where vv.vsa_type_id = 85) t2
 where t1.service_id = t2.service_id(+) 
   and (utl_p_$redback.convert_rate_vsa_attr(t1.value)) <> nvl(t2.value,'0')-- for update 
  --and t1.value = '60M]'
/*
begin
  -- нужно добавить в m3_srv.updateservice
  utl_p_$redback.synchronize;
  --utl_p_$redback.synchronize_filter_vsa_attr;
end;
select * from cifra.m3_vsa_values vv  where vv.vsa_type_id = 71 and vv.service_id = 280590 for update
*/
