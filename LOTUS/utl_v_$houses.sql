create or replace view utl_v_$houses as
select id, house, corpus, stroenie, street_id from cifra.ao_adrhouse;
