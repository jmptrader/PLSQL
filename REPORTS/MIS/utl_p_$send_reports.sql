create or replace package utl_p_$send_reports is
/*
  Author  : V.ERIN
  Created : 05.04.2015 12:00:00
  Purpose : ������� ��� ��������� ���������� �������
  Version : 1.1.00
  HISTORY
  User    : Date         : Description
  -------------------------------------------------------------------------------------------------
  V.ERIN    17/10/2014     �������� ������
  -------------------------------------------------------------------------------------------------
*/
  --
  -- ���������� ���� ������
  --
  -- ��������� ������� 
  type text_table_t is table of varchar2(2000); 
  --
  -- ������� ��������� ������ ������ �� ����������� SQL
  --
  function make_report_data(p_rep_sql     in varchar2,
                            p_report_data in out text_table_t,
                            p_divider     in char
                            )return integer;
  --
end utl_p_$send_reports;
/
create or replace package body utl_p_$send_reports is
  --
  -- ������� ��������� ������ ������ �� ����������� SQL
  --
  function make_report_data(p_rep_sql     in varchar2,
                            p_report_data in out text_table_t,
                            p_divider     in char
                            )return integer is
    -- ������������ ��������
    v_retval        integer := 0;
    -- ����� ��� ������ ������
    v_report_buf    varchar2(2000);
    -- ��������� ������
    v_report_header varchar2(2000) := '';
    -- ������
    cur integer;
    -- ������� ������
    colnum      integer;
    v_desc_t    dbms_sql.desc_tab;
    v_colval    varchar2(256);
    v_exec      integer;
  begin
    begin
       -- ��������� ������ ���������� ��� � SQL ������
       cur := dbms_sql.open_cursor;
       dbms_sql.parse(cur, p_rep_sql, dbms_sql.native);
       -- ��������������� ��������� ������
       dbms_sql.describe_columns(cur, colnum, v_desc_t);
       for i in 1..colnum loop
         if v_report_header is not null then
            v_report_header := v_report_header||p_divider;
         end if;
         v_report_header := v_report_header||v_desc_t(i).col_name;
         dbms_sql.define_column(cur, i, v_colval, 256);
       end loop;
       p_report_data.extend;
       p_report_data(p_report_data.last) := v_report_header || utl_tcp.crlf;
       -- ��������� SQL
       v_exec := dbms_sql.execute(cur);
       -- ��������������� ���� ������
       loop
         -- �������� ������ � �����
         if  dbms_sql.fetch_rows(cur) > 0 then
           v_report_buf := '';
           for i in 1..colnum loop
             if v_report_buf is not null then
                v_report_buf := v_report_buf||p_divider;
             end if;
             dbms_sql.column_value(cur, i, v_colval);
             v_report_buf := v_report_buf||v_colval;
           end loop;
           p_report_data.extend;
           p_report_data(p_report_data.last) := v_report_buf || utl_tcp.crlf;
         else
           exit;
         end if;
       end loop;
    exception
       when others then v_retval := sqlcode;
    end;
    if dbms_sql.is_open(cur) then
      dbms_sql.close_cursor(cur);
    end if;
    return v_retval;
  end;
  --
begin
  null;
end utl_p_$send_reports;
/
