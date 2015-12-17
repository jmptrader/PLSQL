create or replace view abon_serv_params_$v as
select vv.service_id,
       vv.value, 
       vt.attribute_name, 
       vt.attribute_number, 
       vt.need_binary_convert, 
       vt.is_complex, 
       uv.id_for_vsa
  from cifra.m3_vsa_values vv,
       cifra.m3_vsa_types vt, 
       cifra.m3_unit_vendors uv
 where vv.vsa_type_id = vt.id
   and uv.id = vt.vendor_id
   and vt.attribute_number = 8;
   
