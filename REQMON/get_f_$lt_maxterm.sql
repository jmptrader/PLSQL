create or replace function get_f_$lt_maxterm(p_pin in varchar2)return integer is
/*
  Author  : V.ERIN
  Created : 19.10.2015 12:00:00
  Purpose : ������� ��� ����������� ���������� ���������� IPTV ��� ��������� ������
  Version : 1.0.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    19.10.2015     �������� 
  -------------------------------------------------------------------------------------------------
*/
  c_def_maxterm constant integer := 2;
  -- ������������ ��������
  v_retval integer;
  v_stb integer;
begin
  select count(1) into v_stb
   from lt_abon_packages$ ap
  where ap.pin = p_pin
    and (--trim(upper(ap.package)) like '%������_���������_NV_300%' or
         trim(upper(ap.package)) like '%��������������_���������%');
  --if (v_stb = 0) then
    --v_retval := c_def_maxterm;
  --else
    v_retval := v_stb + c_def_maxterm;
  --end if;
  return v_retval;
end get_f_$lt_maxterm;
/
