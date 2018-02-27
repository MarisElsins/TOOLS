-- Use it like this: 
-- @is_path_applied <patchnr>,<patchnr>,<patchnr>,...

set echo off feed off tab off ver off
alter session set nls_date_format='DD.MM.YYYY HH24:MI:SS';
set feed on lines 300 pages 50000
col CHECK_PATCH for a20
col PATCH_NAME for a20
col MERGED for a6
col APPL_TOP_NAME for a20
col LANGUAGE for a4
col APPLIED_DATE for a19
col PATCH_DESCRIPTION for a100
col applications_system_name for a8
col driver_file_name for a20
def patchnum='&1'

with t as (select '&patchnum' as patchlist from dual),
patches as (select /*+ materialize */ x.*
from t
    ,xmltable('x/y'
              passing xmltype('<x><y>'||replace(t.patchlist,',','</y><y>')||'</y></x>')
              columns check_patch varchar2(20) path '.') x)
SELECT pt.check_patch, PATCH_RUN_ID, nvl(PATCH_NAME,'NOT APPLIED!') PATCH_NAME, MERGED, APPL_TOP_NAME, LANGUAGE, max(APPLIED_DATE) APPLIED_DATE, PATCH_DESCRIPTION, applications_system_name, driver_file_name
FROM (
    SELECT p.check_patch,
      CASE WHEN ( pd.patch_abstract IS NULL AND pd.driver_file_name IN ( 'uprepare.drv', 'ufinalize.drv', 'ucutover.drv', 'ucleanup.drv', 'uactualize.drv', 'uabort.drv' ) )
           THEN Decode(pd.driver_file_name, 'uprepare.drv', 'PREPARE', 'ufinalize.drv', 'FINALIZE' , 'ucutover.drv', 'CUTOVER', 'ucleanup.drv', 'CLEANUP', 'uactualize.drv', 'ACTUALIZE_ALL', 'uabort.drv', 'ABORT', NULL)
           ELSE ap.patch_name || Decode(ab.baseline_name, NULL, '', '.') || ab.baseline_name
      END PATCH_NAME,
      merged_driver_flag merged,
      at.name APPL_TOP_NAME,
      l.LANGUAGE LANGUAGE,
      --ap.applied_patch_id,
      --pr.appl_top_id,
      CASE WHEN NOT EXISTS (SELECT 1 FROM   ad_adop_session_patches aasp2 WHERE  aasp2.patchrun_id = pr.patch_run_id)
           THEN pr.end_date ELSE Nvl(aas.cutover_end_date, aasp.end_date)
      END APPLIED_DATE,
      --pd.patch_driver_id PATCH_DRV_ID,
      Decode(pd.patch_abstract, NULL, Decode(pd.driver_file_name, 'uprepare.drv', 'adop phase=prepare', 'ufinalize.drv', 'adop phase=finalize', 'ucutover.drv', 'adop phase=cutover', 'ucleanup.drv', 'adop phase=cleanup', 'uactualize.drv', 'adop phase=actualize_all', 'uabort.drv', 'adop phase=abort', Decode( merged_driver_flag, 'Y', 'Merged Patch', NULL)), pd.patch_abstract) PATCH_DESCRIPTION,
      at.applications_system_name,
      pd.driver_file_name,
      pr.patch_run_id
    FROM ad_appl_tops at,
         ad_patch_driver_langs l,
         ad_applied_patches ap,
         ad_patch_drivers pd,
         ad_patch_runs pr,
         ad_bugs ab,
         ad_adop_sessions aas,
         ad_adop_session_patches aasp,
         patches p
    WHERE pr.patch_run_id IN (SELECT prb.patch_run_id FROM ad_patch_run_bugs prb, ad_bugs b WHERE b.bug_id = prb.bug_id AND Upper(b.bug_number) = p.check_patch)
      AND pr.appl_top_id = at.appl_top_id
      AND at.appl_top_id = aas.appltop_id
      AND aas.appltop_id = aasp.appltop_id
      AND pr.patch_driver_id = pd.patch_driver_id
      AND pd.applied_patch_id = ap.applied_patch_id
      AND pd.patch_driver_id = l.patch_driver_id
      AND ab.bug_number (+) = ap.patch_name
      AND ( pr.patch_action_options IS NULL OR pr.patch_action_options NOT LIKE '%syncfs%' )
      AND ( NOT EXISTS (SELECT 1 FROM ad_adop_session_patches aasp2 WHERE aasp2.patchrun_id = pr.patch_run_id)
            OR ( pr.patch_run_id = aasp.patchrun_id AND aasp.adop_session_id = aas.adop_session_id AND aas.node_name = aasp.node_name AND ( aas.cutover_status = 'Y' OR aas.cutover_status = 'X' )))
UNION
    SELECT p.check_patch,
      CASE WHEN ( pd.patch_abstract IS NULL AND pd.driver_file_name IN ( 'uprepare.drv', 'ufinalize.drv', 'ucutover.drv', 'ucleanup.drv', 'uactualize.drv', 'uabort.drv' ) )
           THEN Decode(pd.driver_file_name, 'uprepare.drv', 'PREPARE', 'ufinalize.drv', 'FINALIZE' , 'ucutover.drv', 'CUTOVER', 'ucleanup.drv', 'CLEANUP', 'uactualize.drv', 'ACTUALIZE_ALL', 'uabort.drv', 'ABORT', NULL)
           ELSE ap.patch_name || Decode(ab.baseline_name, NULL, '', '.') || ab.baseline_name
      END PATCH_NAME,
      merged_driver_flag merged,
      at.name APPL_TOP_NAME,
      l.LANGUAGE LANGUAGE,
      --ap.applied_patch_id,
      --pr.appl_top_id,
      CASE WHEN NOT EXISTS (SELECT 1 FROM   ad_adop_session_patches aasp2 WHERE  aasp2.patchrun_id = pr.patch_run_id)
           THEN pr.end_date ELSE Nvl(aas.cutover_end_date, aasp.end_date)
      END APPLIED_DATE,
      --pd.patch_driver_id PATCH_DRV_ID,
      Decode(pd.patch_abstract, NULL, Decode(pd.driver_file_name, 'uprepare.drv', 'adop phase=prepare', 'ufinalize.drv', 'adop phase=finalize', 'ucutover.drv', 'adop phase=cutover', 'ucleanup.drv', 'adop phase=cleanup', 'uactualize.drv', 'adop phase=actualize_all', 'uabort.drv', 'adop phase=abort', Decode( merged_driver_flag, 'Y', 'Merged Patch', NULL)), pd.patch_abstract) PATCH_DESCRIPTION,
      at.applications_system_name,
      pd.driver_file_name,
      pr.patch_run_id
    FROM ad_appl_tops at,
         ad_patch_driver_langs l,
         ad_applied_patches ap,
         ad_patch_drivers pd,
         ad_patch_runs pr,
         ad_bugs ab,
         ad_adop_sessions aas,
         ad_adop_session_patches aasp,
         patches p
    WHERE Upper (ap.patch_name) = p.check_patch
      AND pr.appl_top_id = at.appl_top_id
      AND at.appl_top_id = aas.appltop_id
      AND aas.appltop_id = aasp.appltop_id
      AND pr.patch_driver_id = pd.patch_driver_id
      AND pd.applied_patch_id = ap.applied_patch_id
      AND pd.patch_driver_id = l.patch_driver_id
      AND ab.bug_number (+) = ap.patch_name
      AND ( pr.patch_action_options IS NULL OR pr.patch_action_options NOT LIKE '%syncfs%' )
      AND ( NOT EXISTS (SELECT 1 FROM ad_adop_session_patches aasp2 WHERE aasp2.patchrun_id = pr.patch_run_id)
            OR ( pr.patch_run_id = aasp.patchrun_id AND aasp.adop_session_id = aas.adop_session_id AND aas.node_name = aasp.node_name AND ( aas.cutover_status = 'Y' OR aas.cutover_status = 'X' )))) ad,
  patches pt
where pt.check_patch=ad.check_patch (+) and pt.check_patch is not null
GROUP BY pt.check_patch, PATCH_RUN_ID, PATCH_NAME, MERGED, APPL_TOP_NAME, LANGUAGE, PATCH_DESCRIPTION, applications_system_name, driver_file_name
ORDER BY sign(PATCH_RUN_ID) nulls first, 1, 8 desc;

undef patchnum
set ver on
