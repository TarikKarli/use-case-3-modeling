with products as (

    select
        stock_code,
        product_name

    from {{ ref('stg_products') }}

),

final as (

    select
        cast(
            row_number() over (
                order by stock_code
            )
            as bigint
        ) as product_sk,

        stock_code,
        product_name

    from products

)

select *
from final