set pages 50000 lines 238 tab off serverout on echo off
col sql_text for a100
col force_matching_signature for 999999999999999999999999
col exact_matching_signature for 999999999999999999999999
col fms for 999999999999999999999999
col sql_length for 9999999999
set echo on
alter session set container = sample;

-- Let's see how sorting by elapsed time looks when we aggregate by PLAN_HASH_VALUE
pause

-- Look at this crazy script!
!cat awr_top_by_plan_snaps.sql
pause

@awr_top_by_plan_snaps.sql 25 50 5 10
set echo on
pause

-- What is plan 1628223527?
pause
@awr_top_by_plan_detail_snaps.sql 25 50 5 15 1628223527
set echo on
pause

-- Let's look at some of these queries
pause
@awr_show_sqlid.sql 5mddt5kt45rg3
set echo on
pause
@awr_show_sqlid.sql f9u2k84v884y7
set echo on
pause

-- Is the plan the same, really?
pause
select * from table(dbms_xplan.display_awr('5mddt5kt45rg3',1628223527));
pause
select * from table(dbms_xplan.display_awr('f9u2k84v884y7',1628223527));
pause
-- Looking at the top execution plans in the system can help finding inefficient access paths to the data

exit

