{{ config(materialized='table') }}

WITH cte_home_away AS (
    SELECT
        season_id,
        kickoff_date,
        matchweek,
        status,
        'Home' home_away_category,
        'Home' home_away,
        home_team team_name,
        home_manager manager_name,
        away_team opponent_name,
        home_score_final goal_scored,
        away_score_final goal_against,
        home_team_status result_status
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
        away_team team_name,
        away_manager manager_name,
        home_team opponent_name,
        away_score_final goal_scored,
        home_score_final goal_against,
        away_team_status
    FROM
        {{ ref('fact_matches') }}
),
cte_overall as (
    SELECT
        season_id,
        kickoff_date,
        matchweek,
        status,
        'Overall' home_away_category,
        home_away,
        team_name,
        manager_name,
        opponent_name,
        goal_scored,
        goal_against,
        result_status
    FROM
        cte_home_away
),
cte_union as (
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
SELECT
*
FROM
cte_union
order by
season_id,
team_name,
kickoff_date