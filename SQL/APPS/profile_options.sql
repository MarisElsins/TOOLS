undef level_id
undef profile_option
set pages 50000 lines 240 tab off
column USER_PROFILE_OPTION_NAME for a80
column PROFILE_OPTION_VALUE for a45
column PROFILE_OPTION_NAME for a40
select O.user_profile_option_name,
       O.profile_option_id,
       O.Profile_option_name,
       v.level_id,
       decode(to_char(v.level_id),
               '10001', 'SITE',
               '10002', 'APP',
               '10003', 'RESP',
               '10005', 'SERVER',
               '10006', 'ORG',
               '10004', 'USER', '???') "LEVEL",
       V.LEVEL_VALUE,
       v.profile_option_value
  from apps.fnd_profile_options_vl O, apps.fnd_profile_option_values V
 where 1 = 1
   and V.profile_option_id = O.profile_option_id
   --and O.profile_option_id = 5924
   and O.profile_option_id in (select profile_option_id from apps.fnd_profile_options_vl where upper(user_profile_option_name) like upper('%&profile_option%'))
   and level_id<=&level_id
   order by level_id desc, user_profile_option_name asc;
