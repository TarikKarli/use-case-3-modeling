with source_data as (

    select
        nullif(
            trim(cast("StockCode" as varchar)),
            ''
        ) as stock_code,

        nullif(
            trim(cast("Description" as varchar)),
            ''
        ) as product_name,

        try_cast(
            nullif(
                trim(cast("InvoiceDate" as varchar)),
                ''
            )
            as timestamp
        ) as invoice_timestamp

    from {{ source('raw_retail', 'online_retail') }}

),

valid_products as (

    select
        stock_code,
        product_name,
        invoice_timestamp

    from source_data

    where stock_code is not null

),

ranked_products as (

    select
        stock_code,
        product_name,
        invoice_timestamp,

        row_number() over (
            partition by stock_code

            order by
                case
                    when product_name is not null then 0
                    else 1
                end,
                invoice_timestamp desc
        ) as product_row_number

    from valid_products

),

final as (

    select
        stock_code,

        coalesce(
            product_name,
            'Unknown Product'
        ) as product_name

    from ranked_products

    where product_row_number = 1

)

select *
from final