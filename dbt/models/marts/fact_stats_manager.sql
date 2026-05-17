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
    case when away_score_final = 0 then 1 else 0 end as home_clean_sheet ,
	dta.team_key away_team_key ,
	sm.away_team ,
	ma.manager_name away_manager ,
    ma.incumbent_manager away_incumbent_manager ,
    ma.caretaker_manager away_caretaker_manager ,
	sm.away_score_final ,
    case when home_score_final = 0 then 1 else 0 end as away_clean_sheet ,
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
    end away_team_status
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
	where sm.status = 'FullTime'
)
, cte_manager_home_stats as (
	select 
	season_id ,
	home_manager ,
    home_incumbent_manager ,
    home_caretaker_manager ,
	home_team_key ,
	home_team ,
    count(*) total_home_matches ,
    sum(case when home_team_status = 'W' then 1 else 0 end) home_win ,
    sum(case when home_team_status = 'D' then 1 else 0 end) home_draw ,
    sum(case when home_team_status = 'L' then 1 else 0 end) home_lose ,
    sum(home_team_points) total_home_points ,
    sum(home_score_final ) total_home_scores ,
    sum(away_score_final ) total_home_conceded ,
    sum(home_clean_sheet) total_home_clean_sheet
	from cte_matches
	group by 1,2,3,4,5,6
)
, cte_manager_away_stats as (
	select 
	season_id ,
	away_manager ,
    away_incumbent_manager ,
    away_caretaker_manager ,
	away_team_key ,
	away_team ,
    count(*) total_away_matches ,
    sum(case when away_team_status = 'W' then 1 else 0 end) away_win ,
    sum(case when away_team_status = 'D' then 1 else 0 end) away_draw ,
    sum(case when away_team_status = 'L' then 1 else 0 end) away_lose ,
    sum(away_team_points) total_away_points ,
    sum(away_score_final ) total_away_scores ,
    sum(home_score_final ) total_away_conceded ,
    sum(away_clean_sheet) total_away_clean_sheet
	from cte_matches
	group by 1,2,3,4,5,6
)
, cte_manager_full as (
	select
	coalesce(ch.season_id , ca.season_id ) season_id ,
	coalesce(ch.home_manager , ca.away_manager) manager ,
	coalesce(ch.home_team_key , ca.away_team_key) team_key ,
	coalesce(ch.home_team , ca.away_team) team_name ,
    coalesce(ch.home_incumbent_manager , ca.away_incumbent_manager) incumbent_manager ,
    coalesce(ch.home_caretaker_manager , ca.away_caretaker_manager) caretaker_manager ,
    coalesce(ch.total_home_matches , 0) total_home_matches ,
	coalesce(ch.home_win , 0) home_win ,
	coalesce(ch.home_draw , 0) home_draw ,
	coalesce(ch.home_lose , 0) home_lose ,
	coalesce(ch.total_home_points , 0) total_home_points ,
	coalesce(ch.total_home_scores , 0) total_home_scores ,
	coalesce(ch.total_home_conceded , 0) total_home_conceded ,
    coalesce(ch.total_home_clean_sheet , 0) total_home_clean_sheet ,
    coalesce(ca.total_away_matches , 0) total_away_matches ,
	coalesce(ca.away_win , 0) away_win ,
	coalesce(ca.away_draw , 0) away_draw ,
	coalesce(ca.away_lose , 0) away_lose ,
	coalesce(ca.total_away_points , 0) total_away_points ,
	coalesce(ca.total_away_scores , 0) total_away_scores ,
	coalesce(ca.total_away_conceded , 0) total_away_conceded ,
    coalesce(ca.total_away_clean_sheet , 0) total_away_clean_sheet ,
    coalesce(ch.total_home_matches , 0) + coalesce(ca.total_away_matches , 0) total_matches ,
	coalesce(ch.home_win , 0) + coalesce(ca.away_win , 0) total_win ,
	coalesce(ch.home_draw , 0) + coalesce(ca.away_draw , 0) total_draw ,
    coalesce(ch.home_lose , 0) + coalesce(ca.away_lose , 0) total_lose ,
    coalesce(ch.total_home_points , 0) + coalesce(ca.total_away_points , 0) total_points ,
    coalesce(ch.total_home_scores , 0) + coalesce(ca.total_away_scores , 0) total_scores ,
    coalesce(ch.total_home_conceded , 0) + coalesce(ca.total_away_conceded , 0) total_conceded ,
    coalesce(ch.total_home_clean_sheet , 0) + coalesce(ca.total_away_clean_sheet , 0) total_clean_sheet ,
	now() as created_at
	from 
	cte_manager_home_stats ch
	full outer join cte_manager_away_stats ca
		on ca.season_id = ch.season_id
		and ca.away_manager = ch.home_manager 
        and ca.away_team_key = ch.home_team_key
)
select * from cte_manager_full 