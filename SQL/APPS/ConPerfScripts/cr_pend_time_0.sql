-- Concurrent Processing Performance Analysis for Apps DBAs
-- Author: Maris Elsins | @MarisElsins
-- Purpose: Reports pending time statistics for concurrent requests
-- Usage: cr_pend_time_0.sql <start reporting interval DDMMYYYY_HH24MISS> <end reporting interval DDMMYYYY_HH24MISS> <interval split DD HH MI SS>

set pages 50000 lines 170 echo off feed off ver off
alter session set nls_date_format='DDMMYYYY_HH24MISS';
col req_cmp_count for 99999999
col req_sch_count for 99999999
col pend_s for 9999999999
col sum_pend_crm_s for 9999999999
col sum_pend_cm_s for 9999999999
col sum_exe_time_s for 9999999999
define from_DDMMYYYY_HH24MISS="&1"
define to_DDMMYYYY_HH24MISS="&2"
define split_interval="&3"

with interv0 as (select to_date('&from_DDMMYYYY_HH24MISS','DDMMYYYY-HH24MISS') int_start, to_date('&to_DDMMYYYY_HH24MISS','DDMMYYYY-HH24MISS') int_end from dual),
     interv1 as (select * from (select int_start, lead(int_start) over (order by int_start) int_end from (
                select to_date('&from_DDMMYYYY_HH24MISS','DDMMYYYY_HH24MISS')+(rownum-1)/decode(upper('&split_interval'), 'DD',1,'HH24',1*24,'HH',1*24, 'MI', 1*24*60, 'SS', 1*24*60*60) int_start
                from dual connect by level <=999999)) where int_end<=to_date('&to_DDMMYYYY_HH24MISS','DDMMYYYY_HH24MISS'))
    select  i.int_start, i.int_end,
            sum(case when greatest(request_date, requested_start_date) between i.int_start and  i.int_end-1/86400 then 1 else 0 end) req_scheduled,
            sum(case when actual_start_date between i.int_start and  i.int_end-1/86400 then 1 else 0 end) req_started,
            sum(case when actual_completion_date between i.int_start and  i.int_end-1/86400 then 1 else 0 end) req_completed,
            round(sum(greatest(0,least(actual_start_date,i.int_end) - greatest(greatest(request_date, requested_start_date),i.int_start))*24*60*60)) sum_pend_s,
            round(sum(greatest(0,least(crm_release_date,i.int_end) - greatest(greatest(request_date, requested_start_date),i.int_start))*24*60*60)) sum_pend_crm_s,
            round(sum(greatest(0,least(actual_start_date,i.int_end) - greatest(crm_release_date,i.int_start))*24*60*60)) sum_pend_cm_s
    from fnd_concurrent_requests r, interv1 i, interv0 i0
    where phase_code='C'
        and greatest(request_date, requested_start_date) <= i0.int_end  --BIND1
        and actual_completion_date >= i0.int_start    --BIND2
    group by i.int_start, i.int_end
    order by 1 asc;

undefine from_DDMMYYYY_HH24MISS
undefine to_DDMMYYYY_HH24MISS
undefine split_interval