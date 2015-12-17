select ab.filial,
       ab.card_num, 
       dates.dt, 
       reports.rpt_p_$utils.get_market_segment(ab.id) as segment,
       reports.rpt_p_$utils.get_abon_tpname(ab.id) as tar_plan,
       (select sum(reports.rpt_p_$utils.get_tabonplata(s.cusl_ucod, s.cusl_vid)) from cifra.cusl s where s.cusl_abon_num = ab.id) abonplata, 
       decode(ab.stype, 17, 'ТВ', 'Телефония') as srv_main
 from (select distinct (a.id) id, 
              a.card_num,
              ltz.ltz_name as filial,
              srv.cusl_vid as stype
         from cifra.ao_abonent a,
              cifra.list_telzone ltz,
              cifra.cusl srv 
        where ltz.ltz_cod = a.telzone_id
          and srv.cusl_vid in (1, 17) 
          and srv.cusl_edate is null 
          and srv.cusl_abon_num = a.id) ab,
      (select dts.column_value as dt from table(reports.rpt_p_$utils.get_dates(to_date('01.07.2015','dd.mm.yyyy'), to_date('01.07.2015','dd.mm.yyyy'))) dts) dates
 where reports.get_f_$abo_last_charge(ab.id, dates.dt) > trunc(dates.dt) - 180
order by 3
