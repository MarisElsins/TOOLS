-- UKOUG2011 - Concurrent Processing Performance Analysis for Apps DBAs
-- Author: Maris Elsins
-- Purpose: Lists the mamagers that can (could have) execute the particular concurrent requests
-- WARNING: the query is based on current specialization rules, so It might not be 100% accurate for requests that have completed already if the rulas have been changed.
-- Usage: which_cm_can_exec_cr.sql <request id>

set pages 50000 lines 140 echo off feed off ver off
alter session set nls_date_format='DDMMYYYY_HH24MISS';
col REQUEST_ID for 999999999
col QUEUE_ID for 99999999
col CONCURRENT_QUEUE_NAME for a30
col USER_CONCURRENT_QUEUE_NAME for a60
col sleep_seconds for 99999
define req_id="&1"

with in_rules as (  select q.concurrent_queue_id, q.concurrent_queue_name, q.sleep_seconds,
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
              and ccli.complex_rule_id=qci.type_id)
select distinct qt.concurrent_queue_id queue_id, rul.concurrent_queue_name, qt.user_concurrent_queue_name, rul.sleep_seconds from
  fnd_concurrent_requests req,
  fnd_concurrent_programs p,
  fnd_concurrent_queues_tl qt,
  in_rules rul
where  1=1
and qt.concurrent_queue_id=rul.concurrent_queue_id
and qt.language='US'
and req.request_id=&req_id --BIND1
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
                  or (erul.type_code='U' and erul.user_id=req.requested_by)));

undefine req_id
