/* SECTION 1 — DATA CLEANSING
   Creates: data_mart.clean_weekly_sales  */

CREATE TABLE data_mart.clean_weekly_sales AS
SELECT
    /* 1. week_date converted to DATE (source format: D/M/YY) */
    STR_TO_DATE(week_date, '%d/%m/%y')                                      AS week_date,

    /* 2. week_number — ISO-style: day-of-year ÷ 7, 1-based */
    WEEK(STR_TO_DATE(week_date, '%d/%m/%y'), 3)                             AS week_number,

    /* 3. month_number */
    MONTH(STR_TO_DATE(week_date, '%d/%m/%y'))                               AS month_number,

    /* 4. calendar_year */
    YEAR(STR_TO_DATE(week_date, '%d/%m/%y'))                                AS calendar_year,

    region,
    platform,

    /* 5 & 7. segment — replace bare 'null' strings with 'unknown' */
    CASE
        WHEN LOWER(segment) = 'null' OR segment IS NULL THEN 'unknown'
        ELSE segment
    END                                                                      AS segment,

    /* 6. age_band — mapped from trailing digit of segment */
    CASE
        WHEN LOWER(segment) = 'null' OR segment IS NULL THEN 'unknown'
        WHEN RIGHT(segment, 1) = '1'                    THEN 'Young Adults'
        WHEN RIGHT(segment, 1) = '2'                    THEN 'Middle Aged'
        WHEN RIGHT(segment, 1) IN ('3', '4')            THEN 'Retirees'
        ELSE 'unknown'
    END                                                                      AS age_band,

    /* 7. demographic — mapped from leading letter of segment */
    CASE
        WHEN LOWER(segment) = 'null' OR segment IS NULL THEN 'unknown'
        WHEN LEFT(segment, 1) = 'C'                     THEN 'Couples'
        WHEN LEFT(segment, 1) = 'F'                     THEN 'Families'
        ELSE 'unknown'
    END                                                                      AS demographic,

    customer_type,
    transactions,
    sales,

    /* 8. avg_transaction */
    ROUND(sales / transactions, 2)                                           AS avg_transaction

FROM data_mart.weekly_sales;

