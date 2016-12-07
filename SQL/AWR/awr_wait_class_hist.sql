set ver off pages 50000 lines 1200 tab off
undef event_name
undef days_history
undef interval_hours
def days_history="&1"
def interval_hours="&2"
col time for a19
col EVENT_NAME for a40
col wait_count for 99999999999999
col wait_time_milli for 999999999999
col "'Administrative'" for 9999999999999999
col "'Application'" for 9999999999999999
col "'Cluster'" for 9999999999999999
col "'Commit'" for 9999999999999999
col "'Concurrency'" for 9999999999999999
col "'Configuration'" for 9999999999999999
col "'Idle'" for 9999999999999999
col "'Network'" for 9999999999999999
col "'Other'" for 9999999999999999
col "'Queueing'" for 9999999999999999
col "'Scheduler'" for 9999999999999999
col "'System I/O'" for 9999999999999999
col "'User I/O'" for 9999999999999999
select * from (
select to_char(time,'DD.MM.YYYY HH24:MI:SS') time, wait_class, sum(delta_time_waited)/1000000 wait_time_s from 
    (select hse.snap_id, 
      trunc(sysdate-&days_history+1)+trunc((cast(hs.begin_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24 time,
      EVENT_NAME,
      WAIT_CLASS,
      TIME_WAITED_MICRO-(lag(TIME_WAITED_MICRO,1) over(partition by hs.STARTUP_TIME, EVENT_NAME order by hse.snap_id)) delta_time_waited
   from DBA_HIST_SYSTEM_EVENT hse, DBA_HIST_SNAPSHOT hs
   where hse.snap_id=hs.snap_id
      and hs.begin_interval_time>=trunc(sysdate)-&days_history+1)
group by time, event_name, wait_class)
pivot 
(
 sum(wait_time_s) for wait_class in ('Administrative'
                                    ,'Application'
                                    ,'Cluster'
                                    ,'Commit'
                                    ,'Concurrency'
                                    ,'Configuration'
                                    ,'Network'
                                    ,'Other'
                                    ,'Queueing'
                                    ,'Scheduler'
                                    ,'System I/O'
                                    ,'User I/O')
                                    ,'Idle'
                                    )
order by 2, to_date(time,'DD.MM.YYYY HH24:MI:SS');
