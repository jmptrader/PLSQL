select p.name, count(1) from REQ_IPTV_ABONENTS$ t, cifra.m3_plan_types p where t.params = p.id group by rollup(p.name)
