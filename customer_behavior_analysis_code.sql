-- ============================================================================
-- Customer Behavior & Shopping Habits Analysis
-- Dataset : customer_transactions_800k_2025.csv (800,000 rows, Jan-Dec 2025)
-- Adapted from: "Data Analytics Using SQL: Customer Behavior and Shopping
--   Habits" (Hafez Afghan, Medium) -- structure follows the same 5 chapters;
--   queries are rewritten for this dataset's actual columns:
--   customer_id, transaction_id, transaction_date, product_purchased,
--   product_category, amount, customer_country, traffic_source
--   (no discount / age / gender / rating columns exist here, so those
--   sections are replaced with country- and traffic_source-based analogues)
-- ============================================================================

-- Load the CSV into a table first
CREATE TABLE customer_transaction AS
SELECT *
FROM read_csv_auto('customer_transactions_800k_2025.csv');

SELECT *
FROM customer_transaction
LIMIT 10;


-- ============================================================================
-- SECTION 1: DESCRIPTIVE ANALYSIS
-- Basic shape of the dataset before deeper analysis.
-- ============================================================================

SELECT
    COUNT(*)                               AS transaction_count,
    COUNT(DISTINCT customer_id)            AS customer_count,
    ROUND(SUM(amount), 2)                  AS total_revenue,
    ROUND(AVG(amount), 2)                  AS avg_order_value,
    COUNT(DISTINCT product_category)       AS category_count,
    COUNT(DISTINCT product_purchased)      AS product_count,
    COUNT(DISTINCT customer_country)       AS country_count,
    COUNT(DISTINCT traffic_source)         AS traffic_source_count
FROM customer_transaction;


-- ============================================================================
-- SECTION 2: SALES PERFORMANCE & GROWTH ANALYSIS
-- ============================================================================

-- 2a. Orders and sales by month
SELECT
    EXTRACT(MONTH FROM transaction_date) AS month,
    COUNT(*)                               AS number_of_orders,
    ROUND(SUM(amount), 2)                  AS total_sales
FROM customer_transaction
GROUP BY month
ORDER BY month;

-- 2b. Orders and sales by month AND product category
SELECT
    EXTRACT(MONTH FROM transaction_date) AS month,
    product_category,
    COUNT(*)                               AS number_of_orders,
    ROUND(SUM(amount), 2)                  AS total_sales
FROM customer_transaction
GROUP BY month, product_category
ORDER BY month, product_category;

-- 2c. Month-over-month growth in orders and sales (overall)
SELECT
    month,
    orders,
    sales,
    ROUND(((orders / LAG(orders) OVER (ORDER BY month)) - 1) * 100, 2) AS order_growth_pct,
    ROUND(((sales  / LAG(sales)  OVER (ORDER BY month)) - 1) * 100, 2) AS sales_growth_pct
FROM (
    SELECT
        EXTRACT(MONTH FROM transaction_date) AS month,
        COUNT(*)                               AS orders,
        SUM(amount)                            AS sales
    FROM customer_transaction
    GROUP BY month
) monthly
ORDER BY month;

-- 2d. Month-over-month growth in orders and sales, by product category
SELECT
    month,
    product_category,
    orders,
    sales,
    ROUND(((orders / LAG(orders) OVER (PARTITION BY product_category ORDER BY month)) - 1) * 100, 2) AS order_growth_pct,
    ROUND(((sales  / LAG(sales)  OVER (PARTITION BY product_category ORDER BY month)) - 1) * 100, 2) AS sales_growth_pct
FROM (
    SELECT
        EXTRACT(MONTH FROM transaction_date) AS month,
        product_category,
        COUNT(*)                               AS orders,
        SUM(amount)                            AS sales
    FROM customer_transaction
    GROUP BY month, product_category
) monthly_cat
ORDER BY product_category, month;


-- ============================================================================
-- SECTION 3: TRAFFIC SOURCE & COUNTRY EFFICIENCY ANALYSIS
-- here we look at how much revenue each acquisition channel and market actually drives.
-- ============================================================================

-- 3a. Revenue and orders by month and traffic source
SELECT
    EXTRACT(MONTH FROM transaction_date) AS month,
    traffic_source,
    COUNT(*)                               AS orders,
    ROUND(SUM(amount), 2)                  AS revenue
FROM customer_transaction
GROUP BY month, traffic_source
ORDER BY month, traffic_source;

-- 3b. Overall channel performance: revenue share and average order value
SELECT
    traffic_source,
    COUNT(*)                                                                   AS orders,
    ROUND(SUM(amount), 2)                                                      AS revenue,
    ROUND(AVG(amount), 2)                                                      AS avg_order_value,
    ROUND(SUM(amount) * 100.0 / (SELECT SUM(amount) FROM customer_transaction), 2) AS revenue_share_pct
