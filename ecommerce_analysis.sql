create database ecommerce_analysis;
use ecommerce_analysis;
-- customers table
create table customers(
customer_id int primary key,
customer_name varchar(50),
gender varchar(15),
age int,
city varchar(20),
state varchar(30),
signup_date datetime,
customer_segment varchar(20),
email varchar(50)
);

-- products
create table products(
product_id int primary key,
product_name varchar(40),
category varchar(30),
unit_price decimal(10,2),
brand varchar(30),
stock_quantity int
);

-- orders
create table orders(
order_id int primary key,
customer_id int,
order_date datetime,
order_status varchar(40),
payment_method varchar(40),
sales_channel varchar(40),
shipping_type varchar(40),
discount_pct decimal(5,2),
shipping_fee decimal(10,2),
constraint fk_customerid foreign key(customer_id) references customers(customer_id)
);

-- payments table
create table payments(
payment_id int primary key,
order_id int,
payment_date datetime,
payment_method varchar(40),
payment_status varchar(40),
transaction_amount decimal(10,2),
constraint fk_orderid1 foreign key(order_id) references orders(order_id)
);

-- order_items table
create table order_items(
order_item_id int primary key,
order_id int,
product_id int,
quantity int,
unit_price decimal(10,2),
discount_amount decimal(10,2),
line_total decimal(10,2),
delivery_date datetime,
constraint fk_orderid2 foreign key(order_id) references orders(order_id),
constraint fk_productid foreign key(product_id) references products(product_id)
);

-- returns table
create table returns(
return_id int primary key,
order_id int,
return_date datetime,
return_reason varchar(40),
refund_status varchar(30),
constraint fk_orderid3 foreign key(order_id) references orders(order_id)
);

set foreign_key_checks=0;

alter table orders
add column total_payable decimal(10,2);

update orders o join(
select order_id,sum(line_total) as items_total from order_items group by order_id)oi on o.order_id=oi.order_id 
set o.total_payable=oi.items_total+o.shipping_fee;

-- total revenue 
select sum(total_payable)as revenue from orders;

-- monthly sales
select year(o.order_date)as sales_year,month(o.order_date)as sales_month,sum(o.total_payable)as total_sales from orders o group by year(o.order_date),month(o.order_date) order by sales_year,sales_month;

-- delivered orders monthly sales
select month(delivery_date) as month_name,year(delivery_date) as year_num,sum(total_payable) as total_sales from orders o join order_items oi on o.order_id=oi.order_id where delivery_date is not null group by month(delivery_date),year(delivery_date) order by year(delivery_date), month(delivery_date);

-- top 10 months by total_sales
select month(delivery_date) as month_name,year(delivery_date) as year_num,sum(total_payable) as total_sales from orders o join order_items oi on o.order_id=oi.order_id where delivery_date is not null group by month(delivery_date),year(delivery_date) order by total_sales desc limit 10;

-- sales growth in % month wise 
with temp as(select month(delivery_date) as month_num,year(delivery_date) as year_num,sum(total_payable) as total_sales,lag(sum(total_payable),1,0)over(order by year(delivery_date),month(delivery_date))as pre_month_sales from orders o join order_items oi on o.order_id=oi.order_id where delivery_date is not null group by month(delivery_date),year(delivery_date))select month_num,year_num,total_sales,pre_month_sales,(total_sales-pre_month_sales)as sales_difference,round((total_sales-pre_month_sales)/nullif(pre_month_sales,0)*100,2) as growth from temp;

-- order growth in % month wise
with temp as(select month(delivery_date) as month_num,year(delivery_date)as year_num,count(o.order_id) as total_orders,lag(count(o.order_id),1,0) over(order by year(delivery_date),month(delivery_date))as pre_month_orders from orders o join order_items oi on o.order_id=oi.order_id where delivery_date is not null group by month(delivery_date),year(delivery_date) order by year(delivery_date),month(delivery_date))select month_num,year_num,total_orders,pre_month_orders,total_orders-pre_month_orders as order_difference,round((total_orders-pre_month_orders)/nullif(pre_month_orders,0)*100,2) as growth_orders from temp;

-- revenue by category
select p.category,round(sum(oi.line_total),2)as product_revenue from order_items oi join products p on oi.product_id=p.product_id group by p.category order by product_revenue desc;

