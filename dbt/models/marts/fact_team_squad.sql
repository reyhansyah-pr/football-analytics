{{ config(materialized='table') }}

with cte_player_squad as (
    select
        sts.season_id 
        , sts.team_id 
        , st.team_name 
        , sts.player_id 
        , sts.display_name as player_name
        , sts.position 
        , sts.shirt_num
        , sts.birth_date
        , sts.joined_club 
        , sts.nationality 
        , sts.height_cm
        , sts.weight_kg 
        , sts.preferred_foot 
        , sts.is_loan
        , extract(year from age(current_date, sts.birth_date))::int as current_age
        , extract(year from age(ds.season_start_date, sts.birth_date))::int as age_season_start
    from {{ ref('stg_team_squad') }} sts 
    left join {{ ref('stg_teams') }} st 
        on st.team_id = sts.team_id 
        and st.season_id = sts.season_id
    left join {{ ref('dim_season') }} ds 
        on ds.season_id = sts.season_id
)

, cte_age_group as (
    select
        *
        , case
            when age_season_start < 18 then 'Under 18'
            when age_season_start between 18 and 25 then '18-25'
            when age_season_start between 26 and 30 then '26-30'
            else '31++'
        end as age_group
    from cte_player_squad
)
select
    season_id 
    , team_id 
    , team_name 
    , player_id 
    , player_name
    , position 
    , shirt_num
    , current_date
    , birth_date
    , current_age
    , age_season_start as age
    , age_group
    , case
        when height_cm is null then avg(height_cm) over(partition by age_group, season_id)::int
        else height_cm
    end as height_cm_handling
    , case
        when weight_kg is null then avg(weight_kg) over(partition by age_group, season_id)::int
        else weight_kg
    end as weight_kg_handling
    , joined_club 
    , nationality 
    , height_cm
    , weight_kg 
    , preferred_foot 
    , is_loan
    , case when count(*) over(partition by player_id, season_id) > 1 then 1 else 0 end as is_dupl
    , now() as created_at
from cte_age_group