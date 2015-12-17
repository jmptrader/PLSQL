--
--insert into cifra.m3_vsa_template_values  values (cifra.m3_vsa_template_values_seq.nextval, 162, 82, 'Баланс >0', null );
--insert into cifra.m3_vsa_template_values  values (cifra.m3_vsa_template_values_seq.nextval, 161, 82, 'Отрицательный', null );
--insert into cifra.m3_vsa_template_values  values (cifra.m3_vsa_template_values_seq.nextval, 164, 82, 'Разрешить всё', null );
--
update cifra.m3_dialup_filters t set t.value = 161 where t.id = 4;
