create or replace view iptv_abonents$ as
select to_char(ab.card_num)        abon_num,
       nvl(ab.name,'Êëèåíò Ì2000') name,
       'M2000'                     branch,
       to_char(ab.id)              pswd,
       srv.plan_id                 params,
       decode(ab.state_id,5,1,0)   atype,
       get_f_$maxterm(ab.id)         maxterm,
       get_f_$servstate(ab.id)       state,
       get_f_$abonent_address(ab.id) address,
       get_f_$abonent_segment(ab.id) segment
  from cifra.m3_services srv, cifra.ao_abonent ab
 where ab.id = srv.abonent_id
   and ((srv.type_id in (64, 65, 70) -- Èíòåğíåò-åæåäíåâíûé + Unlim
        and (srv.state_dt < sysdate and (srv.edate is null or srv.edate > sysdate))
        and srv.plan_id in (select rqp.rqpm_value from req_parameters$ rqp where rqp.rqpm_id like 'IPTV_TP_ID%'))
        or
        (srv.type_id = 72        -- Óñëóãà IPTV
        and (srv.state_dt < sysdate and (srv.edate is null or srv.edate > sysdate)))) -- Äåéñòâóşùàÿ óñëóãà
union
select replace(lab.pin,'-','')         abon_num,
       get_f_$lt_abonent_name(lab.pin) name,
       'ÄÏÔË'                          branch,
       lab.p_password                  pswd,
       case
         when instr(trim(upper(lab.tarif_name)),'ÏÅĞÂÛÉ_IPTV')  > 0 then 2769
         when instr(trim(upper(lab.tarif_name)),'ÂÒÎĞÎÉ_IPTV')  > 0 then 2770
         when instr(trim(upper(lab.tarif_name)),'ÑÓÏÅĞ_IPTV')   > 0 then 2771
         when instr(trim(upper(lab.tarif_name)),'ÌÏ_3_Â_1')     > 0 then 2806
         when instr(trim(upper(lab.tarif_name)),'3_Â_1')        > 0 then 2807
         when instr(trim(upper(lab.tarif_name)),'ÌÏ_ÏËÀÍÅĞÍÀß') > 0 then 8000
         when instr(trim(upper(lab.tarif_name)),'ÑÓÏÅĞ_ÎÔÔÅĞ')  > 0 then 8001
         when instr(trim(upper(lab.tarif_name)),'ËÜÃÎÒÍÛÉ_IPTV_ÀĞÅÍÄÀ_NV300')  > 0 then 8002
         else -1
       end params,
       0 atype,
       2 maxterm,
       1 state,
       get_f_$ltabonent_address(lab.pin) address,
       get_f_$ltabonent_segment(lab.pin) segment
  from lt_abonents$ lab
 where (trim(upper(lab.tarif_name)) like '%ÏÅĞÂÛÉ_IPTV%')
    or (trim(upper(lab.tarif_name)) like '%ÂÒÎĞÎÉ_IPTV%')
    or (trim(upper(lab.tarif_name)) like '%ÑÓÏÅĞ_IPTV%')
    or (trim(upper(lab.tarif_name)) like '%ÌÏ_3_Â_1%')
    or (trim(upper(lab.tarif_name)) like '%3_Â_1%')
    or (trim(upper(lab.tarif_name)) like '%ÌÏ_ÏËÀÍÅĞÍÀß%')
    or (trim(upper(lab.tarif_name)) like '%ÑÓÏÅĞ_ÎÔÔÅĞ%')
    or (trim(upper(lab.tarif_name)) like '%ËÜÃÎÒÍÛÉ_IPTV_ÀĞÅÍÄÀ_NV300%')
;
