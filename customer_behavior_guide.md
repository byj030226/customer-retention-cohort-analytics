# Customer Behavior and Shopping Habits Analysis
Tools: SQL | CTE | Window Functions | DuckDB (execution) | MySQL (target dialect)

Dataset: `customer_transactions_800k_2025.csv`. It contains 800,000 transactions from January to December 2025, covering 220,000 unique customers, with no missing values.

Columns: `customer_id, transaction_id, transaction_date, product_purchased, product_category, amount, customer_country, traffic_source`

---

# Executive Summary

## 1. Business Background

The business behind this dataset is a global, multi-channel retailer. It sells across ten countries: Australia, Brazil, Canada, France, Germany, India, Japan, Mexico, the UK, and the US. Customers arrive through six acquisition channels: Google, Organic, Facebook, Email, Ads, and Referral. The catalog spans six categories (Electronics, Fashion, Home, Books, Accessories, and Kids), represented by ten flagship products ranging from a $20 book to a laptop priced above $1,200. In 2025, the business recorded 800,000 transactions from 220,000 distinct customers, generating $218.2M in revenue.

## 2. Problem Statement

Leadership needs a clear, data-backed view of customer behavior and shopping habits to plan for 2026. Specifically, they need to know which months and product lines drive the most revenue, whether marketing channels and geographic markets perform evenly, whether customers stay loyal or churn, and which products sell best in which markets. Without this information, budget and inventory decisions for next year would rely on guesswork instead of evidence.

## 3. Business Solution & Objective

This analysis answers those questions using SQL alone. It combines descriptive statistics, time-series trend and growth analysis, channel and market efficiency comparisons, cohort-based retention analysis, and product and customer behavior analysis. The findings are organized into the five chapters below.

---

# Dataset Overview

## 1. Dataset Description

The source file is a single flat table of transaction-level records, with one row per purchase. It spans the full 2025 calendar year, with no gaps, duplicates, or null values in any column. Each row represents one transaction, so repeat buyers naturally generate multiple rows tied to the same `customer_id`.

## 2. Data Structure

| Column | Type | Description |
|---|---|---|
| `customer_id` | integer | Unique identifier for the customer; repeats across transactions |
| `transaction_id` | string | Unique identifier for the transaction (one per row) |
| `transaction_date` | date | Date the transaction occurred (2025-01-01 to 2025-12-31) |
| `product_purchased` | string | The specific item bought (10 distinct products) |
| `product_category` | string | The category the product belongs to (6 distinct categories) |
| `amount` | decimal | Transaction value in dollars |
| `customer_country` | string | Two-letter country code of the customer (10 distinct countries) |
| `traffic_source` | string | Acquisition/marketing channel for the transaction (6 distinct sources) |

Distinct value counts, confirmed directly from the data: 220,000 customers, 6 product categories, 10 products, 10 countries, 6 traffic sources.

---

# Analysis

## 1. Descriptive Analysis

This step establishes the overall shape of the dataset before drilling into details. It answers basic questions: how many transactions, how many customers, total revenue, and how many distinct categories, products, countries, and channels.

```sql
SELECT
    COUNT(*)                          AS transaction_count,
    COUNT(DISTINCT customer_id)       AS customer_count,
    ROUND(SUM(amount), 2)             AS total_revenue,
    ROUND(AVG(amount), 2)             AS avg_order_value,
    COUNT(DISTINCT product_category)  AS category_count,
    COUNT(DISTINCT product_purchased) AS product_count,
    COUNT(DISTINCT customer_country)  AS country_count,
    COUNT(DISTINCT traffic_source)    AS traffic_source_count
FROM customer_transaction;
```

**Result:**

| transactions | customers | total_revenue | avg_order_value | categories | products | countries | traffic_sources |
|---|---|---|---|---|---|---|---|
| 800,000 | 220,000 | $218,184,133.21 | $272.73 | 6 | 10 | 10 | 6 |

Each customer makes about 3.6 transactions per year on average. Revenue is spread evenly across countries, with roughly 80,000 transactions each. This suggests the dataset is intentionally balanced by market. Average order value is also remarkably consistent regardless of channel or country, a pattern confirmed in later sections.

These figures should serve as the 2026 baseline scorecard: 3.6 transactions per customer, $272.73 average order value, and $218.2M in total revenue. Any future monthly or quarterly data pull should be checked against this baseline first. A drop in transactions per customer is often the earliest sign of a loyalty problem. A shift in average order value is often the earliest sign of a pricing or product-mix change. Both tend to appear well before they show up in total revenue.