-- delivered sales in %
with temp as (select round(sum(total_payable),2) as total_sales,sum(case when order_status='Delivered' then total_payable else 0 end)as delivered_amount from orders)select round(total_sales,2) as total_orders_sales,round(delivered_amount,2)as delivered_amount,round((total_sales-delivered_amount),2) as non_delivered,round((delivered_amount)/nullif(total_sales,0)*100,2)as delivered_percentage from temp;
with temp as(select month(delivery_date)as month_num,year(delivery_date)as year_num,(order_status),count(*) as del_order_count,lag(count(*),1,0)over(order by year(delivery_date),month(delivery_date))as pre_month_delcount from orders o join order_items oi on o.order_id=oi.order_id where order_status='Delivered' group by month(delivery_date),year(delivery_date) order by year_num,month_num asc)select *,round((del_order_count-pre_month_delcount)/nullif(pre_month_delcount,0)*100,2)as ordercount_growth from temp;
with temp as(select month(delivery_date)as month_num,year(delivery_date)as year_num,(order_status),sum(total_payable) as del_order_sales,lag(sum(total_payable),1,0)over(order by year(delivery_date),month(delivery_date))as pre_month_delsales from orders o join order_items oi on o.order_id=oi.order_id where order_status='Delivered' group by month(delivery_date),year(delivery_date) order by year_num,month_num asc)select *,round((del_order_sales-pre_month_delsales)/nullif(pre_month_delsales,0)*100,2)as deliveredsales_growth from temp;

-- cancellation rate
with temp as(select round(sum(total_payable),2) as total_amount,round(sum(case when order_status='Cancelled' then total_payable else 0 end),2)as total_cancel from orders)select *,round((total_cancel/total_amount)*100,2) as cancellation_rate from temp;
with temp as(select count(*) as total_orders,sum(order_status='Cancelled')as cancelled_orders from orders) select *,round((cancelled_orders/total_orders)*100,2) as cancelled_orders_rate from temp;

-- Returned rate
with temp as(select round(sum(total_payable),2) as total_amount,round(sum(case when order_status='Returned' then total_payable else 0 end),2)as total_return from orders)select *,round((total_return/total_amount)*100,2) as returned_rate from temp;
with temp as(select count(*) as total_orders,sum(order_status='Returned')as returned_orders from orders) select *,round((returned_orders/total_orders)*100,2) as returned_orders_rate from temp;

-- revenue by category 
select p.category,sum(oi.line_total)as total_sales from orders o join order_items oi on oi.order_id=o.order_id join products p on p.product_id=oi.product_id where o.order_status='Delivered' group by p.category order by total_sales desc;
select p.category,sum(oi.line_total)as total_sales from orders o join order_items oi on oi.order_id=o.order_id join products p on p.product_id=oi.product_id where o.order_status='Delivered' group by p.category order by total_sales desc limit 3;

-- revenue by city
set sql_safe_updates=0;
update customers 
set city='Unknown'
where city is null;

select count(*) from customers where city ='Unknown';
select c.city as city,sum(o.total_payable) as total_sales from orders o join customers c on c.customer_id=o.customer_id group by c.city order by total_sales desc;

-- revenue by sales_channel
select sales_channel,sum(total_payable)as total_sales from orders group by sales_channel order by total_sales desc;

-- repeated customers
select c.customer_id,count(o.customer_id)as repeated_times from orders o join customers c on c.customer_id=o.customer_id group by c.customer_id having count(o.customer_id)>1;
with temp as(select c.customer_id,count(o.customer_id)as repeated_times from orders o join customers c on c.customer_id=o.customer_id group by c.customer_id having count(o.customer_id)>1),
temp2 as(select customer_id from customers)select round((sum(temp.repeated_times>=2)/count(*))*100,2) as repeat_rate from temp2 left join temp on temp2.customer_id=temp.customer_id;
-- segment-wise customer count and total
select c.customer_segment,count(c.customer_id)as num_of_customers,count(o.order_id)as total_orders from orders o right join customers c on c.customer_id=o.customer_id group by c.customer_segment;
select c.customer_segment,count(c.customer_id)as num_of_customers,count(o.order_id)as total_orders from orders o right join customers c on c.customer_id=o.customer_id where o.order_status='Delivered' group by c.customer_segment;

-- aov
select sum(total_payable) as total_sales,count(order_id)as num_of_orders,round((sum(total_payable)/count(order_id)),2) as aov from orders;

-- delivery time
select o.order_id,o.customer_id,o.order_date,oi.delivery_date,datediff(oi.delivery_date,o.order_date)as delivery_days from orders o join order_items oi on o.order_id=oi.order_id;
with temp as(select o.order_id,o.customer_id,o.order_date,oi.delivery_date,(datediff(oi.delivery_date,o.order_date))as delivery_days from orders o join order_items oi on o.order_id=oi.order_id)select avg(delivery_days)as avg_delivery_days,min(delivery_days)as minimum_days,max(delivery_days)as maximun_days from temp;

