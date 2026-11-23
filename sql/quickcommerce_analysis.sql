-- Quick-Commerce Profitability: Blinkit vs Zepto vs Instamart
-- PostgreSQL analysis queries (Q0 sanity checks, Q1-Q12 analysis)
-- Tables: fact_orders (450,000 synthetic orders, FY24-FY26), dim_store, dim_product,
--         monthly_operations, benchmark_fy26 (reported figures)
-- Author: Vartika Yadav

-- ===================== STEP 1: SANITY CHECKS =====================
-- Q0a. Row counts (expect 450000 / 4525 / 96 / 108 / 3)
SELECT (SELECT COUNT(*) FROM fact_orders) AS orders, (SELECT COUNT(*) FROM dim_store) AS stores,
       (SELECT COUNT(*) FROM dim_product) AS products, (SELECT COUNT(*) FROM monthly_operations) AS monthly_rows,
       (SELECT COUNT(*) FROM benchmark_fy26) AS benchmark_rows;
-- Q0b. Nulls in key money columns (expect 0)
SELECT COUNT(*) AS null_rows FROM fact_orders
WHERE aov_rs IS NULL OR dark_store_cost_rs IS NULL OR packaging_rs IS NULL OR allocated_corporate_oh_rs IS NULL OR ebitda_contribution_rs IS NULL;
-- Q0c. Does the P&L tie out to EBITDA? (expect 0 rows)
SELECT order_id FROM fact_orders
WHERE ABS(gross_product_margin_rs + ad_revenue_rs + delivery_fee_rs + handling_fee_rs + marketplace_commission_rs
        - discount_rs - rider_cost_rs - dark_store_cost_rs - packaging_rs - payment_processing_rs
        - allocated_corporate_oh_rs - ebitda_contribution_rs) > 0.02 LIMIT 10;

-- ===================== STEP 2: THE PROBLEM STATEMENT =====================
-- Q1. Headline: AOV and EBITDA per order (profitability gap)
SELECT company, fiscal_year, COUNT(*) AS orders, ROUND(AVG(aov_rs), 2) AS avg_aov,
       ROUND(AVG(ebitda_contribution_rs), 2) AS ebitda_per_order
FROM fact_orders GROUP BY company, fiscal_year ORDER BY company, fiscal_year;

-- Q2. Per-order P&L waterfall, FY26
SELECT company,
       ROUND(AVG(gross_product_margin_rs + marketplace_commission_rs), 2) AS gross_margin_and_commission,
       ROUND(AVG(ad_revenue_rs), 2) AS ads, ROUND(AVG(delivery_fee_rs + handling_fee_rs), 2) AS fees,
       ROUND(-AVG(discount_rs), 2) AS discounts, ROUND(-AVG(rider_cost_rs), 2) AS rider,
       ROUND(-AVG(dark_store_cost_rs), 2) AS dark_store, ROUND(-AVG(packaging_rs + payment_processing_rs), 2) AS pack_and_payment,
       ROUND(-AVG(allocated_corporate_oh_rs), 2) AS overhead, ROUND(AVG(ebitda_contribution_rs), 2) AS ebitda
FROM fact_orders WHERE fiscal_year = 'FY26' GROUP BY company ORDER BY ebitda DESC;

-- Q3. Bottleneck 1: where does the gap vs Blinkit come from? (FY26, Rs per order, each company minus Blinkit)
WITH c AS (
  SELECT company, AVG(gross_product_margin_rs + marketplace_commission_rs) AS margin, AVG(ad_revenue_rs) AS ads,
         AVG(delivery_fee_rs + handling_fee_rs) AS fees, AVG(discount_rs) AS disc, AVG(rider_cost_rs) AS rider,
         AVG(dark_store_cost_rs) AS ds, AVG(packaging_rs + payment_processing_rs) AS pp, AVG(allocated_corporate_oh_rs) AS oh,
         AVG(ebitda_contribution_rs) AS ebitda
  FROM fact_orders WHERE fiscal_year = 'FY26' GROUP BY company)
SELECT c.company,
       ROUND(c.margin - b.margin, 2) AS margin_gap, ROUND(c.ads - b.ads, 2) AS ads_gap, ROUND(c.fees - b.fees, 2) AS fees_gap,
       ROUND(-(c.disc - b.disc), 2) AS discount_gap, ROUND(-(c.rider - b.rider), 2) AS rider_gap,
       ROUND(-(c.ds - b.ds), 2) AS dark_store_gap, ROUND(-(c.oh - b.oh), 2) AS overhead_gap,
       ROUND(c.ebitda - b.ebitda, 2) AS total_gap
FROM c CROSS JOIN (SELECT * FROM c WHERE company = 'Blinkit') b WHERE c.company <> 'Blinkit';

-- Q4. Bottleneck 2: delivery radius bands (FY26)
SELECT company,
       CASE WHEN delivery_radius_km < 2 THEN '1. Under 2 km' WHEN delivery_radius_km <= 3 THEN '2. 2-3 km' ELSE '3. Over 3 km' END AS radius_band,
       COUNT(*) AS orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY company), 1) AS pct_of_company_orders,
       ROUND(AVG(rider_cost_rs), 2) AS rider_cost_po, ROUND(AVG(ebitda_contribution_rs), 2) AS ebitda_po