FROM customer_transaction
GROUP BY traffic_source
ORDER BY revenue DESC;

-- 3c. Revenue and customers by country
SELECT
    customer_country,
    COUNT(*)                       AS orders,
    COUNT(DISTINCT customer_id)    AS customers,
    ROUND(SUM(amount), 2)          AS revenue,
    ROUND(AVG(amount), 2)          AS avg_order_value
FROM customer_transaction
GROUP BY customer_country
ORDER BY revenue DESC;

-- 3d. Month-over-month revenue growth, by traffic source
SELECT
    month,
    traffic_source,
    revenue,
    ROUND(((revenue / LAG(revenue) OVER (PARTITION BY traffic_source ORDER BY month)) - 1) * 100, 2) AS revenue_growth_pct
FROM (
    SELECT
        EXTRACT(MONTH FROM transaction_date) AS month,
        traffic_source,
        SUM(amount)                            AS revenue
    FROM customer_transaction
    GROUP BY month, traffic_source
) monthly_src
ORDER BY traffic_source, month;


-- ============================================================================
-- SECTION 4: CUSTOMER RETENTION ANALYSIS (COHORT ANALYSIS)
-- Bucket each customer into a cohort by the month of their FIRST purchase,
-- then track what % of that cohort is still transacting in each subsequent month.
-- ============================================================================

-- 4a. Retention rate (%) cohort table
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(EXTRACT(MONTH FROM transaction_date)) AS first_month
    FROM customer_transaction
    GROUP BY customer_id
),
purchase_months AS (
    SELECT DISTINCT
        customer_id,
        EXTRACT(MONTH FROM transaction_date) AS month
    FROM customer_transaction
),
cohort_index AS (
    SELECT
        pm.customer_id,
        fp.first_month,
        pm.month,
        pm.month - fp.first_month AS month_number
    FROM purchase_months pm
    JOIN first_purchase fp ON pm.customer_id = fp.customer_id
),
cohort_table AS (
    SELECT
        first_month AS cohort_month,
        SUM(CASE WHEN month_number = 0  THEN 1 ELSE 0 END) AS m0,
        SUM(CASE WHEN month_number = 1  THEN 1 ELSE 0 END) AS m1,
        SUM(CASE WHEN month_number = 2  THEN 1 ELSE 0 END) AS m2,
        SUM(CASE WHEN month_number = 3  THEN 1 ELSE 0 END) AS m3,
        SUM(CASE WHEN month_number = 4  THEN 1 ELSE 0 END) AS m4,
        SUM(CASE WHEN month_number = 5  THEN 1 ELSE 0 END) AS m5,
        SUM(CASE WHEN month_number = 6  THEN 1 ELSE 0 END) AS m6,
        SUM(CASE WHEN month_number = 7  THEN 1 ELSE 0 END) AS m7,
        SUM(CASE WHEN month_number = 8  THEN 1 ELSE 0 END) AS m8,
        SUM(CASE WHEN month_number = 9  THEN 1 ELSE 0 END) AS m9,
        SUM(CASE WHEN month_number = 10 THEN 1 ELSE 0 END) AS m10,
        SUM(CASE WHEN month_number = 11 THEN 1 ELSE 0 END) AS m11
    FROM cohort_index
    GROUP BY first_month
)
SELECT
    cohort_month,
    ROUND(m0  / CAST(m0 AS DECIMAL) * 100, 0) AS m0,
    ROUND(m1  / CAST(m0 AS DECIMAL) * 100, 0) AS m1,
    ROUND(m2  / CAST(m0 AS DECIMAL) * 100, 0) AS m2,
    ROUND(m3  / CAST(m0 AS DECIMAL) * 100, 0) AS m3,
    ROUND(m4  / CAST(m0 AS DECIMAL) * 100, 0) AS m4,
    ROUND(m5  / CAST(m0 AS DECIMAL) * 100, 0) AS m5,
    ROUND(m6  / CAST(m0 AS DECIMAL) * 100, 0) AS m6,
    ROUND(m7  / CAST(m0 AS DECIMAL) * 100, 0) AS m7,
    ROUND(m8  / CAST(m0 AS DECIMAL) * 100, 0) AS m8,
    ROUND(m9  / CAST(m0 AS DECIMAL) * 100, 0) AS m9,
    ROUND(m10 / CAST(m0 AS DECIMAL) * 100, 0) AS m10,
    ROUND(m11 / CAST(m0 AS DECIMAL) * 100, 0) AS m11
FROM cohort_table
ORDER BY cohort_month;

-- 4b. Churn rate (%) = 100 - retention rate. Wrap 4a as a CTE (retention_cte)
-- and subtract each column from 100, e.g.:
-- SELECT cohort_month, 100-m0 AS m0, 100-m1 AS m1, ..., 100-m11 AS m11
-- FROM retention_cte;

