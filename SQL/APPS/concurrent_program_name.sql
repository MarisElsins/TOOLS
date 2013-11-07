set pages 50000 lines 240 ver off tab off
undef name_filer
def name_filer="&1"
col concurrent_program_name for a30
col user_concurrent_program_name for a120
select cpt.user_concurrent_program_name,
       cp.concurrent_program_name,
       cp.application_id, 
       cp.concurrent_program_id,
       cp.executable_id
 from fnd_concurrent_programs cp, fnd_concurrent_programs_tl cpt
where cp.application_id=cpt.application_id
  and cp.concurrent_program_id=cpt.concurrent_program_id
  and cpt.language='US'
  and (cpt.user_concurrent_program_name like '&name_filer' or cp.concurrent_program_name like '&name_filer')
order by 1;
