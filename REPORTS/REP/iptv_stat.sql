select count(1) "����������", pt.name "��"
  from reqmon.iptv_abonents$ t,
       cifra.m3_plan_types pt
 where pt.id = t.params
 group by rollup(pt.name)
