--# Introduction

--Rishi’s new business, DMart, is focused on selling fresh produce online.
--After managing international operations, he now needs your help to review how his sales are doing.
--In June 2020, DMart made a major change by switching to fully sustainable packaging—from farm to doorstep.
--Rishi wants your help to understand how this change affected DMart’s sales. Specifically, he needs answers to these questions:
--What was the measurable effect on sales after switching to sustainable packaging in June 2020?
--Which parts of the business (like platform, region, customer segment, and customer type) were most affected?
--How can DMart prepare for future sustainability changes to reduce any negative impact on sales?

--### Available Data
--For this case study there is only a single table: dmart.weekly_sales

--![](tbl.png)

--The column names mostly explain themselves, but here are a few extra details:
--DMart operates internationally using a strategy that covers multiple regions.
--It has two platforms: physical Offline stores and an online store.
--Customer segment and customer_type are based on personal age and demographic info shared with DMart.
--Transactions show the number of unique purchases, while sales represent the total rs value of those purchases.
--Each row in the dataset is a weekly summary of sales, grouped by the week_date, which marks the start of that sales week.

--## Data Cleansing Steps
--a single query, perform the following operations and generate a new table in the dmart schema named clean_weekly_sales:
use dmart;

--Convert the week_date to a DATE format
--Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
--Add a month_number with the calendar month for each week_date value as the 3rd column
--Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
--Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
--Add a new demographic column using the following mapping for the first letter in the segment values:
--|segment   | demographic   |
--|----------|---------------|
--|C         | Couples       |
--|F         | Families      |
--|----------|---------------|

--Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
--Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
create view sales_data
as
select s.week_date, (datepart(week,s.week_date)) as week_number, datepart(month, s.week_date) as month_number,
datepart(year,s.week_date) as calandar_year, s.region, s.platform, replace(s.segment,'null','Unknown') as segment,
case
	when right(s.segment,1) = '1' then 'Young Adults'
	when right(s.segment,1) = '2' then 'Middle Aged'
	when right(s.segment,1) in ('3','4') then 'Retirees'
	else 'Unknown'
end as age_band,
case
	when left(s.segment,1) = 'C' then 'Couples'
	when left(s.segment,1) = 'F' then 'Families'
	else 'Unknown'
end as demographic,s.customer_type, s.transactions,s.sales,
round(cast(s.sales as float)/cast(s.transactions as float),2) as avg_transaction
from (select parse(week_date as date using 'en-GB') as week_date,region,platform,segment,customer_type,transactions,sales from dmart.qt.weekly_sales) as s

--![](age_band.png)


--## Data Exploration
--1. What day of the week does each week_date fall on?
--→ Find out which weekday (e.g., Monday, Tuesday) each sales week starts on.
select distinct datename(dw,week_date) as day_of_salestart from sales_data
;

--2. What range of week numbers are missing from the dataset?
with new_cte as (
select 1 as Week_start,datepart(week,'2020-12-31') as week_end

union all

select Week_start +1, week_end from new_cte
where Week_start < week_end)

select n.Week_start from new_cte as n
left join sales_data as s
on n.Week_start = s.week_number
where s.week_number is null
order by week_number;

select distinct week_number from sales_data
order by week_number

--3. How many purchases were made in total for each year?
select year(week_date) as years, count(transactions) as total_purchases from sales_data
group by year(week_date)
order by years;

--→ Count the total number of transactions for every year in the dataset.

--4. How much was sold in each region every month?
select region,
--calandar_year, 
month_number, sum(cast(sales as bigint)) as monthly_sales from sales_data
group by region,
--calandar_year,
month_number
order by region,month_number;
--→ Show total sales by region, broken down by month.

--5. How many transactions happened on each platform?
select platform, count(transactions) as trans_count from sales_data
group by platform;

--→ Count purchases separately for the online store and the physical store.

--6. What share of total sales came from Offline vs Online each month
with off_cte as (
select platform, month_number, sum(cast(sales as bigint)) as sales from sales_data
where platform = 'offline-Store'
group by platform,month_number),

on_cte as (
select platform, month_number, sum(cast(sales as bigint)) as sales from sales_data
where platform = 'online-Store'
group by platform,month_number)

select f.month_number, (f.sales + n.sales) as total_sales,round((cast(f.sales as float)/cast((f.sales + n.sales) as float))*100.0,2) as Offline_sales_share,
round((cast(n.sales as float)/ cast((f.sales + n.sales) as float))*100.0,2) as Online_sales_share from off_cte as f
inner join on_cte as n
on f.month_number = n.month_number
order by f.month_number;


--→ Compare the percentage of monthly sales from the physical store vs. the online store.