## 2. Performance & Sales Growth Analysis

**2a. Orders and sales by month**

```sql
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS month,
    COUNT(*)                               AS number_of_orders,
    ROUND(SUM(amount), 2)                  AS total_sales
FROM customer_transaction
GROUP BY month
ORDER BY month;
```

| month | orders | sales |
|---|---|---|
| 2025-01 | 28,079 | $7,610,185 |
| 2025-02 | 39,940 | $10,806,861 |
| 2025-03 | 58,208 | $15,879,309 |
| 2025-04 | 72,540 | $19,792,659 |
| 2025-05 | 85,814 | $23,292,665 |
| 2025-06 | 92,694 | $25,412,155 |
| **2025-07** | **96,337** | **$26,132,094** ← peak |
| 2025-08 | 90,116 | $24,786,104 |
| 2025-09 | 76,052 | $20,846,805 |
| 2025-10 | 65,094 | $17,630,426 |
| 2025-11 | 51,534 | $14,105,408 |
| 2025-12 | 43,592 | $11,889,461 |

There is a clear arc across the year. Orders and sales ramp up steadily from January, peak in July, and then decline through December. Orders and revenue move together throughout the year, with no month breaking that pattern.

**2b. Same breakdown, by product category**

```sql
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS month,
    product_category,
    COUNT(*)                               AS number_of_orders,
    ROUND(SUM(amount), 2)                  AS total_sales
FROM customer_transaction
GROUP BY month, product_category
ORDER BY month, product_category;
```

Every category follows the same seasonal shape: a ramp-up to July, then a decline through December. This pattern applies across the whole dataset, not just one category. Electronics dominates dollar volume every month. For example, $5.9M of January's $7.6M in sales came from Electronics alone, because the category contains the highest-priced items, like laptops and phones.

**2c. Month-over-month growth (overall)**

Uses `LAG()` to compare each month to the one before it:

```sql
SELECT
    month, orders, sales,
    ROUND(((orders / LAG(orders) OVER (ORDER BY month)) - 1) * 100, 2) AS order_growth_pct,
    ROUND(((sales  / LAG(sales)  OVER (ORDER BY month)) - 1) * 100, 2) AS sales_growth_pct
FROM (
    SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS month, COUNT(*) AS orders, SUM(amount) AS sales
    FROM customer_transaction GROUP BY month
) monthly
ORDER BY month;
```

| month | order_growth | sales_growth |
|---|---|---|
| 2025-02 | +42.2% | +42.0% |
| 2025-03 | +45.7% | +46.9% |
| 2025-04 | +24.6% | +24.6% |
| 2025-05 | +18.3% | +17.7% |
| 2025-06 | +8.0% | +9.1% |
| 2025-07 | +3.9% | +2.8% |
| 2025-08 | **−6.5%** | **−5.1%** |
| 2025-09 | −15.6% | −15.9% |
| 2025-10 | −14.4% | −15.4% |
| 2025-11 | −20.8% | −20.0% |
| 2025-12 | −15.4% | −15.7% |

Growth turns negative starting in August and stays negative for the rest of the year. The July peak marks the exact turning point where growth momentum reverses.

**2d. Growth by category**

The same query, partitioned by `product_category`, shows every category tracing essentially the same growth curve: positive through July, negative afterward. This confirms the July inflection point is a dataset-wide pattern, not specific to one category.

**Business Recommendation:** Build the 2026 demand-generation and inventory calendar around a single, company-wide seasonal curve rather than separate curves for each category, since every category peaks and declines together. Treat August as the trigger point for renewed promotional activity. Waiting until the traditional Q4 push means reacting a full quarter after growth has already turned negative. Because this pattern repeats across every category, it is worth confirming with Finance and Merchandising whether it comes from an external seasonal factor, such as a mid-year sale event that could be deliberately repeated, or whether it is linked to the acquisition patterns uncovered in Section 4.

## 3. Traffic Source & Country Efficiency Analysis

**3a/3b. Channel performance (revenue share & average order value)**

