create or replace view utl_v_$liked_addresses as
select lotus_code, m2000_code from reqmon.lt_m2_addresses$;
