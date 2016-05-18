set pages 50000 lines 100 tab off serverout on echo off
col sql_text for a100
col force_matching_signature for 999999999999999999999999
col exact_matching_signature for 999999999999999999999999
col fms for 999999999999999999999999
col sql_length for 9999999999
set echo on
alter session set container = sample;

-- if you want to stat digging into AWR you don't have to know all the tables - 2 is enough!
pause

desc dba_hist_snapshot
pause

desc dba_hist_sqlstat
pause
-- CAREFUL WITH THE SNAP_IDs!!!
pause


set lines 238
-- Look at this crazy script!
!cat awr_top_by_sqlid_snaps.sql
pause

@awr_top_by_sqlid_snaps.sql 25 50 5 10
set echo on
pause

@awr_top_by_sqlid_snaps.sql 25 50 7 10
set echo on
pause

@awr_top_by_sqlid_snaps.sql 25 50 9 10
set echo on
pause

-- Why is it good to see DIFF_PLANS?
pause
-- Look at the row for sql_id = c13sma6rkr27c
pause
@awr_sqlid_perf_trend_by_plan.sql 25 50 c13sma6rkr27c
set echo on
pause
--let's look at two of the plans
select * from table(dbms_xplan.display_awr('c13sma6rkr27c',725271039));
pause
select * from table(dbms_xplan.display_awr('c13sma6rkr27c',3004904301));
pause

-- Querying the AWR tables directy gives more flexibility, but provides basically the same results as THe AWR report.
exit


