set pages 50000 lines 238 tab off serverout on echo off
col sql_text for a100
col force_matching_signature for 999999999999999999999999
col exact_matching_signature for 999999999999999999999999
col fms for 999999999999999999999999
col sql_length for 9999999999
set echo on
alter session set container = sample;

-- Look at this crazy script!
!cat awr_top_by_sqlid_snaps.sql
pause

@awr_top_by_sqlid_snaps.sql 24 50 4 40
set echo on
pause

@awr_top_by_sqlid_snaps.sql 24 50 6 10
set echo on
pause

@awr_top_by_sqlid_snaps.sql 24 50 11 10
set echo on
pause

-- Why is it good to see DIFF_PLANS?
pause
-- Look at the row for sql_id = c13sma6rkr27c
pause
@awr_sqlid_perf_trend_by_plan.sql 24 54 c13sma6rkr27c
set echo on
pause
--let's look at the plans one by one
select * from table(dbms_xplan.display_awr('c13sma6rkr27c',214043693));
pause
select * from table(dbms_xplan.display_awr('c13sma6rkr27c',3004904301));
pause
select * from table(dbms_xplan.display_awr('c13sma6rkr27c',725271039));
pause

-- By The way these are adaptive plans, you can get more information about them!
pause
select * from table(dbms_xplan.display_awr('c13sma6rkr27c',3004904301, format=>'+adaptive'));
pause
select * from table(dbms_xplan.display_awr('c13sma6rkr27c',725271039, format=>'+adaptive'));
pause
