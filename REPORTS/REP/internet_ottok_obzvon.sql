select ab.filial,
       ab.card_num, 
       dates.dt, 
       reports.rpt_p_$utils.get_market_segment(ab.id) as segment,
       reports.rpt_p_$utils.get_phone(ab.id) phones,
       cifra.ao_adr.get_addressf(nvl(ab.adr_real_id, ab.adr_id)) as adress
 from (select distinct (a.id) id,
              ac.adr_id,
              ac.adr_real_id, 
              a.card_num,
              ltz.ltz_name as filial
         from cifra.ao_abonent a,
              cifra.ao_contragent ac,
              cifra.list_telzone ltz,
              cifra.m3_services srv 
        where ltz.ltz_cod = a.telzone_id
          and a.contragent_id = ac.id
          and srv.type_id in (44, 51, 53, 54, 64, 65, 69, 70) 
          and srv.edate is null 
          and srv.abonent_id = a.id) ab,
      (select dts.column_value as dt from table(reports.rpt_p_$utils.get_dates(to_date('#param0#','dd.mm.yyyy'), to_date('#param1#','dd.mm.yyyy'))) dts) dates --#param0# #param1#
 where reports.get_f_$abo_last_charge(ab.id, dates.dt) = trunc(dates.dt) - 31
order by 3
