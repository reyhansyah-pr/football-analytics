{{ config(materialized='table') }}

select 
distinct 
season_id ,
to_date(concat(season_id, '-07-01'), 'yyyy-mm-dd') as season_start_date ,
to_date(concat(season_id::int + 1, '-06-30'), 'yyyy-mm-dd') as season_end_date ,
now() as created_at
from {{ ref('stg_matches') }}