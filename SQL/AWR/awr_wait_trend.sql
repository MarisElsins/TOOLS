-- Maris Elsins / Pythian / 2013
-- Wait event trends from AWR
-- Usage: @awr_wait_trend.sql <name of the wait event> <number of days to report> <interval in hours>
-- i.e. @awr_wait_trend.sql "db file sequential read" 2 4
-- i.e. The example above summarizes the number of "db file sequential read" each 4 hours in last 2 days.
-- v1.0 - inital version
-- v1.1 - Adding instance_number to the outputs
set ver off pages 50000 lines 140 tab off
undef event_name
undef days_history
undef interval_hours
def event_name="&1"
def days_history="&2"
def interval_hours="&3"
col inst for 9
col time for a19
col EVENT_NAME for a64
col total_waits for 99999999999999
col total_time_s for 999999999.999
col avg_time_ms for 999999999.999
BREAK ON inst SKIP 1
select instance_number inst, to_char(time,'DD.MM.YYYY HH24:MI:SS') time, event_name,  sum(delta_total_waits) total_waits, round(sum(delta_time_waited/1000000),3) total_time_s, round(sum(delta_time_waited)/decode(sum(delta_total_waits),0,null,sum(delta_total_waits))/1000,3) avg_time_ms from 
    (select hse.instance_number, hse.snap_id, 
      trunc(sysdate-&days_history+1)+trunc((cast(hs.end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24 time,
      EVENT_NAME,
      (lead(TOTAL_WAITS,1) over(partition by hse.instance_number, hs.STARTUP_TIME, EVENT_NAME order by hse.snap_id))-TOTAL_WAITS delta_total_waits,
      (lead(TIME_WAITED_MICRO,1) over(partition by hse.instance_number, hs.STARTUP_TIME, EVENT_NAME order by hse.snap_id))-TIME_WAITED_MICRO delta_time_waited
   from DBA_HIST_SYSTEM_EVENT hse, DBA_HIST_SNAPSHOT hs
   where hse.snap_id=hs.snap_id
      and hs.begin_interval_time>=trunc(sysdate)-&days_history+1
      and hse.EVENT_NAME like '&event_name') a
group by instance_number, time, event_name
order by 1, 3, a.time;
