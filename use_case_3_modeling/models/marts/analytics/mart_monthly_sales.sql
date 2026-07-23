{{ config(materialized='table') }}

with fact_orders as (

    select
        invoice_no,
        customer_sk,
        product_sk,
        date_sk,
        quantity,
        line_amount,
        is_cancellation_invoice,
        is_return_or_adjustment

    from {{ ref('fact_orders') }}

),

dates as (

    select
        date_sk,
        full_date,
        year,
        month_number,
        month_name

    from {{ ref('dim_date') }}

),

customers as (

    select
        customer_sk,
        country

    from {{ ref('dim_customer') }}

),

enriched_orders as (

    select
        cast(
            date_trunc('month', dates.full_date)
            as date
        ) as month_start_date,

        dates.year,
        dates.month_number,
        dates.month_name,

        coalesce(
            customers.country,
            'Unknown'
        ) as country,

        fact_orders.invoice_no,
        fact_orders.customer_sk,
        fact_orders.product_sk,
        fact_orders.quantity,
        fact_orders.line_amount,
        fact_orders.is_cancellation_invoice,
        fact_orders.is_return_or_adjustment

    from fact_orders

    inner join dates
        on fact_orders.date_sk = dates.date_sk

    inner join customers
        on fact_orders.customer_sk = customers.customer_sk

),

monthly_sales as (

    select
        month_start_date,
        year,
        month_number,
        month_name,
        country,

        count(*) as order_line_count,

        count(
            distinct invoice_no
        ) as invoice_count,

        count(
            distinct product_sk
        ) as distinct_product_count,

        count(
            distinct case
                when customer_sk <> -1 then customer_sk
            end
        ) as known_customer_count,

        count(
            distinct case
                when is_cancellation_invoice then invoice_no
            end
        ) as cancellation_invoice_count,

        sum(
            case
                when quantity > 0 then quantity
                else 0
            end
        ) as sold_quantity,

        abs(
            sum(
                case
                    when quantity < 0 then quantity
                    else 0
                end
            )
        ) as returned_or_adjusted_quantity,

        sum(
            case
                when line_amount > 0
                     and is_return_or_adjustment = false
                    then line_amount
                else 0
            end
        ) as gross_sales_amount,

        sum(
            case
                when is_return_or_adjustment = true
                     or line_amount < 0
                    then line_amount
                else 0
            end
        ) as return_adjustment_amount,

        sum(
            line_amount
        ) as net_sales_amount

    from enriched_orders

    group by
        month_start_date,
        year,
        month_number,
        month_name,
        country

),

final as (

    select
        md5(
            cast(month_start_date as varchar)
            || '|'
            || country
        ) as monthly_sales_sk,

        month_start_date,
        year,
        month_number,
        month_name,
        country,
        order_line_count,
        invoice_count,
        distinct_product_count,
        known_customer_count,
        cancellation_invoice_count,
        sold_quantity,
        returned_or_adjusted_quantity,
        gross_sales_amount,
        return_adjustment_amount,
        net_sales_amount

    from monthly_sales

)

select *
from final