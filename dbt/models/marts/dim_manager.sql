{{ config(materialized='table') }}

select 
distinct 
manager_name ,
nationality ,
now() as created_at
from {{ ref('stg_manager') }}