```sql
SELECT
    traffic_source,
    COUNT(*)                                                                   AS orders,
    ROUND(SUM(amount), 2)                                                      AS revenue,
    ROUND(AVG(amount), 2)                                                      AS avg_order_value,
    ROUND(SUM(amount) * 100.0 / (SELECT SUM(amount) FROM customer_transaction), 2) AS revenue_share_pct
FROM customer_transaction
GROUP BY traffic_source
ORDER BY revenue DESC;
```

| traffic_source | orders | revenue | AOV | revenue share |
|---|---|---|---|---|
| Google | 247,007 | $67,421,633 | $272.95 | 30.9% |
| Organic | 171,937 | $46,714,350 | $271.69 | 21.4% |
| Facebook | 142,048 | $38,829,747 | $273.36 | 17.8% |
| Email | 103,227 | $28,187,254 | $273.06 | 12.9% |
| Ads | 95,879 | $26,193,382 | $273.19 | 12.0% |
| Referral | 39,902 | $10,837,767 | $271.61 | 5.0% |

Google drives nearly a third of all revenue. Average order value is nearly identical across every channel, all within $2 of each other at roughly $272 to $273. This means channel does not influence how much a customer spends per transaction. It only influences how many transactions the channel brings in.

**3c. Revenue by country**

```sql
SELECT
    customer_country,
    COUNT(*)                    AS orders,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(SUM(amount), 2)       AS revenue,
    ROUND(AVG(amount), 2)       AS avg_order_value
FROM customer_transaction
GROUP BY customer_country
ORDER BY revenue DESC;
```

All ten countries fall within a tight band: $21.6M to $22.0M in revenue, roughly 66,000 to 66,500 customers, and $270 to $274 in average order value each. No market stands out as underperforming or overperforming. The dataset appears deliberately balanced across geography.

**3d. Month-over-month revenue growth by traffic source**

The same `LAG()` pattern from 2c, partitioned by channel, shows every channel tracking the same ramp-to-July-then-decline curve as the overall trend. Ads, for example, grows from $894K in January to $3.15M in July, including a single-month jump of 57.6% in March. It then declines every month starting in August.

**Business Recommendation:** Average order value is essentially flat across every channel and country, so channel and market budget decisions should not be based on AOV differences, since there are none to act on. The real lever is cost per acquisition, which this table cannot show because it has no ad-spend data. Pulling in cost data from each channel platform, such as Google Ads, Meta, and email platform costs, is the natural next step before reallocating budget. In the meantime, Google's 31% revenue share makes it the highest-priority channel to protect. Referral's small 5% share, combined with its likely lower cost per acquisition, makes it worth testing for incremental investment. Geographically, no market needs intervention. The ten countries are close enough that regional budget can stay roughly fixed, with effort instead focused on the timing question raised in Section 4.

## 4. Customer Retention Analysis — Cohort Analysis

This analysis groups customers into cohorts by the month of their first purchase. It then tracks what percentage of each original cohort is still buying in each subsequent month.

```sql
WITH first_purchase AS (
    SELECT customer_id, MIN(DATE_FORMAT(transaction_date, '%Y-%m')) AS first_month
    FROM customer_transaction GROUP BY customer_id
),
purchase_months AS (
    SELECT DISTINCT customer_id, DATE_FORMAT(transaction_date, '%Y-%m') AS month
    FROM customer_transaction
),
cohort_index AS (
    SELECT pm.customer_id, fp.first_month, pm.month,
        PERIOD_DIFF(
            DATE_FORMAT(STR_TO_DATE(CONCAT(pm.month, '-01'), '%Y-%m-%d'), '%Y%m'),
            DATE_FORMAT(STR_TO_DATE(CONCAT(fp.first_month, '-01'), '%Y-%m-%d'), '%Y%m')
        ) AS month_number
    FROM purchase_months pm JOIN first_purchase fp ON pm.customer_id = fp.customer_id
),
cohort_table AS (
    SELECT first_month AS cohort_month,
        SUM(CASE WHEN month_number=0 THEN 1 ELSE 0 END) AS m0,
        -- ... m1 through m11, see full script
    FROM cohort_index GROUP BY first_month
)
SELECT cohort_month,
    ROUND(m0/CAST(m0 AS DECIMAL)*100,0) AS m0,
    -- ... m1 through m11
FROM cohort_table ORDER BY cohort_month;
```

**Retention rate (%) by cohort:**

