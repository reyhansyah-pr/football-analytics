{{ config(materialized='table') }}

with
  performance AS (
    select
      t.season_id,
      'Champions Points' points_category,
      t.total_points,
      1 order_col
    from
      {{ ref('fact_standings') }} t
    where t.position_order = 1
    
    union all
    
    select
      t.season_id,
      'Top 4 Points' points_category,
      t.total_points,
      2 order_col
    from
      {{ ref('fact_standings') }} t
    where t.position_order = 4

    union all
    
    select
      t.season_id,
      'Relegation Points' points_category,
      t.total_points,
      3 order_col
    from
      {{ ref('fact_standings') }} t
    where t.position_order = 18
)
select
season_id,
points_category,
total_points,
lag(total_points) over(partition by points_category order by season_id asc) total_points_prev,
round(total_points::numeric / lag(total_points) over(partition by points_category order by season_id asc)::numeric - 1,4) points_prev_perc,
now() as created_at
from
performance
order by season_id asc, order_col asc