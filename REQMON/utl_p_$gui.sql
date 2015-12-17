create or replace package utl_p_$gui is
/*
  Author  : V.ERIN
  Created : 07.06.2015 12:00:00
  Purpose : Объекты для обеспечения работы GUI
  Version : 1.0.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    07/06/2015     Создание пакета
  -------------------------------------------------------------------------------------------------
*/
  --
  -- Получение состояния RADIUS сервера
  --
  function get_radius_state return number;
  --
  --  Получение  состояния загрузки NetFlow
  --
  function get_netflow_state return number;
  --
end utl_p_$gui;
/
create or replace package body utl_p_$gui is
  --
  --  Получение  состояния RADIUS сервера
  --
  function get_radius_state return number is
    c_one_min number := 1/(24*60);
    v_cnt number;
  begin  
    select count(1) into v_cnt
      from cifra.m3_rad_log t 
     where t.dt > sysdate - (5*c_one_min)
       and t.msg like '%PL%';
    return v_cnt;
  end;
  --
  --  Получение  состояния загрузки NetFlow
  --
  function get_netflow_state return number is
    c_one_hour number := 1/(24);
    v_cnt number;
  begin  
    select count(1) into v_cnt
      from cifra.m3_traf_flows t 
     where t.bdate > sysdate - (c_one_hour*2);
    return v_cnt;
  end;
  --  
begin
  null;
end utl_p_$gui;
/
