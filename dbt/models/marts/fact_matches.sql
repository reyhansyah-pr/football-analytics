{{ config(materialized='table') }}

with
cte_matches as (
	select distinct
	sm.season_id ,
	sm.matchweek ,
	sm.kickoff_date ,
	sm.status ,
	sm.result_type ,
	dth.team_key home_team_key ,
	sm.home_team ,
	mh.manager_name home_manager ,
    mh.incumbent_manager home_incumbent_manager ,
    mh.caretaker_manager home_caretaker_manager ,
	sm.home_score_final ,
	dta.team_key away_team_key ,
	sm.away_team ,
	ma.manager_name away_manager ,
    ma.incumbent_manager away_incumbent_manager ,
    ma.caretaker_manager away_caretaker_manager ,
	sm.away_score_final ,
    case
            when home_score_final > away_score_final then 3
            when home_score_final = away_score_final then 1
            else 0
    end home_team_points ,
    case
            when home_score_final > away_score_final then 'W'
            when home_score_final = away_score_final then 'D'
            else 'L'
    end home_team_status ,
    case
            when home_score_final > away_score_final then 0
            when home_score_final = away_score_final then 1
            else 3
    end away_team_points ,
    case
            when home_score_final > away_score_final then 'L'
            when home_score_final = away_score_final then 'D'
            else 'W'
    end away_team_status ,
	now() as created_at
	from 
	{{ ref('stg_matches') }} sm 
	left join {{ ref('dim_teams') }} dth
		on dth.team_id = sm.home_team_id
	left join {{ ref('stg_manager') }} mh 
		on mh.club_key = dth.team_key 
		and sm.kickoff_date >= mh.from_date and sm.kickoff_date <= mh.until_date 
	left join {{ ref('dim_teams') }} dta 
		on dta.team_id = sm.away_team_id 
	left join {{ ref('stg_manager') }} ma
		on ma.club_key = dta.team_key 
		and sm.kickoff_date >= ma.from_date and sm.kickoff_date <= ma.until_date
)
select * from cte_matches