| cohort | m0 | m1 | m2 | m3 | m4 | m5 | m6 |
|---|---|---|---|---|---|---|---|
| 2025-01 | 100 | 51 | 65 | 59 | 51 | 42 | 35 |
| 2025-02 | 100 | 54 | 65 | 62 | 51 | 45 | 34 |
| 2025-03 | 100 | 57 | 67 | 61 | 52 | 43 | 32 |
| 2025-04 | 100 | 59 | 67 | 63 | 53 | 42 | 32 |
| 2025-05 | 100 | 59 | 69 | 64 | 51 | 42 | 31 |
| 2025-06 | 100 | 61 | 69 | 62 | 53 | 41 | 32 |
| **2025-07** | 100 | **27** | 18 | 9 | 6 | 5 | – |
| 2025-08 | 100 | 26 | 19 | 9 | 7 | – | – |
| 2025-09 | 100 | 28 | 19 | 10 | – | – | – |
| 2025-10 | 100 | 27 | 21 | – | – | – | – |
| 2025-11 | 100 | 29 | – | – | – | – | – |
| 2025-12 | 100 | – | – | – | – | – | – |

There is a sharp structural break in the data. Customers acquired between January and June retain much better: 51% to 61% are still buying a month later, and this rate decays gradually over the following months. Customers acquired between July and December show a very different pattern. Their retention collapses to roughly 27% after just one month and keeps falling quickly. Whatever drove the July order and revenue peak in Section 2 also brought in a much less loyal customer base. Churn rate is simply 100 minus retention. The January cohort, for example, has 49% churn by month 1 and 65% churn by month 6.

**Deep dive: root cause of the July retention drop**

The retention table raises an obvious question: what actually changed about customers acquired starting in July? To answer this, each available dimension in the dataset was tested: acquisition channel, country, and product category. Each one was checked against new-customer composition by cohort month, to see whether the mix of arriving customers shifted at the same point retention broke down.

```sql
-- New-customer acquisition mix by traffic source, per cohort month
WITH first_purchase AS (
    SELECT customer_id, MIN(transaction_date) AS first_date
    FROM customer_transaction GROUP BY customer_id
),
first_txn AS (
    SELECT ct.customer_id, EXTRACT(MONTH FROM fp.first_date) AS cohort_month, ct.traffic_source
    FROM customer_transaction ct
    JOIN first_purchase fp ON ct.customer_id = fp.customer_id AND ct.transaction_date = fp.first_date
)
SELECT cohort_month, traffic_source, COUNT(*) AS new_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY cohort_month), 1) AS pct_of_month
FROM first_txn
GROUP BY cohort_month, traffic_source
ORDER BY cohort_month, traffic_source;
```

The same query structure, swapping `traffic_source` for `customer_country` and `product_category`, covers the other two dimensions. Both are included in `customer_behavior_analysis_code.sql`.

| dimension | January–June pattern | July–December pattern | verdict |
|---|---|---|---|
| Acquisition channel | Google ~32–33%, Organic ~23%, Facebook ~12–13%, Email ~13–14%, Ads ~12%, Referral ~5% — stable every month | Facebook jumps to ~55%, Google falls to ~15%, Organic falls to ~8%, Email falls to ~5%; Ads and Referral unchanged | **Real structural break, lines up exactly with the retention cliff** |
| Country | Every country holds ~9.5–10.5% of new customers, every month (e.g. US: 9.7% in January, 9.7% in July) | No change | Ruled out |
| Product category | Electronics ~30%, Fashion/Home ~20% each, Books/Accessories/Kids ~10% each, every month (e.g. Electronics: 30.1% in January, 29.7% in July) | No change | Ruled out |

Country and category mix stay flat all year, so neither explains why cohorts from July onward behave differently. Acquisition channel is the one dimension that changes at the same point retention does. Facebook's share of new customers more than quadrupled starting in July, rising from roughly 13% to roughly 55%, and stayed there through year-end. Meanwhile, Google and Organic, the two channels with the best historical retention, lost the most share.

That timing makes Facebook the leading explanation, though it is worth testing rather than accepting based on timing alone. Comparing month-1 retention channel by channel between the June and July cohorts shows the Facebook shift is part of the story, but not the whole story. In June, Facebook already retained worse than every other channel, at 44.8% versus 60% to 65% for Ads, Email, Google, Organic, and Referral. This means Facebook being a lower-quality channel predates July. But in July, every channel fell to roughly the same 24% to 29% range, not just Facebook. This includes Google and Organic, which had no connection to the Facebook surge and had been retaining above 60% just one month earlier. A channel-mix shift alone cannot explain that pattern. If it were the full explanation, Google's own July customers should have kept retaining near 65%, just in smaller volume.

