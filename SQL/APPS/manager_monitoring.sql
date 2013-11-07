set pages 50000
set lines 300
col user_concurrent_queue_name for a60
col status for a12
select case
when STATUS is not null then 'ERROR'
when actual<TARGET then 'ERROR'
when target<least(nvl(a.min,target), nvl(a.max,target)) then 'ERROR'
when PENDING>100 then 'ERROR'
when ACTUAL>TARGET then 'WARNING'
else 'OK' end result,
a.* from (SELECT substr(v.user_concurrent_queue_name,1,60) user_concurrent_queue_name,
       v.target_node,
       nvl(s.min_processes,s.max_processes) min,
       nvl(s.min_processes,s.max_processes) max,
       (SELECT Count(*)
        FROM   gv$session gv,
               apps.fnd_concurrent_processes p
        WHERE  Gv.inst_id = P.instance_number
               AND Gv.audsid = P.session_id
               AND process_status_code NOT IN ( 'S', 'K', 'U' )
               AND P.queue_application_id = v.application_id
               AND concurrent_queue_id = v.concurrent_queue_id) ACTUAL,
       v.max_processes TARGET,
       (SELECT Count(phase_code)
        FROM   apps.fnd_concurrent_worker_requests wr
        WHERE  v.concurrent_queue_name = WR.concurrent_queue_name
               AND v.application_id = WR.queue_application_id
               AND phase_code = 'R') RUNNING,
       (SELECT Count(phase_code)
        FROM   apps.fnd_concurrent_worker_requests wr
        WHERE  v.concurrent_queue_name = WR.concurrent_queue_name
               AND v.application_id = WR.queue_application_id
               AND WR.phase_code = 'P'
               AND WR.hold_flag != 'Y'
               AND WR.requested_start_date <= SYSDATE) PENDING,
       (SELECT trunc((sysdate-min(greatest(request_date, requested_start_date)))*24*60*60)
        FROM   apps.fnd_concurrent_worker_requests wr
        WHERE  v.concurrent_queue_name = WR.concurrent_queue_name
               AND v.application_id = WR.queue_application_id
               AND WR.phase_code = 'P'
               AND WR.hold_flag != 'Y'
               AND WR.requested_start_date <= SYSDATE) PENDING_MAX_SEC,
       substr(l.meaning,1,30) STATUS
FROM   apps.fnd_concurrent_queues_vl v,
       apps.fnd_concurrent_queue_size s,
       apps.fnd_lookups l
WHERE  v.enabled_flag = 'Y'
       AND l.lookup_type(+) = 'CP_CONTROL_CODE'
       AND l.lookup_code(+) = v.control_code
       AND Nvl(L.meaning,'OK') != 'Deactivated'
       and S.queue_application_id(+)=v.application_id
       and s.concurrent_queue_id(+)=v.concurrent_queue_id
ORDER  BY Decode(application_id, 0, Decode(v.concurrent_queue_id, 1, 1, 4, 2)),
          Sign(v.max_processes) DESC,
          concurrent_queue_name,
          application_id) a;
