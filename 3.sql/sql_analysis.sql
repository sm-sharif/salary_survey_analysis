-- =====================================================
-- SALARY SURVEY SQL ANALYSIS
-- Author: [S. M. Sharifuzzaman]
-- Database: PostgreSQL
-- Date: October 2025
-- Dataset: 27,739 salary responses from 2021
-- =====================================================

-- Query 1: Top 10 highest paying industries
-- Question 1: Which industry pay the most on average?
-- -----------------------------------------------------
select 
job_category,
round(avg(annual_salary_usd::numeric),2) as average_salary,
round(min(annual_salary_usd::numeric),2) as minimum_salary,
round(max(annual_salary_usd::numeric),2) as maximum_salary,
count(*) as total_employees
from salary_data
group by job_category
order by average_salary desc
limit 10

-- Query 2: Salary Distribution by Career Level
-- Business Question: How does salary vary across career stages?
-- -----------------------------------------------------

select 
career_level,
round(avg(annual_salary_usd)) as average_salary,
count(*) total_employees
from salary_data
group by career_level
order by average_salary

-- Query 3: Top 10 US States by Average Salary
-- Business Question: Which states in US offer highest salaries?
-- -----------------------------------------------------

select 
state,
round(avg(annual_salary_usd)) as average_salary,
count(*) as total_employees
from salary_data
where country = 'United States'
and state is not null
group by state
having count(*) >= 100
order by average_salary desc
limit 10

-- Query 4: Gender Pay Gap Overall
-- Business Question: What is the salary difference between genders?
-- -----------------------------------------------------
with gender_avg as
(
select 
round(avg(case when gender = 'Man' then annual_salary_usd end)) as man_avg_salary,
round(avg(case when gender = 'Woman' then annual_salary_usd end)) as woman_avg_salary
from salary_data
)

select 
man_avg_salary, 
woman_avg_salary,
case when man_avg_salary > woman_avg_salary then man_avg_salary - woman_avg_salary 
else woman_avg_salary - man_avg_salary end as salary_difference,

case when man_avg_salary > woman_avg_salary then round((man_avg_salary / woman_avg_salary -1)::numeric*100,2)
else round((woman_avg_salary / man_avg_salary-1)::numeric*100,2) end as salary_difference_in_percentage,

case when man_avg_salary > woman_avg_salary then 'man earns more'
else 'woman earns more' end as direction
from gender_avg

-- Query 5: Gender Pay Gap by Industry
-- Business Question: Which industries have the largest gender pay gaps?
-- -----------------------------------------------------

select 
job_category,
count(*) as total_employee,
round(avg(case when gender = 'Man' then annual_salary_usd end)) as man_avg_salary,
round(avg(case when gender = 'Woman' then annual_salary_usd end)) as woman_avg_salary,
round(avg(case when gender = 'Man' then annual_salary_usd end)) - 
round(avg(case when gender = 'Woman' then annual_salary_usd end)) as gap,
round((round(avg(case when gender = 'Man' then annual_salary_usd end)) / 
round(avg(case when gender = 'Woman' then annual_salary_usd end)) - 1) * 100) as percentage
from salary_data
where gender in ('Man', 'Woman')
and job_category not in ('Unclassifiable')
group by job_category
having count(*) > 500
order by gap desc
limit 5


-- Query 6: Salary Ranges by Education Level
-- Business Question: What's the salary premium for higher education?
-- -----------------------------------------------------

select
degree,
round(avg(annual_salary_usd)) as avg_annual_salary,
round(min(annual_salary_usd)) as min_annual_salary,
round(max(annual_salary_usd)) as max_annual_salary,
round(max(annual_salary_usd)) - round(min(annual_salary_usd)) as salary_range
from salary_data
group by degree
order by round(avg(annual_salary_usd)) desc

-- Query 7: Salary Percentiles by Career Level
-- Business Question: What are the salary benchmarks (25th, 50th, 75th, 90th percentiles)?
-- -----------------------------------------------------

select 
career_level,
count(*) as total_population,
percentile_cont(0.25) within group (order by annual_salary_usd) as "25th",
percentile_cont(0.50) within group (order by annual_salary_usd) as "50th",
percentile_cont(0.75) within group (order by annual_salary_usd) as "75th",
round(percentile_cont(0.90) within group (order by annual_salary_usd)) as "90th"
from salary_data
group by career_level
order by 
case career_level
when 'Entry Level' then 1
when 'Mid Level' then 2
when 'Senior' then 3
when 'Lead/Executive' then 4
end

-- Query 8: Salary Ranking Within Each Industry
-- Business Question: Who are the top earners in each industry?
-- -----------------------------------------------------
with max_salary as
(
select 
job_category,
job_title,
annual_salary_usd,
row_number() over(partition by job_category order by annual_salary_usd desc) as ranking
from salary_data
)

