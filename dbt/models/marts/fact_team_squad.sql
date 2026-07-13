{{ config(materialized='table') }}

select
sts.season_id 
, sts.team_id 
, st.team_name 
, sts.player_id 
, sts.display_name player_name
, sts.position 
, sts.shirt_num
, current_date
, sts.birth_date
, ((date(current_date) - date(sts.birth_date)) / 365) age
, sts.joined_club 
, sts.nationality 
, sts.height_cm
, sts.weight_kg 
, sts.preferred_foot 
, sts.is_loan
, case when count(*) over(partition by sts.player_id, sts.season_id) > 1 then 1 else 0 end is_dupl
, now() as created_at
from
{{ ref('stg_team_squad') }} sts 
left join {{ ref('stg_teams') }} st 
	on st.team_id = sts.team_id 
	and st.season_id = sts.season_id 