**Key Takeaway:** The Facebook acquisition surge is the clearest lead. It is a real, dated, correlated shift that deserves its own investigation into why spend or targeting moved so sharply that month. However, the data shows something broader also happened, since retention fell across every channel at once, not just Facebook's. Two diagnostics would narrow this further, though neither has been run yet. The first is a day-by-day count of new customers through July, to check for a concentrated spike versus a steady drift. The second is the full distribution of July's first-order values compared with June's, not just the average, which was already checked and found flat at around $270.

**Business Recommendation:** This is still the single highest-priority finding in the analysis, and the deep dive narrows the investigation without fully closing it. Country and product-category mix are ruled out as causes. The Facebook acquisition surge is a real, correlated change, but it is demonstrably not the full explanation. Google- and Organic-acquired July customers collapsed just as hard, even though those channels' own mix and historical quality were unaffected by the Facebook shift. This points to a broader, month-specific cause, most likely a promotional event, a pricing change, or an attribution or tracking shift that touched every channel at once. This dataset's columns cannot fully resolve the question alone. The next concrete steps are to pull daily new-customer counts for July to check for a spike versus a steady drift, compare the full order-value distribution of July's first purchases against June's (not just the average), and cross-reference July's actual campaign and pricing records with Marketing, including why Facebook's share of spend or traffic jumped so sharply that month. In parallel, a 30-day post-first-purchase retention flow should be tested against the later-2025 cohorts that show this weaker retention pattern, regardless of root cause, since closing the gap does not require first fully explaining it. Month-1 retention rate should become a standing KPI tracked alongside revenue, not after it. On this data, revenue alone would have shown July as the best month of the year, while retention shows it as the point where customer quality broke down.

## 5. Customer Behavior Analysis

**5a. Most frequently purchased products**

```sql
SELECT
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk,
    product_purchased,
    COUNT(*)               AS purchase_count,
    ROUND(SUM(amount), 2)  AS total_revenue
FROM customer_transaction
GROUP BY product_purchased
ORDER BY rnk;
```

| rank | product | purchase count | total revenue |
|---|---|---|---|
| 1 | Book | 80,457 | $1,609,235 |
| 2 | Laptop | 80,351 | $96,481,473 |
| 3 | Phone | 80,200 | $64,167,055 |
| 4 | Shoes | 80,135 | $7,218,226 |
| 5 | Headphones | 80,107 | $9,607,225 |
| 6 | Coffee Maker | 79,841 | $5,989,337 |
| 7 | Watch | 79,836 | $14,373,257 |
| 8 | Jacket | 79,834 | $11,179,805 |
| 9 | Toy | 79,763 | $2,789,833 |
| 10 | Blender | 79,476 | $4,768,686 |

Purchase counts are nearly flat across all ten products, each selling roughly 79,500 to 80,500 units. Revenue, however, is wildly uneven. Laptop alone generates $96.5M, or 44% of all revenue, despite selling at roughly the same frequency as a $20 book. High-ticket electronics carry the business's revenue even though they are not purchased more often than anything else.

**5b. Top-selling product per country**

```sql
WITH product_by_country AS (
    SELECT customer_country, product_purchased, COUNT(*) AS purchase_count,
        DENSE_RANK() OVER (PARTITION BY customer_country ORDER BY COUNT(*) DESC) AS rnk
    FROM customer_transaction GROUP BY customer_country, product_purchased
)
SELECT customer_country, product_purchased, purchase_count
FROM product_by_country WHERE rnk = 1 ORDER BY customer_country;
```

| country | top product | count |
|---|---|---|
| AU | Headphones | 8,066 |
| BR | Laptop | 8,131 |
| CA | Shoes | 8,134 |
| DE | Book | 8,183 |
| FR | Phone | 8,080 |
| IN | Book | 8,113 |
| JP | Laptop | 8,168 |
| MX | Coffee Maker | 8,210 |
| UK | Blender | 8,139 |
| US | Phone | 8,213 |

No single product dominates globally. Top sellers vary by country, though Laptop and Phone, the two highest-revenue items, each lead in two markets.

**5c. Does purchase frequency affect average spend?**

