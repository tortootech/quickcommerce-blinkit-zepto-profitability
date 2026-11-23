# Quick-Commerce Profitability: Blinkit vs Zepto vs Instamart

A business analysis of why Blinkit is closing in on break-even while Zepto and Instamart lose far more per order, built with Excel, PostgreSQL and Power BI.

## Business question
Which quick-commerce player has the healthiest unit economics, and what would it take for the others to catch up?

## Data
- 450,000 synthetic orders across FY24 to FY26 for Blinkit, Zepto and Instamart
- 15 data-quality checks run before any analysis
- Reported annual losses and AOV are included on the "Annual burn" page for comparison with the modelled numbers

The orders are synthetic. They were generated to reflect each company's publicly reported scale, so treat the results as a model, not as company disclosures.

## Key findings
| Finding | Result |
|---|---|
| EBITDA per order, Blinkit | improved from -Rs 35 to -Rs 3.02 |
| EBITDA per order, Zepto | -Rs 78.75 |
| EBITDA per order, Instamart | -Rs 85.18 |
| Discount as % of order value | Zepto 8.5% vs Blinkit 5.5% |
| Orders delivered within 2 km (FY26) | Blinkit 84% vs Zepto 19% |
| Value of closing half the discount and rider-cost gap | about Rs 735 Cr a year for Zepto |

## Dashboard
`QuickCommerce_Dashboard.pbix` has 5 pages:
1. EBITDA trend by company and fiscal year
2. FY26 per-order P&L (gross margin, discount, rider cost, allocated overhead)
3. Delivery radius: rider cost by distance band, share of orders under 2 km
4. Discount as % of AOV, first-party share, EBITDA by category
5. Annual burn: reported losses vs modelled

Open it in Power BI Desktop. Use the fiscal-year slicer to switch years.

## Tools
Excel (data prep, findings), PostgreSQL (per-order unit economics queries), Power BI (dashboard, DAX).

## Author
Vartika Yadav | [LinkedIn](https://www.linkedin.com/in/vartika-yadav-b39a23314) | [Portfolio](https://tortootech.github.io/vartika/)
