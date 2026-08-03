{{ config(materialized='table') }}

with cte_total_club as (
	select
	season_id
	, manager_name
	, team_name 
	, count(distinct kickoff_date) total_matches
	, sum(points) total_points
	, sum(case when result_status = 'W' then 1 else 0 end) total_win
	from
	{{ ref('fact_result_gameweek') }}
	where home_away_category = 'Overall'
	group by 1,2,3
)
, cte_total_overall as (
	select 
	season_id
	, manager_name
	, team_name
	, total_matches
	, total_points
	, total_win
	from cte_total_club
	union all
	select distinct
	season_id
	, manager_name
	, 'All Club' team_name
	, sum(total_matches) over(partition by season_id, manager_name) total_matches
	, sum(total_points) over(partition by season_id, manager_name) total_points
	, sum(total_win) over(partition by season_id, manager_name) total_win
	from
	cte_total_club
) 
select 
* 
, total_points/total_matches::numeric as points_per_match
, now() as created_at
from cte_total_overall
order by 2,1,3