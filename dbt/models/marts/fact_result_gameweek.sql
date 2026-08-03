{{ config(materialized='table') }}

WITH cte_home_away AS (
    SELECT
        season_id,
        kickoff_date,
        matchweek,
        status,
        'Home' home_away_category,
        'Home' home_away,
        home_team_key team_key,
        home_team team_name,
        home_manager manager_name,
        away_team_key opponent_key,
        away_team opponent_name,
        home_score_final goal_scored,
        away_score_final goal_against,
        home_clean_sheet clean_sheet,
        home_team_status result_status,
        home_team_points points
    FROM
        {{ ref('fact_matches') }}
    UNION ALL
    SELECT
        season_id,
        kickoff_date,
        matchweek,
        status,
        'Away' home_away_category,
        'Away' home_away,
        away_team_key team_key,
        away_team team_name,
        away_manager manager_name,
        home_team_key opponent_key,
        home_team opponent_name,
        away_score_final goal_scored,
        home_score_final goal_against,
        away_clean_sheet clean_sheet,
        away_team_status,
        away_team_points points
    FROM
        {{ ref('fact_matches') }}
)

, cte_overall as (
    SELECT
        season_id,
        kickoff_date,
        matchweek,
        status,
        'Overall' home_away_category,
        home_away,
        team_key,
        team_name,
        manager_name,
        opponent_key,
        opponent_name,
        goal_scored,
        goal_against,
        clean_sheet,
        result_status,
        points
    FROM
        cte_home_away
)

, cte_union as (
    SELECT
        *
    FROM
        cte_home_away
    UNION ALL
    SELECT
        *
    FROM
        cte_overall
)

, cte_standings as (
	select
	distinct
	season_id
	, t.team_key 
	, team_name
	, t.pos_by_season 
	from
	{{ ref('fact_standings') }} t 
	order by 1,4
)

, cte_results_standings as (
	select
	cu.season_id
    , kickoff_date
    , matchweek
    , status
	, home_away_category
    , home_away
    , cu.team_key
    , cu.team_name
    , cu.manager_name
    , cs.pos_by_season team_position
    , cu.opponent_key
    , cu.opponent_name
    , cs2.pos_by_season opponent_position
    , cu.goal_scored
    , cu.goal_against
    , cu.clean_sheet
    , cu.result_status
    , cu.points
	from
	cte_union cu 
	left join cte_standings cs
		on cs.team_key = cu.team_key   
        and cs.season_id = cu.season_id
	left join cte_standings cs2
		on cs2.team_key = cu.opponent_key  
        and cs2.season_id = cu.season_id
)
SELECT
*
, now() as created_at
FROM
cte_results_standings
order by
season_id,
team_name,
kickoff_date