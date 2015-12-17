create or replace view utl_v_$streets as
select st.id, at.name type_name, st.name, st.city_id
  from cifra.ao_street st, cifra.ao_list_adrtype at
 where st.type_id = at.id;
