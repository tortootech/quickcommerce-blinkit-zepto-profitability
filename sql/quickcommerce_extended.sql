-- Quick-Commerce Profitability: extended analysis queries (PostgreSQL)
-- Complements quickcommerce_analysis.sql. These use only columns that exist in the workbook's
-- Orders sheet (columns A:S), so they run on the workbook data as well as on the full fact_orders table.
-- "Contribution after rider" = gross margin + marketplace commission + ad revenue + delivery fee
--   + handling fee - discount - rider cost. It is BEFORE dark-store cost and corporate overhead.
-- Author: Vartika Yadav

-- E1. Contribution after rider per order, with year-on-year change (LAG)
WITH c AS (
  SELECT company, fiscal_year,
         AVG(gross_product_margin_rs + marketplace_commission_rs + ad_revenue_rs + delivery_fee_rs
             + handling_fee_rs - discount_rs - rider_cost_rs) AS contrib_po
  FROM fact_orders GROUP BY company, fiscal_year)
SELECT company, fiscal_year, ROUND(contrib_po, 2) AS contribution_after_rider_po,
       ROUND(contrib_po - LAG(contrib_po) OVER (PARTITION BY company ORDER BY fiscal_year), 2) AS yoy_change
FROM c ORDER BY company, fiscal_year;

-- E2. Data quality: share of orders with a missing dark-store cost
SELECT company, fiscal_year, COUNT(*) AS orders,
       COUNT(*) FILTER (WHERE dark_store_cost_rs IS NULL) AS missing_dark_store_cost,
       ROUND(100.0 * COUNT(*) FILTER (WHERE dark_store_cost_rs IS NULL) / COUNT(*), 1) AS pct_missing
FROM fact_orders GROUP BY company, fiscal_year ORDER BY company, fiscal_year;

-- E3. Data quality: does the product's category in dim_product match the order's category?
SELECT COUNT(*) AS orders,
       COUNT(*) FILTER (WHERE f.category <> p.category) AS category_mismatch,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.category <> p.category) / COUNT(*), 1) AS pct_mismatch
FROM fact_orders f JOIN dim_product p ON p.product_id = f.product_id;

-- E4. Zepto's gap to Blinkit on discount and rider cost (FY26, Rs per order)
WITH c AS (
  SELECT company, AVG(discount_rs) AS disc, AVG(rider_cost_rs) AS rider
  FROM fact_orders WHERE fiscal_year = 'FY26' GROUP BY company)
SELECT c.company, ROUND(c.disc - b.disc, 2) AS discount_gap_po, ROUND(c.rider - b.rider, 2) AS rider_gap_po
FROM c CROSS JOIN (SELECT * FROM c WHERE company = 'Blinkit') b
WHERE c.company <> 'Blinkit' ORDER BY c.company;

-- E5. Impact sizing: Rs crore a year if each company closes 50% of its discount and rider-cost gap to Blinkit
WITH c AS (
  SELECT company, AVG(discount_rs) AS disc, AVG(rider_cost_rs) AS rider
  FROM fact_orders WHERE fiscal_year = 'FY26' GROUP BY company),
gap AS (
  SELECT c.company, c.disc - b.disc AS disc_gap, c.rider - b.rider AS rider_gap
  FROM c CROSS JOIN (SELECT * FROM c WHERE company = 'Blinkit') b WHERE c.company <> 'Blinkit')
SELECT g.company,
       ROUND(0.5 * g.disc_gap  * bm.reported_orders / 1e7, 1) AS discount_uplift_cr,
       ROUND(0.5 * g.rider_gap * bm.reported_orders / 1e7, 1) AS rider_uplift_cr,
       ROUND(0.5 * (g.disc_gap + g.rider_gap) * bm.reported_orders / 1e7, 1) AS total_uplift_cr
FROM gap g JOIN benchmark_fy26 bm ON bm.company = g.company ORDER BY g.company;

-- E6. Rider cost penalty for long distances (FY26): under 1.5 km vs 3 km and over
SELECT company,
       ROUND(AVG(rider_cost_rs) FILTER (WHERE delivery_radius_km >= 3), 2)  AS rider_cost_3km_plus,
       ROUND(AVG(rider_cost_rs) FILTER (WHERE delivery_radius_km < 1.5), 2) AS rider_cost_under_1_5km,
       ROUND(AVG(rider_cost_rs) FILTER (WHERE delivery_radius_km >= 3)
           - AVG(rider_cost_rs) FILTER (WHERE delivery_radius_km < 1.5), 2) AS penalty_po
FROM fact_orders WHERE fiscal_year = 'FY26' GROUP BY company ORDER BY company;

-- E7. City league table by contribution after rider (FY26) with RANK
SELECT company, city, COUNT(*) AS orders,
       ROUND(AVG(gross_product_margin_rs + marketplace_commission_rs + ad_revenue_rs + delivery_fee_rs
                 + handling_fee_rs - discount_rs - rider_cost_rs), 2) AS contribution_po,
       RANK() OVER (PARTITION BY company ORDER BY AVG(gross_product_margin_rs + marketplace_commission_rs
            + ad_revenue_rs + delivery_fee_rs + handling_fee_rs - discount_rs - rider_cost_rs) DESC) AS rank_in_company
FROM fact_orders WHERE fiscal_year = 'FY26'
GROUP BY company, city ORDER BY company, rank_in_company;

-- E8. Seasonality: January vs December orders per store per day, with a 3-month rolling average
SELECT company, month, orders_per_store_per_day,
       ROUND(AVG(orders_per_store_per_day) OVER (PARTITION BY company ORDER BY month
             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 1) AS rolling_3m_avg
FROM monthly_operations
WHERE company = 'Blinkit' ORDER BY month;

-- E9. January dip: orders in January vs the previous December, each company and year
WITH m AS (
  SELECT company, month, orders,
         LAG(orders) OVER (PARTITION BY company ORDER BY month) AS prev_month_orders
  FROM monthly_operations)
SELECT company, month, orders, prev_month_orders,
       ROUND(100.0 * (orders - prev_month_orders) / prev_month_orders, 1) AS pct_change_vs_dec
FROM m WHERE EXTRACT(MONTH FROM month) = 1 AND prev_month_orders IS NOT NULL
ORDER BY company, month;
