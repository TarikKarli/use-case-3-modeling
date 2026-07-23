with fact_total as (

    select
        coalesce(
            sum(line_amount),
            0
        ) as fact_net_total

    from {{ ref('fact_orders') }}

),

mart_total as (

    select
        coalesce(
            sum(net_sales_amount),
            0
        ) as mart_net_total

    from {{ ref('mart_monthly_sales') }}

),

comparison as (

    select
        fact_total.fact_net_total,
        mart_total.mart_net_total,

        fact_total.fact_net_total
        - mart_total.mart_net_total
            as difference

    from fact_total

    cross join mart_total

)

select
    fact_net_total,
    mart_net_total,
    difference

from comparison

where abs(difference) > 0.01
