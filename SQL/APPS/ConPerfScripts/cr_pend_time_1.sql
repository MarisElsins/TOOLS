-- UKOUG2011 - Concurrent Processing Performance Analysis for Apps DBAs
-- Author: Maris Elsins
-- Purpose: Reports average pending time for each concurrent program during the reporting interval
-- Usage: cr_pend_time_1.sql <start reporting interval DDMMYYYY_HH24MISS> <end reporting interval DDMMYYYY_HH24MISS>

set pages 50000 lines 140 echo off ver off
col AP_ID for 99999
col pr_id for 99999
col sg_id for a15
col program for a60
col req_cnt for 99999999
col pend_tot for 99999999
col pend_crm for 99999999
col pend_cm for 99999999
col exe_time for 99999999
define from_DDMMYYYY_HH24MISS="&1"
define to_DDMMYYYY_HH24MISS="&2"

with interv1 as (select to_date('&from_DDMMYYYY_HH24MISS','DDMMYYYY_HH24MISS') int_start, to_date('&to_DDMMYYYY_HH24MISS','DDMMYYYY_HH24MISS') int_end from dual)
select  ap_id,
        pr_id,
        sg_id,
        program,
        count(*) req_cnt,
        trunc(avg(pending_total)) pend_tot,
        trunc(avg(pending_crm)) pend_crm,
        trunc(avg(pending_total-pending_crm)) pend_cm,
        trunc(avg(execution_time)) exe_time
from (select r.program_application_id  ap_id,
             r.concurrent_program_id pr_id,
             decode(pr.concurrent_program_name,'FNDRSSUB',r.argument1||'-'||r.argument2,'FNDRSSTG', r.argument1||'-'||r.argument2||'-'||r.argument3, '""') sg_id,
             decode(pr.concurrent_program_name,'FNDRSSUB',p.user_concurrent_program_name||' ('||r.description||')','FNDRSSTG',(select 'Report Set ('||user_request_set_name||') Stage' from fnd_request_sets_tl st where st.application_id=r.argument1 and st.request_set_id=r.argument2 and language='US')||' ('||r.description||')',p.user_concurrent_program_name) program,
             greatest(request_date, requested_start_date) requested_start_date,
             round((actual_start_date-greatest(request_date, requested_start_date))*24*60*60) pending_total,
             round(nvl((crm_release_date-greatest(request_date, requested_start_date))*24*60*60,0)) pending_crm,
             round((actual_completion_date-actual_start_date)*24*60*60) execution_time
      from fnd_concurrent_requests r, fnd_concurrent_programs pr, fnd_concurrent_programs_tl p, interv1, fnd_concurrent_processes cpr, fnd_concurrent_queues q
      where phase_code='C'
            and greatest(request_date, requested_start_date) >= interv1.int_start  --BIND1
            and greatest(request_date, requested_start_date) <= interv1.int_end  --BIND2
            and pr.application_id=r.program_application_id
            and pr.concurrent_program_id=r.concurrent_program_id
            and p.application_id=r.program_application_id
            and p.concurrent_program_id=r.concurrent_program_id
            and cpr.concurrent_process_id=r.controlling_manager
            and q.concurrent_queue_id=cpr.concurrent_queue_id
            and q.application_id=cpr.queue_application_id
            and q.manager_type=1
            and p.language='US')
group by ap_id, pr_id, sg_id, program
order by pend_tot asc;

undefine from_DDMMYYYY_HH24MISS
undefine to_DDMMYYYY_HH24MISS
