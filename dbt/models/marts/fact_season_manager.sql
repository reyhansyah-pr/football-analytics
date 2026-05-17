{{ config(materialized='table') }}

with cte_manager as (
    select
    * ,
	case
		when until_date = '9999-12-31' then now()::date else until_date 
	end  until_date_current
    from
    {{ ref('stg_manager') }} 
)

, cte_matches as (
    (
		select
		distinct
		season_id ,
		home_team_key team_key,
		home_team team_name,
		home_manager manager
		from
		{{ ref('fact_matches') }}
	)

    union

    (
		select
		distinct
		season_id ,
		away_team_key ,
		away_team ,
		away_manager manager
		from
		{{ ref('fact_matches') }}
	)
)

, cte_manager_season as (
	select
	mt.season_id ,
	ds.season_start_date ,
	ds.season_end_date ,
	mt.team_key ,
	mt.team_name ,
	mt.manager ,
	mn.from_date ,
	mn.until_date ,
	mn.until_date_current ,
	case 
		when mn.from_date <= ds.season_start_date then ds.season_start_date else mn.from_date 
	end from_season_date ,
	case 
		when 	
			mn.until_date_current >= ds.season_end_date then ds.season_end_date else mn.until_date_current
	end until_season_date ,
	mn.incumbent_manager ,
	mn.caretaker_manager 
	from 
	cte_matches mt
	left join marts.dim_season ds 
		on ds.season_id = mt.season_id 
	left join cte_manager mn
		on mn.manager_name = mt.manager 
		and mn.club_key = mt.team_key 	
		and (ds.season_start_date between mn.from_date and mn.until_date or mn.from_date between ds.season_start_date and ds.season_end_date)
)
select
* ,
until_season_date - from_season_date as duration_days ,
now() as created_at
from cte_manager_season