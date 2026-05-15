{{ config(materialized='table') }}

with 
cte_teams as (
    select * from {{ ref('stg_teams') }}
)

, cte_dedup as (
    select
        *,
        row_number() over(partition by team_id order by season_id desc) as rn
    from cte_teams
)

, cte_transform as (
    select
        md5(lower(team_name)) as team_key,
        team_id,
        team_name,
        short_name,
        abbreviation,
        city,
        loaded_at,
        created_at
    from cte_dedup
    where rn = 1
)

select * from cte_transform