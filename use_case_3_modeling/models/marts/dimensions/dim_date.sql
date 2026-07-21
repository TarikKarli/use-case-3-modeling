with date_bounds as (

    select
        cast(
            min(invoice_timestamp)
            as date
        ) as minimum_date,

        cast(
            max(invoice_timestamp)
            as date
        ) as maximum_date

    from {{ ref('stg_orders') }}

    where invoice_timestamp is not null

),

date_spine as (

    select
        cast(generated_date as date) as full_date

    from date_bounds

    cross join generate_series(
        cast(minimum_date as timestamp),
        cast(maximum_date as timestamp),
        interval 1 day
    ) as generated_dates(generated_date)

),

final as (

    select
        cast(
            strftime(full_date, '%Y%m%d')
            as integer
        ) as date_sk,

        full_date,

        cast(
            extract(year from full_date)
            as smallint
        ) as year,

        cast(
            extract(quarter from full_date)
            as smallint
        ) as quarter,

        cast(
            extract(month from full_date)
            as smallint
        ) as month_number,

        monthname(full_date) as month_name,

        cast(
            extract(week from full_date)
            as smallint
        ) as week_number,

        cast(
            extract(day from full_date)
            as smallint
        ) as day_of_month,

        dayname(full_date) as day_name,

        case
            when strftime(full_date, '%w') in ('0', '6')
                then true
            else false
        end as is_weekend

    from date_spine

)

select *
from final

order by full_date
