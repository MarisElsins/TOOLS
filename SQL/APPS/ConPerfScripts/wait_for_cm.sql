-- UKOUG2011 - Concurrent Processing Performance Analysis for Apps DBAs
-- Author: Maris Elsins
-- Purpose: the query reports the the concurrent manager activity for managers that could have executed the given request
-- WARNING: the query is based on current specialization rules, so It might not be 100% accurate for requests that have completed already if the rulas have been changed.
-- Usage: wait_for_cm.sql <request id>

set pages 50000 lines 140 echo off feed off ver off
alter session set nls_date_format='DDMMYYYY_HH24MISS';
col conc_queue_name for a20
col conc_proc_id for 9999999
col uptime_sec for 999999
col req_cnt for 9999999
col busy_sec for 99999999
col busy_pct for 99999999
col avg_delay for 999999999
col sleep_sec for 999999999

define req_id="&1"

Prompt This reports manager activity during time when request &req_id was waiting for a free concurrent manager.
Prompt &req_id was waiting for a free manager during this time interval:
select r.request_id,
       nvl(crm_release_date,requested_start_date) released_by_crm,
       actual_start_date actual_start_date
 from fnd_concurrent_requests r where request_id=&req_id;

Prompt
Prompt
Prompt Summary of concurrent manager process activity, only managers that could have executed request &req_id are listed
with req as (select r.request_id,
                    r.requested_by,
                    r.oracle_id,
                    r.concurrent_request_class_id,
                    r.request_class_application_id,
                    r.concurrent_program_id,
                    r.program_application_id,
                    greatest(request_date, requested_start_date) req_start_date,
                    nvl(crm_release_date,requested_start_date) pending_crm_till,
                    actual_start_date pending_till
 from fnd_concurrent_requests r where request_id=&req_id),
in_rules as (  select q.concurrent_queue_id, q.concurrent_queue_name, q.sleep_seconds,
                        nvl(qci.include_flag,'I') include_flag,
                        nvl(qci.type_code,'P') type_code,
                        decode(qci.type_code, 'P', qci.type_application_id, null) program_application_id,
                        decode(qci.type_code, 'P', qci.type_id, null) concurrent_program_id,
                        decode(qci.type_code, 'R', qci.type_application_id, null) request_class_application_id,
                        decode(qci.type_code, 'R', qci.type_id, null) concurrent_request_class_id,
                        decode(qci.type_code, 'O', qci.type_id, null) oracle_id,
                        decode(qci.type_code, 'U', qci.type_id, null) user_id,
                        'S' queue_method_flag_not
                  from fnd_concurrent_queues q,
                      fnd_concurrent_queue_content qci
                  where 1=1
                  and q.manager_type=1
                  and qci.queue_application_id(+)=q.application_id
                  and qci.concurrent_queue_id(+)=q.concurrent_queue_id
                  and qci.type_code(+)!='C'
                  and qci.include_flag(+)='I'
                  union all 
                  select q.concurrent_queue_id, q.concurrent_queue_name, q.sleep_seconds,
                        'I' include_flag,
                        'P' type_code,
                        qpcp.program_application_id,
                        qpcp.concurrent_program_id,
                        null request_class_application_id,
                        null concurrent_request_class_id,
                        null oracle_id,
                        null user_id,
                        'DUMMY' queue_method_flag_not
                  from fnd_concurrent_queues q,
                       FND_CONC_PROCESSOR_PROGRAMS qpcp
                  where 1=1
                  and q.manager_type=1
                  and qpcp.processor_application_id=q.processor_application_id
                  and qpcp.concurrent_processor_id=q.concurrent_processor_id
                  union all
                  select q.concurrent_queue_id, q.concurrent_queue_name, q.sleep_seconds,
                        decode(qci.include_flag,ccli.include_flag,'I','E') include_flag,
                        ccli.type_code,
                        decode(ccli.type_code, 'P', ccli.type_application_id, null) program_application_id,
                        decode(ccli.type_code, 'P', ccli.type_id, null) concurrent_program_id,
                        decode(ccli.type_code, 'R', ccli.type_application_id, null) request_class_application_id,
                        decode(ccli.type_code, 'R', ccli.type_id, null) concurrent_request_class_id,
                        decode(ccli.type_code, 'O', ccli.type_id, null) oracle_id,
                        decode(ccli.type_code, 'U', ccli.type_id, null) user_id,
                        'S' queue_method_flag_not
                  from fnd_concurrent_queues q,
                      fnd_concurrent_queue_content qci,
                      fnd_concurrent_complex_lines ccli
                  where
                      q.manager_type=1
                  and qci.include_flag='I'
                  and qci.queue_application_id=q.application_id
                  and qci.concurrent_queue_id=q.concurrent_queue_id
                  and qci.type_code='C'
                  and ccli.application_id=qci.type_application_id
                and ccli.complex_rule_id=qci.type_id)
