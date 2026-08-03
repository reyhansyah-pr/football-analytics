{{ config(materialized='table') }}

with cte_result as (
	select
	season_id 
	, manager_name
	, team_name
	, home_away_category
	, case when opponent_position between 1 and 10 then 'vs Top 10' else 'vs Bottom 10' end opponent_position
	, sum(points) total_points
	, count(distinct kickoff_date) total_match
	from
	{{ ref('fact_result_gameweek')}}
	group by 1,2,3,4,5
)
, cte_points as (
	select
	a.season_id
	, a.manager_name
	, a.team_name
	, a.home_away_category
	, a.opponent_position 
	, sum(a.total_match) total_match
	, sum(a.total_points) total_points
	from
	cte_result a
	left join {{ ref('fact_manager_total_match') }} b
		on b.manager_name = a.manager_name
		and b.season_id = a.season_id
		and b.team_name = 'All Club'
	group by 1,2,3,4,5
)
, cte_points_overall as (
	select
	*
	, sum(total_match) over(partition by season_id, team_name, manager_name, home_away_category) total_match_overall
	, sum(total_points) over(partition by season_id, team_name, manager_name, home_away_category) total_points_overall
	from
	cte_points
)
select
*
, now() as created_at
from
cte_points_overall