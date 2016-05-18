set pages 50000 lines 238 tab off serverout on echo off
col sql_text for a100
col force_matching_signature for 999999999999999999999999
col exact_matching_signature for 999999999999999999999999
col fms for 999999999999999999999999
col sql_length for 9999999999
set echo on


alter system flush shared_pool;
/
/
alter session set container = sample;

-- Take a look at different SQL_IDs!
pause

select /*testquery*/ count(*) from oe.orders;
pause

select sql_id, sql_text, length(sql_text) sql_length from v$sql where sql_text like '%/*test'||'query%*/%' order by LAST_LOAD_TIME;
pause 

SELECT /*testquery*/ COUNT(*) FROM OE.ORDERS;
pause

select sql_id, sql_text, length(sql_text) sql_length from v$sql where sql_text like '%/*test'||'query%*/%' order by LAST_LOAD_TIME;
pause 

SELECT /*testquery*/ COUNT(*) FROM OE.ORDERS          ;
pause

select sql_id, sql_text, length(sql_text) sql_length from v$sql where sql_text like '%/*test'||'query%*/%' order by LAST_LOAD_TIME;
pause 

SELECT /*testquery*/ COUNT(*) FROM    OE.ORDERS;
pause

select sql_id, sql_text, length(sql_text) sql_length from v$sql where sql_text like '%/*test'||'query%*/%' order by LAST_LOAD_TIME;
pause 

SELECT /*testquery*/ COUNT(*) FROM OE.ORDERS WHERE 1=1;
pause

select sql_id, sql_text, length(sql_text) sql_length from v$sql where sql_text like '%/*test'||'query%*/%' order by LAST_LOAD_TIME;
pause 

SELECT /*testquery*/ COUNT(*) FROM OE.ORDERS WHERE order_id>-1;
pause

select sql_id, sql_text, length(sql_text) sql_length from v$sql where sql_text like '%/*test'||'query%*/%' order by LAST_LOAD_TIME;
pause 

SELECT /*testquery*/ COUNT(*) FROM OE.ORDERS WHERE order_id>-1000;
pause

select sql_id, sql_text, length(sql_text) sql_length from v$sql where sql_text like '%/*test'||'query%*/%' order by LAST_LOAD_TIME;
pause 

var a number
var b number
exec :a:=-1
exec :b:=-1
pause

SELECT /*testquery*/ COUNT(*) FROM OE.ORDERS WHERE order_id>:a;
pause

select sql_id, sql_text, length(sql_text) sql_length from v$sql where sql_text like '%/*test'||'query%*/%' order by LAST_LOAD_TIME;
pause 

SELECT /*testquery*/ COUNT(*) FROM OE.ORDERS WHERE order_id>:b;
pause

select sql_id, sql_text, length(sql_text) sql_length from v$sql where sql_text like '%/*test'||'query%*/%' order by LAST_LOAD_TIME;
pause

-- Do you know of any other SQL identification methods?
pause
-- What about EXACT_MATCHING_SIGNATURE?
pause

break on EXACT_MATCHING_SIGNATURE duplicates skip 1
select sql_id, exact_matching_signature, sql_text, length(sql_text) sql_length from v$sql where sql_text like '%/*test'||'query%*/%' order by 2, LAST_LOAD_TIME;
pause

-- You must have heard of FORCE_MATCHING_SIGNATURE too
pause

clear breaks
break on FORCE_MATCHING_SIGNATURE duplicates skip 1;
select sql_id, force_matching_signature, sql_text, length(sql_text) sql_length from v$sql where sql_text like '%/*test'||'query%*/%' order by 2, 3, LAST_LOAD_TIME;
pause

-- This doesn't really identify the SQL statement, but take a look what happens if we group them by PLAN_HASH_VALUE
pause

clear breaks
break on PLAN_HASH_VALUE duplicates skip 1;
select sql_id, plan_hash_value, sql_text, length(sql_text) sql_length from v$sql where sql_text like '%/*test'||'query%*/%' order by 2, 4, LAST_LOAD_TIME;
pause

exit
