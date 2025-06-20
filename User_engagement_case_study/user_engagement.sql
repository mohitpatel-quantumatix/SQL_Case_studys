--# SET A
use user_engagementDB;

--1. How many distinct users are in the dataset?
select count(distinct user_id) as count_users from user_engagement.users;

--2. What is the average number of cookie IDs per user?
with avg_cte as
(select user_id, count(cookie_id) as count_cooki from user_engagement.users
group by user_id)
select avg(count_cooki) as avg_cookie_ids from avg_cte;

--3. What is the number of unique site visits by all users per month?
select month(event_time)as months ,count(distinct visit_id) as counts from user_engagement.events
group by month(event_time)
order by months;

--4. What is the count of each event type?
select ei.event_type,ei.event_name, count(e.event_type) as counts from user_engagement.event_identifier as ei
left join user_engagement.events as e
on ei.event_type = e.event_type
group by ei.event_type, ei.event_name
order by ei.event_type;

--5. What percentage of visits resulted in a purchase?
select round(cast((select count(visit_id) from user_engagement.events where event_type = 3)as float)/cast(count(distinct visit_id) as float)*100.0,2) as percentage_purchase
from user_engagement.events;


--6. What percentage of visits reached checkout but not purchase?
select round((cast((select count(distinct visit_id) from user_engagement.events
where page_id = 12) - (select count(distinct visit_id) from user_engagement.events where page_id = 13) as float)/cast(count(distinct visit_id) as float))*100.0,2) as checkout_not_purchase from user_engagement.events;


--7. What are the top 3 most viewed pages?
with rankCTE as (
select page_id, count(page_id) as counts, dense_rank() over (order by count(page_id) desc) ov from user_engagement.events
group by page_id)
select page_id, counts from rankCTE
where ov < 4;

--8. What are the views and add-to-cart counts per product category?
select p.product_category , e.event_type, count(p.product_category) as counts from user_engagement.page_hierarchy as p
left join user_engagement.events as e
on p.page_id = e.page_id
where (e.event_type = 1 or e.event_type = 2) and p.product_category is not null
group by p.product_category, e.event_type;

--9. What are the top 3 products by purchases?
with where_13 as
(select visit_id, page_id, event_type from user_engagement.events
where page_id = '13'),
--select * from where_13;
page_and_count as (
select e.visit_id, e.page_id, e.event_type from where_13 as w
left join user_engagement.events as e
on w.visit_id = e.visit_id
where e.event_type = 2),
product_counts as (
select pc.page_id,p.product_id, count(pc.event_type) as counts from page_and_count as pc
inner join user_engagement.page_hierarchy as p
on pc.page_id = p.page_id
group by pc.page_id, p.product_id)
select top 3 product_id, counts from product_counts
order by counts desc;

use user_engagementDB;


--# SET B

--10. Create a product-level funnel table with views, cart adds, abandoned carts, and purchases.
-- funnel table of cart adds
--funnel table views
create view funnel_table_views
as
select ph.product_id,ph.product_category, count(e.page_id) as counts from user_engagement.page_hierarchy as ph
left join user_engagement.events as e
on ph.page_id = e.page_id
where ph.product_id is not null and e.event_type = 1
group by ph.product_id,ph.product_category;

select * from funnel_table_views;

----------------END--------------------------------------
CREATE VIEW Funnel_table_cart_adds
AS 
select ph.product_id,ph.product_category, count(e.page_id) as counts from user_engagement.page_hierarchy as ph
left join user_engagement.events as e
on ph.page_id = e.page_id
where ph.product_id is not null and e.event_type = 2
group by ph.product_id,ph.product_category;

select * from Funnel_table_cart_adds
order by counts desc;
----------------------END-----------------------------

--Funnel table of abondoned carts

create view funnel_table_aboudoned_carts 
as
with where_13 as
(select visit_id, page_id, event_type from user_engagement.events
where page_id = '13'),
--select * from where_13;
aboudoned_data as (
select e.visit_id, e.page_id,e.event_type from user_engagement.events as e
left join where_13 as w
on e.visit_id = w.visit_id
where w.visit_id is null and e.event_type = 2)
--select * from aboudoned_data
select ph.product_id,ph.product_category, count(a.page_id) as counts from aboudoned_data as a
inner join user_engagement.page_hierarchy as ph
on ph.page_id = a.page_id
group by ph.product_id,ph.product_category;

select * from funnel_table_aboudoned_carts;


----------------------END---------------------------------------------------------
--funnel table of purchase
create view funnel_table_purchase
as
with where_13 as
(select visit_id, page_id, event_type from user_engagement.events
where page_id = '13'),
--select * from where_13;
page_and_count as (
select e.visit_id, e.page_id, e.event_type from where_13 as w
left join user_engagement.events as e
on w.visit_id = e.visit_id
where e.event_type = 2),
product_counts as (
select p.product_id,p.product_category, count(pc.event_type) as counts from page_and_count as pc
inner join user_engagement.page_hierarchy as p
on pc.page_id = p.page_id
group by p.product_id,p.product_category)
select product_id,product_category, counts from product_counts;

select * from funnel_table_purchase;

---------------------------------END-----------------------------------------------------
-- final query
select ph.product_id,(select v.counts from funnel_table_views as v where ph.product_id = v.product_id) as Views,
(select ca.counts from Funnel_table_cart_adds as ca where ph.product_id = ca.product_id ) as Cart_adds,
(select ac.counts from funnel_table_aboudoned_carts as ac where ph.product_id = ac.product_id) as Aboudoned_carts,
(select p.counts from funnel_table_purchase as p where ph.product_id = p.product_id) as Purchase
from user_engagement.page_hierarchy as ph
where ph.product_id is not null;


