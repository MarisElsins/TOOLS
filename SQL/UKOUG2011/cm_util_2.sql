-- UKOUG2011 - Concurrent Processing Performance Analysis for Apps DBAs
-- Author: Maris Elsins
-- Purpose: Reports average pending time for all requests of particular concurrent program during the reporting interval
-- Usage: cr_pend_time_2.sql <start reporting interval DDMMYYYY_HH24MISS> <end reporting interval DDMMYYYY_HH24MISS> <con prog application id> <con prog id> <stage id>

set pages 50000 lines 140 echo off feed off ver off tab off
alter session set nls_date_format='DDMMYYYY_HH24MISS';
col proc_cnt for 999999
col q_id for 99999
col conc_queue_name for a20
col proc_id for 9999999
col uptime_sec for 9999999999
col req_cnt for 9999999
col busy_sec for 99999999
col busy_pct for a8
col avg_delay for 999999999
col sleep_sec for 999999999

define from_DDMMYYYY_HH24MISS="&1"
define to_DDMMYYYY_HH24MISS="&2"
define conc_queue_id="&3"
define split_interval="&4"

with interv1 as (select * from (select int_start, lead(int_start/*-1/24/60/60*/) over (order by int_start) int_end from (
                select to_date('&from_DDMMYYYY_HH24MISS','DDMMYYYY_HH24MISS')+(rownum-1)/decode(upper('&split_interval'), 'DD',1,'HH24',1*24,'HH',1*24, 'MI', 1*24*60, 'SS', 1*24*60*60) int_start
                from dual connect by level <=999999)) where int_end<=to_date('&to_DDMMYYYY_HH24MISS','DDMMYYYY_HH24MISS')),
interv_proc as (select interv1.int_start, interv1.int_end, q.concurrent_queue_id,
                        q.concurrent_queue_name,
                        p.concurrent_process_id,
                        p.process_start_date,
                        decode(p.process_status_code,'A',to_date(null),p.last_update_date) process_stop_date,
                        trunc((least(interv1.int_end,decode(p.process_status_code,'A',sysdate,p.last_update_date))-
                                greatest(interv1.int_start,p.process_start_date))*24*60*60) uptime_sec
                  from fnd_concurrent_queues q,
                      fnd_concurrent_processes p,
                      interv1
                  where 1=1
                  and q.manager_type=1
                  and q.concurrent_queue_id=&conc_queue_id --bind 3
                  and p.concurrent_queue_id=q.concurrent_queue_id
                  and decode(p.process_status_code,'A',sysdate,p.last_update_date) >= interv1.int_start
                  and p.process_start_date <= interv1.int_end  --bind2 to date
                order by 1,2,3,4),
raw_data as (select interv.int_start,
                    interv.int_end, interv.concurrent_queue_id,
                        interv.concurrent_queue_name,
                        interv.concurrent_process_id,
                        interv.process_start_date,
                        interv.process_stop_date,
                        interv.uptime_sec,
                        r.request_id,
                        r.actual_start_date,
                        r.actual_completion_date,
                        trunc((least(interv.int_end,nvl(r.actual_completion_date,sysdate))-
                                greatest(interv.int_start,r.actual_start_date))*24*60*60)
                        -decode(p.concurrent_program_name,'FNDRSSUB',1,'FNDRSSTG',1,0)*(select trunc(least(interv.int_end-interv.int_start,nvl((max(least(interv.int_end,nvl(r.actual_completion_date,sysdate),nvl(r2.actual_completion_date,sysdate)))-
                                min(greatest(interv.int_start,r.actual_start_date,r2.actual_start_date))),0))*24*60*60) from fnd_concurrent_requests r2 where r2.parent_request_id=r.request_id
                                and nvl(r2.actual_completion_date,sysdate) >= interv.int_start
                                and r2.actual_start_date <=  interv.int_end
                                and nvl(r2.actual_completion_date,sysdate) >= r.actual_start_date
                                and r2.actual_start_date <=  nvl(r.actual_completion_date,sysdate))
                                req_exec_sec
                  from fnd_concurrent_requests r,
                      fnd_concurrent_programs p,
                      interv_proc interv
                  where 1=1
                  and p.application_id(+)=r.program_application_id
                  and p.concurrent_program_id(+)=r.concurrent_program_id
                  and r.controlling_manager(+)=interv.concurrent_process_id
                  --and r.phase_code(+) in ('C','R')
                  and r.phase_code(+)='C'
                  and nvl(r.actual_completion_date(+),sysdate) >= interv.int_start
                  and r.actual_start_date(+) <= interv.int_end
                order by 1,2,3,4),
sum_data as (select int_start, int_end, concurrent_queue_id,
                  concurrent_queue_name,
                  concurrent_process_id,
                  process_start_date,
                  process_stop_date,
                  uptime_sec,
                  nvl(count(request_id),0) req_cnt,
                  nvl(sum(req_exec_sec),0) req_exec_sec
            from raw_data
            group by int_start, int_end, concurrent_queue_id,
                  concurrent_queue_name,
                  concurrent_process_id,
                  process_start_date,
                  process_stop_date,
                  uptime_sec
          order by 1,2,3)
select int_start, int_end, concurrent_queue_id q_id,
       concurrent_queue_name,
       count(unique concurrent_process_id) proc_cnt,
       sum(uptime_sec) uptime_sec,
       sum(req_cnt) req_cnt,
       sum(req_exec_sec) busy_sec,
       --round((sum(req_exec_sec)/sum(uptime_sec))*100,2) busy_pct
       decode(sum(uptime_sec),0,null,round((sum(req_exec_sec)/sum(uptime_sec))*100,2)) busy_pct
from sum_data
group by  rollup((int_start, int_end)), concurrent_queue_id,
          concurrent_queue_name
order by 3 nulls last,1 nulls last;

undefine from_DDMMYYYY_HH24MISS
undefine to_DDMMYYYY_HH24MISS
undefine split_interval
undefine conc_queue_id