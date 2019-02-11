-- Maris Elsins / Pythian / 2013
-- SQL performance trends from AWR
-- Usage: @awr_sqlid_perf_trend.sql <sql_id> <number of days to report> <reporting interval in hours> [<I - for instance breakdown>]
-- i.e. The example above summarizes the execution statistics for sql_id 46ah673phw02j in last 2 days breaking down the statistics by 4 hours. Statistics per execution are displayed. Additionally total execution time is shown too.
-- v1.0 - inital version
-- v1.1 - Adding instance_number to the outputs
-- v1.2 - Making it database-wide, as instance-wise breaks the readability
--      - Ading total elapsed time as the rest of stats are per-sql
--      - Introduced gaps for the time slots when the execution didn't happen at all
-- v1.3 - Change of the date format to ISO 8601
-- v1.4 - Optional instance breakdown when "I" parameter is passed
--
-- Example:
-- Show sql_id=2v9tgrfymr06q execution statistics for past 24 days with reporing intervals of 72 hours globally
-- SQL> @awr_sqlid_perf_trend.sql 2v9tgrfymr06q 24 72
-- 
-- TIME                 EXECUTIONS ELAPSED_TIME_S_TOTAL ELAPSED_TIME_S_1EXEC CPU_TIME_S_1EXEC IOWAIT_S_1EXEC CLWAIT_S_1EXEC APWAIT_S_1EXEC CCWAIT_S_1EXEC ROWS_PROCESSED_1EXEC BUFFER_GETS_1EXEC  DISK_READS_1EXEC DIRECT_WRITES_1EXEC
-- ------------------- ----------- -------------------- -------------------- ---------------- -------------- -------------- -------------- -------------- -------------------- ----------------- ----------------- -------------------
-- 2019-01-19 00:00:00     2900376           125534.430                 .043             .043           .000           .000           .000           .000                 .998          5591.842              .000                .000
-- 2019-01-22 00:00:00     2900359           125828.246                 .043             .043           .000           .000           .000           .000                 .998          5590.366              .000                .000
-- 2019-01-25 00:00:00     2872194           124606.857                 .043             .043           .000           .000           .000           .000                 .998          5588.041              .000                .000
-- 2019-01-28 00:00:00     2685476           118097.106                 .044             .044           .000           .000           .000           .000                 .998          5652.032              .001                .000
-- 2019-01-31 00:00:00     2900428           128101.221                 .044             .044           .000           .000           .000           .000                 .998          5589.829              .000                .000
-- 2019-02-03 00:00:00     2899759           128250.831                 .044             .044           .000           .000           .000           .000                 .998          5589.462              .000                .000
-- 2019-02-06 00:00:00     2899782           128215.744                 .044             .044           .000           .000           .000           .000                 .998          5588.555              .000                .000
-- 2019-02-09 00:00:00     2215201            97792.781                 .044             .044           .000           .000           .000           .000                 .998          5595.474              .000                .000
--
-- Show sql_id=2v9tgrfymr06q execution statistics for past 24 days with reporing intervals of 72 hours with an instance breakdown
-- SQL> @awr_sqlid_perf_trend.sql 2v9tgrfymr06q 24 72 i
-- 
--  INST TIME                 EXECUTIONS ELAPSED_TIME_S_TOTAL ELAPSED_TIME_S_1EXEC CPU_TIME_S_1EXEC IOWAIT_S_1EXEC CLWAIT_S_1EXEC APWAIT_S_1EXEC CCWAIT_S_1EXEC ROWS_PROCESSED_1EXEC BUFFER_GETS_1EXEC  DISK_READS_1EXEC DIRECT_WRITES_1EXEC
-- ----- ------------------- ----------- -------------------- -------------------- ---------------- -------------- -------------- -------------- -------------- -------------------- ----------------- ----------------- -------------------
--     1 2019-01-19 00:00:00           0
--       2019-01-22 00:00:00           0
--       2019-01-25 00:00:00           0
--       2019-01-28 00:00:00           0
--       2019-01-31 00:00:00           0
--       2019-02-03 00:00:00           0
--       2019-02-06 00:00:00           0
--       2019-02-09 00:00:00           0
-- 
--     2 2019-01-19 00:00:00           0
--       2019-01-22 00:00:00           0
--       2019-01-25 00:00:00           0
--       2019-01-28 00:00:00       10203              449.320                 .044             .044           .000           .000           .000           .000                 .998          5897.371              .221                .000
--       2019-01-31 00:00:00           0
--       2019-02-03 00:00:00           0
--       2019-02-06 00:00:00           0
--       2019-02-09 00:00:00           0
-- 
--     3 2019-01-19 00:00:00     2900376           125534.430                 .043             .043           .000           .000           .000           .000                 .998          5591.842              .000                .000
--       2019-01-22 00:00:00     2900359           125828.246                 .043             .043           .000           .000           .000           .000                 .998          5590.366              .000                .000
--       2019-01-25 00:00:00     2872194           124606.857                 .043             .043           .000           .000           .000           .000                 .998          5588.041              .000                .000
--       2019-01-28 00:00:00     2675273           117647.786                 .044             .044           .000           .000           .000           .000                 .998          5651.096              .000                .000
--       2019-01-31 00:00:00     2900428           128101.221                 .044             .044           .000           .000           .000           .000                 .998          5589.829              .000                .000
--       2019-02-03 00:00:00     2899759           128250.831                 .044             .044           .000           .000           .000           .000                 .998          5589.462              .000                .000
--       2019-02-06 00:00:00     2899782           128215.744                 .044             .044           .000           .000           .000           .000                 .998          5588.555              .000                .000
--       2019-02-09 00:00:00     2215201            97792.781                 .044             .044           .000           .000           .000           .000                 .998          5595.474              .000                .000
-- 
--     4 2019-01-19 00:00:00           0
--       2019-01-22 00:00:00           0
--       2019-01-25 00:00:00           0
--       2019-01-28 00:00:00           0
--       2019-01-31 00:00:00           0
--       2019-02-03 00:00:00           0
--       2019-02-06 00:00:00           0
--       2019-02-09 00:00:00           0

