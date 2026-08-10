# Customer Retention Cohort Analysis
SQL-based customer retention and cohort analysis to measure repeat purchasing behavior, identify retention trends, and deliver data-driven recommendations for improving customer lifetime value.

## Tools

SQL (CTE, Window Functions) | Power BI (DAX, Power Query) | Google Sheets 

## 🎯 Business Problem

The business behind this dataset is a global, multi-channel retailer. It sells across ten countries: Australia, Brazil, Canada, France, Germany, India, Japan, Mexico, the UK, and the US. Customers arrive through six acquisition channels: Google, Organic, Facebook, Email, Ads, and Referral. The catalog spans six categories (Electronics, Fashion, Home, Books, Accessories, and Kids), represented by ten flagship products ranging from a $20 book to a laptop priced above $1,200.

Leadership needs a clear, data-backed view of customer behavior and shopping habits to plan for 2026. Specifically, they need to know which months and product lines drive the most revenue, whether marketing channels and geographic markets perform evenly, whether customers stay loyal or churn, and which products sell best in which markets.

## 🗂️ Dataset Overview

800,000 transactions, 220,000 customers, January-December 2025. Covers 6 product categories, 10 countries, and 6 acquisition channels. No cost, spend, or demographic data.

## 🔍 Analytical Approach

Cohort retention analysis in SQL, segmented by acquisition month, channel, country, and product category. Findings built into two Power BI dashboards (Executive and Marketing/Growth) and an interactive country map.

## 💡 Key Insights

- Month-1 retention averaged 51-61% for cohorts acquired January-June, then collapsed to 26-29% for every cohort acquired July onward.
- Facebook's share of new customer acquisition jumped from ~13% (Jan-Jun) to ~55% (Jul-Dec), the same month retention broke, making it the natural first suspect.
- Retention collapsed across every channel, not just Facebook: Google 60.2% → 28.4%, Organic 60.5% → 27.6%, Email 60.5% → 27.0%, Referral 57.2% → 28.1%, Ads 56.1% → 26.7%, Facebook 37.0% → 27.3%. This rules out channel mix as the sole cause.
- Revenue and channel mix are both flat across all 10 countries ($21.6M-$22.0M each), so the cause isn't geographic either.
- Google is the top revenue channel (30.9%), and Electronics, led by Laptop alone at $96.48M, drives revenue independent of order volume.

## ✅ Business Recommendations

- Marketing: investigate what changed business-wide in July, onboarding, pricing, or fulfillment, rather than cutting Facebook spend based on channel mix alone, since every channel was hit equally.
- Sales: protect the Google relationship (30.9% of revenue) while testing Referral as a lower-cost incremental channel.
- Supply chain: prioritize Electronics and Laptop inventory, given its outsized revenue share.
- Finance & Data: add cost and ad-spend data to measure true channel profitability (CAC, ROI), not just revenue share, and to properly evaluate the customers already being retained.

## Explore

`/report` full write-up · `/sql` queries · `/dashboards` Power BI screenshots and file · `/plots` major result charts and interactive map
