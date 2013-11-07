-- Maris Elsins / Pythian / 2013
-- System Statistic trends from AWR
-- Usage: @awr_stat_trend.sql <name of the statistic> <number of days to report> <interval in hours>
-- i.e. @awr_stat_trend.sql "physical read bytes" 2 4
-- i.e. The example above summarizes the number of "physical read bytes" each 4 hours in last 2 days.
-- v1.0 - inital version
-- v1.1 - Adding instance_number to the outputs
set ver off pages 50000 lines 140 tab off
undef stat_name
undef days_history
undef interval_hours
def stat_name="&1"
def days_history="&2"
def interval_hours="&3"
col inst for 9999
col time for a19
col stat_name for a64
col value for 9999999999999999
BREAK ON inst SKIP 1
select instance_number inst, to_char(time,'DD.MM.YYYY HH24:MI:SS') time, stat_name,  sum(delta_value) value from 
    (select hss.instance_number, hss.snap_id,
        trunc(sysdate-&days_history+1)+trunc((cast(hs.begin_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24 time,
        stat_name,
        value,
        (lead(value,1) over(partition by hss.instance_number, hs.startup_time, stat_name order by hss.snap_id))-value delta_value
    from DBA_HIST_SYSSTAT hss, dba_hist_snapshot hs
    where hss.snap_id=hs.snap_id 
        and hs.begin_interval_time>=trunc(sysdate)-&days_history+1
        and hss.stat_name like '&stat_name') a
group by instance_number, time, stat_name
order by 1, 3, a.time;
