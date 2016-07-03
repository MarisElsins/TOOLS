-- Maris Elsins / Pythian / 2013
-- System Statistic trends from AWR
-- Usage: @awr_stat_trend.sql <name of the statistic> <number of days to report> <interval in hours>
-- i.e. @awr_stat_trend.sql "physical read bytes" 2 4
-- i.e. The example above summarizes the number of "physical read bytes" each 4 hours in last 2 days.
set ver off pages 50000 lines 140 tab off
undef stat_name
undef days_history
undef interval_hours
def stat_name="&1"
def days_history="&2"
def interval_hours="&3"
col time for a19
col stat_name for a64
col value_delta for 9999999999999999
select to_char(time,'DD.MM.YYYY HH24:MI:SS') time, stat_name,  sum(delta_value) value_delta from 
    (select hss.snap_id,
        trunc(sysdate-&days_history+1)+trunc((cast(hs.end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24 time,
        stat_name,
        value,
        value-(lag(value,1) over(partition by hs.startup_time, stat_name order by hss.snap_id)) delta_value
    from dba_hist_sysstat hss, dba_hist_snapshot hs
    where hss.snap_id=hs.snap_id 
        and hss.instance_number=hs.instance_number
        and hs.begin_interval_time>=trunc(sysdate)-&days_history+1
        and hss.stat_name like '&stat_name') 
group by time, stat_name
order by 2, 1;
