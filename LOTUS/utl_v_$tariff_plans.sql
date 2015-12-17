create or replace view utl_v_$tariff_plans as
select pt.id,
       pt.name
  from cifra.m3_plan_types pt
 where pt.is_for_abonent = 'Y'
   and pt.is_deleted = 'N'
 order by 2;
