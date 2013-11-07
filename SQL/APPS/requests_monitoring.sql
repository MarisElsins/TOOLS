set pages 50000 lines 4000 tab off
col REQ_NAME for a40 
col USER_NAME for a16
col CP_PROCESS for a30
col CM_PROCESS for a30
col "DB_SID_SERIAL#" for a30
col DB_PROCESS for a50
col ARGUMENT_TEXT for a80
col START_TRACE for a80
select *
  from (select distinct r.request_id req_id,
                        r.parent_request_id preq_id,
                        ps.concurrent_program_name prog_name,
                        p.user_concurrent_program_name || case
                          when concurrent_program_name = 'FNDRSSUB' then
                           (select ': ' || rs.user_request_set_name
                              from applsys.fnd_request_sets_tl rs
                             where rs.application_id = to_number(argument1)
                               and rs.request_set_id = to_number(argument2)
                               and rs.language = 'US')
                        end || case
                          when concurrent_program_name = 'FNDRSSTG' then
                           (select ': ' || rss.user_stage_name
                              from applsys.fnd_request_set_stages_tl rss
                             where rss.set_application_id =
                                   to_number(argument1)
                               and rss.request_set_id = to_number(argument2)
                               and rss.request_set_stage_id =
                                   to_number(argument3)
                               and rss.language = 'US')
                        end req_name,
                        r.phase_code p,
                        r.status_code s,
                        u.user_name,
                        r.priority PRIO,
                        (select node_name || ':'
                           from applsys.fnd_concurrent_processes cp
                          where concurrent_process_id = r.controlling_manager) ||
                        r.os_process_id cp_process,
                        gi.INSTANCE_NAME || ':' || ss.sid||','||ss.serial# db_sid_serial#,
                        gi.HOST_NAME || ':' || pp.spid db_process,
                        decode(ss.status,
                               'ACTIVE',
                               'A',
                               'INACTIVE',
                               'I',
                               ss.status) STAT, ss.state,
                        ss.sql_id, ss.sql_child_number,
                        w.event cp_event,
                        w.p1 cp_p1,
                        w.p1raw cp_p1raw,
                        w.seconds_in_wait cp_sw,
			ss.last_call_et,
                        cp.node_name || ':' || cp.os_process_id cm_process,
                        /*cmgi.INSTANCE_NAME || ':' || cmss.sid||','||cmss.serial# cm_db_sid_serial#,
                        cmgi.HOST_NAME || ':' || cmpp.spid cm_db_process,
                        cmw.event cm_event,
                        cmw.p1 cm_p1,
                        cmw.p1raw cm_p1raw,
                        cmw.seconds_in_wait cm_sw,*/
                        r.actual_start_date,
                        argument_text,
                        R.Priority_Request_ID,
                        'exec /*'||gi.INSTANCE_NAME||'*/ dbms_monitor.session_trace_enable('||ss.sid||','||ss.serial#||',true,true);' start_trace
          from applsys.fnd_user                   u,
               applsys.fnd_concurrent_requests    r,
               applsys.fnd_concurrent_programs_tl p,
               applsys.fnd_concurrent_programs    ps,
               gv$session                 ss,
               gv$process                 pp,
               gv$session_wait            w,
               gv$instance                gi,
               gv$session                 cmss,
               gv$process                 cmpp,
               gv$session_wait            cmw,
               gv$instance                cmgi,
               applsys.fnd_concurrent_processes   cp
         where 1 = 1
           and r.requested_by = u.user_id
           and (r.phase_code = 'R' or r.status_code = 'I')
           And r.Requested_Start_Date <= Sysdate
           and p.concurrent_program_id = r.concurrent_program_id
           and ps.concurrent_program_id = r.concurrent_program_id
           and p.language = 'US'
           and ss.audsid(+) = r.oracle_session_id
           and r.hold_flag = 'N'
           and pp.inst_id(+) = ss.inst_id
           and pp.addr(+) = ss.paddr
           and w.INST_ID(+) = ss.inst_id
           and w.sid(+) = ss.sid
           and gi.inst_id(+) = ss.inst_id
           and cp.concurrent_process_id(+) = r.controlling_manager
           and cmss.audsid(+) = cp.session_id
           and cmpp.inst_id(+) = cmss.inst_id
           and cmpp.addr(+) = cmss.paddr
           and cmw.INST_ID(+) = cmss.inst_id
           and cmw.sid(+) = cmss.sid
           and cmgi.inst_id(+) = cmss.inst_id
         order by decode(r.phase_code, 'R', 0, 1),
                  NVL(R.priority, 999999999),
                  R.Priority_Request_ID,
                  R.Request_ID)
where ((cp_process=cm_process /*and db_sid_serial#=cm_db_sid_serial#*/) or cp_process!=cm_process);

