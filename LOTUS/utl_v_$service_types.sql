create or replace view utl_v_$service_types as
select t.id, t.name 
  from cifra.m3_service_types t 
 where t.is_deleted = 'N'
 order by 2;
