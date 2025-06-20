CREATE DATABASE Pizza;

USE Pizza;

-- Create Schema
CREATE SCHEMA pizza_delivery_india;

-- Drop tables if exist
DROP TABLE IF EXISTS pizza_delivery_india.riders;
DROP TABLE IF EXISTS pizza_delivery_india.customer_orders;
DROP TABLE IF EXISTS pizza_delivery_india.rider_orders;
DROP TABLE IF EXISTS pizza_delivery_india.pizza_names;
DROP TABLE IF EXISTS pizza_delivery_india.pizza_recipes;
DROP TABLE IF EXISTS pizza_delivery_india.pizza_toppings;

-- Riders Table
CREATE TABLE pizza_delivery_india.riders (
  rider_id INT,
  registration_date DATE
);

INSERT INTO pizza_delivery_india.riders (rider_id, registration_date) VALUES
  (1, '2023-01-01'),
  (2, '2023-01-05'),
  (3, '2023-01-10'),
  (4, '2023-01-15');

-- Customer Orders
CREATE TABLE pizza_delivery_india.customer_orders (
  order_id INT,
  customer_id INT,
  pizza_id INT,
  exclusions VARCHAR(10),
  extras VARCHAR(10),
  order_time DATETIME
);

INSERT INTO pizza_delivery_india.customer_orders (order_id, customer_id, pizza_id, exclusions, extras, order_time) VALUES
  (1, 201, 1, '', '', '2023-01-01 18:05:02'),
  (2, 201, 1, '', '', '2023-01-01 19:00:52'),
  (3, 202, 1, '', '', '2023-01-02 23:51:23'),
  (3, 202, 2, '', NULL, '2023-01-02 23:51:23'),
  (4, 203, 1, '4', '', '2023-01-04 13:23:46'),
  (4, 203, 2, '4', '', '2023-01-04 13:23:46'),
  (5, 204, 1, NULL, '1', '2023-01-08 21:00:29'),
  (6, 201, 2, NULL, NULL, '2023-01-08 21:03:13'),
  (7, 205, 2, NULL, '1', '2023-01-08 21:20:29'),
  (8, 202, 1, NULL, NULL, '2023-01-09 23:54:33'),
  (9, 203, 1, '4', '1, 5', '2023-01-10 11:22:59'),
  (10, 204, 1, NULL, NULL, '2023-01-11 18:34:49'),
  (10, 204, 1, '2, 6', '1, 4', '2023-01-11 18:34:49');

-- Rider Orders
CREATE TABLE pizza_delivery_india.rider_orders (
  order_id INT,
  rider_id INT,
  pickup_time VARCHAR(20),
  distance VARCHAR(10),
  duration VARCHAR(15),
  cancellation VARCHAR(50)
);

INSERT INTO pizza_delivery_india.rider_orders (order_id, rider_id, pickup_time, distance, duration, cancellation) VALUES
  (1, 1, '2023-01-01 18:15:34', '5km', '32 minutes', ''),
  (2, 1, '2023-01-01 19:10:54', '6km', '27 minutes', ''),
  (3, 1, '2023-01-03 00:12:37', '4.2km', '20 mins', NULL),
  (4, 2, '2023-01-04 13:53:03', '5.5km', '40', NULL),
  (5, 3, '2023-01-08 21:10:57', '3.3km', '15', NULL),
  (6, 3, NULL, NULL, NULL, 'Restaurant Cancellation'),
  (7, 2, '2023-01-08 21:30:45', '6.1km', '25mins', NULL),
  (8, 2, '2023-01-10 00:15:02', '7.2km', '15 minute', NULL),
  (9, 2, NULL, NULL, NULL, 'Customer Cancellation'),
  (10, 1, '2023-01-11 18:50:20', '2.8km', '10minutes', NULL);

-- Pizza Names
CREATE TABLE pizza_delivery_india.pizza_names (
  pizza_id INT,
  pizza_name NVARCHAR(100)
);

INSERT INTO pizza_delivery_india.pizza_names (pizza_id, pizza_name) VALUES
  (1, 'Paneer Tikka'),
  (2, 'Veggie Delight');

-- Pizza Recipes
CREATE TABLE pizza_delivery_india.pizza_recipes (
  pizza_id INT,
  toppings NVARCHAR(100)
);

