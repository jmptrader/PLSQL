-- Create table
create table LT_M2_ADDRESSES$
(
  lotus_code VARCHAR2(256),
  m2000_code VARCHAR2(256) not null
)
tablespace USERS
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate primary, unique and foreign key constraints 
alter table LT_M2_ADDRESSES$
  add constraint LT_M2_PK primary key (M2000_CODE)
  using index 
  tablespace USERS
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
alter table LT_M2_ADDRESSES$
  add constraint LT_M2_UK unique (LOTUS_CODE)
  using index 
  tablespace USERS
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
-- Grant/Revoke object privileges 
grant select, insert, delete on LT_M2_ADDRESSES$ to LOTUS_WRITE;
