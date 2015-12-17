select 
(select i.inf_bdate from cifra.information i where i.inf_num=o.inf_num) as PERIOD,
(case when o.lso_cod=1700 then 'TV'
else 'Öטפנ.TV' end) as SRV, 
 o.lso_cod,
(select l.lso_name from cifra.list_operation l where l.lso_cod=o.lso_cod) as LSO_NAME,
COUNT(*) from cifra.operations o where 
o.lso_cod in (1700,1701,1702,1708,1709,1710,1711,1712,1713,1714,1715,1716,1717,1718,1719,1720,1721,1722)
and o.lsop_cod=3 and o.cusl_id is not null
and not exists (select (1) from cifra.operations op where op.lvo_cod=7  
and op.inf_num=o.inf_num and op.cusl_id=o.cusl_id and op.o_fullsumma=o.o_fullsumma and op.o_user_id is null)
and o.inf_num   = m2_clc.lastcloseinformationnumber
group by o.inf_num, o.lso_cod
order by o.lso_cod
