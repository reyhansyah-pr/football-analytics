with source as (
    select * from {{ source('raw_data', 'raw_players') }}
)

, dedup as (
    select
        *,
        rank() over(partition by team_id, season_id order by loaded_at desc) as rn
    from source
)

, renamed as (
    select
        md5(player_id::varchar||season_id::varchar||team_id::varchar) as player_season_team_key,
        season_id::varchar as season_id,
        team_id::varchar as team_id,
        player_id::varchar as player_id,
        display_name::varchar as display_name,
        first_name::varchar as first_name,
        last_name::varchar as last_name,
        position::varchar as position,
        shirt_num::int as shirt_num,
        nullif(birth_date, 'Unknown')::date birth_date,
        joined_club::varchar as joined_club,
        nationality::varchar as nationality,
        height_cm::float as height_cm,
        weight_kg::float as weight_kg,
        preferred_foot::varchar as preferred_foot,
        is_loan::int as is_loan,
        loaded_at::timestamp as loaded_at,
        now() as created_at
    from dedup
    where rn = 1
)
select * from renamed