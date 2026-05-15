with source as (
    select * from {{ source('raw_data', 'raw_managers') }}
)

, dedup as (
    select
        *,
        row_number() over(partition by club, manager_name, from_date order by loaded_at desc) as rn
    from source
)

, cte_transform as (
    select
        REGEXP_REPLACE(manager_name, '[†§‡]', '', 'g')::varchar as manager_name,
        nationality::varchar as nationality,
        REGEXP_REPLACE(club, '[&]', 'and', 'g')::varchar as club_name,
        to_date(from_date, 'DD Month YYYY')::date from_date,
		case
			when lower(until_date) like '%present%' then '12-31-9999'::date
			else to_date(until_date, 'DD Month YYYY')::date
		end until_date,
        case
            when (manager_name like '%†%' or manager_name like '%§%') then 1
            else 0
        end incumbent_manager,
        case
            when manager_name like '%‡%' then 1 
            else 0
        end caretaker_manager,
        loaded_at::timestamp as loaded_at,
        now() as created_at
    from dedup
    where rn = 1
)
select 
md5(lower(club_name)::varchar) as club_key,
* 
from cte_transform