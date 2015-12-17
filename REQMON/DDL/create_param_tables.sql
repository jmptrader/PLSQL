--drop table req_parameters$;

create table req_parameters$
(
  rqpm_id        varchar2(50)   primary key,
  rqpm_value     varchar2(256)  not null,
  rqpm_text      varchar2(2000) not null
);

-- Add/modify columns 
alter table req_parameters$ add rqpm_data blob;

insert into req_parameters$ values ('IS_STOPED','0','Флаг аварийной остановки монитора обработки балансов.',null); 
insert into req_parameters$ values ('BAL_THRESHOLD','50','Порог информирования о балансе (Сообщения создаются если баланс меньше этого значения).',null); 
--
insert into req_parameters$ values ('RQTM_PAY_DFLT','11','Cообщение о платеже',null);
insert into req_parameters$ values ('RQTM_PAY_STND','12','Состояние услуг не изменились',null);
insert into req_parameters$ values ('RQTM_PAY_DNSRV','13','Средств платежа не достаточно для включения услуг',null);
insert into req_parameters$ values ('RQTM_PAY_UPSRV','14','Средств платежа достаточно для включения услуг',null);
-- Баланс
insert into req_parameters$ values ('RQTM_BAL_ZERO','15','Cообщение о нулевом балансе',null);
insert into req_parameters$ values ('RQTM_BAL_DNSRV','16','Cообщение об отрицательном балансе',null);
insert into req_parameters$ values ('RQTM_BAL_REMIND','17','Cообщение о приближении к 0',null);
-- Услуга
insert into req_parameters$ values ('RQTM_SERV_UPSRV','20','Cообщение о подключении услуг',null);
insert into req_parameters$ values ('RQTM_SERV_DNSRV','21','Cообщение об отключении услуг',null);
--
insert into req_parameters$ values ('IPTV_SERV_ID_1','69','ID услуги IPTV',null);
-- Обработчик
insert into req_parameters$ values ('STEP',5,'Шаг запуска обычных заданий на сканирование',null);
insert into req_parameters$ values ('REQ_JOB_MAX',3,'Количество обычных заданий обработки заявок',null);
insert into req_parameters$ values ('REQ_HIJOB_MAX',2,'Количество заданий для обработки заявок высокого приоритета',null);
-- Настройки
--insert into req_parameters$ values ('SMTP_SERVER','212.34.32.22','Адрес SMTP сервера',null);
--insert into req_parameters$ values ('SMTP_PORT','25','Порт SMTP сервера',null);
--insert into req_parameters$ values ('SMTP_USER','informer@cifra1.ru','Пользователь SMTP сервера',null);
--insert into req_parameters$ values ('SMTP_PASSWORD','erin_1970','Пароль SMTP сервера',null);
--insert into req_parameters$ values ('SMSC_URL','gate.mobilmoney.ru','Адрес портала для отправки SMS',null);
-- Шрифты для PDF
insert into req_parameters$ values ('PDF_FONT_ARIAL','FONT','Шрифт для загрузки в PDF документ',null);

