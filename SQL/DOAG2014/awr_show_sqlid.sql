set ver off pages 50000 lines 32000 tab off long 9999999 timing off echo off
col PROGRAM for a30
col MODULE for a30
col ACTION for a30
col CLIENT_ID for a30
col MACHINE for a30
undef sql_id
def sql_id="&1"

prompt ### Occurrences in ASH (DBA_HIST_ACTIVE_SESS_HISTORY):
select sql_id, program, module, action, client_id, count(*) from dba_hist_active_sess_history  where sql_id='&sql_id' group by sql_id, program, module, action, client_id order by count(*) desc;

set pages 0
col sql_text for a32000

prompt ### The Statement (DBA_HIST_SQLTEXT):
select sql_text from dba_hist_sqltext where sql_id='&sql_Id' and rownum=1;

set lines 238

