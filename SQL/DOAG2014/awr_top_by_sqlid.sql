-- Maris Elsins / Pythian / 2014
-- Sorry, no description yet, but you can check http://www.pythian.com/blog/do-awr-reports-show-the-whole-pictureset ver off pages 50000 lines 260 tab off
set pages 50000 lines 3000 tab off ver off
undef days_history
undef interval_hours
def days_history="&1"
def interval_hours="&2"
def sort_col_nr="&3"
def top_n="&4"
col inst for 9999
col time for a19
col force_matching_signature for 99999999999999999999
col executions for 9999999999
col rows_processed for 9999999999
col elapsed_time_s for 9999999.999
col cpu_time_s for 9999999.999
col iowait_s for 9999999.999
col clwait_s for 9999999.999
col apwait_s for 9999999.999
col ccwait_s for 9999999.999
col plsexec_time_s for 9999999.999
col javexec_time_s for 9999999.999
col buffer_gets for 999999999999
col disk_reads for 999999999999
col direct_writes for 999999999999
col diff_sqlid for a13
col diff_plans for 9999999999
col fms for 99999999999999999999

select * from (
select hss.sql_id,
    decode(count(unique(plan_hash_value)),1,max(plan_hash_value),count(unique(plan_hash_value))) diff_plans,
    decode(count(unique(force_matching_signature)),1,max(force_matching_signature),count(unique(force_matching_signature))) fms,
    sum(hss.executions_delta) executions,
    round(sum(hss.elapsed_time_delta)/1000000,3) elapsed_time_s,
    round(sum(hss.cpu_time_delta)/1000000,3) cpu_time_s,
    round(sum(hss.iowait_delta)/1000000,3) iowait_s,
    round(sum(hss.clwait_delta)/1000000,3) clwait_s,
    round(sum(hss.apwait_delta)/1000000,3) apwait_s,
    round(sum(hss.ccwait_delta)/1000000,3) ccwait_s,
    round(sum(hss.rows_processed_delta),3) rows_processed,
    round(sum(hss.buffer_gets_delta),3) buffer_gets,
    round(sum(hss.disk_reads_delta),3) disk_reads,
    round(sum(hss.direct_writes_delta),3) direct_writes
from dba_hist_sqlstat hss, dba_hist_snapshot hs
where hss.snap_id=hs.snap_id
    and hs.begin_interval_time>=trunc(sysdate)-&days_history+1
    and hs.begin_interval_time<=trunc(sysdate)-&days_history+1+(&interval_hours/24)
    and hss.executions_delta>0
group by sql_id
order by &sort_col_nr desc nulls last)
where rownum<=&top_n;
