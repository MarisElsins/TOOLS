set ver off pages 50000 lines 260 tab off echo off
undef sql_id
def sql_id="&3"
undef snap_id_from
undef snap_id_to
def snap_id_from="&1"
def snap_id_to="&2"
col inst for 9999
col time for a19
col executions for 9999999999
col rows_processed_1e for 999999999999.999
col elapsed_time_s_1e for 9999999.999
col cpu_time_s_1e for 9999999.999
col iowait_s_1e for 9999999.999
col clwait_s_1e for 9999999.999
col apwait_s_1e for 9999999.999
col ccwait_s_1e for 9999999.999
col plsexec_time_s_1e for 9999999.999
col javexec_time_s_1e for 9999999.999
col buffer_gets_1e for 9999999999999.999
col disk_reads_1e for 9999999999999.999
col direct_writes_1e for 9999999999999.999

select 
    to_char(cast(hs.begin_interval_time as date),'dd.mm.yyyy hh24:mi:ss') time,
    plan_hash_value,
    sum(hss.executions_delta) executions,
    round(sum(hss.elapsed_time_delta)/1000000/nvl(sum(hss.executions_delta),1),3) elapsed_time_s_1e,
    round(sum(hss.cpu_time_delta)/1000000/nvl(sum(hss.executions_delta),1),3) cpu_time_s_1e,
    round(sum(hss.iowait_delta)/1000000/nvl(sum(hss.executions_delta),1),3) iowait_s_1e,
--    round(sum(hss.clwait_delta)/1000000/nvl(sum(hss.executions_delta),1),3) clwait_s_1e,
--    round(sum(hss.apwait_delta)/1000000/nvl(sum(hss.executions_delta),1),3) apwait_s_1e,
--    round(sum(hss.ccwait_delta)/1000000/nvl(sum(hss.executions_delta),1),3) ccwait_s_1e,
    round(sum(hss.rows_processed_delta)/nvl(sum(hss.executions_delta),1),3) rows_processed_1e,
    round(sum(hss.buffer_gets_delta)/nvl(sum(hss.executions_delta),1),3) buffer_gets_1e,
    round(sum(hss.disk_reads_delta)/nvl(sum(hss.executions_delta),1),3) disk_reads_1e,
    round(sum(hss.direct_writes_delta)/nvl(sum(hss.executions_delta),1),3) direct_writes_1e
from dba_hist_sqlstat hss, dba_hist_snapshot hs
where hss.sql_id='&sql_id'
    and hss.snap_id=hs.snap_id
    and hs.snap_id between &snap_id_from and &snap_id_to
group by to_char(cast(hs.begin_interval_time as date),'dd.mm.yyyy hh24:mi:ss'), plan_hash_value, cast(hs.begin_interval_time as date)
order by cast(hs.begin_interval_time as date), 4 desc;
