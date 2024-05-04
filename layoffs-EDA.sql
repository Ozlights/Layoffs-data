-- Exploratory Data Analysis

select *
from layoffs_staging2;

-- Find the maximun layoffs and if there were companies that laid off all their workers

select MAX(total_laid_off), MAX(percentage_laid_off)
from layoffs_staging2;

-- Companies that laid off all their workers (1 = 100%)

select *
from layoffs_staging2
where percentage_laid_off = 1
order by total_laid_off desc;

-- Identify companies that laid off the most workers

select company, sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc;

-- Identify industries that laid off the most workers

select industry, sum(total_laid_off)
from layoffs_staging2
group by industry
order by 2 desc;

-- Identify countries that laid off the most workers

select country, sum(total_laid_off)
from layoffs_staging2
group by country
order by 2 desc;

-- Identify the year where most workers were laid off

select year(`date`), sum(total_laid_off)
from layoffs_staging2
group by 1
order by 1 desc;



select substring(`date`,1,7) as `month`, sum(total_laid_off)
from layoffs_staging2
group by 1
having `month` is not null
order by 1 asc;

-- This query calculates the total number of employees laid off for each month, 
-- as well as the rolling total of laid off employees over time.

-- Common Table Expression (CTE) to calculate total laid off by month
with date_month as
(
    -- Extract the year and month part of the date and calculate the total laid off for each month
    select substring(`date`,1,7) as `month`, sum(total_laid_off) as total_off
    from layoffs_staging2
    -- Group the data by the extracted month
    group by 1
    -- Filter out rows where the month is null
    having `month` is not null
)
-- Main query to select the month, total laid off for that month, and the rolling total of laid off employees over time
select `month`, total_off, sum(total_off) over(order by `month`) as rolling_total
from date_month;

-- Company ranking

select company, year(`date`),sum(total_laid_off)
from layoffs_staging2
group by company, 2
order by 3 desc;


-- This query calculates the total number of employees laid off by each company for each year,
-- assigns a ranking to each company within each year based on the total number of layoffs,
-- and selects the top 5 ranked companies for each year.

-- Common Table Expression (CTE) to calculate total laid off by each company for each year
with company_year as
(
    -- Extract the year from the date, and calculate the total laid off for each company for each year
    select company, year(`date`) as years, sum(total_laid_off) as total_laidoff
    from layoffs_staging2
    -- Group the data by company and year
    group by company, 2
    -- Filter out rows where the year is null
    having years is not null
),
-- Common Table Expression (CTE) to assign ranking to each company within each year
company_rank as (
    select *, dense_rank() over (partition by years order by total_laidoff desc) as ranking
    from company_year
)
-- Main query to select all columns from the ranking CTE and filter the results to show only the top 5 ranked companies for each year
select *
from company_rank
where ranking <= 5;

-- This query categorizes companies into stage groups based on their funding stage,
-- calculates the total number of employees laid off for each company in each stage group for each year,
-- assigns a ranking to each stage group within each year based on the total number of layoffs,
-- and presents the total number of layoffs for each stage group, ordered by the total number of layoffs in descending order.

-- Common Table Expression (CTE) to categorize companies into stage groups and calculate total laid off by each company for each year
with company_year_stage as
(
    select 
        company, 
        year(`date`) as years,
        case 
            when stage in ('Seed', 'Series A') then 'Early Stage'
            when stage in ('Series B', 'Series C') then 'Mid Stage'
            when stage in ('Series D', 'Series E') then 'Late Stage'
            when stage in ('Series F', 'Series G', 'Series H', 'Series I', 'Series J') then 'Later Stage'
            else stage
        end as stage_group,
        sum(total_laid_off) as total_laidoff
    from layoffs_staging2
    group by company, years, stage_group
    having years is not null
    and stage_group is not null
), 
-- Common Table Expression (CTE) to assign ranking to each stage group within each year
stage_group_rank as (
    select 
        *, 
        dense_rank() over (partition by years, stage_group order by total_laidoff desc) as ranking
    from company_year_stage
)
-- Main query to select the stage group and the total number of layoffs for each stage group, ordered by total number of layoffs in descending order
select 
    stage_group,
    sum(total_laidoff) as total_laidoff
from stage_group_rank
group by stage_group
order by total_laidoff desc;