create or replace view rad_log$ as
select t.id,
       decode(t.kind, 1, 'Ошибка',2 ,'Операция',3 , 'Подсказка', 'Не определено') sknd,
       t.msg,
       to_char(t.dt, 'dd.mm.yyyy hh24:mi:ss') sdt,
       t.dt,
       t.nas_ip_address nas
  from cifra.m3_rad_log t 
