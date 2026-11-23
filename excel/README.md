# Excel workbook: Quick-Commerce Business Analyst Case Study

`QuickCommerce_Business_Analyst_CaseStudy.xlsx` is the working file behind the SQL and Power BI work. It is about 95 MB (the 450,000-row `Orders` sheet is most of that), which is too big for a normal GitHub upload, so this folder describes it instead. See "Getting the file" below.

**Data disclosure:** all order, store, product and monthly data is synthetic, calibrated to published headline numbers. Only the `Benchmark_FY26` sheet holds figures from case-study notes.

## What is in the workbook (26 tabs)
| Group | Tabs | What they do |
|---|---|---|
| Summary | Project_Overview, Dashboard, Findings, Business_Problems, Insights_Recommendations, Assumptions, GitHub_Report | KPI cards, charts and slicers; 9 problems with evidence; recommendations with impact sizing |
| Analysis | Analysis, Unit_Economics, Drivers_PnL, Category_City_Store, Trends, Pivot_Analysis | Per-order P&L, FY26 drivers, category, city and store performance, 36-month trends, PivotTables |
| Data quality | Data_Quality, Cleaning_Practice | Blank, duplicate and inconsistent-value checks; TRIM / PROPER / UPPER / LOWER / VALUE / DATE cleaning |
| Data | README, Benchmark_FY26, Annual_KPIs, Monthly_Operations, Orders, Stores, Products | 450,000 orders, 4,525 stores, 96 products, 20 cities, FY24 to FY26 |

## PivotTables (6)
| Pivot | Shows |
|---|---|
| `ptCompanyYear` | Orders, GMV, average AOV, discount and rider cost by company and fiscal year |
| `ptUnitEconomics` | Average EBITDA per order by company and year |
| `ptCategoryCompany` | Average gross margin per order by category and company (fiscal-year slicer) |
| `ptCity`, `ptDashCity` | GMV and orders by city |
| `ptStoreTop` | Top stores by GMV, orders and average gross margin |

Example, average EBITDA per order (Rs):

| Company | FY24 | FY25 | FY26 |
|---|---|---|---|
| Blinkit | -35.00 | -12.00 | -3.02 |
| Swiggy Instamart | -120.00 | -100.00 | -85.18 |
| Zepto | -105.00 | -95.00 | -78.75 |

## Findings
1. Blinkit is near break-even: EBITDA per order improved from -Rs 35.00 (FY24) to -Rs 3.02 (FY26).
2. Zepto (-Rs 78.75) and Instamart (-Rs 85.18) lose far more per order. Annual burn: Zepto about Rs 5,042 Cr, Instamart about Rs 3,511 Cr, Blinkit about Rs 277 Cr.
3. Zepto discounts 8.5% of order value; Blinkit 5.5%. The gap is about Rs 16.24 per order.
4. Blinkit's gain comes from scale: contribution per order barely moved (-0.4%) while overhead per order fell by Rs 32.35.
5. 84% of Blinkit's FY26 orders ship within 2 km, against 19% for Zepto. Rider cost rises by about Rs 15 per order beyond 3 km.
6. Only high-margin categories are profitable: Beauty earns +Rs 82 EBITDA per order at Blinkit, Staples loses Rs 61.

## Nine business problems (each backed by a live metric in the workbook)
1. Zepto and Instamart grow into bigger losses. 2. Over-reliance on discounts. 3. Blinkit stores expanding faster than demand (orders per store per day fell). 4. Blinkit's gain is scale, not better orders. 5. Commission per order fell as first-party share rose. 6. Longer delivery radius raises rider cost. 7. Low-margin Staples drags EBITDA. 8. Seasonal dip every January. 9. Incomplete cost data (198,607 blank dark-store cost cells).

## Recommendations and impact sizing
| Priority | Recommendation | KPI and target |
|---|---|---|
| High | Replace blanket discounts with targeted, brand-funded offers (Zepto, Instamart) | Discount % of AOV at or below 6.5% |
| High | Densify stores in busy areas and cap radius near 2 km | Average radius at or below 2.0 km |
| High | Gate new Blinkit store openings on utilisation | At least 1,200 orders per store per day |
| Medium | Grow Beauty, Electronics, Home & Kitchen share | +3 pp high-margin GMV share |
| Medium | Private label and minimum basket for Staples | Staples EBITDA per order at break-even |
| Medium | Sell ad slots to offset lost commission (Blinkit) | About Rs 16.70 ad plus commission per order |

Closing half of the discount and rider-cost gap to Blinkit is worth about **Rs 735 Cr a year for Zepto** and **Rs 399 Cr a year for Instamart** (gap per order x FY26 orders; ignores second-order effects).

## Assumptions to read before quoting a number
- Overhead is the balancing item: overhead per order = contribution minus reported EBITDA per order, so EBITDA ties to -3.02 / -78.75 / -85.18 by construction.
- Zepto's Rs 650 AOV is a labelled demo assumption, not a reported figure.
- Blinkit's supplied revenue, order count and AOV do not reconcile mathematically; the workbook keeps them and flags the issue.
- Dark-store cost is blank for all Instamart orders and most Zepto FY26 orders; blanks are kept blank, not zero.
- Fiscal-year labels are kept as supplied and may differ from company reports.

## Getting the file
The workbook is too large for a normal upload. Upload it as a **GitHub Release** asset (limit 2 GB per file): Releases, Draft a new release, attach the .xlsx, publish. Then link it here.