-- 4c. Deep Dive: Root Cause Analysis of the Significant Drop in Retention Rate for the July Cohort
-- We will analyze the July cohort's retention drop by examining product categories, traffic sources, 
-- and customer countries for that cohort.
-- (1) By Traffic Sources
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(transaction_date) AS first_date
    FROM customer_transaction
    GROUP BY customer_id
),
first_txn AS (
    SELECT
        ct.customer_id,
        EXTRACT(MONTH FROM fp.first_date) AS cohort_month,
        ct.traffic_source
    FROM customer_transaction ct
    JOIN first_purchase fp
        ON ct.customer_id = fp.customer_id
       AND ct.transaction_date = fp.first_date
)
SELECT
    cohort_month,
    traffic_source,
    COUNT(*) AS new_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY cohort_month), 1) AS pct_of_month
FROM first_txn
GROUP BY cohort_month, traffic_source
ORDER BY cohort_month, traffic_source;

-- (2) By Country
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(transaction_date) AS first_date
    FROM customer_transaction
    GROUP BY customer_id
),
first_txn AS (
    SELECT
        ct.customer_id,
        EXTRACT(MONTH FROM fp.first_date) AS cohort_month,
        ct.customer_country
    FROM customer_transaction ct
    JOIN first_purchase fp
        ON ct.customer_id = fp.customer_id
       AND ct.transaction_date = fp.first_date
)
SELECT
    cohort_month,
    customer_country,
    COUNT(*) AS new_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY cohort_month), 1) AS pct_of_month
FROM first_txn
GROUP BY cohort_month, customer_country
ORDER BY cohort_month, customer_country;

-- (3) By Product Category
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(transaction_date) AS first_date
    FROM customer_transaction
    GROUP BY customer_id
),
first_txn AS (
    SELECT
        ct.customer_id,
        EXTRACT(MONTH FROM fp.first_date) AS cohort_month,
        ct.product_category
    FROM customer_transaction ct
    JOIN first_purchase fp
        ON ct.customer_id = fp.customer_id
       AND ct.transaction_date = fp.first_date
)
SELECT
    cohort_month,
    product_category,
    COUNT(*) AS new_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY cohort_month), 1) AS pct_of_month
FROM first_txn
GROUP BY cohort_month, product_category
ORDER BY cohort_month, product_category;

-- ============================================================================
-- SECTION 5: CUSTOMER BEHAVIOR ANALYSIS
-- ============================================================================

-- 5a. Revenue trend by month 
SELECT
    EXTRACT(MONTH FROM transaction_date) AS month,
    ROUND(SUM(amount), 2)                  AS revenue
FROM customer_transaction
GROUP BY month
ORDER BY month;

-- 5b. Most frequently purchased products (ranked)
SELECT
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk,
    product_purchased,
    COUNT(*)                                   AS purchase_count,
    ROUND(SUM(amount), 2)                      AS total_revenue
FROM customer_transaction
GROUP BY product_purchased
ORDER BY rnk;

-- 5c. Top-selling product per country
-- product preference breakdown
WITH product_by_country AS (
    SELECT
        customer_country,
        product_purchased,
        COUNT(*) AS purchase_count,
        DENSE_RANK() OVER (PARTITION BY customer_country ORDER BY COUNT(*) DESC) AS rnk
    FROM customer_transaction
    GROUP BY customer_country, product_purchased
)
SELECT customer_country, product_purchased, purchase_count
FROM product_by_country
ORDER BY customer_country;

-- 5d. Does purchase frequency affect average spend per order? 
WITH customer_stats AS (
    SELECT
        customer_id,
        COUNT(*)               AS order_count,
        ROUND(AVG(amount), 2)  AS avg_spend
    FROM customer_transaction
    GROUP BY customer_id
)
SELECT
    order_count AS transactions_per_customer,
    COUNT(*)    AS num_customers,
    ROUND(AVG(avg_spend), 2) AS avg_order_value
FROM customer_stats
GROUP BY order_count
ORDER BY order_count;

WITH customer_stats AS (
SELECT
    customer_id,
    COUNT(*) AS order_count,
    AVG(amount) AS avg_spend
FROM customer_transaction
GROUP BY customer_id
)

SELECT *
FROM customer_stats;

-- 5e. Repeat purchase rate -> loyalty measurement
WITH customer_orders AS (
    SELECT customer_id, COUNT(*) AS order_count
    FROM customer_transaction
    GROUP BY customer_id
)
SELECT
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    COUNT(*)                                          AS total_customers,
    ROUND(SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS repeat_purchase_rate_pct
FROM customer_orders;
