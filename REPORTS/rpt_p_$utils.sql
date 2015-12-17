create or replace package rpt_p_$utils is
/*
  Author  : V.ERIN
  Created : 17.11.2014 12:00:00
  Version : 1.1.01
  Purpose : Объекты для в отчетах.
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    17/11/2014     Создание пакета
  -------------------------------------------------------------------------------------------------
  M.PAK     17/03/2015     Добавлены методы get_period, get_qty_change_tp, get_inet_qty_change_tp,
                           get_tv_qty_change_tp, get_ab_qty_change_tp, get_phone_qty_change_tp.
                           Изменен метод get_tserv_tpname.
  -------------------------------------------------------------------------------------------------
  V.ERIN    25/05/2015     Добавлены процедуры для работы с таблицей параметров rpt_parametrs$
  -------------------------------------------------------------------------------------------------
  V.ERIN    13/07/2015     Добавлена функция, возвращающая перечень дат
  -------------------------------------------------------------------------------------------------
  V.ERIN    11/09/2015     Добавлена функция, возвращающая контактный телефон
  -------------------------------------------------------------------------------------------------
*/
  -- Константы
  c_current_period      constant number  :=  cifra.m2_clc.currentinformationnumber;
  c_previous_period     constant number  :=  c_current_period - 1;
  c_pre_previous_period constant number  :=  c_current_period - 2;
  c_last_period         constant number  :=  c_current_period - 3;
  -- Сегменты рынка
  c_b2b constant varchar2(3)  := 'B2B';
  c_b2c constant varchar2(3)  := 'B2C';
  c_b2g constant varchar2(3)  := 'B2G';
  c_b2o constant varchar2(3)  := 'B2O';
  -- Глобальные переменные
  type t_date is table of date;
  --
  -- Функции
  --
  -- Вернуть сегмент рынка абонента
  --
  function get_market_segment(p_abonent_id in number) return varchar2;
  --
  -- Вернуть текущий период
  --
  function get_current_period return number;
  --
  -- Вернуть предыдущий период
  --
  function get_previous_period return number;
  --
  -- Вернуть предпредыдущий период
  --
  function get_pre_previous_period return number;
  --
  -- Вернуть последний период
  --
  function get_last_period return number;
  --
  -- Статус абонента
  --
  function get_status(p_state_id in number) return varchar2;
  --
  -- Вернуть название основной услуги абонента (тип договора)
  --
  function get_abon_servname(p_abonent_id in number) return varchar2;
  --
  -- Вернуть ФИО пользователя
  --
  function get_username(p_user_id in number) return varchar2;
  --
  -- Вернуть ФИО acount manager
  --
  function get_accname(p_abonent_id in number) return varchar2;
  --
  -- ТП абонента
  --
  function get_abon_tpname(p_abonent_id in number) return varchar2;
  --
  -- ТП услуги абонента (для Интернет)
  --
  function get_iserv_tpname(p_abonent_id in number) return varchar2;
  --
  -- ТП услуги абонента (для телефонии и ТВ)
  --
  function get_tserv_tpname(p_abonent_id in number) return varchar2;
  --
  -- Функция получения значения параметра
  --
  function get_param_value(p_rppm_id in varchar2, def_value in varchar2 default null) return varchar2;
  --
  -- Процедура установки значения параметра
  --
  procedure set_param_value(p_rppm_id in varchar2, set_value in varchar2);
  --
  -- Вернуть значение дополнительного параметра абонента
  --
  function get_abon_addparam_value(p_abonent_id    in number,
                                   p_param_type_id in number,
                                   p_def_val       in varchar2) return varchar2;
  --
  -- Абонплата абонента интернет
  --
  function get_iabonplata(p_service_id in number, p_sertype_id in number, p_tp_id in number ) return number;
  --
  -- Абонплата абонента телефония и ТВ
  --
  function get_tabonplata(p_service_id in number, p_sertype_id in number) return number;
  --
  -- Вернуть период по дате
  --
  function get_period(p_date in date)  return number;
  --
  -- Количество изменений тарифных планов абонента по типу услуги
  --
  function get_qty_change_tp(
    p_abonid in number,
    p_srvid in number,
    p_type_srv in varchar2,
    p_bdate in date,
    p_edate in date) return number;
  --
  -- Процедура изменения параметра
  --
  procedure upd_param_value(p_param_id in varchar2, p_value in varchar2 , p_comment in varchar2);
  --
  -- Процедура добавления параметра
  --
  procedure ins_param_value(p_param_id in varchar2, p_value in varchar2 , p_comment in varchar2);
  --
  -- Функция, возвращающая перечень дат
  function get_dates(p_start_date in date,
                     p_end_date in date) return t_date pipelined;
  --
  -- Функция поиска контактного номера телефона абонента
  --
  function get_phone(p_account_id in number) return varchar2;
  --
