{{ config(materialized='table') }}

with 
cte_match as (
	select 
	*
	from
	{{ ref('stg_matches') }} sm 
	where 1=1
	and sm.status = 'FullTime'
)

, cte_season_end as (
	select 
	sm.season_id 
	, case
		when sum(case when sm.matchweek = 38 then 1 else 0 end) = 10 
			then 1 
			else 0 
	end season_complete
	from {{ ref('stg_matches') }} sm 
	where sm.status = 'FullTime'
	group by 1
)

, cte_point as (
	select
	season_id ,
	match_id ,
	dth.team_key home_team_key ,
	home_team_id ,
	home_team ,
	home_score_final ,
	away_score_final ,
	dta.team_key away_team_key ,
	away_team_id ,
	away_team ,
	case
		when home_score_final > away_score_final then 3
		when home_score_final = away_score_final then 1
		else 0
	end home_team_points,
	case
		when home_score_final > away_score_final then 'W'
		when home_score_final = away_score_final then 'D'
		else 'L'
	end home_team_status,
	case
		when home_score_final > away_score_final then 0
		when home_score_final = away_score_final then 1
		else 3
	end away_team_points,
	case
		when home_score_final > away_score_final then 'L'
		when home_score_final = away_score_final then 'D'
		else 'W'
	end away_team_status,
	cte.loaded_at ,
	cte.created_at
	from cte_match cte
	left join {{ ref('dim_teams') }} dth
		on dth.team_id = cte.home_team_id
	left join {{ ref('dim_teams') }} dta
		on dta.team_id = cte.away_team_id
	order by match_id asc
)

, cte_team as (
	select distinct season_id, home_team_key team_key, home_team_id team_id, home_team team_name from cte_point
	union
	select distinct season_id, away_team_key team_key, away_team_id team_id, away_team team_name from cte_point
)

, cte_home_point as (
	select
	season_id ,
	home_team_key ,
	home_team_id ,
	home_team ,
	count(distinct match_id) total_home_games ,
	sum(case when home_team_status = 'W' then 1 else 0 end) home_win ,
	sum(case when home_team_status = 'D' then 1 else 0 end) home_draw ,
	sum(case when home_team_status = 'L' then 1 else 0 end) home_lose ,
	sum(home_team_points) total_home_points ,
	sum(home_score_final ) total_home_scores ,
	sum(away_score_final ) total_away_scores ,
	max(loaded_at) loaded_at ,
	max(created_at) created_at
	from cte_point 
	group by 1,2,3,4
)

, cte_away_point as (
	select
	season_id ,
	away_team_key ,
	away_team_id  ,
	away_team ,
	count(distinct match_id) total_away_games ,
	sum(case when away_team_status = 'W' then 1 else 0 end) away_win ,
	sum(case when away_team_status = 'D' then 1 else 0 end) away_draw ,
	sum(case when away_team_status = 'L' then 1 else 0 end) away_lose ,
	sum(away_team_points) total_away_points ,
	sum(away_score_final ) total_away_scores ,
	sum(home_score_final ) total_home_scores ,
	max(loaded_at) loaded_at ,
	max(created_at) created_at
	from cte_point 
	group by 1,2,3,4
)

, cte_table as (
	select
	t.season_id ,
	t.team_key ,
	t.team_id ,
	t.team_name ,
	coalesce(h.total_home_games, 0) + coalesce(a.total_away_games, 0) total_games ,
	coalesce(h.total_home_games, 0) total_home_games ,
	coalesce(h.total_home_points, 0) total_home_points ,
	coalesce(h.total_home_scores, 0) total_home_scores ,
	coalesce(h.total_away_scores, 0) total_home_against ,
	coalesce(h.total_home_scores, 0) - coalesce(h.total_away_scores, 0) home_goal_difference ,
	coalesce(h.home_win, 0) home_win ,
	coalesce(h.home_draw, 0) home_draw ,
	coalesce(h.home_lose, 0) home_lose ,
	coalesce(a.total_away_games, 0) total_away_games ,
	coalesce(a.total_away_points, 0) total_away_points ,
	coalesce(a.total_away_scores, 0) total_away_scores ,
	coalesce(a.total_home_scores, 0) total_away_against ,
	coalesce(a.total_away_scores, 0) - coalesce(a.total_home_scores, 0) away_goal_difference ,
	coalesce(a.away_win, 0) away_win ,
	coalesce(a.away_draw, 0) away_draw ,
	coalesce(a.away_lose, 0) away_lose ,
	coalesce(h.home_win, 0) + coalesce(a.away_win, 0) total_win ,
	coalesce(h.home_draw, 0) + coalesce(a.away_draw, 0) total_draw ,
	coalesce(h.home_lose, 0) + coalesce(a.away_lose, 0) total_lose ,
	coalesce(h.total_home_scores, 0) + coalesce(a.total_away_scores, 0) goal_scored ,
	coalesce(h.total_away_scores, 0) + coalesce(a.total_home_scores, 0) goal_against ,
	(coalesce(h.total_home_scores, 0) + coalesce(a.total_away_scores, 0)) - (coalesce(h.total_away_scores, 0) + coalesce(a.total_home_scores, 0)) goal_difference,
	coalesce(h.total_home_points, 0) + coalesce(a.total_away_points, 0) total_points ,
	s.season_complete ,
	coalesce(h.loaded_at, a.loaded_at) loaded_at
	from
	cte_team t
	full outer join cte_home_point h
		on h.season_id = t.season_id 
		and h.home_team_key = t.team_key 
	full outer join cte_away_point a
		on a.season_id  = t.season_id 
		and a.away_team_key = t.team_key 
	left join cte_season_end s
		on s.season_id = t.season_id
)

select 
*,
rank() over(partition by season_id order by season_id asc, total_points desc, goal_difference desc, goal_scored desc) pos_by_season,
row_number() over(partition by season_id order by season_id asc, total_points desc, goal_difference desc, goal_scored desc) position_order,
now() as created_at 
from cte_table
where  1=1
order by season_id asc, total_points desc, goal_difference desc, goal_scored desc