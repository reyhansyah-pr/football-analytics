{{ config(materialized='table') }}

(select
t.season_id 
, t.team_name 
, 'Overall' performance
, t.total_games 
, t.total_win 
, t.total_draw 
, t.total_lose
, t.goal_scored
, t.goal_against
, t.goal_difference
, t.total_points
, now() as created_at
from
{{ ref('fact_standings') }} t)

union all

(select
t.season_id 
, t.team_name 
, 'Home' performance
, t.total_home_games 
, t.home_win 
, t.home_draw 
, t.home_lose 
, t.total_home_scores 
, t.total_home_against 
, t.home_goal_difference 
, t.total_home_points
, now() as created_at
from
{{ ref('fact_standings') }} t)

union all

(select
t.season_id 
, t.team_name 
, 'Away' performance
, t.total_away_games 
, t.away_win 
, t.away_draw 
, t.away_lose 
, t.total_away_scores 
, t.total_away_against 
, t.away_goal_difference 
, t.total_away_points
, now() as created_at
from
{{ ref('fact_standings') }} t)