-- avg deliveries per month
with temp as(select month(oi.delivery_date) as delivery_month,year(oi.delivery_date)as delivery_year,count(*) as total_deliveries from orders o join order_items oi on oi.order_id=o.order_id where oi.delivery_date is not null and o.order_status='Delivered' group by month(oi.delivery_date),year(oi.delivery_date) order by delivery_year,delivery_month)select avg(total_deliveries) as avg_deli_per_month from temp; 

-- top 10 delivered products
select p.product_name,count(distinct o.order_id)as num_of_orders,sum(oi.quantity)as total_units,sum(oi.line_total)as total_revenue,o.order_status as orderstatus from products p join order_items oi on p.product_id=oi.product_id join orders o on oi.order_id=o.order_id where order_status='Delivered' group by product_name order by num_of_orders desc limit 10;

-- revenue by gender
select c.gender as gender,sum(o.total_payable) as total_sales from orders o join customers c on c.customer_id=o.customer_id group by c.gender order by total_sales desc;

-- revenue by state
select c.state as state,sum(o.total_payable) as total_sales,count(o.order_id)as total_orders from orders o join customers c on c.customer_id=o.customer_id group by c.state order by total_sales desc;
select c.state as state,sum(o.total_payable) as total_sales,count(o.order_id)as total_orders from orders o join customers c on c.customer_id=o.customer_id where o.order_status='Delivered' group by c.state  order by total_sales desc;

-- revenue for ap
select p.category as category,c.state as state,count(o.order_id) as orders_placed,sum(oi.line_total)as total_sales from orders o join customers c  on c.customer_id=o.customer_id join order_items oi on oi.order_id=o.order_id join products p on oi.product_id=p.product_id where c.state='Andhra Pradesh' group by p.category order by total_sales desc;

-- revenue for telangana
select p.category as category,c.state as state,count(o.order_id) as orders_placed,sum(oi.line_total)as total_sales from orders o join customers c  on c.customer_id=o.customer_id join order_items oi on oi.order_id=o.order_id join products p on oi.product_id=p.product_id where c.state='Telangana' group by p.category order by total_sales desc;

-- signed up but never placed a order
select c.customer_id,c.city,c.state,c.customer_segment from customers c left join orders o on c.customer_id=o.customer_id where o.customer_id is null;
select count(*) as never_orderd from customers c left join orders o on c.customer_id=o.customer_id where o.customer_id is null;

-- order_status
select order_status,count(order_id)as no_of_orders from orders group by order_status order by no_of_orders desc;

-- payment method 
select payment_method,count(*) as num_of_customers,sum(total_payable)as total_sales from orders group by payment_method order by num_of_customers desc;

-- return reason
select count(*) as num_returns,return_reason from returns group by return_reason order by num_returns desc;
with temp as(select count(*) as total_returns,sum(return_reason='Late Delivery')as late_delivery from returns)select *,round((late_delivery/total_returns)*100,2)as late_deli_rate from temp;
with temp as(select count(*) as total_returns,sum(return_reason='Wrong Item')as wrong_item from returns)select *,round((wrong_item/total_returns)*100,2)as wrong_item_rate from temp;

-- low stock products 
select p.product_id,p.product_name,p.category,p.stock_quantity,sum(oi.quantity)as units_sold from products p join order_items oi on p.product_id=oi.product_id join orders o on o.order_id=oi.order_id where stock_quantity<=10 and o.order_status='Delivered' group by p.product_id,p.product_name,p.category,p.stock_quantity order by units_sold desc;

-- payment status 
select payment_status,count(*) as payment_count from payments group by payment_status order by payment_count desc;

select o.payment_method,p.payment_status,count(o.order_id)as pay_count,sum(total_payable)as revenue from orders o join payments p on o.order_id=p.order_id group by o.payment_method,p.payment_status order by pay_count desc;

-- payment success rate
with temp as(select count(*)as total,sum(payment_status='Paid')as success from payments)select*,round((success/total)*100,2) as success_rate from temp;

-- discount pct
select discount_pct,count(*) as total_orders,sum(total_payable)as total_sales from orders group by discount_pct order by total_sales desc;
select discount_pct,count(*) as total_orders,sum(total_payable)as total_sales,avg(total_payable)as avg_order from orders group by discount_pct order by total_sales desc;

