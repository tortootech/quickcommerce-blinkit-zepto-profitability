# DAX in the Power BI dashboard

Source: `QuickCommerce_Dashboard.pbix`. Model: star schema with `fact_orders` (450,000 orders) joined to `dim_store` (on `store_id`) and `dim_product` (on `product_id`), many-to-one, single direction. `monthly_operations` and `benchmark_fy26` are separate tables used for trend and reported-loss visuals.

## Measures (table: `fact_orders`)

### Orders Under 2km %
Share of orders delivered within 2 km. Drives the "Share of Orders Delivered Under 2 km" chart.
```dax
Orders Under 2km % =
DIVIDE(
    CALCULATE(
        COUNTROWS('public fact_orders'),
        'public fact_orders'[Radius Band] = "1. Under 2 km"
    ),
    COUNTROWS('public fact_orders')
)
```
`CALCULATE` changes the filter context to count only under-2 km rows. `DIVIDE` returns blank instead of an error if the denominator is zero. Result for FY26: Blinkit 83.98%, Instamart 25.21%, Zepto 18.51%.

### Discount % of AOV
```dax
Discount % of AOV =
DIVIDE(
    SUM('public fact_orders'[discount_rs]),
    SUM('public fact_orders'[aov_rs])
)
```
A ratio of sums, so big orders weigh more than small ones. Result for FY26: Zepto 8.50%, Instamart 7.50%, Blinkit 5.51%.

### Avg First Party Share
```dax
Avg First Party Share =
AVERAGE('public fact_orders'[first_party_share])
```
Share of orders fulfilled from the company's own inventory (not marketplace sellers). Blinkit is about 79.9%.

## Calculated column (table: `fact_orders`)

### Radius Band
```dax
Radius Band =
IF('public fact_orders'[delivery_radius_km] < 2, "1. Under 2 km",
IF('public fact_orders'[delivery_radius_km] <= 3, "2. 2-3 km", "3. Over 3 km"))
```
Groups each order into a distance band. The numeric prefix keeps the bands in order on chart axes. The same bands are used in `sql/quickcommerce_analysis.sql` (Q4), so SQL and Power BI results match.

## Notes
- The EBITDA-per-order bars use Power BI's built-in `Average of ebitda_contribution_rs`, not a custom measure.
- A fiscal-year slicer filters every page, and some pages are set to FY26.
