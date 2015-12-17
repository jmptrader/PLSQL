select ab.filial,
       ab.card_num, 
       dates.dt, 
       reports.rpt_p_$utils.get_market_segment(ab.id) as segment,
       reports.rpt_p_$utils.get_phone(ab.id) phones
 from (select distinct (a.id) id, 
              a.card_num,
              ltz.ltz_name as filial
         from cifra.ao_abonent a,
              cifra.list_telzone ltz,
              cifra.m3_services srv 
        where ltz.ltz_cod = a.telzone_id
          and srv.type_id in (44, 51, 54, 64, 65, 70) 
          and srv.edate is null 
          and srv.abonent_id = a.id) ab,
      (select dts.column_value as dt from table(reports.rpt_p_$utils.get_dates(to_date('01.09.2015','dd.mm.yyyy'), to_date('01.09.2015','dd.mm.yyyy'))) dts) dates --#param0# #param1#
 where reports.get_f_$abo_last_charge(ab.id, dates.dt) = trunc(dates.dt) - 31
order by 3
