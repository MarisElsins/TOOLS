-- UKOUG2011 - Concurrent Processing Performance Analysis for Apps DBAs
-- Author: Maris Elsins
-- Purpose: Reports average pending time for all requests of particular concurrent program during the reporting interval
-- Usage: cr_pend_time_2.sql <start reporting interval DDMMYYYY_HH24MISS> <end reporting interval DDMMYYYY_HH24MISS> <con prog application id> <con prog id> <stage id>

set pages 50000 lines 160 echo off feed off ver off
alter session set nls_date_format='DDMMYYYY_HH24MISS';
col proc_cnt for 999999
col q_id for 99999
col conc_queue_name for a20
col proc_id for 9999999
col uptime_sec for 9999999999
col req_cnt for 9999999
col busy_sec for 99999999
col busy_pct for 999.00
col avg_delay for 999999999
col sleep_sec for 999999999
col program for a79

define from_DDMMYYYY_HH24MISS="&1"
define to_DDMMYYYY_HH24MISS="&2"
define conc_queue_id="&3"

prompt
prompt The following table reports concurrent requests that ran during interval &from_DDMMYYYY_HH24MISS and &to_DDMMYYYY_HH24MISS on manager &conc_queue_id

with interv1 as (select to_date('&from_DDMMYYYY_HH24MISS','DDMMYYYY_HH24MISS') int_start, to_date('&to_DDMMYYYY_HH24MISS','DDMMYYYY_HH24MISS') int_end from dual),
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
                order by 1,2,3,4)
select                  interv.concurrent_queue_id q_id,
                        interv.concurrent_queue_name conc_queue_name,
                        interv.concurrent_process_id proc_id,
                        r.request_id,
                        r.actual_start_date req_start,
                        r.actual_completion_date req_stop,
                        decode(p.concurrent_program_name,'FNDRSSUB',pt.user_concurrent_program_name||' ('||r.description||')','FNDRSSTG',(select 'Report Set ('||user_request_set_name||') Stage' from fnd_request_sets_tl st where st.application_id=r.argument1 and st.request_set_id=r.argument2 and language='US')||' ('||r.description||')',pt.user_concurrent_program_name) program
                  from fnd_concurrent_requests r,
                      fnd_concurrent_programs p,
                      fnd_concurrent_programs_tl pt,
                      interv_proc interv
                  where 1=1
                  and p.application_id(+)=r.program_application_id
                  and p.concurrent_program_id(+)=r.concurrent_program_id
                  and pt.application_id(+)=r.program_application_id
                  and pt.concurrent_program_id(+)=r.concurrent_program_id
                  and pt.language='US'
                  and r.controlling_manager(+)=interv.concurrent_process_id
                  --and r.phase_code(+) in ('C','R')
                  and r.phase_code(+)='C'
                  and nvl(r.actual_completion_date(+),sysdate) >= interv.int_start
                  and r.actual_start_date(+) <= interv.int_end
                order by r.actual_start_date;

undefine from_DDMMYYYY_HH24MISS
undefine to_DDMMYYYY_HH24MISS
undefine split_interval
undefine conc_queue_id