,ex_rules as (  select q.concurrent_queue_id, q.concurrent_queue_name, q.sleep_seconds,
                      nvl(qci.include_flag,'I') include_flag,
                      nvl(qci.type_code,'P') type_code,
                      decode(qci.type_code, 'P', qci.type_application_id, null) program_application_id,
                      decode(qci.type_code, 'P', qci.type_id, null) concurrent_program_id,
                      decode(qci.type_code, 'R', qci.type_application_id, null) request_class_application_id,
                      decode(qci.type_code, 'R', qci.type_id, null) concurrent_request_class_id,
                      decode(qci.type_code, 'O', qci.type_id, null) oracle_id,
                      decode(qci.type_code, 'U', qci.type_id, null) user_id,
                        'S' queue_method_flag_not
                from fnd_concurrent_queues q,
                    fnd_concurrent_queue_content qci
                where 1=1
                and q.manager_type=1
                and qci.queue_application_id=q.application_id
                and qci.concurrent_queue_id=q.concurrent_queue_id
                and qci.type_code!='C'
                and qci.include_flag='E'
                union all
                select q.concurrent_queue_id, q.concurrent_queue_name, q.sleep_seconds,
                      decode(qci.include_flag,ccli.include_flag,'I','E') include_flag,
                      ccli.type_code,
                      decode(ccli.type_code, 'P', ccli.type_application_id, null) program_application_id,
                      decode(ccli.type_code, 'P', ccli.type_id, null) concurrent_program_id,
                      decode(ccli.type_code, 'R', ccli.type_application_id, null) request_class_application_id,
                      decode(ccli.type_code, 'R', ccli.type_id, null) concurrent_request_class_id,
                      decode(ccli.type_code, 'O', ccli.type_id, null) oracle_id,
                      decode(ccli.type_code, 'U', ccli.type_id, null) user_id,
                        'S' queue_method_flag_not
                from fnd_concurrent_queues q,
                    fnd_concurrent_queue_content qci,
                    fnd_concurrent_complex_lines ccli
                where
                    q.manager_type=1
                and qci.include_flag='E'
                and qci.queue_application_id=q.application_id
                and qci.concurrent_queue_id=q.concurrent_queue_id
                and qci.type_code='C'
                and ccli.application_id=qci.type_application_id
              and ccli.complex_rule_id=qci.type_id),
req_managers as (select distinct req.request_id, qt.concurrent_queue_id, qt.user_concurrent_queue_name from
  req,
  fnd_concurrent_programs p,
  fnd_concurrent_queues_tl qt,
  in_rules rul
where  1=1
and qt.concurrent_queue_id=rul.concurrent_queue_id
and qt.language='US'
and p.application_id=req.program_application_id
and p.concurrent_program_id=req.concurrent_program_id
and p.execution_method_code!=rul.queue_method_flag_not
and ( (rul.type_code='P' and nvl(rul.program_application_id,req.program_application_id)=req.program_application_id and nvl(rul.concurrent_program_id,req.concurrent_program_id)=req.concurrent_program_id)
   or (rul.type_code='R' and nvl(rul.request_class_application_id,req.request_class_application_id)=req.request_class_application_id and nvl(rul.concurrent_request_class_id,req.concurrent_request_class_id)=req.concurrent_request_class_id)
   or (rul.type_code='O' and rul.oracle_id=req.oracle_id)
   or (rul.type_code='U' and rul.user_id=req.requested_by))
and not exists (select null from ex_rules erul where
                  erul.concurrent_queue_id=rul.concurrent_queue_id
                  and p.execution_method_code!=rul.queue_method_flag_not
                  and ((erul.type_code='P' and nvl(erul.program_application_id,req.program_application_id)=req.program_application_id and nvl(erul.concurrent_program_id,req.concurrent_program_id)=req.concurrent_program_id)
                  or (erul.type_code='R' and nvl(erul.request_class_application_id,req.request_class_application_id)=req.request_class_application_id and nvl(erul.concurrent_request_class_id,req.concurrent_request_class_id)=req.concurrent_request_class_id)
                  or (erul.type_code='O' and erul.oracle_id=req.oracle_id)
                  or (erul.type_code='U' and erul.user_id=req.requested_by)))),
