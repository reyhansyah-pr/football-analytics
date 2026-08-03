{{ config(materialized='table') }}

with cte_manager as (
    select
    *
	, case
		when until_date = '9999-12-31' then now()::date else until_date 
	end  until_date_current
    from
    {{ ref('stg_manager') }}
)

, cte_season_manager as (
	select
	sm.manager_name
	, sm.club_key team_key
	, sm.club_name team_name
    , dt.abbreviation team_abbreviation
    , dt.short_name team_short_name
	, sm.from_date 
	, sm.until_date 
	, ds.season_id
	, ds.season_start_date
	, ds.season_end_date
	, 	case 
			when sm.from_date <= ds.season_start_date then ds.season_start_date else sm.from_date 
		end from_season_date
	,	case 
			when 	
				sm.until_date_current >= ds.season_end_date then ds.season_end_date else sm.until_date_current
		end until_season_date
	from
	cte_manager sm 
	inner join {{ ref('dim_season') }} ds 
		on ds.season_start_date between sm.from_date and sm.until_date 
		or sm.from_date between ds.season_start_date and ds.season_end_date
    inner join {{ ref('dim_teams') }} dt
        on dt.team_key = sm.club_key
	where 1=1
	and season_id is not null
	order by club_name, from_date , season_id
)
select
*
, until_season_date - from_season_date as duration_days
, now() as created_at
from
cte_season_manager