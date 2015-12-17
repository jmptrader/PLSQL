create or replace package utl_p_$redback is
/*
  Author  : V.ERIN
  Created : 10.05.2014 12:00:00
  Purpose : Объекты для обеспечения работы с настройками М2000 для поддержки ERICSON REDBACK 
  Version : 1.0.01
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    10/05/2015     Создание пакета
  -------------------------------------------------------------------------------------------------
  V.ERIN    06/09/2015     Запущена процедура синхронизации VSA как задание Oracle
  -------------------------------------------------------------------------------------------------
*/
  c_err    constant varchar2(50) := 'UNKNOWN';
  c_rb_vsa_attr_type constant number := 85; -- speed radback
  c_mt_vsa_attr_type constant number := 71; -- speed mikrotik
  c_fl_vsa_attr_type constant number := 82; -- service profile
  c_job_name constant varchar2(50) := 'VSA_SYNCHRONIZE';
  -- 
  -- Процедура синхронизации  VSA атрибутов для REDBACK
  --
  procedure synchronize;
  -- 
  -- Процедура синхронизации статических VSA атрибута Service-Name и Service-Action
  --
  procedure synchronize_static_attr;
  -- 
  -- Процедура синхронизации VSA атрибута скорости
  --
  procedure synchronize_speed_vsa_attr;
  -- 
  -- Функция конвертирования скорости
  --
  function convert_rate_vsa_attr(p_mt_ratelimit in varchar2) return varchar2;
  -- 
  -- Процедура установки VSA атрибута Service-Parameter в соответствии со
  -- значением атрибута Mikrotik-Rate-Limit
  --
  procedure set_ratelimit_vsa_attr(p_service_id in number);
  -- 
  -- Процедура синхронизации VSA атрибута Subscriber-Profile-Name в соответствии с Filter ID
  --
  procedure synchronize_filter_vsa_attr;
  -- 
  -- Процедура установки VSA атрибута Subscriber-Profile-Name в соответствии с Filter ID
  --
  procedure set_filter_vsa_attr(p_service_id in number, p_filter_id in number);
  --
  -- Процедура создания процесса сканирования VSA атрибутов
  --
  procedure create_sync_jobs;
  --
  -- Процедура удаления процесса сканирования VSA атрибутов
  --
  procedure drop_sync_jobs;
  --
