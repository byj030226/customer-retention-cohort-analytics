# Plots

Visuals from the customer behavior and shopping habits analysis, in the order they build on each other: baseline, then the finding, then the investigation, then the resolution.

## monthly_revenue.png

Total revenue by month for 2025. Revenue ramps up steadily from January, peaks at $26.1M in July, then declines through December. On its own, this looks like an ordinary seasonal pattern, nothing alarming.

## revenue_by_channel.png

The same year, broken out by acquisition channel (Google, Organic, Facebook, Email, Ads, Referral). Google and Organic dominate through the first half of the year, then Facebook overtakes both starting in July and stays highest through December.

## cohort_retention_rate_heatmap.png

The core finding. Each row is a monthly cohort (customers grouped by the month of their first purchase), each column is how many months since that first purchase, and each cell is the percent of that cohort still buying. Cohorts from January through June hold in the 50-60% range for several months before fading. Cohorts from July onward collapse to under 30% almost immediately. This is what the revenue chart alone hides, July was the month growth peaked and the month the customer base started falling apart.

## retention_rate_by_channel_before_after_july.png

The investigation. Splits retention by acquisition channel, comparing Jan-Jun cohorts to Jul-Nov cohorts. Every channel drops to roughly the same 27-28% range after July, not just Facebook. Facebook actually started with the lowest retention of any channel before July (37%, versus 56-60% elsewhere), so it drops the least in percentage-point terms. This rules out "Facebook's rising share caused the collapse" as the explanation, whatever changed in July affected every acquisition channel at once.

## country_level_results.html

Interactive choropleth map of revenue by country. Hover any country for a quick value; click one for full detail (orders, customers, average order value, top product, and that country's own channel mix). Revenue is deliberately flat across all ten countries ($21.6M-$22.0M each), and channel mix is nearly identical everywhere too, confirming the July finding isn't a geography story either.

This file needs to be opened through GitHub Pages to work, not viewed as raw code in the repo's file browser:
`https://byj030226.github.io/customer-retention-cohort-analytics/plots/country_level_results.html`