--7. What percentage of total sales came from each demographic group each year?
select a.calandar_year, a.demographic, round((sum(cast(sales as float))/(select sum(cast(sales as float)) as per_year_sale from sales_data as b
where a.calandar_year = b.calandar_year))*100.0,2) as sales_percentage from sales_data as a
group by a.calandar_year,a.demographic
order by a.calandar_year,a.demographic;
--→ Break down annual sales by customer demographics (e.g., age or other groupings).

--8. Which age groups and demographic categories had the highest sales in physical stores?
select age_band, demographic, sum(cast(sales as bigint)) as sales from sales_data
where age_band <> 'Unknown' and platform = 'offline-store'
group by age_band,demographic
order by sales desc;
--→ Find out which age and demographic combinations contribute most to Offline-Store sales.

--9. Can we use the avg_transaction column to calculate average purchase size by year and platform? If not, how should we do it?
--incorrect
select calandar_year,platform, avg(avg_transaction) from sales_data
group by calandar_year,platform
order by calandar_year;

--correct
select calandar_year,platform, (sum(cast(sales as float))/sum(cast(transactions as float))) as avg_sale from sales_data
group by calandar_year,platform
order by calandar_year;
--→ Check if the avg_transaction column gives us correct yearly average sales per transaction for Offline vs Online. If it doesn't, figure out how to calculate it manually (e.g., by dividing total sales by total transactions).

--### Pre-Change vs Post-Change Analysis
--This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

--Taking the week_date value of 2020-06-15 as the baseline week where the DMart sustainable packaging changes came into effect.

--We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

--1. What is the total sales for the 4 weeks pre and post 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
with pre_cte as (
select 1 as rn, sum(cast(sales as bigint)) as Pre_sales from sales_data
where week_date between DATEADD(week, -4, '2020-06-15') and '2020-06-14'),

post_cte as (
select 1 as rn ,sum(cast(sales as bigint)) as post_sales from sales_data
where week_date between '2020-06-15' and  DATEADD(week, 3, '2020-06-15'))

select pr.pre_sales,po.post_sales, (po.post_sales - pr.Pre_sales) as groth_or_reduction_values, round(((cast(po.post_sales - pr.Pre_sales as float))/cast(pr.Pre_sales as float))*100.0,2) as percentage_of_sales  from pre_cte as pr
inner join post_cte as po
on pr.rn = po.rn;


--dono ka ho sakta he ek column or jodna he piche same to same formule me month exchange kar ke or total sale se percent nikalne he iske total sale ke hisab se itne samay me kitne percent sale hui apni

--2. What is the total sales for the 12 weeks pre and post 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
with pre_cte as (
select 1 as rn, sum(cast(sales as bigint)) as Pre_sales from sales_data
where week_date between DATEADD(week, -12, '2020-06-15') and '2020-06-14'),

post_cte as (
select 1 as rn ,sum(cast(sales as bigint)) as post_sales from sales_data
where week_date between '2020-06-15' and  DATEADD(week, 11, '2020-06-15'))

select pr.pre_sales,po.post_sales, (po.post_sales - pr.Pre_sales) as groth_or_reduction_values, round(((cast(po.post_sales - pr.Pre_sales as float))/cast(pr.Pre_sales as float))*100.0,2) as percentage_of_sales  from pre_cte as pr
inner join post_cte as po
on pr.rn = po.rn;


--3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

with date_cte as (
select cast('2018-06-15' as date) as compare_date

union all

select dateadd(year, 1, compare_date) as compare_date from date_cte
where compare_date < '2020-06-15'),
pre_post_CTE as (
select year(d.compare_date) as years,(select sum(cast(s.sales as bigint)) as Pre_sales from sales_data as s
where s.week_date between DATEADD(week, -12, d.compare_date) and dateadd(day,-1, d.compare_date)) as pre_sales,
(select sum(cast(sales as bigint)) as post_sales from sales_data
where week_date between d.compare_date and  DATEADD(week, 11, d.compare_date)) as post_sales
from date_cte as d)

select years,pre_sales,post_sales,(post_sales - pre_sales) as groth_or_reduction_values, round(((cast(post_sales - pre_sales as float))/cast(pre_sales as float))*100.0,2) as percentage_of_sales from pre_post_CTE

--### Bonus Question
--Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
--1. region
with pre_cte as (
select region, sum(cast(sales as bigint)) as Pre_sales from sales_data
where week_date between DATEADD(week, -12, '2020-06-15') and '2020-06-15'
group by region)
,

post_cte as (
select region,sum(cast(sales as bigint)) as post_sales from sales_data
where week_date between '2020-06-15' and  DATEADD(week, 12, '2020-06-15')
group by region)

