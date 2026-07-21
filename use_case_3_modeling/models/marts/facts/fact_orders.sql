with orders as (

    select
        invoice_no,
        stock_code,
        product_name,
        quantity,
        invoice_timestamp,
        unit_price,
        customer_id,
        country,
        line_amount,
        is_cancellation_invoice,
        is_negative_quantity,
        is_return_or_adjustment,
        is_non_positive_price

    from {{ ref('stg_orders') }}

),

joined_dimensions as (

    select
        cast(
            row_number() over (
    order by
        orders.invoice_timestamp,
        orders.invoice_no,
        orders.stock_code,
        coalesce(orders.customer_id, -1),
        orders.quantity,
        orders.unit_price,
        orders.product_name,
        orders.country
)
            as bigint
        ) as order_line_sk,

        orders.invoice_no,

        coalesce(
            customers.customer_sk,
            -1
        ) as customer_sk,

        products.product_sk,
        dates.date_sk,

        orders.invoice_timestamp,
        orders.quantity,
        orders.unit_price,
        orders.line_amount,

        orders.is_cancellation_invoice,
        orders.is_negative_quantity,
        orders.is_return_or_adjustment,
        orders.is_non_positive_price

    from orders

    left join {{ ref('dim_product') }} as products
        on orders.stock_code = products.stock_code

    left join {{ ref('dim_date') }} as dates
        on cast(orders.invoice_timestamp as date)
            = dates.full_date

    left join {{ ref('dim_customer') }} as customers
        on orders.customer_id = customers.customer_id

        and orders.invoice_timestamp >= customers.valid_from

        and orders.invoice_timestamp < coalesce(
            customers.valid_to,
            timestamp '9999-12-31 00:00:00'
        )

)

select *
from joined_dimensions