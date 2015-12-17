create or replace view utl_v_$zones as
select ltz_cod id, ltz_name name
  from cifra.list_telzone;
