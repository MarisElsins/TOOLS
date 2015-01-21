-- UKOUG2011 - Concurrent Processing Performance Analysis for Apps DBAs
-- Author: Maris Elsins
-- Purpose: Lists the mamagers that can (could have) execute the particular concurrent requests
-- WARNING: the query reports the requests that are incompatible with the given request and caused it to be waiting to be released by Conflict resolution manager.
-- Usage: wait_crm_incomp_crs.sql <request id>

set pages 50000 lines 140 echo off feed off ver off
alter session set nls_date_format='DDMMYYYY_HH24MISS';
col PEND_REQ_ID for 999999999
col GAP_SEC for 99999
col incomp_req_id for 999999999
col incomp_program for a60
break on PEND_REQ_ID on PEND_START on PEND_END

define req_id="&1"

Prompt Pending request:
select r.request_id pend_req_id,
      greatest(request_date, requested_start_date) pend_crm_start,
      nvl(crm_release_date,requested_start_date) pend_crm_end
 from fnd_concurrent_requests r, fnd_concurrent_programs p
where request_id=&req_id --BIND
  and p.application_id=r.program_application_id
  and p.concurrent_program_id=r.concurrent_program_id;

Prompt
Prompt
Prompt Incompatible requests that were running at the time request &req_id was pending:
with req as (select r.request_id,
                    p.concurrent_program_name,
                    r.program_application_id,
                    r.concurrent_program_id,
                    greatest(request_date, requested_start_date) req_start_date,
                    nvl(crm_release_date,requested_start_date) pending_crm_till,
                    actual_start_date pending_till,
                    argument1,
                    argument2
 from fnd_concurrent_requests r, fnd_concurrent_programs p
where request_id=&req_id --BIND
  and p.application_id=r.program_application_id
  and p.concurrent_program_id=r.concurrent_program_id),
raw_data as (
select  r.request_id  incomp_req_id ,
        r.actual_start_date incomp_req_start,
        r.actual_completion_date incomp_req_end,
        decode(pr.concurrent_program_name,'FNDRSSUB',p.user_concurrent_program_name||' ('||r.description||')','FNDRSSTG',(select 'Report Set ('||user_request_set_name||') Stage' from fnd_request_sets_tl st where st.application_id=r.argument1 and st.request_set_id=r.argument2 and language='US')||' ('||r.description||')',p.user_concurrent_program_name) incomp_program
from fnd_concurrent_program_serial s, req, fnd_concurrent_requests r, fnd_concurrent_programs pr, fnd_concurrent_programs_tl p
where s.to_run_application_id=to_number(decode(req.concurrent_program_name, 'FNDRSSUB',req.argument1,'FNDRSSTG',req.argument1,req.program_application_id))
  and s.to_run_concurrent_program_id=to_number(decode(req.concurrent_program_name, 'FNDRSSUB',req.argument2,'FNDRSSTG',req.argument2,req.concurrent_program_id))
  and nvl(s.to_run_type,'P')=decode(req.concurrent_program_name, 'FNDRSSUB','S','FNDRSSTG','S','P')
  and pr.application_id=r.program_application_id
  and pr.concurrent_program_id=r.concurrent_program_id
  and p.application_id=r.program_application_id
  and p.concurrent_program_id=r.concurrent_program_id
  and p.language='US'
  and r.actual_start_date <= req.pending_crm_till  --BIND1
  and r.actual_completion_date >= req.req_start_date  --BIND2
  and s.running_application_id = to_number(decode(pr.concurrent_program_name, 'FNDRSSUB',r.argument1,'FNDRSSTG',r.argument1,r.program_application_id))
  and s.running_concurrent_program_id= to_number(decode(pr.concurrent_program_name, 'FNDRSSUB',r.argument2,'FNDRSSTG',r.argument2,r.concurrent_program_id))
  and nvl(s.running_type,'P')=decode(pr.concurrent_program_name, 'FNDRSSUB','S','FNDRSSTG','S','P')
order by r.actual_start_date)
select incomp_req_id,
       incomp_req_start,
       incomp_req_end,
       case when exists (select null from raw_data b where d.incomp_req_start between b.incomp_req_start and b.incomp_req_end and d.incomp_req_id!=b.incomp_req_id) then 0
       else (select trunc(min(d.incomp_req_start-b.incomp_req_end)*24*60*60) from raw_data b where b.incomp_req_end< d.incomp_req_start and d.incomp_req_id!=b.incomp_req_id)
       end gap_sec,
       incomp_program
 from raw_data d;

undefine req_id