interv_proc as (select req.pending_crm_till int_start, req.pending_till int_end, q.concurrent_queue_id,
                        q.concurrent_queue_name,
                        p.concurrent_process_id,
                        p.process_start_date,
                        q.sleep_seconds,
                        decode(p.process_status_code,'A',to_date(null),p.last_update_date) process_stop_date,
                        trunc((least(req.pending_till,decode(p.process_status_code,'A',sysdate,p.last_update_date))-
                                greatest(req.pending_crm_till,p.process_start_date))*24*60*60) uptime_sec
                  from fnd_concurrent_queues q,
                      fnd_concurrent_processes p,
                      req,
                      req_managers rm
                  where 1=1
                  and q.concurrent_queue_id=rm.concurrent_queue_id
                  and p.concurrent_queue_id=q.concurrent_queue_id
                  and decode(p.process_status_code,'A',sysdate,p.last_update_date) >= req.pending_crm_till
                  and p.process_start_date < req.pending_till  --BIND2 to date
                order by 1,2,3,4)                ,
raw_data as (select interv.int_start, interv.int_end, concurrent_queue_id,
                        interv.concurrent_queue_name,
                        interv.concurrent_process_id,
                        interv.process_start_date,
                        interv.process_stop_date,
                        interv.uptime_sec,
                        r.request_id,
                        r.actual_start_date,
                        r.actual_completion_date,
                        p.concurrent_program_name,
                        trunc((least(interv.int_end,nvl(r.actual_completion_date,sysdate))-
                                greatest(interv.int_start,r.actual_start_date))*24*60*60)
                        -decode(p.concurrent_program_name,'FNDRSSUB',1,'FNDRSSTG',1,0)*(select trunc(least(interv.int_end-interv.int_start,nvl((max(least(interv.int_end,nvl(r.actual_completion_date,sysdate),nvl(r2.actual_completion_date,sysdate)))-
                                min(greatest(interv.int_start,r.actual_start_date,r2.actual_start_date))),0))*24*60*60) from fnd_concurrent_requests r2 where r2.parent_request_id=r.request_id
                                and nvl(r2.actual_completion_date,sysdate) >= interv.int_start
                                and r2.actual_start_date <=  interv.int_end
                                and nvl(r2.actual_completion_date,sysdate) >= r.actual_start_date
                                and r2.actual_start_date <=  nvl(r.actual_completion_date,sysdate))
                                req_exec_sec,
                        interv.sleep_seconds
                  from interv_proc interv,
                      fnd_concurrent_requests r,
                      fnd_concurrent_programs p
                  where 1=1
                  and r.program_application_id=p.application_id(+)
                  and r.concurrent_program_id=p.concurrent_program_id(+)
                  and r.controlling_manager(+)=interv.concurrent_process_id
                  and r.phase_code(+)='C'
                  and nvl(r.actual_completion_date(+),sysdate) >= interv.int_start  --BIND1 from date
                  and r.actual_start_date(+) <=  interv.int_end  --BIND2 to date
                order by 1, interv.process_start_date, NVL(R.priority, 999999999), R.Priority_Request_ID, R.Request_ID),
sum_data as (select concurrent_queue_name conc_queue_name,
                  concurrent_process_id conc_proc_id,
                  process_start_date proc_start,
                  process_stop_date proc_stop,
                  uptime_sec,
                  nvl(count(request_id),0) req_cnt,
                  nvl(sum(req_exec_sec),0) busy_sec,
                  round((sum(req_exec_sec)/uptime_sec)*100,2) busy_pct,
                  trunc((uptime_sec-sum(req_exec_sec))/(count(request_id)+1)) avg_delay,
                  sleep_seconds sleep_sec
            from raw_data
            group by int_start, int_end, concurrent_queue_id,
                  concurrent_queue_name,
                  concurrent_process_id,
                  process_start_date,
                  process_stop_date,
                  uptime_sec,
                  sleep_seconds
          order by 1,2,3)
select * from sum_data;

undefine req_id
