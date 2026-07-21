with source_data as (

    select
        nullif(
            trim(cast("Invoice" as varchar)),
            ''
        ) as invoice_no,

        nullif(
            trim(cast("StockCode" as varchar)),
            ''
        ) as stock_code,

        nullif(
            trim(cast("Description" as varchar)),
            ''
        ) as product_name,

        try_cast(
            nullif(trim(cast("Quantity" as varchar)), '')
            as integer
        ) as quantity,

        try_cast(
            nullif(trim(cast("InvoiceDate" as varchar)), '')
            as timestamp
        ) as invoice_timestamp,

        try_cast(
            nullif(trim(cast("Price" as varchar)), '')
            as decimal(18, 2)
        ) as unit_price,

        cast(
            try_cast(
                nullif(trim(cast("Customer ID" as varchar)), '')
                as double
            )
            as bigint
        ) as customer_id,

        nullif(
            trim(cast("Country" as varchar)),
            ''
        ) as country

    from {{ source('raw_retail', 'online_retail') }}

),

enriched as (

    select
        invoice_no,
        stock_code,
        product_name,
        quantity,
        invoice_timestamp,
        unit_price,
        customer_id,
        country,

        cast(
            quantity * unit_price
            as decimal(18, 2)
        ) as line_amount,

        coalesce(
            upper(invoice_no) like 'C%',
            false
        ) as is_cancellation_invoice,

        coalesce(
            quantity < 0,
            false
        ) as is_negative_quantity,

        coalesce(
            upper(invoice_no) like 'C%',
            false
        )
        or coalesce(
            quantity < 0,
            false
        ) as is_return_or_adjustment,

        coalesce(
            unit_price <= 0,
            false
        ) as is_non_positive_price,

        row_number() over (
            partition by
                invoice_no,
                stock_code,
                product_name,
                quantity,
                invoice_timestamp,
                unit_price,
                customer_id,
                country
            order by invoice_timestamp
        ) as duplicate_row_number

    from source_data

),

final as (

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

    from enriched

    where duplicate_row_number = 1

)

select *
from final