end rpt_p_$utils;
/
create or replace package body rpt_p_$utils is
  --
  -- Вернуть текущий период
  --
  function get_current_period return number is
  begin
    return c_current_period;
  end;
  --
  -- Вернуть предыдущий период
  --
  function get_previous_period return number is
  begin
    return c_previous_period;
  end;
  --
  -- Вернуть предпредыдущий период
  --
  function get_pre_previous_period return number is
  begin
    return c_pre_previous_period;
  end;
  --
  -- Вернуть последний период
  --
  function get_last_period return number is
  begin
    return c_last_period;
  end;
  --
  -- Количество изменений тарифных планов у интернет-услуги
  --
  function get_inet_qty_change_tp(
    p_srvid in number,
    p_bdate in date,
    p_edate in date) return number;
  --
  -- Количество изменений тарифных планов у услуги по телевидению
  --
  function get_tv_qty_change_tp(
    p_srvid in number,
    p_bdate in date,
    p_edate in date) return number;
  --
  -- Количество изменений тарифных планов у абонента(лицевого счета)
  --
  function get_ab_qty_change_tp(
    p_abid in number,
    p_bdate in date,
    p_edate in date) return number;
  --
  -- Количество изменений тарифных планов для услуги по телефонии
  --
  function get_phone_qty_change_tp(
    p_cuslid in number,
    p_abid in number,
    p_bdate in date,
    p_edate in date) return number;
  --
  -- Статус абонента
  --
  function get_status(p_state_id in number) return varchar2 is
    v_retval varchar2(50) := 'Не определен';
  begin
    begin
      select t.name into v_retval from cifra.ao_list_abstate t where t.id = p_state_id;
    exception
      when no_data_found then null;
    end;
    return v_retval;
  end;
  --
  -- Вернуть сегмент рынка абонента
  --
  function get_market_segment(p_abonent_id in number) return varchar2 is
    v_cardtype_id  number;
    v_finans_id    number;
    v_retval       varchar2(3) := c_b2c;
  begin
    begin
      select ab.cardtype_id, aco.finans into v_cardtype_id, v_finans_id
        from cifra.ao_abonent ab, cifra.ao_contragent ac, cifra.ao_contragent_org aco
       where ab.id = p_abonent_id
         and ab.contragent_id = ac.id
         and aco.contragent = ac.id;
      -- Определяем сегмент рынка
      case
        when v_cardtype_id = 0 then v_retval := c_b2c;
        when v_finans_id = 1   then v_retval := c_b2g;
        when v_finans_id = 2   then v_retval := c_b2o;
        else v_retval := c_b2b;
      end case;
    exception
      when no_data_found then null;
    end;
    return v_retval;
  end;
  --
  -- Вернуть название основной услуги абонента (тип договора)
  --
  function get_abon_servname(p_abonent_id in number) return varchar2 is
    v_type_id integer := null;
    v_retval  varchar2(50);
  begin
    begin
      select act.type_id into v_type_id
        from cifra.ao_abonent ab, cifra.ao_contracts act
       where ab.id = p_abonent_id
         and ab.id = act.abonent_id
         and act.edate is null
         and act.type_id not in (2, 5, 6, 10);
    exception
      when no_data_found or too_many_rows then null;
    end;
    -- Выбор абонентской услуги
    case
      when v_type_id is null              then v_retval := '[Закрыт]';
      when v_type_id = 12                 then v_retval := '[Телефония ПИН]';
      when v_type_id = 9                  then v_retval := '[Телефония]';
      when v_type_id = 8                  then v_retval := '[Интернет]';
      when v_type_id = 11                 then v_retval := '[Цифровое ТВ]';
                                          else v_retval := '[Неизвестно]' ;
    end case;
    return v_retval;
  end;
  --
  -- Вернуть ФИО пользователя
  --
  function get_username(p_user_id in number) return varchar2 is
    v_retval  varchar2(256) := '';
  begin
    begin
      select lu.user_fam||' '||lu.user_name||' '||lu.user_otch||' ('||lu.user_nickname||')' as mgr into v_retval
        from cifra.userlist lu
       where lu.user_id = p_user_id;
    exception
      when no_data_found or too_many_rows then null;
    end;
    return v_retval;
  end;
  --
  -- Вернуть ФИО acount manager
  --
  function get_accname(p_abonent_id in number) return varchar2 is
    c_accmgr_type_id number := 58;
    v_accmgr_user_id number := -1;
  begin
    begin
      select value into v_accmgr_user_id
        from cifra.ao_attrib_values av
       where av.attrib_type_id = c_accmgr_type_id
         and av.rec_id = p_abonent_id;
    exception
      when no_data_found or too_many_rows then null;
    end;
    return get_username(v_accmgr_user_id);
  end;
  --
  -- ТП абонента
  --
  function get_abon_tpname(p_abonent_id in number) return varchar2 is
    v_retval  varchar2(256) := 'Не определен ТП';
    v_servnum number := reqmon.info_p_$procedures.get_service_num(p_abonent_id);
  begin
    -- Выбор абонентской услуги
    case v_servnum
      when reqmon.info_p_$procedures.c_phone_nserv then v_retval := get_tserv_tpname(p_abonent_id);
      when reqmon.info_p_$procedures.c_tv_nserv    then v_retval := get_tserv_tpname(p_abonent_id);
      when reqmon.info_p_$procedures.c_inet_nserv  then v_retval := get_iserv_tpname(p_abonent_id);
      else                                              v_retval := get_tserv_tpname(p_abonent_id);
    end case;
    return v_retval;
  end;
  --
  -- ТП услуги абонента (для Интернет)
  --
  function get_iserv_tpname(p_abonent_id in number) return varchar2 is
    v_retval  varchar2(256) := 'Не определен ТП';
    v_serv_id number := null;
     -- Проверка на интернет
    function get_inet_serv return number is
      v_retval number := null;
    begin
      begin
        select srv.id into v_retval
          from cifra.m3_services srv
         where srv.type_id in (44, 51, 54, 64, 65, 70) and srv.edate is null and srv.abonent_id = p_abonent_id;
      exception
        when no_data_found or too_many_rows then null;
      end;
      return v_retval;
    end;
  begin
    v_serv_id := get_inet_serv;
    begin
      select pt.name v_retval
        into v_retval
        from cifra.m3_services srv,
             cifra.m3_plan_types pt
          where srv.plan_id = pt.id
            and srv.id = v_serv_id
            and srv.abonent_id = p_abonent_id;
    exception
      when no_data_found or too_many_rows then null;
    end;
    return v_retval;
  end;
  --
  -- ТП услуги абонента (для телефонии, ТВ)
  -- M.PAK  17/03/2015  Для услуги по телефонии добавлен поиск ТП услуги.
  --