end utl_p_$redback;
/
create or replace package body utl_p_$redback is
  -- 
  -- Процедура синхронизации  VSA атрибутов для REDBACK
  --
  procedure synchronize is
  begin
    synchronize_static_attr;
    synchronize_speed_vsa_attr;
    synchronize_filter_vsa_attr;
  end;
  -- 
  -- Процедура синхронизации статических VSA атрибута Service-Name и Service-Action
  --
  procedure synchronize_static_attr is
    c_sn_attr_type constant number := 83;
    c_sa_attr_type constant number := 84;
    c_sn_attr_val  constant varchar2(50) := 'InetBand';
    c_sa_attr_val  constant varchar2(50) := '1';
    -- Определяем значение атрибута VSA
    function get_vsa_attr_value(p_service_id in number, p_vsa_type_id in number ) return varchar2 is
      v_retval varchar2(256);
    begin
      begin
        select t.value into v_retval from cifra.m3_vsa_values t where t.service_id = p_service_id and t.vsa_type_id = p_vsa_type_id;
      exception 
        when no_data_found then v_retval := null;
      end;
      return v_retval;
    end;
    -- Задаем значение атрибута VSA
    procedure set_vsa_attr_value(p_service_id in number, p_vsa_type_id in number, p_value in varchar2 ) is
      v_value varchar2(256);
    begin
      v_value := get_vsa_attr_value(p_service_id, p_vsa_type_id);
      if (v_value is not null) and (v_value <> p_value) then
        update cifra.m3_vsa_values vv set vv.value = p_value
         where vv.vsa_type_id = p_vsa_type_id 
          and vv.service_id = p_service_id;
      elsif (v_value is null) then
        insert into cifra.m3_vsa_values (id, vsa_type_id, value, service_id)
             values (cifra.m3_vsa_values_seq.nextval, p_vsa_type_id, p_value, p_service_id);
      end if;
    end;
    -- Синхронизируем заданный атрибут
    procedure synchronize_attr(p_vsa_type_id in number, p_value in varchar2 ) is
    begin
      -- Выбираем записи где отличается значения атрибута или оно не установлено
      for spd_rec in ( select dld.service_id
                         from (select dd.service_id
                                 from cifra.m3_service_dialup_details dd
                                where dd.is_used_vsa = 'Y') dld,
                              (select vv.service_id, vv.value
                                 from cifra.m3_vsa_values vv 
                                where vv.vsa_type_id = p_vsa_type_id) vsv
                        where dld.service_id = vsv.service_id(+)
                          and nvl(vsv.value,0) <> p_value) loop
          -- Устанавливаем в соответстиве с перданным значением
          set_vsa_attr_value(spd_rec.service_id, p_vsa_type_id, p_value);
          commit;
      end loop;
    end;
  begin
    synchronize_attr(c_sn_attr_type, c_sn_attr_val);
    synchronize_attr(c_sa_attr_type, c_sa_attr_val);
  end;
  -- 
  -- Процедура синхронизации VSA атрибута скорости
  --
  procedure synchronize_speed_vsa_attr is
  begin
    -- Выбираем записи где отличается значение Filter ID и значение Subscriber-Profile-Name
    for spd_rec in (select t1.service_id
                      from (select * from cifra.m3_vsa_values vv  where vv.vsa_type_id = c_mt_vsa_attr_type) t1,
                           (select * from cifra.m3_vsa_values vv  where vv.vsa_type_id = c_rb_vsa_attr_type) t2
                     where t1.service_id = t2.service_id(+) 
                       and (utl_p_$redback.convert_rate_vsa_attr(t1.value)) <> nvl(t2.value,'0')) loop
        -- Устанавливаем в соответстиве Subscriber-Profile-Name
        set_ratelimit_vsa_attr(spd_rec.service_id);
        commit;
    end loop;
  end;
  -- 
  -- Функция конвертирования скорости
  --
  function convert_rate_vsa_attr(p_mt_ratelimit in varchar2) return varchar2 is
    c_parm_value_templ constant varchar2(256) := 'Rate=$X Burst=$Y ExceedBurst=$Z';
    c_Mbytes_1 constant char(1) := 'M'; -- lat
    c_Kbytes_1 constant char(1) := 'K'; -- lat
    c_Mbytes_2 constant char(1) := 'М'; -- rus
    c_Kbytes_2 constant char(1) := 'К'; -- rus
    v_rate  number;
    v_speed number;
    v_power char(1) := '';
    v_rate_value varchar2(512);
  begin
    v_power := substr(upper(p_mt_ratelimit),length(p_mt_ratelimit),1); 
    case  
      when v_power in (c_Mbytes_1, c_Mbytes_2) then 
        begin
          v_rate  := to_number(substr(upper(p_mt_ratelimit), 1 ,length(p_mt_ratelimit)-1));
          v_speed := v_rate*1024;
        end;
      when v_power in (c_Kbytes_1, c_Kbytes_2) then 
        begin
          v_rate  := to_number(substr(upper(p_mt_ratelimit), 1 ,length(p_mt_ratelimit)-1));
          v_speed := v_rate;
        end;    
      else
        begin
          v_rate  := to_number(upper(p_mt_ratelimit));
          v_speed := v_rate/1024;
        end;    
    end case;
    v_rate_value := replace(c_parm_value_templ,'$X',v_speed);
    v_rate_value := replace(v_rate_value,'$Y',v_speed*16);
    v_rate_value := replace(v_rate_value,'$Z',v_speed*32);
    return v_rate_value;
  exception
    when others then return c_err;
  end;
  -- 
  -- Процедура установки VSA атрибута Service-Parameter в соответствии со
  -- значением атрибута Mikrotik-Rate-Limit
  --
  -- Service-Parameter = "Rate=XXXX Burst=YYYY ExceedBurst=ZZZZ"
  -- SPEED - скорость в килобитах (10240, например)
  -- rate = SPEED
  -- burst = (SPEED * 16 )
  -- exceed-burst = (SPEED * 32) 
  -- SPEED берется  из аттрибута Mikrotik-Rate-Limit, там он указывается в
  -- таком формате:
  -- xxxM = в мегабитах/c , SPEED=xxx*1024
  -- xxxK = в килобитах/c , SPEED=xxx
  -- xxx  = в битах/c     , SPEED=xxx/1024 
  --
  procedure set_ratelimit_vsa_attr(p_service_id in number) is
    v_mt_rate_limit varchar2(256);
    v_cnt integer;
    v_value varchar2(256);
  begin
    begin 
      -- Получаем значение атрибута скорости для Mikrotik
      select vv.value 
        into v_mt_rate_limit
        from cifra.m3_vsa_values vv  
       where vv.vsa_type_id = c_mt_vsa_attr_type 
         and vv.service_id = p_service_id; 
    exception 
      when no_data_found or too_many_rows then return; -- Если значение скорости не установлено не делаем ничего
    end;
    -- Синхронизируем атрибуты для Redback
    select count(1) into v_cnt from cifra.m3_vsa_values vv
     where vv.vsa_type_id = c_rb_vsa_attr_type 
       and vv.service_id = p_service_id;
    -- Конвертируем скорость
    v_value := convert_rate_vsa_attr(v_mt_rate_limit);
    -- Добавляем\изменяем\удаляем атрибут
    if (v_cnt > 0) and (v_value <> c_err) then
      update cifra.m3_vsa_values vv set vv.value = v_value
       where vv.vsa_type_id = c_rb_vsa_attr_type 
        and vv.service_id = p_service_id;
    elsif (v_cnt = 0)  and (v_value <> c_err) then
      insert into cifra.m3_vsa_values (id, vsa_type_id, value, service_id)
           values (cifra.m3_vsa_values_seq.nextval, c_rb_vsa_attr_type, v_value, p_service_id);
    end if;
  end;    
  -- 
  -- Процедура синхронизации VSA атрибута Subscriber-Profile-Name в соответствии с Filter ID
  --
  procedure synchronize_filter_vsa_attr is
  begin
    -- Выбираем записи где отличается значение Filter ID и значение Subscriber-Profile-Name
    for fltr_rec in (select dld.service_id, dld.filter_id 
                       from (select dd.service_id, dd.filter_id, dfl.value
                               from cifra.m3_service_dialup_details dd, 
                                    cifra.m3_dialup_filters dfl
                              where dd.is_used_vsa = 'Y' 
                                and dd.filter_id = dfl.id(+)) dld,
                            (select vv.service_id, vv.value
                               from cifra.m3_vsa_values vv 
                              where vv.vsa_type_id = c_fl_vsa_attr_type) vsv
                      where dld.service_id = vsv.service_id(+)
                        and nvl(vsv.value,0) <> nvl(dld.value,0)) loop
        -- Устанавливаем в соответстиве Subscriber-Profile-Name
        set_filter_vsa_attr(fltr_rec.service_id, fltr_rec.filter_id);
        commit;
    end loop;
  end;
  -- 
  -- Процедура установки VSA атрибута Subscriber-Profile-Name в соответствии с Filter ID
  --
  procedure set_filter_vsa_attr(p_service_id in number, p_filter_id in number) is
    v_cnt     number; 
    v_vsa_val varchar2(10);  
    -- Определяем значение атрибута равное значению Filter ID
    function get_vsa_attr_value return varchar2 is
      v_retval varchar2(10);
    begin
      begin
        select t.value into v_retval from cifra.m3_dialup_filters t where t.id = p_filter_id;
      exception 
        when no_data_found then v_retval := null;
      end;
      return v_retval;
    end;
  begin
    v_vsa_val := get_vsa_attr_value;
    -- Проверяем наличие установки данного атрибута
    select count(1) into v_cnt from cifra.m3_vsa_values vv
     where vv.vsa_type_id = c_fl_vsa_attr_type 
       and vv.service_id = p_service_id;
    -- Добавляем\изменяем\удаляем атрибут
    if ((v_cnt > 0) and (p_filter_id is not null)) then
      update cifra.m3_vsa_values vv set vv.value = v_vsa_val
       where vv.vsa_type_id = c_fl_vsa_attr_type 
         and vv.service_id = p_service_id;
    elsif ((v_cnt > 0) and (p_filter_id is null)) then
      delete from cifra.m3_vsa_values vv
       where vv.vsa_type_id = c_fl_vsa_attr_type 
         and vv.service_id = p_service_id;
    elsif ((v_cnt = 0) and (p_filter_id is not null)) then
      insert into cifra.m3_vsa_values (id, vsa_type_id, value, service_id)
             values (cifra.m3_vsa_values_seq.nextval, c_fl_vsa_attr_type, v_vsa_val, p_service_id);
    end if;
  end;
  --
  -- Процедура создания процесса сканирования VSA атрибутов
  --
  procedure create_sync_jobs is
    v_job_start_date date;
  begin
    -- Создаем процесс 
    v_job_start_date := sysdate+((1/(24*60)));
    dbms_scheduler.create_job(job_name            => c_job_name,
                              job_type            => 'PLSQL_BLOCK',
                              job_action          => 'begin utl_p_$redback.synchronize; end; ',
                              start_date          => v_job_start_date,
                              repeat_interval     => 'freq=minutely;interval=3',
                              end_date            => to_date(null),
                              job_class           => 'DEFAULT_JOB_CLASS',
                              enabled             => false,
                              auto_drop           => false,
                              comments            => 'Процесс синхронизации атрибутов VSA');
    commit;
  end;
  --
  -- Процедура удаления процесса сканирования VSA атрибутов
  --
  procedure drop_sync_jobs is
  begin  
    dbms_scheduler.drop_job(c_job_name);
  end;
  --
begin
  null;
end utl_p_$redback;
/
