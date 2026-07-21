with source_data as (

    select
        cast(
            try_cast(
                nullif(
                    trim(cast("Customer ID" as varchar)),
                    ''
                )
                as double
            )
            as bigint
        ) as customer_id,

        nullif(
            trim(cast("Country" as varchar)),
            ''
        ) as country,

        try_cast(
            nullif(
                trim(cast("InvoiceDate" as varchar)),
                ''
            )
            as timestamp
        ) as invoice_timestamp

    from {{ source('raw_retail', 'online_retail') }}

),

valid_customers as (

    select
        customer_id,
        country,
        invoice_timestamp

    from source_data

    where customer_id is not null

),

ranked_customers as (

    select
        customer_id,
        country,
        invoice_timestamp,

        row_number() over (
            partition by customer_id
            order by invoice_timestamp desc
        ) as customer_row_number

    from valid_customers

),

final as (

    select
        customer_id,

        coalesce(
            country,
            'Unknown'
        ) as country,

case
    when customer_id = 13085 then 'Premium'
    else 'Standard'
end as customer_segment
    from ranked_customers

    where customer_row_number = 1

)

select *
from final