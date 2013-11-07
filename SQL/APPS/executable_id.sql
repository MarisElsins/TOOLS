set pages 50000 lines 240 ver off tab off
undef name_filer
def id_filter="&1"
col executable_name for a30
col EXEC_METHOD for a30
col EXECUTION_FILE_NAME for a61
select cp.concurrent_program_id,
	   e.application_id, 
       e.executable_id,
       e.executable_name,
       l.MEANING EXEC_METHOD,
       e.EXECUTION_FILE_NAME
 from fnd_concurrent_programs cp, fnd_executables e, fnd_lookups l
where cp.application_id=e.application_id
  and cp.executable_id=e.executable_id
  and l.lookup_type='CP_EXECUTION_METHOD_CODE'
  and l.lookup_code=e.EXECUTION_METHOD_CODE
  and cp.executable_id=&id_filter
order by 1;