```sql
WITH customer_stats AS (
    SELECT customer_id, COUNT(*) AS order_count, ROUND(AVG(amount), 2) AS avg_spend
    FROM customer_transaction GROUP BY customer_id
)
SELECT order_count AS transactions_per_customer, COUNT(*) AS num_customers, ROUND(AVG(avg_spend), 2) AS avg_order_value
FROM customer_stats GROUP BY order_count ORDER BY order_count;
```

| transactions | customers | avg order value |
|---|---|---|
| 1 | 49,323 | $275.59 |
| 2 | 34,504 | $272.31 |
| 3 | 30,189 | $270.73 |
| 4 | 25,994 | $274.76 |
| 5 | 26,694 | $273.11 |
| 6 | 26,558 | $272.78 |
| 7 | 20,582 | $271.21 |
| 8 | 5,268 | $274.09 |
| 9–12 | 888 | ~$255–274 |

Average order value stays flat, roughly $270 to $276, regardless of how many times a customer transacts. Heavy buyers do not spend more or less per order than occasional ones. Purchase frequency and basket size behave as independent variables in this dataset.

**5d. Repeat purchase rate**

```sql
WITH customer_orders AS (
    SELECT customer_id, COUNT(*) AS order_count FROM customer_transaction GROUP BY customer_id
)
SELECT
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    COUNT(*) AS total_customers,
    ROUND(SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS repeat_purchase_rate_pct
FROM customer_orders;
```

170,677 of 220,000 customers, or 77.6%, made more than one purchase. That is a strong headline loyalty number. However, the cohort breakdown in Section 4 shows it is driven almost entirely by customers acquired in the first half of the year. Cohorts from the second half of the year behave much more like one-time buyers.

**Business Recommendation:** Protect margin and supply reliability on Laptop and Phone specifically, since together they represent a disproportionate share of total revenue relative to their purchase volume. Any disruption to those two products, such as a stockout, a price war, or a supplier issue, would hit the business harder than the "10 products sold evenly" headline suggests. Use the top-product-per-country table to localize homepage merchandising and email campaigns by market, rather than running one global product feature. Design any loyalty or VIP tier around retention and recency rather than raw purchase count. Section 5's data shows frequent buyers do not spend more per order than one-time buyers, so a frequency-based reward structure would optimize for a metric that does not correlate with what the business actually wants to protect: repeat and retained customers.

---

# Conclusion

Across all five chapters, the same underlying story shows up from different angles. 2025 was a single-arc year, not a series of independent months. Orders and revenue climbed from January to a peak in July, then declined every month through December. This shape holds true in every product category, every country, and every acquisition channel individually, which shows it is a dataset-wide seasonal pattern rather than a shift in any one segment's behavior. Layered on top of that, the timing of a customer's first purchase turns out to matter more than any other variable measured here. Customers acquired in the first half of the year stuck around at two to three times the rate of customers acquired in the second half. The Section 4c deep dive traced that split partway to its source: a real acquisition-channel mix shift toward Facebook starting in July. However, this mix shift alone does not account for the pattern, since every channel's July-acquired customers underperformed their own historical norm, not just Facebook's. Everything else examined, including country, product category, average order value, and purchase frequency, turned out to be strikingly uniform. Revenue concentration comes almost entirely from product mix, particularly Electronics and Laptop specifically, rather than from any customer segment buying more often or spending more per visit.

# Key Business Insights

The clearest and most actionable finding is a sharp divide in how well the business retains customers, depending on when they first bought something. Customers whose first purchase fell between January and June retained at 51% to 61% into their second month, decaying gradually from there. Customers first acquired between July and December fell to roughly 27% retention after a single month and kept dropping sharply. The deep dive in Section 4c found a real, dated correlate: Facebook's share of new-customer acquisition jumped from about 13% to about 55% exactly in July and stayed there. However, this was ruled out as the sole cause, since Google- and Organic-acquired customers collapsed just as hard in July, even though those channels had no connection to the Facebook shift and had retained normally, at 60% to 65%, as recently as June. Country and product-category composition were also checked and found flat all year, ruling both out as well. What remains is a business-wide, July-specific drop in new-customer quality that cuts across every channel. This is consistent with a single dated event, such as a promotion, a pricing change, or an acquisition or attribution shift, rather than a slow-building trend in any one segment.