function get_tserv_tpname(p_abonent_id in number) return varchar2 is
    v_retval    varchar2(256) := '';
    v_cusl_id   number := null;
    v_cusl_type number := null;
  begin
    begin
      select cl.cusl_ucod, cl.cusl_vid into v_cusl_id, v_cusl_type from cifra.cusl cl where cl.cusl_abon_num = p_abonent_id and cl.cusl_vid in (1, 17) and rownum =1;
    exception
      when no_data_found or too_many_rows then null;
    end;
    if v_cusl_type = 17 then -- Телевидение + Определяем дополнительно, какой пакет подключен
        begin
          select lo.lso_name
            into v_retval
            from cifra.cusl c,
                 cifra.cusl_xr cx,
                 cifra.list_operation lo
           where c.cusl_parent = v_cusl_id
             and c.cusl_vid = 2 -- абонплата
             and cx.cxr_id = cifra.m2_abn.m2_get_lcxr(c.cusl_ucod)
             and lo.lso_cod = cx.cxr_targroup;
        exception
          when no_data_found or too_many_rows then null;
        end;
        if v_retval is null then
           v_retval := 'Цифровое ТВ';
        else
           v_retval := v_retval;
        end if;
    else -- Для остальных услуг
        if v_cusl_type = 1 then -- Телефония
          -- Поиск тарифного плана для услуги
          for rec in (
            select pt.name
              from cifra.m3_plan_types pt,
                   cifra.tarplan tp,
                   cifra.cusl_tel ct
             where ct.ct_cusl_ucod = v_cusl_id
               and tp.tp_telid = ct.ct_ucod
               and pt.id = tp.tp_cod
             order by tp.tp_date desc, tp.tp_id desc)
          loop
            v_retval := rec.name;
            exit;
          end loop;
        end if;
        if v_retval is null then
          -- Поиск тарифного плана для абонента
          begin
            select pt.name v_retval
              into v_retval
              from cifra.tarplan tp,
                   cifra.m3_plan_types pt,
                   cifra.ao_abonent ab
             where tp.tp_date = ( select max( tp2.tp_date ) from cifra.tarplan tp2 where tp2.tp_id = tp.tp_id)
               and tp.tp_cod = pt.id
               and ab.plan_id = tp.tp_id
               and ab.id = p_abonent_id;
          exception
            when no_data_found or too_many_rows then null;
          end;
        end if;
    end if;
    if v_retval is null then
      v_retval := 'Не определен ТП';
    end if;
    return v_retval;
  end;
  --
  -- Функция получения значения параметра
  --
  function get_param_value(p_rppm_id in varchar2, def_value in varchar2) return varchar2 is
    v_retval varchar2(256) := def_value;
   pragma autonomous_transaction;
  begin
    begin
      select rpp.rppm_value into v_retval from rpt_parameters$ rpp where rpp.rppm_id = p_rppm_id;
    exception
      when no_data_found then
        insert into rpt_parameters$ values (p_rppm_id, def_value, p_rppm_id);
        commit;
    end;
    return v_retval;
  end;
  --
  -- Процедура установки значения параметра
  --
  procedure set_param_value(p_rppm_id in varchar2, set_value in varchar2) is
    pragma autonomous_transaction;
  begin
    update rpt_parameters$ rpp set rpp.rppm_value = set_value where rpp.rppm_id = p_rppm_id;
    commit;
  end;
  --
  -- Вернуть значение дополнительного параметра абонента
  --
  function get_abon_addparam_value(p_abonent_id    in number,
                                   p_param_type_id in number,
                                   p_def_val       in varchar2) return varchar2 is
    v_retval varchar2(256) := p_def_val;
  begin
    begin
      select value into v_retval
        from cifra.ao_attrib_values av
       where av.attrib_type_id = p_param_type_id
         and av.rec_id = p_abonent_id;
    exception
      when no_data_found or too_many_rows then null;
    end;
    return v_retval;
  end;
  --
  -- Абонплата абонента интернет
  --
  function get_iabonplata(p_service_id in number, p_sertype_id in number, p_tp_id in number ) return number is
    v_retval   number;
    v_rate     number;
    v_currency number;
  begin
    cifra.s_calc.get_tariff(a_service_id  => p_service_id,
                            a_srv_type_id => p_sertype_id,
                            a_plan_id     => p_tp_id,
                            a_dt          => sysdate,
                            a_rate_state  => v_rate,
                            a_tariff      => v_retval,
                            a_currency_id => v_currency);
    if v_retval is null then
       v_retval := 0;
    end if;
    return v_retval;
  end;
  --
  -- Абонплата абонента телефония и ТВ
  --
  function get_tabonplata(p_service_id in number, p_sertype_id in number) return number is
    v_retval number := 0;
  begin
    begin
      v_retval := cifra.get_ucod_abon(p_service_id);
      if p_sertype_id = 17 then
         for srv in (select cl.cusl_ucod id from cifra.cusl cl where cl.cusl_parent = p_service_id) loop
             v_retval := v_retval + cifra.get_ucod_abon(srv.id);
         end loop;
      end if;
    exception
      when others then v_retval := -1;
    end;
    if v_retval is null then
       v_retval := 0;
    end if;
    return v_retval;
  end;
  --
  -- Вернуть период по дате
  -- Создан  11.03.2015  M.Pak
  --
  function get_period(p_date in date)  return number is
    v_retval number;
  begin
    begin
      select inf.inf_num into v_retval
        from cifra.information inf
       where trunc(p_date) between inf.inf_bdate and nvl(inf.inf_edate, last_day(inf.inf_bdate));

    exception
      when no_data_found or too_many_rows then null;
    end;
    return v_retval;
  end;
  --
  -- Количество изменений тарифных планов абонента по типу услуги за заданный период
  -- Создан  13.05.2015 M.Pak
  --
  function get_qty_change_tp(
    p_abonid in number,
    p_srvid in number,
    p_type_srv in varchar2,
    p_bdate in date,
    p_edate in date) return number
  is
    v_retval number;
    v_srvid number;
    v_cuslid number;
    v_qty_dop_srv number;
  begin
    if p_type_srv = 'inet' then
      if p_srvid is not null then
        v_srvid := p_srvid;
      else
        begin
          -- Код интернет-услуги, действующий на nvl(p_edate, sysdate)
          select srv.id into v_srvid
            from cifra.m3_services srv
           where srv.abonent_id = p_abonid
             and srv.type_id in (44, 51, 54, 64, 65, 70)
             and srv.bdate <= nvl(p_edate, sysdate)
             and (srv.edate is null or srv.edate >= nvl(p_edate, sysdate));
        exception
          when no_data_found or too_many_rows then null;
        end;
      end if;
      if v_srvid is not null then
        v_retval := rpt_p_$utils.get_inet_qty_change_tp(v_srvid, p_bdate, p_edate);
      else
        v_retval := rpt_p_$utils.get_ab_qty_change_tp(p_abonid, p_bdate, p_edate);
      end if;
    elsif p_type_srv = 'phone' then
      if p_srvid is not null then
        v_cuslid := p_srvid;
      else
        begin
          -- Код услуги по телефонии, действующий на nvl(p_edate, sysdate)
          select cusl.cusl_ucod
            into v_cuslid
            from cifra.cusl cusl
           where cusl.cusl_vid = 1
             and cusl.cusl_bdate <= nvl(p_edate, sysdate)
             and (cusl.cusl_edate is null or cusl.cusl_edate >= nvl(p_edate, sysdate));
        exception
          when no_data_found or too_many_rows then null;
        end;
      end if;
      if v_cuslid is not null then
        v_retval := rpt_p_$utils.get_phone_qty_change_tp(v_cuslid, p_abonid, p_bdate, p_edate);
        null;
      end if;
    elsif p_type_srv = 'tv' then
      if p_srvid is not null then
        v_cuslid := p_srvid;
        begin
          -- Код услуги по телевидению, действующий на nvl(p_edate, sysdate)
          select cusl.cusl_ucod,
                 (select count(cuslf.cusl_ucod)
                    from cifra.cusl cuslf
                   where cuslf.cusl_parent = cusl.cusl_ucod
                     and cuslf.cusl_vid = 2) qty_dop_srv
          into v_cuslid,
               v_qty_dop_srv
            from cifra.cusl cusl
           where cusl.cusl_ucod = v_cuslid
             and cusl.cusl_vid+0 = 17;
        exception
          when no_data_found or too_many_rows then null;
        end;
      else
        begin
          -- Код услуги по телевидению, действующий на nvl(p_edate, sysdate)
          select cusl.cusl_ucod,
                 (select count(cuslf.cusl_ucod)
                    from cifra.cusl cuslf
                   where cuslf.cusl_parent = cusl.cusl_ucod
                     and cuslf.cusl_vid = 2) qty_dop_srv
          into v_cuslid,
               v_qty_dop_srv
            from cifra.cusl cusl
           where cusl.cusl_abon_num = p_abonid
             and cusl.cusl_vid+0 = 17
             and cusl.cusl_bdate <= nvl(p_edate, sysdate)
             and (cusl.cusl_edate is null or cusl.cusl_edate >= nvl(p_edate, sysdate));
        exception
          when no_data_found or too_many_rows then null;
        end;
      end if;
      if v_cuslid is not null and v_qty_dop_srv <= 1 then
        v_retval := rpt_p_$utils.get_tv_qty_change_tp(v_cuslid, p_bdate, p_edate);
      else
        v_retval := rpt_p_$utils.get_ab_qty_change_tp(p_abonid, p_bdate, p_edate);
      end if;
    else
      v_retval := rpt_p_$utils.get_ab_qty_change_tp(p_abonid, p_bdate, p_edate);
    end if;
    return v_retval;
  end;
  --
  -- Количество изменений тарифных планов у интернет-услуги за заданный период
  -- Создан  13.05.2015 M.Pak
  --
  function get_inet_qty_change_tp(
    p_srvid in number,
    p_bdate in date,
    p_edate in date) return number
  is
    v_retval number;
  begin
    begin
      select decode(count(id), 0, 0, 1, 1, count(id)- 1) into v_retval
      from   (select srv.id
              from   cifra.m3_services srv,
                     cifra.m3_service_types srvtp,
                     cifra.m3_services srvin
              where  srvin.id = p_srvid
                and  srvtp.id = srvin.type_id
                and  srvtp.class_id+0 = 2 -- Коммутируемый доступ
                and  srv.abonent_id = srvin.abonent_id
                and  srv.type_id = srvin.type_id
                and  (p_edate is null or srv.bdate is not null and srv.bdate <= p_edate)
                and  (p_bdate is null or srv.edate is null or srv.edate >= p_bdate)
                and  exists (
                       select 1
                         from cifra.m3_logins lgnin,
                              cifra.m3_logins lgn
                        where lgnin.service_id = p_srvid
                          and lgn.service_id = srv.id
                          and lgn.user_name = lgnin.user_name)
               union all
              select srv.id
              from   cifra.m3_services srv,
                     cifra.m3_service_types srvtp,
                     cifra.m3_services srvin
              where  srvin.id = p_srvid
                and  srvtp.id = srvin.type_id
                and  srvtp.class_id+0 = 16 -- Счетчик трафика
                and  srv.abonent_id = srvin.abonent_id
                and  srv.type_id = srvin.type_id
                and  (p_edate is null or srv.bdate is not null and srv.bdate <= p_edate)
                and  (p_bdate is null or srv.edate is null or srv.edate >= p_bdate)
                and  exists (
                       select 1
                         from cifra.m3_service_trafcnt_details tcin,
                              cifra.m3_service_trafcnt_details tc
                        where tcin.service_id = p_srvid
                          and tc.service_id = srv.id
                          and tc.ip_addr = tc.ip_addr
                          and tc.end_ip_addr = tc.end_ip_addr));
    exception
      when no_data_found then null;
    end;
    return v_retval;
  end;
  --
  -- Количество изменений тарифных планов у услуги по телевидению
  -- Создан  13.05.2015 M.Pak
  --
  function get_tv_qty_change_tp(
    p_srvid in number,
    p_bdate in date,
    p_edate in date) return number
  is
    v_retval number;
    v_dopsrv_tp_qty_change number;
    v_is_dop_srv_begin VARCHAR(1);
  begin
    v_is_dop_srv_begin := 'N';
    v_dopsrv_tp_qty_change := 0;
    for rec in (
      select count(lo.lso_cod) dopsrv_tp_qty_change,
             max(decode(cuslin.cusl_bdate, cusl.cusl_bdate, 'Y', 'N')) is_dop_srv_begin
      from   cifra.list_operation lo,
             cifra.cusl_xr cx,
             cifra.cusl cusl,
             cifra.cusl cuslin
      where  cuslin.cusl_ucod = p_srvid
        and  cuslin.cusl_vid+0 = 17
        and  cuslin.cusl_parent is null
        and  cusl.cusl_parent = cuslin.cusl_ucod
        and  cusl.cusl_vid+0 = 2 -- абонплата
        and  (p_edate is null or cusl.cusl_bdate is not null and cusl.cusl_bdate<= p_edate)
        and  (p_bdate is null or cusl.cusl_edate is null or cusl.cusl_edate >= p_bdate)
        and  cx.cxr_cusl_ucod = cusl.cusl_ucod
        and  lo.lso_cod = cx.cxr_targroup
        and  (p_bdate is null or cx.cxr_date >= p_bdate)
        and  (p_edate is null or cx.cxr_date <= p_edate))
    loop
      v_dopsrv_tp_qty_change := rec.dopsrv_tp_qty_change;
      v_is_dop_srv_begin := rec.is_dop_srv_begin;
    end loop;
    --
    if v_is_dop_srv_begin = 'N' and v_dopsrv_tp_qty_change > 0
    then -- сразу не было дополнительной услуги, но потом были назначены
      v_retval := v_dopsrv_tp_qty_change;
    elsif v_is_dop_srv_begin = 'Y' and v_dopsrv_tp_qty_change > 1
    then -- сразу была дополнительная услуга
      v_retval := v_dopsrv_tp_qty_change - 1; -- вычитаем доп.услугу, которая была назначена сразу
    else
      v_retval := 0;
    end if;
    --
    return v_retval;
  end;
  --
  -- Количество изменений тарифных планов у абонента(лицевого счета)
  -- Создан  17.05.2015 M.Pak
  --
  function get_ab_qty_change_tp(
    p_abid in number,
    p_bdate in date,
    p_edate in date) return number
  is
    v_retval number;
  begin
    begin
      select count(tplan.tp_id)
        into v_retval
        from (select tplan.tp_id,
                     tplan.tp_date tp_bdate,
                     lead(tplan.tp_date) over (partition by tplan.tp_abid order by tplan.tp_date) tp_edate,
                     tplan.tp_cod
                from (select tplan.tp_id,
                             tplan.tp_abid,
                             tplan.tp_date,
                             tplan.tp_cod,
                             row_number() over (partition by tplan.tp_date, tplan.tp_cod order by tplan.tp_id desc) ord_
                        from cifra.tarplan tplan
                       where tplan.tp_abid = p_abid) tplan
              where tplan.ord_ = 1) tplan
       where (p_edate is null or tplan.tp_bdate <= p_edate)
         and (p_bdate is null or tplan.tp_edate is null or tplan.tp_edate >= p_bdate);
    exception
      when no_data_found then
        v_retval := 0;
    end;
    if v_retval >= 1 then
      v_retval := v_retval - 1;
    end if;
    return v_retval;
  end;
  --
  -- Количество изменений тарифных планов для услуги по телефонии
  -- Создан  13.05.2015  M.Pak
  --
  function get_phone_qty_change_tp(
    p_cuslid in number,
    p_abid in number,
    p_bdate in date,
    p_edate in date) return number
  is
    v_retval number;
    type t_rec_tarplan is record (
      tp_bdate date,
      tp_edate date,
      tp_cod number);
    type t_tab_tarplan is table of t_rec_tarplan index by binary_integer;
    v_tab_usl_tp t_tab_tarplan;
    v_tab_ab_tp t_tab_tarplan;
    i number;
    j number;
    v_datefirst date;
    v_datelast date;
    v_usl_tp_count_notnull number;
    v_bdate date;
    v_cusl_bdate date;
  begin
    begin
      select cusl.cusl_bdate
      into   v_cusl_bdate
      from   cifra.cusl cusl
      where  cusl.cusl_ucod = p_cuslid;
      if v_cusl_bdate is not null and (p_bdate is null or p_bdate < v_cusl_bdate) then
        v_bdate := v_cusl_bdate;
      else
        v_bdate := p_bdate;
      end if;
      --
      v_usl_tp_count_notnull := 0;
      -- Заполнить список тарифных планов для услуги, которые действовали в заданном периоде
      for rec in (
        select tplan.tp_id,
               tplan.tp_bdate,
               tplan.tp_cod,
               tplan.tp_edate
        from   (select tplan.tp_id,
                       tplan.tp_date tp_bdate,
                       tplan.tp_cod,
                       lead(tplan.tp_date) over (partition by cusl.cusl_ucod order by
                         tplan.tp_date, tplan.tp_id) tp_edate
                 from  cifra.tarplan tplan,
                       cifra.cusl_tel ct,
                       cifra.cusl cusl
                 where cusl.cusl_ucod = p_cuslid
                   and ct.ct_cusl_ucod = cusl.cusl_ucod
                   and tplan.tp_telid = ct.ct_ucod) tplan
         where (p_edate is null or tplan.tp_bdate <= p_edate)
           and (v_bdate is null or tplan.tp_edate is null or tplan.tp_edate >= v_bdate)
        order by tplan.tp_bdate, tplan.tp_id)
      loop
        i := NVL(v_tab_usl_tp.last, 0) + 1;
        v_tab_usl_tp(i).tp_bdate := rec.tp_bdate;
        v_tab_usl_tp(i).tp_edate := rec.tp_edate;
        v_tab_usl_tp(i).tp_cod := rec.tp_cod;
        if rec.tp_cod is not null then
          v_usl_tp_count_notnull := v_usl_tp_count_notnull + 1;
        end if;
      end loop;
      --
      if v_tab_usl_tp.count > 0 and v_usl_tp_count_notnull > 0 then
        if v_bdate is null or v_bdate < v_tab_usl_tp(v_tab_usl_tp.first).tp_bdate
        then -- добавить первый интервал
          v_datefirst := v_tab_usl_tp(v_tab_usl_tp.first).tp_bdate;
          i := 0;
          v_tab_usl_tp(i).tp_bdate := v_bdate;
          v_tab_usl_tp(i).tp_edate := v_datefirst;
          v_tab_usl_tp(i).tp_cod := null;
        end if;
        if p_edate is null and v_tab_usl_tp(v_tab_usl_tp.last).tp_edate is not null or
          p_edate is not null and v_tab_usl_tp(v_tab_usl_tp.last).tp_bdate is not null and
          p_edate > v_tab_usl_tp(v_tab_usl_tp.last).tp_bdate
        then -- добавить последний
          v_datelast := v_tab_usl_tp(v_tab_usl_tp.last).tp_bdate;
          i := NVL(v_tab_usl_tp.last, 0) + 1;
          v_tab_usl_tp(i).tp_bdate := v_datelast;
          v_tab_usl_tp(i).tp_edate := p_edate;
          v_tab_usl_tp(i).tp_cod := null;
        end if;
        -- В интервалы, в которых для услуги не назначен тарифный план, добавить тарифные планы абонента
        for rec in (
          select tplan.tp_date tp_bdate,
                 lead(tplan.tp_date) over (partition by tplan.tp_abid order by tplan.tp_date) tp_edate,
                 tplan.tp_cod
            from (select tplan.tp_id,
                         tplan.tp_abid,
                         tplan.tp_date,
                         tplan.tp_cod,
                         row_number() over (partition by tplan.tp_date, tplan.tp_cod order by tplan.tp_id desc) ord_
                    from cifra.tarplan tplan
                   where tplan.tp_abid = p_abid) tplan
          where tplan.ord_ = 1
          order by tplan.tp_date, tplan.tp_id)
        loop
          i := v_tab_usl_tp.first;
          while i is not null
          loop
            if v_tab_usl_tp(i).tp_cod is null then
              if (rec.tp_bdate < v_tab_usl_tp(i).tp_edate or v_tab_usl_tp(i).tp_edate is null) and
                (v_tab_usl_tp(i).tp_bdate is null or
                v_tab_usl_tp(i).tp_bdate is not null and rec.tp_edate > v_tab_usl_tp(i).tp_bdate)
              then
                j := NVL(v_tab_ab_tp.last, 0) + 1;
                v_tab_ab_tp(j).tp_bdate := rec.tp_bdate;
                v_tab_ab_tp(j).tp_edate := rec.tp_edate;
                v_tab_ab_tp(j).tp_cod := rec.tp_cod;
              end if;
            end if;
            i := v_tab_usl_tp.next(i);
          end loop;
        end loop;
        v_retval := v_tab_usl_tp.count + v_tab_ab_tp.count - 1;
      else -- количество изменений тарифных планов для абонента
        v_retval := rpt_p_$utils.get_ab_qty_change_tp(p_abid, p_bdate, p_edate);
      end if;
    exception
      when others then null;
    end;
    --
    return v_retval;
  end;
  --
  -- Процедура изменения параметра
  --
  procedure upd_param_value(p_param_id in varchar2, p_value in varchar2 , p_comment in varchar2) is
  begin  
    update rpt_parameters$ rp set rp.rppm_value = p_value, rp.rppm_text = nvl(p_comment,rp.rppm_text) where rp.rppm_id = p_param_id;
    commit;
  end;
  --
  -- Процедура добавления параметра
  --
  procedure ins_param_value(p_param_id in varchar2, p_value in varchar2 , p_comment in varchar2) is
  begin  
    insert into rpt_parameters$ (rppm_id, rppm_value, rppm_text) values(upper(p_param_id), p_value, p_comment);
    commit;
  end;
  --
  -- Функция, возвращающая перечень дат
  --
  function get_dates(p_start_date in date,
                     p_end_date in date) return t_date pipelined is
      -- Переменная для курсора
    v_curr_date  date;
  begin
    v_curr_date := trunc(p_start_date);
    loop
      pipe row (v_curr_date);
      v_curr_date := v_curr_date + 1;
      exit when (v_curr_date = trunc(p_end_date)+1);
    end loop;
    return; -- для конвеерной функции просто заканчиваем работу
  end;
  --
  -- Функция поиска контактного номера телефона абонента
  --
  function get_phone(p_account_id in number) return varchar2 is
    v_retval varchar2(256) := '';
  begin
    begin
      select 'Моб.: '||nvl(acf.mobiltelnum,'<Нет>')||' Дом.: '||nvl(acf.hometelnum,'<Нет>')||' Раб.: '||nvl(acf. worktelnum,'<Нет>')
        into v_retval
        from cifra.ao_abonent ab,
             cifra.ao_contragent_face acf 
       where ab.contragent_id = acf.contragent_id
         and ab.id = p_account_id; 
    exception
      when no_data_found then null;
      when too_many_rows then null;
    end;
    return v_retval;
  end;
  --
begin
  null;
end rpt_p_$utils;
/