FROM fact_orders WHERE fiscal_year = 'FY26' GROUP BY company, 2 ORDER BY company, 2;

-- Q5. Bottleneck 3: category mix and margin (FY26)
SELECT company, category, ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY company), 1) AS mix_pct,
       ROUND(AVG(aov_rs), 0) AS avg_aov,
       ROUND(100.0 * SUM(gross_product_margin_rs) / SUM(aov_rs), 1) AS gross_margin_pct,
       ROUND(AVG(ebitda_contribution_rs), 2) AS ebitda_po
FROM fact_orders WHERE fiscal_year = 'FY26' GROUP BY company, category ORDER BY company, ebitda_po DESC;

-- Q6. Discount intensity and YoY change with LAG()
WITH d AS (SELECT company, fiscal_year, 100.0 * SUM(discount_rs) / SUM(aov_rs) AS disc_pct FROM fact_orders GROUP BY company, fiscal_year)
SELECT company, fiscal_year, ROUND(disc_pct, 2) AS discount_pct_of_aov,
       ROUND(disc_pct - LAG(disc_pct) OVER (PARTITION BY company ORDER BY fiscal_year), 2) AS yoy_pts
FROM d ORDER BY company, fiscal_year;

-- Q7. 1P share vs marketplace commission (FY26)
SELECT company, ROUND(AVG(first_party_share), 3) AS avg_1p_share, ROUND(AVG(marketplace_commission_rs), 2) AS commission_po,
       ROUND(AVG(gross_product_margin_rs), 2) AS gross_margin_po
FROM fact_orders WHERE fiscal_year = 'FY26' GROUP BY company ORDER BY company;

-- Q8. Store-level efficiency: best vs worst quartile of stores by EBITDA per order (FY26, stores with 30+ orders)
WITH s AS (
  SELECT f.store_id, f.company, AVG(f.ebitda_contribution_rs) AS ebitda_po, AVG(f.rider_cost_rs) AS rider_po,
         AVG(f.delivery_radius_km) AS radius, COUNT(*) AS orders
  FROM fact_orders f WHERE f.fiscal_year = 'FY26' GROUP BY f.store_id, f.company HAVING COUNT(*) >= 30)
SELECT company, quartile, COUNT(*) AS stores, ROUND(AVG(radius), 2) AS avg_radius_km, ROUND(AVG(rider_po), 2) AS rider_po, ROUND(AVG(ebitda_po), 2) AS ebitda_po
FROM (SELECT *, NTILE(4) OVER (PARTITION BY company ORDER BY ebitda_po) AS quartile FROM s) t
GROUP BY company, quartile ORDER BY company, quartile;

-- Q9. City league table, FY26
SELECT company, city, COUNT(*) AS orders, ROUND(AVG(ebitda_contribution_rs), 2) AS ebitda_po,
       RANK() OVER (PARTITION BY company ORDER BY AVG(ebitda_contribution_rs) DESC) AS rank_in_company
FROM fact_orders WHERE fiscal_year = 'FY26' GROUP BY company, city ORDER BY company, rank_in_company;

-- Q10. Store density: orders per store per day (monthly operations)
SELECT company, fiscal_year, ROUND(AVG(active_dark_stores), 0) AS avg_stores, ROUND(AVG(orders_per_store_per_day), 0) AS orders_per_store_day,
       ROUND(AVG(avg_delivery_radius_km), 2) AS avg_radius_km, ROUND(AVG(discount_rate) * 100, 2) AS discount_pct, ROUND(AVG(cancellation_rate) * 100, 2) AS cancel_pct
FROM monthly_operations GROUP BY company, fiscal_year ORDER BY company, fiscal_year;

-- Q11. Benchmark check: reported loss per order and AOV reconciliation
SELECT company, reported_loss_per_order_rs, reported_aov_rs, revenue_implied_aov_rs,
       ROUND(reported_adjusted_ebitda_loss_crore * 10000000.0 / reported_orders, 2) AS loss_per_order_calc
FROM benchmark_fy26;

-- Q12. Runway what-if: annual burn (Rs crore) if each company closes X% of its gap to Blinkit on discount
WITH b AS (SELECT company, AVG(discount_rs) AS disc FROM fact_orders WHERE fiscal_year = 'FY26' GROUP BY company),
     blk AS (SELECT disc FROM b WHERE company = 'Blinkit')
SELECT bm.company, bm.reported_orders / 1e6 AS orders_m, bm.reported_loss_per_order_rs AS loss_po,
       ROUND(b.disc - blk.disc, 2) AS discount_gap_po,
       ROUND(bm.reported_orders * bm.reported_loss_per_order_rs / 1e7, 0) AS burn_cr_base,
       ROUND(bm.reported_orders * (bm.reported_loss_per_order_rs - 0.5 * GREATEST(b.disc - blk.disc, 0)) / 1e7, 0) AS burn_cr_if_half_discount_gap_closed
FROM benchmark_fy26 bm JOIN b ON b.company = bm.company CROSS JOIN blk;