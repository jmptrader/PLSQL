create or replace view utl_v_$regions as
select rg.id, at.name type_name, rg.name
  from cifra.ao_region rg, cifra.ao_list_adrtype at
 where rg.type_id = at.id;