select 
job_category,
job_title,
annual_salary_usd
from max_salary
where ranking = 1
order by annual_salary_usd desc

-- or

select 
s1.job_category,
s1.job_title,
s1.annual_salary_usd
from salary_data s1
join 
(select 
job_category,
max(annual_salary_usd) max_salary
from salary_data
group by job_category) s2
on s1.job_category = s2.job_category and s1.annual_salary_usd = s2.max_salary
order by s1.annual_salary_usd desc

-- Query 9: Running Total of Employees by Experience
-- Business Question: How does workforce experience distribute cumulatively?
-- -----------------------------------------------------

select
overall_exp,
count(*) as num_employees,
round(avg(annual_salary_usd)) avg_salary,
sum(count(*)) over(order by overall_exp) cumulative_emp_count,
round(sum(count(*)) over(order by overall_exp) * 100
/
sum(count(*)) over()) as cumulative_percentage
from salary_data
group by overall_exp

-- Query 10: Industries Paying Above Average
-- Business Question: Which industries pay significantly above market average?
-- -----------------------------------------------------

with cte as(
select
round(avg(annual_salary_usd)) mkt_avg
from salary_data
)
select
job_category,
round(avg(annual_salary_usd)) as industry_avg,
mkt_avg,
round(avg(annual_salary_usd)) - mkt_avg as premium,
round(((avg(annual_salary_usd) - mkt_avg) / mkt_avg) *100) as percentage
from salary_data,cte
group by job_category, mkt_avg
having round(avg(annual_salary_usd)) > 0
order by percentage desc


-- Query 11: Top 20 Highest Paying Job Titles
-- Business Question: What specific job titles command the highest salaries?
-- -----------------------------------------------------

with salary_stats as(
select 
job_title,
count(*) total_emp,
round(avg(annual_salary_usd)) avg_annual_salary
from salary_data
group by job_title
having count(*) > 5
)
select 
job_title,
avg_annual_salary
from salary_stats
order by avg_annual_salary desc
limit 20

-- Query 12: Salary by Career Level AND Industry (Top 5 Industries)
-- Business Question: How does career progression vary by industry?
-- -----------------------------------------------------

select
job_category,
career_level ,
round(avg(annual_salary_usd))
from salary_data
where job_category in (select job_category from salary_data group by job_category order by count(*) desc limit 5)
group by job_category, career_level
order by 
job_category,
case career_level 
when 'Entry Level' then 1
when 'Mid Level' then 2
when 'Senior' then 3
when 'Lead/Executive' then 4
end

-- Query 13: Age Group Salary Analysis
-- Business Question: How does salary vary across age demographics?
-- -----------------------------------------------------

select
age_group,
round(avg(annual_salary_usd)) avg_salary,
round(avg(overall_exp)) avg_exp
from salary_data
group by age_group
having count(*) > 150
order by 
case age_group
when '18-24' then 1
when '25-34' then 2
when '35-44' then 3
when '45-54' then 4
when '55-64' then 5
end

-- Query 14: Salary Growth Rate Analysis (Entry to Lead)
-- Business Question: Which industries offer the best career growth potential?
-- -----------------------------------------------------

with cte as
(
select
job_category,
round(avg((case when career_level = 'Entry Level' then  annual_salary_usd end))) entry_level_salary,
round(avg((case when career_level = 'Lead/Executive' then  annual_salary_usd end))) lead_executive_salary
from salary_data
where job_category in 
(
select job_category 
from salary_data 
group by job_category 
having count(*)>100 
order by avg(annual_salary_usd) desc 
limit 10
)
group by job_category
)
select
job_category,
entry_level_salary,
lead_executive_salary,
lead_executive_salary - entry_level_salary as absolute_growth,
round((lead_executive_salary / entry_level_salary -1)*100) as growth_rate
from cte
where entry_level_salary is not null and lead_executive_salary is not null
order by growth_rate desc

-- Query 15: International Salary Comparison (Top 10 Countries)
-- Business Question: Which countries offer the best compensation?
-- -----------------------------------------------------

select 
country,
round(avg(annual_salary_usd)) as avg_salary
from salary_data
group by country
having count(*) > 150
order by avg_salary desc
limit 10

-- BONUS Query 16: Complete Summary Statistics
-- Business Question: What's the overall dataset snapshot?
-- -----------------------------------------------------
select 
    count(*) as total_employees,
    round(avg(annual_salary_usd)) as avg_salary,
    round(stddev(annual_salary_usd)) as salary_stddev,
    round(min(annual_salary_usd)) as min_salary,
    round(max(annual_salary_usd)) as max_salary,
    round(percentile_cont(0.5) within group (order by annual_salary_usd)) as median_salary,
    count(distinct job_category) as num_industries,
    count(distinct country) as num_countries,
    round(avg(overall_exp)) as avg_experience_years
from salary_data




