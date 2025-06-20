-- Practice Question Case Study 

-- 1. Total amount spent by each customer
select s.customer_id, sum(m.price) as total_spent from sales as s
inner join menu as m
on s.product_id = m.product_id
group by s.customer_id;

-- 2. Number of distinct visit days per customer
select customer_id, count(distinct order_date) as distinct_day from sales
group by customer_id;

-- 3. First item purchased by each customer
select distinct s.customer_id, m.product_name from sales as s
inner join menu as m
on s.product_id = m.product_id
where s.order_date = (select min(order_date) from sales);


-- 4. Most purchased item and count
-- top 1 nikalna he
select s.product_id, m.Product_name, count(s.product_id) as Times_order from sales as s
inner join menu as m
on s.product_id = m.product_id
group by s.product_id, m.product_name
order by Times_order desc;

-- 5. Most popular item per customer
with mostpopular AS (select s.customer_id, m.product_name, count(s.product_id) as order_count from sales as s
inner join menu as m
on s.product_id = m.product_id
group by s.customer_id, m.product_name)
select customer_id, max(order_count) as Most_popular_item from mostpopular
group by customer_id;

-- 6. First item after becoming a member
with afterMember AS (select m.customer_id, m.join_date, s.order_date, s.product_id, DENSE_RANK() over(partition by join_date order by order_date) as rank_up from members as m 
inner join sales as s
on m.customer_id = s.customer_id
where s.order_date > m.join_date)
select customer_id, join_date, order_date, product_id from afterMember
where rank_up = 1;

-- 7. Last item before becoming a member
with beforeMember AS (select m.customer_id, m.join_date, s.order_date, s.product_id, DENSE_RANK() over(partition by join_date order by order_date desc) as rank_up from members as m 
inner join sales as s
on m.customer_id = s.customer_id
where s.order_date < m.join_date)
select customer_id, join_date, order_date, product_id from beforeMember
where rank_up = 1;

-- 8. Items and amount before becoming a member
with beforeMember AS (select m.customer_id, m.join_date, s.order_date, s.product_id, DENSE_RANK() over(partition by join_date order by order_date desc) as rank_up from members as m 
inner join sales as s
on m.customer_id = s.customer_id
where s.order_date < m.join_date)
select b.customer_id, b.product_id, m.price from beforeMember as b
inner join menu as m
on b.product_id = m.product_id;
--- ttotal count plus total price


-- 9. Loyalty points: 2x for biryani, 1x for others
select customer_id, order_date, product_id, 
CASE product_id
	WHEN 1 THEN 2
	WHEN 2 THEN 1
	WHEN 3 THEN 1
	ELSE 0
END AS Loyalty_point 
from sales;

-- 10. Points during first 7 days after joining
WITH loyaltyPoints as (select s.customer_id, s.order_date, m.join_date, s.product_id, 
CASE product_id
	WHEN 1 THEN 2
	WHEN 2 THEN 1
	WHEN 3 THEN 1
	ELSE 0
END AS Loyalty_point 
from sales as s
inner join members as m
on s.customer_id = m.customer_id)
select customer_id, sum(Loyalty_point) as total_points from loyaltyPoints 
where order_date between join_date and dateadd(day, 7, join_date)
group by customer_id;


-- 11. Total spent on biryani
With ProductPrice AS (select s.product_id, m.price from sales as s
inner join menu as m
on s.product_id = m.product_id)
select product_id, sum(price) as total_spent from ProductPrice
where product_id = 1
group by product_id;


-- 12. Customer with most dosai orders
select customer_id, count(product_id) as most_dosai_orders from sales
where product_id = 3
group by customer_id
order by most_dosai_orders desc;

-- 13. Average spend per visit
with average_spent_cte AS (
select s.customer_id,count(s.product_id) as no_orders, avg(m.price) as AVG_spent from sales as s
inner join menu as m
on s.product_id = m.product_id
group by s.customer_id)
select * from average_spent_cte; 


-- 14. Day with most orders in Jan 2025
select order_date, count(product_id) as most_orders from sales
where order_date between '2025-01-01' and '2025-01-31'
group by order_date
order by most_orders desc;

-- 15. Customer who spent the least
with overallSpent as(select s.customer_id,count(s.product_id) as no_orders, sum(m.price) as Total_spent from sales as s
inner join menu as m
on s.product_id = m.product_id
group by s.customer_id)
select * from overallSpent
where Total_spent = (select min(total_spent) from overallSpent);

-- 16. Date with most money spent
with MostSpentDay AS(select s.order_date, sum(m.price) as most_spent from sales as s
inner join menu as m
on s.product_id = m.product_id
group by s.order_date)
select order_date, most_spent from MostSpentDay
where most_spent = (select max(most_spent) from MostSpentDay);


-- 17. Customers with multiple orders on same day
select customer_id, order_date from sales
group by customer_id,order_date
having count(product_id) > 1;
 
-- 18. Visits after membership
with visitsMenmber as(select s.customer_id, m.join_date, s.order_date from sales as s
inner join members as m
on s.customer_id = m.customer_id
where s.order_date>m.join_date)
select customer_id, count(order_date) as Number_visits from visitsMenmber
group by customer_id;

-- 19. Items never ordered
select m.product_id from menu as m
where not Exists (select s.product_id from sales as s where m.product_id = s.product_id);

-- 20. Customers who ordered but never joined
select distinct s.customer_id from sales as s
where not exists (select m.customer_id from members as m where s.customer_id = m.customer_id);