--11. Create a category-level funnel table with the same metrics as above.
select ph.product_category,(select sum(v.counts) from funnel_table_views as v where ph.product_category = v.product_category
group by v.product_category) as Views,
(select sum(ca.counts) from Funnel_table_cart_adds as ca where ph.product_category = ca.product_category
group by ca.product_category) as Cart_adds,
(select sum(ac.counts) from funnel_table_aboudoned_carts as ac where ph.product_category = ac.product_category
group by ac.product_category) as Aboudoned_carts,
(select sum(p.counts) from funnel_table_purchase as p where ph.product_category = p.product_category
group by p.product_category) as Purchase
from user_engagement.page_hierarchy as ph
where ph.product_category is not null
group by ph.product_category;

--12. Which product had the most views, cart adds, and purchases?
select (select top 1 product_id from funnel_table_views order by counts desc) as views,
(select top 1 product_id from Funnel_table_cart_adds order by counts desc) as cart_adds,
(select top 1 product_id from funnel_table_purchase order by counts desc) as purchases;

--13. Which product was most likely to be abandoned?
select top 1 product_id,counts from funnel_table_aboudoned_carts
order by counts desc;

--14. Which product had the highest view-to-purchase conversion rate?
select top 1 v.product_id, round((cast(p.counts as float)/cast(v.counts as float)*100.0),2) as conversion_rate from funnel_table_views as v
inner join funnel_table_purchase as p
on v.product_id = p.product_id
order by conversion_rate desc;

--15. What is the average conversion rate from view to cart add?
select avg(round((cast(ca.counts as float)/cast(v.counts as float)*100.0),2)) as AVG_conversion_rate from funnel_table_views as v
inner join Funnel_table_cart_adds as ca
on v.product_id = ca.product_id;

--16. What is the average conversion rate from cart add to purchase?
select  round((avg(cast(p.counts as float)/cast(ca.counts as float)*100.0)),2) as avg_conversion_rate from Funnel_table_cart_adds as ca
inner join funnel_table_purchase as p
on ca.product_id = p.product_id;


--# SET C.

--17. Create a visit-level summary table with user_id, visit_id, visit start time, event counts, and campaign name.
with summary_table_cte as (
select u.user_id, e.visit_id, min(e.event_time) as visit_start_time, count(e.event_type) as event_count,(select count(a.visit_id) from user_engagement.events as a where a.event_type = 2 and e.visit_id = a.visit_id ) as product_count from user_engagement.users as u
inner join user_engagement.events as e
on u.cookie_id = e.cookie_id
group by u.user_id , e.visit_id)
--select * from summary_table_cte
--order by user_id;
select user_id, visit_id, visit_start_time, event_count,
case
	when (product_count between 1 and 3) and (visit_start_time between '2020-01-01'and '2020-01-14') then 'BOGOF - Festival Deals'
	when (product_count between 4 and 5) and (visit_start_time between '2020-01-15'and '2020-01-28') then '25% Off - Wedding Essentials'
	when (product_count between 6 and 8) and (visit_start_time between '2020-02-01'and '2020-03-31') then 'Half Off - New Year Bonanza% Off - Wedding Essentials'
	else null
end as campaign_name
from summary_table_cte
order by user_id
--18. (Optional) Add a column for comma-separated cart products sorted by order of addition.

--# Further Investigations
--19. Identify users exposed to campaign impressions and compare metrics with those who were not.
with user_impres_CTE as 
(select distinct u.user_id,u.cookie_id from user_engagement.events as e
inner join user_engagement.users as u
on e.cookie_id = u.cookie_id
where e.event_type = 4),

user_without_impres as (
select distinct u.user_id,u.cookie_id from user_engagement.users as u
left join user_impres_CTE as uc
on u.user_id = uc.user_id
where uc.user_id is null),

without_imp as (
select e.cookie_id,count(e.page_id) as counts from user_engagement.events as e
inner join user_without_impres as ui
on e.cookie_id = ui.cookie_id
group by e.cookie_id),

with_imp as(
select e.cookie_id,count(e.page_id) as counts from user_engagement.events as e
inner join user_impres_CTE as ui
on e.cookie_id = ui.cookie_id
group by e.cookie_id)

select (select avg(counts) from without_imp) as Avg_visits_of_without_impression_users,
(select avg(counts) from with_imp) as Avg_visits_With_impression_users

--20. Does clicking on an impression lead to higher purchase rates?
with user_impres_CTE as 
(select distinct u.user_id,e.visit_id,u.cookie_id from user_engagement.events as e
inner join user_engagement.users as u
on e.cookie_id = u.cookie_id
where e.event_type = 4),

user_without_impres as (
select distinct u.user_id,e.visit_id,u.cookie_id from user_engagement.users as u
left join user_impres_CTE as uc
on u.user_id = uc.user_id
left join user_engagement.events as e
on u.cookie_id = e.cookie_id
where uc.user_id is null)

select e.visit_id from user_without_impres as wu
inner join user_engagement.events as e
on wu.visit_id = e.visit_id
where event_type = 3
order by user_id;



--21. What is the uplift in purchase rate for users who clicked an impression vs. those who didn’t?
--22. What metrics can be used to evaluate the success of each campaign?
