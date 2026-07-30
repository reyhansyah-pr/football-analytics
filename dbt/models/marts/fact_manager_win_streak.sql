{{ config(materialized='table') }}

WITH cte_base_matches AS (
    SELECT
        season_id,
        kickoff_date,
        matchweek,
        home_away_category,
        team_name,
        opponent_name,
        manager_name,
        result_status,
        LAG(manager_name) OVER (
            PARTITION BY team_name, home_away_category 
            ORDER BY kickoff_date ASC
        ) AS prev_manager
    FROM {{ ref('fact_result_gameweek') }}
)

, cte_streak_groups AS (
    SELECT
        *,
        case
        	when result_status = 'W'	then
        SUM(
            CASE 
                WHEN result_status != 'W' 
                  OR prev_manager IS NULL 
                  OR manager_name != prev_manager 
                THEN 1 
                ELSE 0 
            END
        ) OVER (
            PARTITION BY team_name, home_away_category 
            ORDER BY kickoff_date ASC
        ) end AS streak_grp,  
        case
        	when result_status = 'W' then
        SUM(
            CASE 
                WHEN result_status != 'W' 
                  OR prev_manager IS NULL 
                  OR manager_name != prev_manager 
                THEN 1 
                ELSE 0 
            END
        ) OVER (
            PARTITION BY team_name, home_away_category, season_id 
            ORDER BY kickoff_date ASC
        ) end AS streak_grp_season
    FROM cte_base_matches
)

, cte_win_streak AS (
    SELECT
        season_id,
        kickoff_date,
        matchweek,
        home_away_category,
        team_name,
        opponent_name,
        manager_name,
        result_status,
        streak_grp,
        streak_grp_season,
        CASE 
            WHEN result_status = 'W' THEN 
                ROW_NUMBER() OVER (
                    PARTITION BY team_name, home_away_category, streak_grp 
                    ORDER BY kickoff_date ASC
                )
            ELSE 0 
        END AS current_win_streak,
        CASE 
            WHEN result_status = 'W' THEN 
                ROW_NUMBER() OVER (
                    PARTITION BY team_name, home_away_category, season_id, streak_grp_season 
                    ORDER BY kickoff_date ASC
                )
            ELSE 0 
        END AS current_win_streak_season,
        MIN(kickoff_date) OVER (PARTITION BY team_name, home_away_category, streak_grp) AS start_streak,
        MAX(kickoff_date) OVER (PARTITION BY team_name, home_away_category, streak_grp) AS end_streak,
        MIN(kickoff_date) OVER (PARTITION BY team_name, home_away_category, season_id, streak_grp_season) AS start_streak_season,
        MAX(kickoff_date) OVER (PARTITION BY team_name, home_away_category, season_id, streak_grp_season) AS end_streak_season
    FROM cte_streak_groups
)

, cte_final AS (
    SELECT
        *,
        CASE WHEN result_status = 'W' THEN end_streak - start_streak END AS streak_duration,
        CASE WHEN result_status = 'W' THEN end_streak_season - start_streak_season END AS streak_duration_season
    FROM cte_win_streak
)
select
*
, now() as created_at
from
cte_final
order by season_id, team_name, kickoff_date 