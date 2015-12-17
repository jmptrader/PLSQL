select ab.filial,
       ab.card_num, 
       dates.dt, 
       reports.rpt_p_$utils.get_market_segment(ab.id) as segment,
       reports.rpt_p_$utils.get_abon_tpname(ab.id) as tar_plan,
       (select sum(reports.rpt_p_$utils.get_iabonplata(s.id, s.type_id, s.plan_id)) from cifra.m3_services s where s.abonent_id = ab.id) abonplata, 
       'Интернет '||reports.rpt_p_$utils.get_abon_addparam_value(ab.id, 32, '') as srv_main,
       reports.rpt_p_$utils.get_phone(ab.id) phns
 from (select distinct (a.id) id, 
              a.card_num,
              ltz.ltz_name as filial
         from cifra.ao_abonent a,
              cifra.list_telzone ltz,
              cifra.m3_services srv,
              cifra.ao_contragent ctr,
              cifra.ao_address adr,
              cifra.ao_adrhouse hs 
        where ltz.ltz_cod = a.telzone_id
          and srv.type_id in (44, 51, 54, 64, 65, 70) 
          and srv.edate is null 
          and srv.abonent_id = a.id
          and a.contragent_id = ctr.id
          and ctr.adr_real_id = adr.id
          and adr.house_id = hs.id
          and hs.street_id in (12426, 12428)) ab,
      (select dts.column_value as dt from table(reports.rpt_p_$utils.get_dates(to_date('#param0#','dd.mm.yyyy'), to_date('#param1#','dd.mm.yyyy'))) dts) dates
 where reports.get_f_$abo_last_charge(ab.id, dates.dt) = trunc(dates.dt) - 31
union all
select ab.filial,
       ab.card_num, 
       dates.dt, 
       reports.rpt_p_$utils.get_market_segment(ab.id) as segment,
       reports.rpt_p_$utils.get_abon_tpname(ab.id) as tar_plan,
       (select sum(reports.rpt_p_$utils.get_tabonplata(s.cusl_ucod, s.cusl_vid)) from cifra.cusl s where s.cusl_abon_num = ab.id) abonplata, 
       decode(ab.stype, 17, 'ТВ', 'Телефония') as srv_main,
       reports.rpt_p_$utils.get_phone(ab.id) phns
 from (select distinct (a.id) id, 
              a.card_num,
              ltz.ltz_name as filial,
              srv.cusl_vid as stype
         from cifra.ao_abonent a,
              cifra.list_telzone ltz,
              cifra.cusl srv, 
              cifra.ao_contragent ctr,
              cifra.ao_address adr,
              cifra.ao_adrhouse hs 
        where ltz.ltz_cod = a.telzone_id
          and srv.cusl_vid in (1, 17) 
          and srv.cusl_edate is null 
          and srv.cusl_abon_num = a.id
          and a.contragent_id = ctr.id
          and ctr.adr_real_id = adr.id
          and adr.house_id = hs.id
          and hs.street_id in (12426, 12428)) ab,
      (select dts.column_value as dt from table(reports.rpt_p_$utils.get_dates(to_date('#param0#','dd.mm.yyyy'), to_date('#param1#','dd.mm.yyyy'))) dts) dates --#param1#
 where reports.get_f_$abo_last_charge(ab.id, dates.dt) = trunc(dates.dt) - 31

order by 3
