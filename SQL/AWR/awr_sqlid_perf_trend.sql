-- Maris Elsins / Pythian / 2013
-- SQL performance trends from AWR
-- Usage: @awr_sqlid_perf_trend.sql <sql_id> <number of days to report> <reporting interval in hours>
-- i.e. The example above summarizes the execution statistics for sql_id 46ah673phw02j in last 2 days breaking down the statistics by 4 hours. Statistics per execution are displayed. Additionally total execution time is shown too.
-- v1.0 - inital version
-- v1.1 - Adding instance_number to the outputs
-- v1.2 - Making it database-wide, as instance-wise breaks the readability
--      - Ading total elapsed time as the rest of stats are per-sql
--      - Introduced gaps for the time slots when the execution didn't happen at all
--
-- Example:
-- Show sql_id=54dtvn6dmmyh6 execution statistics for past 3 days with reporing intervals of 4 hours
-- SQL> @awr_sqlid_perf_trend.sql 54dtvn6dmmyh6 3 4
-- 
-- TIME                 EXECUTIONS ELAPSED_TIME_S_TOTAL ELAPSED_TIME_S_1EXEC CPU_TIME_S_1EXEC IOWAIT_S_1EXEC CLWAIT_S_1EXEC APWAIT_S_1EXEC CCWAIT_S_1EXEC ROWS_PROCESSED_1EXEC BUFFER_GETS_1EXEC  DISK_READS_1EXEC DIRECT_WRITES_1EXEC
-- ------------------- ----------- -------------------- -------------------- ---------------- -------------- -------------- -------------- -------------- -------------------- ----------------- ----------------- -------------------
-- 13.12.2014 00:00:00        1552                4.108                 .003             .001           .001           .001           .000           .000                1.000            23.399              .115                .000
-- 13.12.2014 04:00:00        1255                2.647                 .002             .001           .001           .001           .000           .000                1.000            23.602              .122                .000
-- 13.12.2014 08:00:00           0
-- 13.12.2014 12:00:00           0
-- 13.12.2014 16:00:00           0
-- 13.12.2014 20:00:00           0
-- 14.12.2014 00:00:00        1158                2.439                 .002             .001           .001           .001           .000           .000                1.000            23.312              .112                .000
-- 14.12.2014 04:00:00        1307                2.846                 .002             .001           .001           .001           .000           .000                1.000            23.660              .129                .000
-- 14.12.2014 08:00:00           0
-- 14.12.2014 12:00:00           0
-- 14.12.2014 16:00:00           0
-- 14.12.2014 20:00:00        2116            27871.109               13.172             .003           .001           .003           .000           .000                1.000           125.500              .169                .000
-- 15.12.2014 00:00:00           0
-- 15.12.2014 04:00:00        1032                2.506                 .002             .001           .001           .001           .000           .000                1.000            23.373              .127                .000
-- 15.12.2014 08:00:00        2298                4.652                 .002             .001           .001           .000           .000           .000                1.000            23.180              .137                .000
-- 
-- 15 rows selected.

set ver off pages 50000 lines 260 tab off
undef sql_id
undef days_history
undef interval_hours
def sql_id="&1"
def days_history="&2"
def interval_hours="&3"
col time for a19
col executions for 9999999999
col rows_processed_1exec for 9999999.999
col elapsed_time_s_total for 9999999.999
col elapsed_time_s_1exec for 9999999.999
col cpu_time_s_1exec for 9999999.999
col iowait_s_1exec for 9999999.999
col clwait_s_1exec for 9999999.999
col apwait_s_1exec for 9999999.999
col ccwait_s_1exec for 9999999.999
col plsexec_time_s_1exec for 9999999.999
col javexec_time_s_1exec for 9999999.999
col buffer_gets_1exec for 999999999999.999
col disk_reads_1exec for 999999999999.999
col direct_writes_1exec for 999999999999.999
select to_char(trunc(sysdate-&days_history+1)+trunc((cast(hs.begin_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24,'dd.mm.yyyy hh24:mi:ss') time,
    nvl(sum(hss.executions_delta),0) executions,
    round(sum(hss.elapsed_time_delta)/1000000,3) elapsed_time_s_total,
    round(sum(hss.elapsed_time_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) elapsed_time_s_1exec,
    round(sum(hss.cpu_time_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) cpu_time_s_1exec,
    round(sum(hss.iowait_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) iowait_s_1exec,
    round(sum(hss.clwait_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) clwait_s_1exec,
    round(sum(hss.apwait_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) apwait_s_1exec,
    round(sum(hss.ccwait_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) ccwait_s_1exec,
    round(sum(hss.rows_processed_delta)/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) rows_processed_1exec,
    round(sum(hss.buffer_gets_delta)/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) buffer_gets_1exec,
    round(sum(hss.disk_reads_delta)/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) disk_reads_1exec,
    round(sum(hss.direct_writes_delta)/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) direct_writes_1exec
from dba_hist_sqlstat hss, (select snap_id, min(hs2.begin_interval_time) begin_interval_time from dba_hist_snapshot hs2 group by snap_id) hs
where hss.sql_id(+)='&sql_id'
and hss.snap_id(+)=hs.snap_id
and hs.begin_interval_time>=trunc(sysdate)-&days_history+1
group by trunc(sysdate-&days_history+1)+trunc((cast(hs.begin_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24
order by trunc(sysdate-&days_history+1)+trunc((cast(hs.begin_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24;
