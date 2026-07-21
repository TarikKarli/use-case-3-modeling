with snapshot_data as (

    select
        customer_id,
        country,
        customer_segment,
        dbt_valid_from,
        dbt_valid_to,
        dbt_scd_id,

        row_number() over (
            partition by customer_id
            order by dbt_valid_from
        ) as customer_version_number

    from {{ ref('customer_snapshot') }}

),

historical_customers as (

    select
        cast(
            row_number() over (
                order by customer_id, dbt_valid_from
            )
            as bigint
        ) as customer_sk,

        customer_id,

        coalesce(
            country,
            'Unknown'
        ) as country,

        coalesce(
            customer_segment,
            'Unknown'
        ) as customer_segment,

        case
            when customer_version_number = 1
                then timestamp '1900-01-01 00:00:00'
            else dbt_valid_from
        end as valid_from,

        dbt_valid_to as valid_to,

        case
            when dbt_valid_to is null then true
            else false
        end as is_current,

        dbt_scd_id as customer_version_id

    from snapshot_data

),

unknown_customer as (

    select
        cast(-1 as bigint) as customer_sk,
        cast(null as bigint) as customer_id,
        cast('Unknown' as varchar) as country,
        cast('Unknown' as varchar) as customer_segment,
        timestamp '1900-01-01 00:00:00' as valid_from,
        cast(null as timestamp) as valid_to,
        true as is_current,
        cast('unknown_customer' as varchar) as customer_version_id

),

final as (

    select *
    from unknown_customer

    union all

    select *
    from historical_customers

)

select *
from final