set ver off pages 50000 lines 270 tab off termout off

COLUMN 4 NEW_VALUE 4
select '' "4" from dual where rownum=0;

undef sql_id
undef days_history
undef interval_hours
undef grby_inst
def sql_id="&1"
def days_history="&2"
def interval_hours="&3"
def grby_inst="&4"
col time for a19
col inst for 9999
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
BREAK ON inst SKIP 1

define _IF_NOT_INST="--"
DEF noprint="noprint"

col show_inst &noprint new_value _IF_NOT_INST
select case when upper('&grby_inst')='I' then '' else '--' end show_inst from dual;

set termout on

               select
&_IF_NOT_INST      hs.instance_number inst,
                   to_char(trunc(sysdate-&days_history+1)+trunc((cast(hs.begin_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24,'yyyy-mm-dd hh24:mi:ss') time,
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
               from dba_hist_sqlstat hss, (select 
&_IF_NOT_INST                                instance_number, 
                                             snap_id, min(hs2.begin_interval_time) begin_interval_time from dba_hist_snapshot hs2 
                                           group by 
&_IF_NOT_INST                                instance_number, 
                                             snap_id) hs
               where hss.sql_id(+)='&sql_id'
               and hss.snap_id(+)=hs.snap_id
&_IF_NOT_INST  and hss.instance_number(+)=hs.instance_number
               and hs.begin_interval_time>=trunc(sysdate)-&days_history+1
               group by
&_IF_NOT_INST       hs.instance_number,
                    trunc(sysdate-&days_history+1)+trunc((cast(hs.begin_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24
               order by
&_IF_NOT_INST       hs.instance_number,
                    trunc(sysdate-&days_history+1)+trunc((cast(hs.begin_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24;


undef 1
undef 2
undef 3
undef 4

