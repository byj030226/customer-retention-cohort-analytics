# Dashboards

Two Power BI pages, built for two different audiences and two different decisions. Screenshots are included here; the working `.pbix` file is also in this folder if you want to open and click around the real thing in Power BI Desktop (free download, no license needed to view).

## executive_overview_dashboard.pdf

Audience: leadership. Question it answers: how is the business doing, and is anything about to go wrong that the headline numbers won't show on their own.

KPI cards cover total revenue, total orders, total customers, average order value, and full-period revenue growth. Below that: monthly revenue, monthly revenue growth rate, new vs. returning customer split, retention rate by cohort month, revenue by category, and revenue by country.

The retention rate chart is the reason this page exists in its current form. Revenue alone tells a story of steady growth peaking in July. Retention tells the real story: the customer base acquired from July onward stopped coming back at anywhere near the earlier rate. An executive looking only at revenue would miss that the business's growth engine broke down in its best-looking month. This page is built to make that visible without requiring anyone to dig into a report.

Decisions this supports: whether to keep scaling spend the way it's been scaling, whether next year's budget assumptions should change, and whether this needs to become a priority investigation rather than a footnote.

## marketing_growth_dashboard.pdf

Audience: marketing and growth. Question it answers: which channel is responsible for what's happening, and where should attention and budget go.

KPI cards cover total revenue and new customers acquired. Below that: revenue by channel, the share of new customers coming from Facebook over time, new customers acquired by channel each month, and retention rate by channel comparing Jan-Jun cohorts to Jul-Nov cohorts.

This page exists to test the obvious first guess, that Facebook's rising share of acquisition caused the retention problem, and rule it out with data rather than assumption. Every channel's retention collapsed together in July, not just Facebook's. That's a more useful and more honest finding for a marketing team to act on than a scapegoat: it means the fix isn't "spend less on Facebook," it's "something changed across the whole acquisition funnel in July," which needs investigation this dataset can't finish on its own.

Decisions this supports: whether to reallocate budget away from any single channel (the data says no single channel is uniquely at fault), and where to start looking next (something universal, not channel-specific: onboarding, product, pricing, or a data collection issue).

## Why these are two separate dashboards, not one

An executive dashboard optimized for a five-second glance and a marketing dashboard optimized for channel-level investigation want different things from the same data. Putting acquisition-channel line charts and root-cause bar charts on the executive page would bury the one number that matters to leadership under detail they don't need to act. Putting only the executive's summary retention line on the marketing page would hide the exact information marketing needs to know their channel isn't the cause. Same underlying dataset, same finding, but each audience gets it filtered to what they'd actually use.

## What's missing: no cost or spend data

Every metric in both dashboards is revenue-side only. The dataset has no ad spend, no cost per click, no marketing budget by channel, and no cost of goods. That means neither dashboard can answer the question both audiences would ask next: is this channel, or this customer, actually profitable, not just high-revenue.

If cost data were added, here's specifically what it would unlock:

Customer acquisition cost (CAC) by channel, spend divided by new customers acquired, would sit next to the existing revenue-by-channel chart and could completely change the read on it. Facebook already shows the lowest retention of any channel before July (37%, versus 56-60% elsewhere). If Facebook also turns out to have a high CAC, that's a channel that was quietly underperforming before the July collapse ever happened, worth flagging regardless of this investigation.

Return on ad spend (ROAS) or marketing ROI by channel, revenue divided by spend, would let the revenue-by-channel bar chart become a profitability chart instead, since right now a channel can look like the biggest revenue driver while actually being the least efficient use of budget.

Customer lifetime value versus CAC would extend the retention analysis into an actual dollar figure. Right now retention rate answers "did they come back," but pairing it with cost data would answer "was acquiring them worth what it cost," which is the number a CFO would actually want.

A dedicated marketing efficiency section (likely its own page, given the volume of new KPIs) would be the natural home for all of this, sitting alongside the existing growth page rather than replacing it, since channel mix and acquisition volume are still useful on their own even without cost context.
