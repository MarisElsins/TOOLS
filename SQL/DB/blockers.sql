-- Author:             Maris Elsins (elmaris@gmail.com), 2016
-- Copyright:          (c) Maris Elsins - https://me-dba.com - All rights reserved.
-- Note:               The script displays the blockers' tree and lets quickly identify the root blocker 
with sessions as (select /* materialize */ * from gv$session)
select lpad('#',lvl-1,'#')||to_char(lvl) lvl, inst_id,
      sid, serial#, 'alter system disconnect session '''||sid||','||serial#||''' immediate;' kill_stm,
      status, seconds_in_wait, state, audsid, lockwait,
       module, action, client_info, client_identifier,
       program, osuser, process, machine, terminal,
       type, sql_id, sql_child_number,
       row_wait_obj#, row_wait_file#, row_wait_block#, row_wait_row#,
       logon_time, last_call_et, event, p1, p2, p3,
       blocking_session_status, blocking_instance, blocking_session, wait_time
from (select level lvl, rownum rn, s.* from sessions s
      connect by prior s.sid = s.blocking_session and prior s.inst_id = s.blocking_instance
      start with s.blocking_session IS NULL)
where lvl>1 or (inst_id, sid) in (select blocking_instance, blocking_session from sessions g where g.blocking_session is not null)
order by rn;