INSERT INTO pizza_delivery_india.pizza_recipes (pizza_id, toppings) VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');

-- Pizza Toppings
CREATE TABLE pizza_delivery_india.pizza_toppings (
  topping_id INT,
  topping_name NVARCHAR(100)
);

INSERT INTO pizza_delivery_india.pizza_toppings (topping_id, topping_name) VALUES
  (1, 'Paneer'),
  (2, 'Schezwan Sauce'),
  (3, 'Tandoori Chicken'),
  (4, 'Cheese'),
  (5, 'Corn'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Capsicum'),
  (9, 'Red Peppers'),
  (10, 'Black Olives'),
  (11, 'Tomatoes'),
  (12, 'Mint Mayo');


--DATA Validation
select * from pizza_delivery_india.riders;
select * from pizza_delivery_india.customer_orders;
select * from pizza_delivery_india.rider_orders;
select * from pizza_delivery_india.pizza_names;
select * from pizza_delivery_india.pizza_recipes;
select * from pizza_delivery_india.pizza_toppings;


--1. How many pizzas were ordered?
select count(order_id) as Total_ordered_pizaa from pizza_delivery_india.customer_orders;

--2. How many unique customer orders were made?
select count(distinct order_id) as Unique_customer_order_count from pizza_delivery_india.customer_orders
;

--3. How many successful orders were delivered by each rider?
select rider_id, count(*) as Delivered_order_count from pizza_delivery_india.rider_orders
where cancellation is null or cancellation = ''
group by rider_id;

--4. How many of each type of pizza was delivered?
select c.pizza_id, count(c.pizza_id) as count_pizzas from pizza_delivery_india.customer_orders as c
inner join pizza_delivery_india.rider_orders as r
on c.order_id = r.order_id
where r.cancellation is null or r.cancellation = ''
group by c.pizza_id;

--5. How many 'Paneer Tikka' and 'Veggie Delight' pizzas were ordered by each customer?
select c.customer_id, 
(select count(pizza_id) from pizza_delivery_india.customer_orders as co where pizza_id = 1 and c.customer_id = co.customer_id) as Panner_tikka,
(select count(pizza_id) from pizza_delivery_india.customer_orders as co where pizza_id = 2 and c.customer_id = co.customer_id) as Veggie_delight
from pizza_delivery_india.customer_orders as c
group by c.customer_id;

--6. What was the maximum number of pizzas delivered in a single order?
with Maximum_pizzas as(
select order_id, count(pizza_id) as Pizza_count, dense_rank() over(order by count(pizza_id) desc) as top_pizzas from pizza_delivery_india.customer_orders
group by order_id)
select * from Maximum_pizzas
where top_pizzas = 1;

--7. For each customer, how many delivered pizzas had at least 1 change (extras or exclusions) and how many had no changes?
with Null_data as(
select c.order_id, c.customer_id, nullif(c.exclusions,'') as Exclusions_1 , 
nullif(c.extras, '') as extras_1 from pizza_delivery_india.customer_orders as c)
, count_data as(
select n.order_id, n.customer_id, count(n.Exclusions_1) + count(n.extras_1) as total_count
from Null_data as n
group by n.order_id, n.customer_id)
select c.customer_id,sum(c.total_count) as total_changes from 
count_data as c
group by c.customer_id;


--8. How many pizzas were delivered that had both exclusions and extras?
with Null_data as(
select c.order_id, c.customer_id, nullif(c.exclusions,'') as Exclusions_1 , 
nullif(c.extras, '') as extras_1 from pizza_delivery_india.customer_orders as c)
select count(nd.order_id) as pizza_count from Null_data as nd
inner join pizza_delivery_india.rider_orders as ro
on nd.order_id = ro.order_id
where (ro.cancellation is null or ro.cancellation = '') and nd.Exclusions_1 is not null and nd.extras_1 is not null
group by nd.order_id;


--9. What was the total volume of pizzas ordered for each hour of the day?
select Datepart(hour,order_time) as Hours_time, count(order_id) ordered_pizzas
from pizza_delivery_india.customer_orders
group by Datepart(hour,order_time)
order by count(order_id) desc;

--10. What was the volume of orders for each day of the week?
select datename(weekday, order_time) as each_day, count(order_id) as volume_of_day
from pizza_delivery_india.customer_orders
group by datename(weekday, order_time);

--11. How many riders signed up for each 1-week period starting from 2023-01-01?
select count(rider_id) as registerd_rider from pizza_delivery_india.riders
where datepart(week,registration_date) = 1;
--extra parameter dena hoga 

--12. What was the average time in minutes it took for each rider to arrive at Pizza Delivery HQ to pick up the order?
with average_time as(
select r.rider_id, DATEDIFF(minute,c.order_time,r.pickup_time) as duration from pizza_delivery_india.customer_orders as c
inner join pizza_delivery_india.rider_orders as r
on c.order_id = r.order_id)
select rider_id, avg(duration) as Avg_time_to_picup from average_time
group by rider_id;
-- kahi koi duplicate record tha to isko dhyan se dekhna he or ek bar or kar ke dekhna he distinct laga ke 

--13. Is there any relationship between the number of pizzas in an order and how long it takes to prepare?
select c.order_id, count(c.pizza_id) as count, datediff(minute,c.order_time,r.pickup_time) as prepare_time from pizza_delivery_india.customer_orders as c
inner join pizza_delivery_india.rider_orders as r
on c.order_id = r.order_id
group by c.order_id,c.order_time,r.pickup_time
-- iske kitne pizza he to kitna time lag rha he ye dekhna he
-- banne me kitna time lag rha he ye nikalna he

--14. What was the average distance traveled for each customer?
select c.customer_id, avg(cast(replace(r.distance,'km','') as float)) as avg_distance from pizza_delivery_india.customer_orders as c
inner join pizza_delivery_india.rider_orders as r
on c.order_id = r.order_id
group by c.customer_id;
--- PATINDEX
---CHARINDEX

--15. What was the difference between the longest and shortest delivery durations across all orders?
with long_sort as(select cast(substring(duration,1,2) as int) as Duration from pizza_delivery_india.rider_orders)
select min(duration) as shortest, max(duration) as longest, max(duration)-min(duration) as diff
from long_sort;

--16. What was the average speed (in km/h) for each rider per delivery? Do you notice any trends
with raw_data as (
select rider_id ,sum(cast(replace(distance,'km','') as float)) as distance, sum(cast(substring(duration,1,2) as float))/60 as Duration
from pizza_delivery_india.rider_orders
group by rider_id)
select rider_id, round((distance/(duration)),2) as Avg_speed from raw_data;

--17. What is the successful delivery percentage for each rider?
with del_per as
(
select rider_id, CUME_DIST() over(order by rider_id) as percent_g from pizza_delivery_india.rider_orders
where cancellation is null or cancellation = ''),
percent_cal as 
(select rider_id,percent_g, 
(percent_g - lag(percent_g,1,0) over(order by percent_g))*100 as delivery_per from del_per)
select rider_id, max(delivery_per) as delivery_percentage from percent_cal
group by rider_id;

--18. What are the standard ingredients for each pizza
with recipes as(
select p.pizza_name, cast(value as int) as toppings
from pizza_delivery_india.pizza_names as p
inner join pizza_delivery_india.pizza_recipes as r
on p.pizza_id = r.pizza_id
cross apply string_split(r.toppings,','))
select distinct r.toppings, t.topping_name from recipes as r
inner join recipes as m
on r.toppings = m.toppings and r.pizza_name != m.pizza_name
inner join pizza_delivery_india.pizza_toppings as t
on r.toppings = t.topping_id

with recipes as(
select p.pizza_name, cast(value as int) as toppings
from pizza_delivery_india.pizza_names as p
inner join pizza_delivery_india.pizza_recipes as r
on p.pizza_id = r.pizza_id
cross apply string_split(r.toppings,','))
select r.pizza_name, STRING_AGG(t.topping_name, ',')  as standart_ingredient from recipes as r
inner join pizza_delivery_india.pizza_toppings as t
on r.toppings = t.topping_id
group by r.pizza_name;

-- string split()
-- string_agg()
--cross apply allows that function to be applied per row of your main table
-- try_cast() to combine names
-- the result is a flattened, normalized version of your data

--19. What was the most commonly added extra (e.g., Mint Mayo, Corn)?
with comman_extras as(
select c.order_id, value as extras1, t.topping_name
from pizza_delivery_india.customer_orders as c
cross apply string_split(extras,',')
inner join pizza_delivery_india.pizza_toppings as t
on value = t.topping_id)
select top 1 topping_name, count(extras1) as top_extras from comman_extras
group by topping_name
order by top_extras desc;

--20. What was the most common exclusion (e.g., Cheese, Onions)?
with comman_exclusion as(
select c.order_id, value as exclusion1, t.topping_name
from pizza_delivery_india.customer_orders as c
cross apply string_split(exclusions, ',')
inner join pizza_delivery_india.pizza_toppings as t
on value = t.topping_id)
select top 1 topping_name, count(exclusion1) as top_exclusions from comman_exclusion
group by topping_name
order by top_exclusions desc;

--21. Generate an order item for each record in the `customer_orders` table in the format:

--    * Paneer Tikka
--    * Paneer Tikka - Exclude Corn
--    * Paneer Tikka - Extra Cheese
--    * Veggie Delight - Exclude Onions, Cheese - Extra Corn, Mushrooms
with excludesCTE as(
select c.order_id, c.pizza_id, STRING_AGG(p.topping_name,',') as excludes
from pizza_delivery_india.customer_orders as c
cross apply string_split(c.exclusions,',')
inner join pizza_delivery_india.pizza_toppings as p 
on cast(value as int) = p.topping_id
group by c.order_id, c.pizza_id),
extrasCTE as
(select c.order_id, c.pizza_id, STRING_AGG(p.topping_name,',') as extras
from pizza_delivery_india.customer_orders as c
cross apply string_split(c.extras,',')
inner join pizza_delivery_india.pizza_toppings as p 
on cast(value as int) = p.topping_id
group by c.order_id, c.pizza_id),
final_result as
(select distinct c.order_id, p.pizza_name, a.excludes, b.extras from pizza_delivery_india.customer_orders as c
left join excludesCTE as a
on c.order_id = a.order_id and c.pizza_id = a.pizza_id
left join extrasCTE as b
on c.order_id = b.order_id and c.pizza_id = b.pizza_id
left join pizza_delivery_india.pizza_names as p
on c.pizza_id = p.pizza_id)

select order_id,
case 
	when excludes is null and extras is null then pizza_name
	when excludes is not null and extras is null then concat(pizza_name, ' - ','Exclude ', excludes)
	when excludes is null and extras is not null then concat(pizza_name, ' - ','Extras ',extras)
	when excludes is not null and extras is not null then concat(pizza_name, ' - ','Exclude ',excludes, ' - ','Extras ',extras)
end as Order_items
from final_result;


--22. Generate an alphabetically ordered, comma-separated ingredient list for each pizza order, using "2x" for duplicates.

--    * Example: "Paneer Tikka: 2xCheese, Corn, Mushrooms, Schezwan Sauce"
--------------------------------------------------------------------------------------------------
with excludesCTE as(
select c.order_id,c.customer_id, c.pizza_id, value as excludes
from pizza_delivery_india.customer_orders as c
cross apply string_split(c.exclusions,',')
inner join pizza_delivery_india.pizza_toppings as p 
on cast(value as int) = p.topping_id)
,
--select * from excludesCTE
  
extrasCTE as
(select c.order_id,c.customer_id, c.pizza_id, value as extras
from pizza_delivery_india.customer_orders as c
cross apply string_split(c.extras,',')
inner join pizza_delivery_india.pizza_toppings as p 
on cast(value as int) = p.topping_id)
,
--select * from extrasCTE;

all_toppings as(
select c.order_id,c.customer_id,p.pizza_id, cast(value as int) as toppings
from pizza_delivery_india.pizza_names as p
inner join pizza_delivery_india.pizza_recipes as r
on p.pizza_id = r.pizza_id
inner join pizza_delivery_india.customer_orders as c
on c.pizza_id = p.pizza_id 
cross apply string_split(r.toppings,','))
,
--select * from all_toppings
--order by order_id;

exclude_excludes as (
select order_id, customer_id, pizza_id, toppings from all_toppings
except
select order_id, customer_id, pizza_id, excludes from excludesCTE)
,
--select * from exclude_excludes;

include_extras as(
select order_id, customer_id, pizza_id,toppings from exclude_excludes
union all
select order_id, customer_id, pizza_id, extras from extrasCTE)
,
--select * from include_extras
--order by order_id;

final_output as (
select i.order_id,i.pizza_id, 
case
	when count(toppings) > 1 then CONCAT(count(toppings),'x ',t.topping_name) else t.topping_name
end as toppings,
	count(toppings) counts from include_extras as i
inner join pizza_delivery_india.pizza_toppings as t
on i.toppings = t.topping_id
group by i.order_id,i.pizza_id,t.topping_name)
--select * from final_output;

select order_id, STRING_AGG(toppings,', ') within group(order by toppings) as ingredient_list from final_output
group by order_id, pizza_id
order by order_id;



--23. What is the total quantity of each topping used in all successfully delivered pizzas, sorted by most used first?
with excludesCTE as(
select c.order_id,c.customer_id, c.pizza_id, value as excludes
from pizza_delivery_india.customer_orders as c
cross apply string_split(c.exclusions,',')
inner join pizza_delivery_india.pizza_toppings as p 
on cast(value as int) = p.topping_id)
,
--select * from excludesCTE
  
extrasCTE as
(select c.order_id,c.customer_id, c.pizza_id, value as extras
from pizza_delivery_india.customer_orders as c
cross apply string_split(c.extras,',')
inner join pizza_delivery_india.pizza_toppings as p 
on cast(value as int) = p.topping_id)
,
--select * from extrasCTE;

all_toppings as(
select c.order_id,c.customer_id,p.pizza_id, cast(value as int) as toppings
from pizza_delivery_india.pizza_names as p
inner join pizza_delivery_india.pizza_recipes as r
on p.pizza_id = r.pizza_id
inner join pizza_delivery_india.customer_orders as c
on c.pizza_id = p.pizza_id 
inner join pizza_delivery_india.rider_orders as ro
on c.order_id = ro.order_id
cross apply string_split(r.toppings,',')
where ro.cancellation is null or ro.cancellation = '')
,
--select * from all_toppings
--order by order_id;

exclude_excludes as (
select order_id, customer_id, pizza_id, toppings from all_toppings
except
select order_id, customer_id, pizza_id, excludes from excludesCTE)
,
--select * from exclude_excludes;

include_extras as(
select order_id, customer_id, pizza_id,toppings from exclude_excludes
union all
select order_id, customer_id, pizza_id, extras from extrasCTE)

select pt.topping_name, count(i.toppings) as counts from pizza_delivery_india.pizza_toppings as pt
inner join include_extras as i
on pt.topping_id = i.toppings
group by pt.topping_name
order by counts desc;

-- string_split function use hoga

--24. If a 'Paneer Tikka' pizza costs ₹300 and a 'Veggie Delight' costs ₹250 (no extra charges), how much revenue has Pizza Delivery India generated (excluding cancellations)?
with pizza_price as (
select pn.pizza_id,pn.pizza_name ,
case pn.pizza_name 
when 'Paneer Tikka' then 300 
when 'Veggie Delight' then 250 
end as price
from pizza_delivery_india.pizza_names pn
join pizza_delivery_india.customer_orders co on pn.pizza_id=co.pizza_id
join pizza_delivery_india.rider_orders ro on co.order_id=ro.order_id
where ro.cancellation is null or ro.cancellation=''
) select sum(price) as  total_revenue  from pizza_price;

--25. What if there’s an additional ₹20 charge for each extra topping?
--

with with_row_num as (
select ROW_NUMBER() over(order by order_id) as row_num, * from pizza_delivery_india.customer_orders),

extrasCTE as
(select c.row_num, c.order_id,c.customer_id, c.pizza_id, value as extras
from with_row_num as c
cross apply string_split(c.extras,',')
inner join pizza_delivery_india.pizza_toppings as p 
on cast(value as int) = p.topping_id),
all_data as (
select  c.row_num, c.order_id, c.pizza_id, c.customer_id, e.extras
from with_row_num as c
left join extrasCTE as e
on c.row_num = e.row_num)

select order_id,pizza_id,
case
	when pizza_id = 1 then (count(extras)*20)+300
	when pizza_id = 2 then (count(extras)*20)+250
end as amount
from all_data
group by row_num,order_id,pizza_id;

--26. Cheese costs ₹20 extra — apply this specifically where Cheese is added as an extra.
with with_row_num as (
select ROW_NUMBER() over(order by order_id) as row_num, * from pizza_delivery_india.customer_orders),

extrasCTE as
(select c.row_num, c.order_id,c.customer_id, c.pizza_id, value as extras
from with_row_num as c
cross apply string_split(c.extras,',')
inner join pizza_delivery_india.pizza_toppings as p 
on cast(value as int) = p.topping_id),
all_data as (
select  c.row_num, c.order_id, c.pizza_id, c.customer_id, e.extras
from with_row_num as c
left join extrasCTE as e
on c.row_num = e.row_num)

select row_num, order_id, pizza_id,
case
 when pizza_id = 1 and extras = 4 then (count(extras)*20)+300
 when pizza_id = 1 then 300
 when pizza_id = 2 and extras = 4 then (count(extras)*20)+250
 when pizza_id = 2 then 250
end as amount
from all_data
group by row_num, order_id, pizza_id,extras
order by order_id
 
--27. Design a new table for customer ratings of riders. Include:

--    * rating_id, order_id, customer_id, rider_id, rating (1-5), comments (optional), rated_on (DATETIME)

--    Example schema:

--    ```sql
CREATE TABLE pizza_delivery_india.rider_ratings(
  rating_id INT IDENTITY PRIMARY KEY,
  order_id INT,
  customer_id INT,
  rider_id INT,
  rating INT CHECK (rating BETWEEN 1 AND 5),
  comments NVARCHAR(255),
  rated_on DATETIME
);

drop table pizza_delivery_india.rider_ratings;
--    `

--28. Insert sample data into the ratings table for each successful delivery.

with insert_data as(
select ROW_NUMBER() over(order by c.order_id) as rating_id, c.order_id, c.customer_id, r.rider_id, cast((rand()*customer_id) as int)%5+1 as random_rating
from pizza_delivery_india.customer_orders as c
inner join pizza_delivery_india.rider_orders as r
on c.order_id = r.order_id
where r.cancellation is null or r.cancellation = ''
group by c.order_id, c.customer_id, r.rider_id)
insert into pizza_delivery_india.rider_ratings
(rating_id,order_id,customer_id,rider_id,rating,comments,rated_on)
select i.rating_id,i.order_id,i.customer_id,i.rider_id,i.random_rating,
case
	when random_rating in(1,2) then 'Its okay okay'
	when random_rating in (3,4) then 'to good pizzas you get here'
	when random_rating = 5 then 'Supercalifragilisticexpialidocious'
end as comment,
DATEADD(hour, 1, ro.pickup_time) as rated_on
from insert_data as i
inner join pizza_delivery_india.rider_orders as ro
on i.order_id = ro.order_id;

select * from pizza_delivery_india.rider_ratings;

SET IDENTITY_INSERT pizza_delivery_india.rider_ratings on; 
SET IDENTITY_INSERT pizza_delivery_india.rider_ratings off; 


--29. Join data to show the following info for successful deliveries:
select * from pizza_delivery_india.riders;
select * from pizza_delivery_india.customer_orders;
select * from pizza_delivery_india.rider_orders;
select * from pizza_delivery_india.pizza_names;
select * from pizza_delivery_india.pizza_recipes;
select * from pizza_delivery_india.pizza_toppings;
--    * customer_id
--    * order_id
--    * rider_id
--    * rating
--    * order_time
--    * pickup_time
--    * Time difference between order and pickup (in minutes)
--    * Delivery duration
--    * Average speed (km/h)
--    * Number of pizzas in the order
with raw_data as (
select rider_id ,sum(cast(replace(distance,'km','') as float)) as distance, sum(cast(substring(duration,1,2) as float))/60 as Duration
from pizza_delivery_india.rider_orders
group by rider_id),

avg_speed as (
select rider_id, round((distance/(duration)),2) as Avg_speed from raw_data)

select distinct c.customer_id, c.order_id, ro.rider_id, rr.rating, c.order_time, ro.pickup_time, datediff(MINUTE,c.order_time,ro.pickup_time) as diff_time, ro.duration, av.avg_speed, count(c.pizza_id) over(partition by c.order_id) as num_of_pizza from pizza_delivery_india.customer_orders as c
inner join pizza_delivery_india.rider_orders as ro
on c.order_id = ro.order_id
inner join pizza_delivery_india.rider_ratings as rr
on c.order_id = rr.order_id
inner join avg_speed as av
on ro.rider_id = av.rider_id
;

--30. If Paneer Tikka is ₹300, Veggie Delight ₹250, and each rider is paid ₹2.50/km, what is Pizza Delivery India's profit after paying riders?
-- ye bhi ho jayega
with pizza_price as (
select pn.pizza_id,pn.pizza_name ,
case pn.pizza_name 
when 'Paneer Tikka' then 300 
when 'Veggie Delight' then 250 
end as price,
cast(replace(ro.distance,'km','') as float)*2.50 as rider_cost
from pizza_delivery_india.pizza_names pn
join pizza_delivery_india.customer_orders co on pn.pizza_id=co.pizza_id
join pizza_delivery_india.rider_orders ro on co.order_id=ro.order_id
where ro.cancellation is null or ro.cancellation=''
) select sum(price)-sum(rider_cost) as  total_revenue  from pizza_price;



--31. If the owner wants to add a new “Supreme Indian Pizza” with all available toppings, how would the existing design support that? Provide an example `INSERT`:
insert into pizza_delivery_india.pizza_names
values (3,'Supreme Indian Pizza');

select * from pizza_delivery_india.pizza_names

insert into pizza_delivery_india.pizza_recipes
select 3 as pizza_id, STRING_AGG(topping_id,',') as toppings from pizza_delivery_india.pizza_toppings;

select * from pizza_delivery_india.pizza_recipes

------------------ 5 ---------------------------

CREATE VIEW Ranking_ac_orders AS(
select order_id, count(pizza_id) as Pizza_count, 
dense_rank() over(order by count(pizza_id) desc) as top_pizzas 
from pizza_delivery_india.customer_orders
group by order_id);

select * from Ranking_ac_orders;


-------------------- 6 -----------------------------

CREATE VIEW Rider_rating AS (
select ROW_NUMBER() over(order by c.order_id) as rating_id, c.order_id, c.customer_id, r.rider_id, cast((rand()*customer_id) as int)%5+1 as random_rating
from pizza_delivery_india.customer_orders as c
inner join pizza_delivery_india.rider_orders as r
on c.order_id = r.order_id
where r.cancellation is null or r.cancellation = ''
group by c.order_id, c.customer_id, r.rider_id);

select * from Rider_rating;


------------------- 7 ----------------------------

---- add pizza details with delev order id

CREATE VIEW Pizza_details as (
select ro.order_id,pn.pizza_id,pn.pizza_name ,
case pn.pizza_name 
when 'Paneer Tikka' then 300 
when 'Veggie Delight' then 250 
end as price
from pizza_delivery_india.pizza_names pn
join pizza_delivery_india.customer_orders co on pn.pizza_id=co.pizza_id
join pizza_delivery_india.rider_orders ro on co.order_id=ro.order_id
where ro.cancellation is null or ro.cancellation='');

select * from Pizza_details;


--------------------- 8 --------------------------

CREATE VIEW total_Time_in_Hours AS(
select rider_id ,sum(cast(replace(distance,'km','') as float)) as distance, sum(cast(substring(duration,1,2) as float))/60 as Duration
from pizza_delivery_india.rider_orders
group by rider_id);

select * from total_Time_in_Hours;



select * from pizza_delivery_india.riders;
select * from pizza_delivery_india.customer_orders;
select * from pizza_delivery_india.rider_orders;
select * from pizza_delivery_india.pizza_names;
select * from pizza_delivery_india.pizza_recipes;
select * from pizza_delivery_india.pizza_toppings;

select * 
into #customer_info
from pizza_delivery_india.customer_orders;



select * from #customer_info

select * into
customer_dd
from #customer_info;


CREATE VIEW customer_from as (
select * from customer_dd);

select * from customer_from;


alter table customer_from
add email varchar(50);

