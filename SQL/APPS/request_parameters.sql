set pages 50000 lines 240 ver off tab off
undef req_id_filter
def req_id_filter="&1"
col END_USER_COLUMN_NAME for a30
col DESCRIPTION for a80
col enabled for a7
col value for a40
select END_USER_COLUMN_NAME, 
	   trim(substr(argument_text,
	   		  decode(rownum,1,1,instr(argument_text,',',1,rownum-1)+2),
	   		  decode(instr(argument_text,',',1,rownum),0,9999,instr(argument_text,',',1,rownum)-1) - decode(rownum,1,1,instr(argument_text,',',1,rownum-1)+2) + 1  
	   		  )) Value,
	   enabled,
	   DESCRIPTION
from (select f.END_USER_COLUMN_NAME,
			f.enabled_flag enabled,
	       f.DESCRIPTION,
	       r.argument_text
	 from fnd_concurrent_requests r, fnd_concurrent_programs cp, FND_DESCR_FLEX_COL_USAGE_VL f 
	where cp.application_id=f.application_id
	  and f.DESCRIPTIVE_FLEXFIELD_NAME='$SRS$.'||cp.concurrent_program_name
	  and r.request_id=&req_id_filter
	  and cp.application_id=r.program_application_id
	  and cp.concurrent_program_id=r.concurrent_program_id
	order by f.column_seq_num);
