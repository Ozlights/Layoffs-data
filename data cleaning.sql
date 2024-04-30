-- Data cleaning



-- Creating a staging table for the safety of the original data

-- Create a staging table 'layoffs_staging' using the structure of 'layoffs'
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Insert data into 'layoffs_staging' from 'layoffs'
INSERT layoffs_staging
SELECT *
FROM  layoffs_staging;



-- Remove Duplicates

/*
Cleaning Guy Annotations (CGA):
The ROW_NUMBER function is utilized to assign a unique sequential integer to each row in the result set. 
When considering multiple columns, this allows us to identify duplicates. 
Since `rownum` is a calculated value and not directly accessible in the WHERE clause due to the sequence of operations, 
we use a Common Table Expression (CTE) to overcome this limitation.
*/

with row_num_table as 
(
	select 
		*,
		row_number() 
        OVER(
        partition by company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) 
        as row_num
	from  layoffs_staging
)
select *
from row_num_table 
where row_num > 1;

-- Creating a new table with the row_num column to be able to identify and delete duplicates
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Inserting data into 'layoffs_staging2' with 'row_num' calculation
INSERT layoffs_staging2
SELECT 
		*,
		row_number() 
        OVER(
        partition by company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) 
        as row_num
from layoffs_staging;

-- Checking for duplicates in 'layoffs_staging2'
select *
from layoffs_staging2
where row_num > 1;

-- Removing duplicates from 'layoffs_staging2' (had to uncheck the safe update/delete in preferences AND reload the app)
delete from layoffs_staging2
where row_num > 1;

-- Removing the row_num column from the layoffs_staging2 table
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;



-- Standardize the Data

-- Checking company column
select company, trim(company)
from layoffs_staging2;

-- Removing whitespaces
update layoffs_staging2
set company = trim(company);

-- Checking industry column
select distinct industry
from layoffs_staging2
order by industry;

-- Updating Crypto, Crypto Currency, CryptoCurrency with a common name (Crypto) 
update layoffs_staging2
set industry = 'Crypto'
where industry LIKE 'Crypto%';

-- Checking location column
select distinct location
from layoffs_staging2
order by location;

-- Checking country column
select distinct country
from layoffs_staging2
order by country;

-- Update United States. to United States (using trim/trailing to remove unwanted '.')
update layoffs_staging2
set country = trim(trailing '.' from country)
where country like 'United States%';

-- Checking date column
select 
	`date`,
	str_to_date(`date`, '%m/%d/%Y')
from layoffs_staging2;

-- Upadte to date format
update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');

-- Chage date column type string to date (now that the format is a date format)
alter table layoffs_staging2
modify column `date` date;



-- Null or blank values

-- industry
select *
from layoffs_staging2
where industry is null 
or industry = '';

-- Checking for a existing location value in other entry
select *
from layoffs_staging2
where company = 'Airbnb';

-- Update blank values to null for later manipultaion 
UPDATE layoffs_staging2
set industry = null
where industry = '';


-- Set the 'industry' value of rows where it is NULL to the 'industry' value of another row where 'company' values match
-- This is done to fill missing 'industry' values based on matching 'company' values
-- va a llenar los null con los mismos datos de industry que no esten vacios en donde las companias sean iguales
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


-- Total_laid_off and percentage_laid_off
select *
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

-- Count total_laid_off and percentage_laid_off
select count(*)
from layoffs_staging2
where total_laid_off is null and percentage_laid_off is null;

-- Remove unuseful values for analysis
delete from layoffs_staging2
where total_laid_off is null and percentage_laid_off is null;





