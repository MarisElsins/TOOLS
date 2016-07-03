-- Author:             Maris Elsins (elmaris@gmail.com), 2016
-- Copyright:          (c) Maris Elsins - https://me-dba.com - All rights reserved.set pages 50000 lines 240 ver off
col file_name for a80
col ID for 999
COLUMN DUMMY1 NOPRINT;
COMPUTE SUM OF MAX_MB ON DUMMY1;
COMPUTE SUM OF CURRENT_MB ON DUMMY1;
BREAK ON DUMMY1;
select 1 dummy1,
       d.file_name file_name, 
       d.file_id ID, 
       d.tablespace_name, 
       t.block_size, 
       d.autoextensible, 
       d.blocks*t.block_size/1024/1024 current_mb, 
       decode(d.autoextensible, 'YES', d.maxblocks, d.blocks) maxblocks, 
       decode(d.autoextensible, 'YES', d.maxblocks, d.blocks)*t.block_size/1024/1024 max_mb, 
       d.increment_by*t.block_size/1024/1024 increment_mb, 
       d.status, 
       d.online_status online_status
 from dba_data_files d, dba_tablespaces t
where t.tablespace_name like '%&1%'
  and d.tablespace_name=t.tablespace_name
order by d.tablespace_name, substr(d.file_name,instr('/',d.file_name,-1)+1);
