select * from
  (select dd.service_id, dd.filter_id, dfl.value
    from cifra.m3_service_dialup_details dd, 
         cifra.m3_dialup_filters dfl
   where dd.is_used_vsa = 'Y' 
     and dd.filter_id = dfl.id(+)) dld,
  (select vv.service_id, vv.value
     from cifra.m3_vsa_values vv 
    where vv.vsa_type_id = 71) vsv
 where dld.service_id = vsv.service_id(+)
  -- and nvl(vsv.value,0) = nvl(dld.value,0)
