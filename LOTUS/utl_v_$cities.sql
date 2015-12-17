create or replace view utl_v_$cities as
select ct.id, at.name type_name, ct.name, ct.region_id
  from cifra.ao_city ct, cifra.ao_list_adrtype at
 where ct.type_id = at.id;
