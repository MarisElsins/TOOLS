set pages 50000 lines 238 tab off serverout on echo off
col sql_text for a100
col force_matching_signature for 999999999999999999999999
col exact_matching_signature for 999999999999999999999999
col fms for 999999999999999999999999
col sql_length for 9999999999
set echo on
alter session set container = sample;

-- Let's see how sorting by elapsed time looks when we aggregate by FORCE_MATCHING_SIGNATURE
pause

-- Look at this crazy script!
!cat awr_top_by_fms_snaps.sql
pause

@awr_top_by_fms_snaps.sql 25 50 5 10
set echo on
pause

-- What is FMS=0?
pause
@awr_top_by_fms_detail_snaps.sql 25 50 5 15 0
set echo on
pause

-- Let's look at some of these queries
pause
@awr_show_sqlid.sql 0w2qpuc6u2zsp
set echo on
pause
@awr_show_sqlid.sql gzhkw1qu6fwxm
set echo on
pause

-- Let's take a closer look at these 999 queries in the TOP 3rd place.
pause
@awr_top_by_fms_detail_snaps.sql 25 50 5 15 5985318870031566873
set echo on
pause

-- Let's look at some of these queries
pause
@awr_show_sqlid.sql 2y383xj04ztf6 
set echo on
pause

@awr_show_sqlid.sql dra5rjs03kmad
set echo on
pause

-- Sorting by FORCE_MATCHING_SIGNATURE allowed me to identify a significant consumer query that doesn't utilize binds

exit

