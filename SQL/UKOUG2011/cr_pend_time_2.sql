-- UKOUG2011 - Concurrent Processing Performance Analysis for Apps DBAs
-- Author: Maris Elsins
-- Purpose: Reports average pending time for a particular concurrent program split by time intervals
-- Usage: cr_pend_time_2.sql <start reporting interval DDMMYYYY_HH24MISS> <end reporting interval DDMMYYYY_HH24MISS> <con prog application id> <con prog id> <stage id> <interval split DD HH MI SS>

set pages 50000 lines 140 echo off feed off ver off
alter session set nls_date_format='DDMMYYYY_HH24MISS';
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
define split_interval="&6"
define ap_id="&3"
define pr_id="&4"
define sg_id="&5"

with interv1 as (select to_date('&from_DDMMYYYY_HH24MISS','DDMMYYYY-HH24MISS') int_start, to_date('&to_DDMMYYYY_HH24MISS','DDMMYYYY-HH24MISS') int_end from dual)
select  decode('&split_interval','SS',requested_start_date, trunc(requested_start_date,'&split_interval')) int_start,
        decode('&split_interval','SS',requested_start_date, trunc(requested_start_date,'&split_interval'))+decode('&split_interval','DD',1,'HH',1/24,'MI',1/24/60,'SS',1/24/60/60,null)-1/24/60/60 int_end,
        ap_id,
        pr_id,
        sg_id,
        count(*) req_cnt,
        trunc(avg(pending_total)) pend_tot,
        trunc(avg(pending_crm)) pend_crm,
        trunc(avg(pending_total-pending_crm)) pend_cm,
        trunc(avg(execution_time)) exe_time
from (select r.program_application_id ap_id,
             r.concurrent_program_id pr_id,
             nvl('&sg_id','""') sg_id,
             greatest(request_date, requested_start_date) requested_start_date,
             round((actual_start_date-greatest(request_date, requested_start_date))*24*60*60) pending_total,
             round(nvl((crm_release_date-greatest(request_date, requested_start_date))*24*60*60,0)) pending_crm,
             round((actual_completion_date-actual_start_date)*24*60*60) execution_time
      from fnd_concurrent_requests r, interv1
      where phase_code='C'
            and greatest(request_date, requested_start_date) >= interv1.int_start  --BIND1
            and greatest(request_date, requested_start_date) <= interv1.int_end  --BIND2
            and r.program_application_id=&ap_id
            and concurrent_program_id=&pr_id
            and ('&sg_id' is null or
                 (length(translate('&sg_id','-0123456789','-'))=1 and r.argument1||'-'||r.argument2='&sg_id') or
                 (length(translate('&sg_id','-0123456789','-'))=2 and r.argument1||'-'||r.argument2||'-'||r.argument3='&sg_id'))
            )
group by ap_id, pr_id, sg_id, decode('&split_interval','SS',requested_start_date, trunc(requested_start_date,'&split_interval'))
order by pend_tot asc;


undefine from_DDMMYYYY_HH24MISS
undefine to_DDMMYYYY_HH24MISS
undefine split_interval
undefine ap_id
undefine pr_id
undefine sg_id