select pr.region,pr.pre_sales, round(((cast(pr.Pre_sales - po.post_sales as float))/cast(po.post_sales as float))*100.0,2) as groth_or_reduction_rate ,po.post_sales, round(((cast(po.post_sales - pr.Pre_sales as float))/cast(pr.Pre_sales as float))*100.0,2) as groth_or_reduction_rate, round(cast((pr.Pre_sales+po.post_sales) as float)/(select sum(cast(sales as float)) from sales_data)*100.0,2) as percentage_of_sales  from pre_cte as pr
inner join post_cte as po
on pr.region = po.region;

--2. platform
with pre_cte as (
select platform, sum(cast(sales as bigint)) as Pre_sales from sales_data
where week_date between DATEADD(week, -12, '2020-06-15') and '2020-06-15'
group by platform)
,

post_cte as (
select platform,sum(cast(sales as bigint)) as post_sales from sales_data
where week_date between '2020-06-15' and  DATEADD(week, 12, '2020-06-15')
group by platform)

select pr.platform,pr.pre_sales, round(((cast(pr.Pre_sales - po.post_sales as float))/cast(po.post_sales as float))*100.0,2) as groth_or_reduction_rate ,po.post_sales, round(((cast(po.post_sales - pr.Pre_sales as float))/cast(pr.Pre_sales as float))*100.0,2) as groth_or_reduction_rate, round(cast((pr.Pre_sales+po.post_sales) as float)/(select sum(cast(sales as float)) from sales_data)*100.0,2) as percentage_of_sales  from pre_cte as pr
inner join post_cte as po
on pr.platform = po.platform;

--3. age_band
with pre_cte as (
select age_band, sum(cast(sales as bigint)) as Pre_sales from sales_data
where week_date between DATEADD(week, -12, '2020-06-15') and '2020-06-15'
group by age_band)
,

post_cte as (
select age_band,sum(cast(sales as bigint)) as post_sales from sales_data
where week_date between '2020-06-15' and  DATEADD(week, 12, '2020-06-15')
group by age_band)

select pr.age_band,pr.pre_sales, round(((cast(pr.Pre_sales - po.post_sales as float))/cast(po.post_sales as float))*100.0,2) as groth_or_reduction_rate ,po.post_sales, round(((cast(po.post_sales - pr.Pre_sales as float))/cast(pr.Pre_sales as float))*100.0,2) as groth_or_reduction_rate, round(cast((pr.Pre_sales+po.post_sales) as float)/(select sum(cast(sales as float)) from sales_data)*100.0,2) as percentage_of_sales  from pre_cte as pr
inner join post_cte as po
on pr.age_band = po.age_band

--4. demographic
with pre_cte as (
select demographic, sum(cast(sales as bigint)) as Pre_sales from sales_data
where week_date between DATEADD(week, -12, '2020-06-15') and '2020-06-15'
group by demographic)
,

post_cte as (
select demographic,sum(cast(sales as bigint)) as post_sales from sales_data
where week_date between '2020-06-15' and  DATEADD(week, 12, '2020-06-15')
group by demographic)

select pr.demographic,pr.pre_sales, round(((cast(pr.Pre_sales - po.post_sales as float))/cast(po.post_sales as float))*100.0,2) as groth_or_reduction_rate ,po.post_sales, round(((cast(po.post_sales - pr.Pre_sales as float))/cast(pr.Pre_sales as float))*100.0,2) as groth_or_reduction_rate, round(cast((pr.Pre_sales+po.post_sales) as float)/(select sum(cast(sales as float)) from sales_data)*100.0,2) as percentage_of_sales  from pre_cte as pr
inner join post_cte as po
on pr.demographic = po.demographic;

--5. customer_type
with pre_cte as (
select customer_type, sum(cast(sales as bigint)) as Pre_sales from sales_data
where week_date between DATEADD(week, -12, '2020-06-15') and '2020-06-15'
group by customer_type)
,

post_cte as (
select customer_type,sum(cast(sales as bigint)) as post_sales from sales_data
where week_date between '2020-06-15' and  DATEADD(week, 12, '2020-06-15')
group by customer_type)

select pr.customer_type,pr.pre_sales, round(((cast(pr.Pre_sales - po.post_sales as float))/cast(po.post_sales as float))*100.0,2) as groth_or_reduction_rate ,po.post_sales, round(((cast(po.post_sales - pr.Pre_sales as float))/cast(pr.Pre_sales as float))*100.0,2) as groth_or_reduction_rate, round(cast((pr.Pre_sales+po.post_sales) as float)/(select sum(cast(sales as float)) from sales_data)*100.0,2) as percentage_of_sales  from pre_cte as pr
inner join post_cte as po
on pr.customer_type = po.customer_type
	