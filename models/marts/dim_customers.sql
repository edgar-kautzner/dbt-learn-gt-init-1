with customers as (

select * from {{ ref('stg__jaffle_shop__customers' ) }}

),

orders as (

select * from {{ ref('stg__jaffle_shop__orders') }}

),

payments as (

select * from {{ ref('stg_stripe__payments') }}

),


customer_orders as (

    select
        customer_id,

        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date,
        count(order_id) as number_of_orders

    from orders

    group by 1

),

order_payments as (

    select
        order_id,
        sum(payment_amount) as total_order_amount
    from payments
    -- where status = 'success' -- Un-comment if payments contains failed/refunded attempts
    group by order_id

),


customer_payments as (

select 
        o.customer_id,
        sum(p.total_order_amount) as lifetime_value
    from orders o
    left join order_payments p on o.order_id = p.order_id
    group by o.customer_id
    
),



final as (

    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customer_orders.first_order_date,
        customer_orders.most_recent_order_date,
        coalesce(customer_orders.number_of_orders, 0) as number_of_orders,
        coalesce(lifetime_value,0) as lifetime_value,

    from customers

    left join customer_orders using (customer_id)
    left join customer_payments using (customer_id)
)

select * from final