Revenue concentration is the second major insight. Laptop accounts for 44% of total revenue while representing exactly one-tenth of unique products and roughly one-tenth of purchase volume. The business's financial health is far more exposed to Electronics category performance, including laptop pricing, supply, and competition, than a glance at "10 products, evenly purchased" would suggest.

Third, outside of the acquisition-channel mix shift documented above, nothing in the channel or geographic data points to inefficiency or underperformance anywhere. Every country contributes within a $400K band of each other, and every channel converts at essentially the same average order value. That uniformity is itself informative: channel mix and market mix are not levers that will move the revenue needle on their own. The growth-and-retention story is happening at the acquisition-timing level, not the channel or geography level. The one exception is how customers were acquired starting in July, which the deep dive flags as the open thread still worth chasing.

Fourth, purchase frequency is not a proxy for customer value in this dataset. A customer who buys once and a customer who buys eight times spend, on average, the identical amount per order. Any loyalty or VIP program built on this data should be designed around retention and repeat-visit behavior, rather than assuming frequent buyers are also higher-ticket buyers.

# Business Recommendations

- **Marketing:** Treat the July acquisition spike as a case study, not a template. Investigate the channel-mix shift toward Facebook found in Section 4c, specifically why spend or targeting reallocated so heavily in July, and why customer quality dropped across every channel at the same time, not just Facebook's. Country and regional mix are already efficient and not worth reallocating, since no market meaningfully underperforms on average order value, so budget attention should go to the channel-timing question instead of geography. Avoid optimizing purely for order volume without also watching cohort retention, to prevent trading long-term customers for short-term gains.

- **Sales:** Prioritize a second-purchase intervention, such as a reminder, a follow-up offer, or an onboarding sequence, timed to land within the first 30 days after a customer's first order. This is the exact window where early-2025 and late-2025 cohorts diverge most sharply in retention. Since 22% of all customers never returned after a single purchase, even a modest lift in month-1 retention would compound meaningfully across the 220,000-customer base.

- **Supply Chain:** Treat Electronics, and Laptop specifically, as the business's central risk and opportunity, not just its top seller. Prioritize margin protection, supplier reliability, and competitive pricing on this product line, since it single-handedly explains close to half of all revenue.

# Next Steps for Cross-Functional Stakeholders

- **Marketing:** Pull campaign and spend records for July 2025, focusing on what changed in Facebook targeting or spend, since its acquisition share more than quadrupled that month. Cross-reference these records against the customer IDs acquired in July to identify what actually drove the order spike, and whether it can be replicated without the retention cost.

- **Customer Success / Lifecycle:** Design and A/B test a 30-day post-purchase retention flow. Use the January–June cohorts, which already show what normal retention looks like, as the benchmark for the July–December cohorts to close the gap against.

- **Merchandising / Category Management:** Review supplier terms, margin, and inventory risk on the Laptop and Phone lines, given their outsized share of revenue. Evaluate whether a comparable high-ticket item could be introduced to diversify that concentration.

- **Finance / FP&A:** Model 2026 revenue scenarios that separate order volume from retained revenue, since this analysis shows the two can move in opposite directions, as they did in July.

- **Data / Analytics:** Extend the Section 4c deep dive with a daily-level view of new-customer arrivals through July, rather than monthly, and a full distribution of first-order values, not just the average, to determine whether the drop traces to a single dated event or a genuine, sustained shift in acquisition quality. Set up recurring monthly refreshes of the cohort retention table so any future acquisition-quality trade-off is caught in near real time rather than at year-end.

# Potential Improvements to the Analysis

- **No cost or spend data:** The dataset has no cost, margin, or marketing-spend data, so channel and product performance can only be measured in revenue and order count. A true efficiency or ROI view, such as revenue per dollar spent by channel or margin-adjusted product ranking, would require pulling in cost data from finance or ad platforms.

- **No customer demographic data:** There is no age, gender, acquisition campaign, device, or referral detail in the dataset. As the Section 4c deep dive showed directly, even after checking channel, country, and product category, the July retention drop still is not fully explained from this table alone. The natural next step is joining in campaign metadata or session-level web analytics to find the actual driver.

- **Cohort analysis is right-censored by the calendar:** A customer acquired in December has only one month of observed data by construction. This is why later cohorts show fewer populated columns in the retention table, rather than genuinely worse long-term outcomes. A live version of this analysis should re-run periodically as more 2026 data becomes available, to get true 6- and 12-month retention reads on the cohorts acquired later in 2025.



