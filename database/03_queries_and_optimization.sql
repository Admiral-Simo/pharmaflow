-- ============================================================================
-- RELATIONAL DATABASE PROJECT - MASTER IN DATA & AI (INPT)
-- File : 03_queries_and_optimization.sql
-- Steps 8 & 9: Advanced Analytical Queries, Indexing & EXPLAIN Optimization
-- ============================================================================

USE pharmaflow_db;

-- ============================================================================
-- PART A: ADVANCED ANALYTICAL QUERIES (Step 8)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- QUERY 1: Temporal Filtering & Multi-Table Inner Joins (INNER JOIN)
-- Purpose: List all active inventory batches expiring within the next 90 days,
--          including medication details, supplier name, and storage zone.
-- ----------------------------------------------------------------------------
SELECT
    b.manufacturer_batch_number,
    m.brand_name AS medication_name,
    c.category_name AS therapeutic_category,
    s.company_name AS supplier_name,
    z.zone_name AS storage_location,
    b.current_quantity,
    b.expiration_date,
    DATEDIFF(b.expiration_date, CURDATE()) AS days_remaining,
    ROUND(b.current_quantity * b.unit_purchase_cost, 2) AS capital_at_risk_mad
FROM stock_batch b
INNER JOIN medication m ON b.medication_id = m.medication_id
INNER JOIN therapeutic_category c ON m.category_id = c.category_id
INNER JOIN supplier s ON b.supplier_id = s.supplier_id
INNER JOIN storage_zone z ON b.zone_id = z.zone_id
WHERE b.batch_status = 'AVAILABLE'
  AND b.current_quantity > 0
  AND b.expiration_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY)
ORDER BY b.expiration_date ASC;

-- ----------------------------------------------------------------------------
-- QUERY 2: Left Join (LEFT JOIN), Aggregation (GROUP BY) & HAVING Clause
-- Purpose: Identify medications whose total valid stock has fallen below their
--          safety reorder threshold (including zero-stock items via LEFT JOIN).
-- ----------------------------------------------------------------------------
SELECT
    m.national_drug_code,
    m.brand_name,
    m.reorder_threshold,
    COALESCE(SUM(CASE WHEN b.batch_status = 'AVAILABLE' AND b.expiration_date >= CURDATE()
                      THEN b.current_quantity ELSE 0 END), 0) AS current_valid_stock,
    m.reorder_threshold - COALESCE(SUM(CASE WHEN b.batch_status = 'AVAILABLE' AND b.expiration_date >= CURDATE()
                                            THEN b.current_quantity ELSE 0 END), 0) AS unit_shortfall
FROM medication m
LEFT JOIN stock_batch b ON m.medication_id = b.medication_id
GROUP BY m.medication_id, m.national_drug_code, m.brand_name, m.reorder_threshold
HAVING current_valid_stock < m.reorder_threshold
ORDER BY unit_shortfall DESC;

-- ----------------------------------------------------------------------------
-- QUERY 3: Correlated Subquery
-- Purpose: For each medication, automatically identify the active contracted
--          supplier offering the lowest unit purchase cost.
-- ----------------------------------------------------------------------------
SELECT
    m.brand_name AS medication_name,
    s.company_name AS best_price_supplier,
    sc.contract_unit_cost AS lowest_unit_cost_mad,
    sc.lead_time_days,
    sc.min_order_quantity
FROM supplier_catalog sc
INNER JOIN medication m ON sc.medication_id = m.medication_id
INNER JOIN supplier s ON sc.supplier_id = s.supplier_id
WHERE s.is_active = TRUE
  AND sc.contract_unit_cost = (
      -- Correlated subquery evaluated per medication_id
      SELECT MIN(sc2.contract_unit_cost)
      FROM supplier_catalog sc2
      INNER JOIN supplier s2 ON sc2.supplier_id = s2.supplier_id
      WHERE sc2.medication_id = sc.medication_id
        AND s2.is_active = TRUE
  )
ORDER BY m.brand_name;

-- ----------------------------------------------------------------------------
-- QUERY 4: Common Table Expression (CTE) + Window Functions
-- Purpose: Perform a Pareto ABC financial analysis of total revenue and gross
--          profit margin per medication using DENSE_RANK() and SUM() OVER().
-- ----------------------------------------------------------------------------
WITH cte_medication_financials AS (
    SELECT
        m.medication_id,
        m.brand_name,
        c.category_name,
        SUM(di.dispensed_quantity) AS total_units_sold,
        ROUND(SUM(di.dispensed_quantity * di.billed_unit_price), 2) AS total_revenue_mad,
        ROUND(SUM(di.dispensed_quantity * (di.billed_unit_price - b.unit_purchase_cost)), 2) AS gross_profit_mad
    FROM dispensing_item di
    INNER JOIN stock_batch b ON di.batch_id = b.batch_id
    INNER JOIN medication m ON b.medication_id = m.medication_id
    INNER JOIN therapeutic_category c ON m.category_id = c.category_id
    GROUP BY m.medication_id, m.brand_name, c.category_name
)
SELECT
    DENSE_RANK() OVER (ORDER BY total_revenue_mad DESC) AS revenue_rank,
    brand_name,
    category_name,
    total_units_sold,
    total_revenue_mad,
    gross_profit_mad,
    ROUND(
        100.0 * SUM(total_revenue_mad) OVER (ORDER BY total_revenue_mad DESC)
        / SUM(total_revenue_mad) OVER (),
        2
    ) AS cumulative_revenue_pct,
    CASE
        WHEN SUM(total_revenue_mad) OVER (ORDER BY total_revenue_mad DESC)
             / SUM(total_revenue_mad) OVER () <= 0.70 THEN 'Class A (Core Revenue)'
        WHEN SUM(total_revenue_mad) OVER (ORDER BY total_revenue_mad DESC)
             / SUM(total_revenue_mad) OVER () <= 0.90 THEN 'Class B (Intermediate)'
        ELSE 'Class C (Slow Moving)'
    END AS pareto_abc_class
FROM cte_medication_financials
ORDER BY revenue_rank;

-- ----------------------------------------------------------------------------
-- QUERY 5: Insurance Provider Billing Breakdown (GROUP BY)
-- ----------------------------------------------------------------------------
SELECT
    p.insurance_provider,
    COUNT(DISTINCT p.patient_id) AS unique_patients,
    COUNT(DISTINCT rx.prescription_id) AS fulfilled_prescriptions,
    SUM(di.dispensed_quantity) AS total_packs_dispensed,
    ROUND(SUM(di.dispensed_quantity * di.billed_unit_price), 2) AS total_billed_amount_mad
FROM patient p
INNER JOIN prescription rx ON p.patient_id = rx.patient_id
INNER JOIN dispensing_item di ON rx.prescription_id = di.prescription_id
WHERE rx.prescription_status = 'DISPENSED'
GROUP BY p.insurance_provider
ORDER BY total_billed_amount_mad DESC;


-- ============================================================================
-- PART B: INDEXING & QUERY OPTIMIZATION WITH EXPLAIN (Step 9)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. BEFORE INDEX CREATION: Inspect baseline execution plans with EXPLAIN
-- ----------------------------------------------------------------------------
-- Target Query A: FEFO lookup of available non-expired batches sorted by expiration_date
EXPLAIN
SELECT batch_id, manufacturer_batch_number, current_quantity, expiration_date
FROM stock_batch
WHERE medication_id = 1
  AND batch_status = 'AVAILABLE'
  AND expiration_date >= CURDATE()
ORDER BY expiration_date ASC;

-- Target Query B: Audit log lookup filtered by movement_type and sorted by movement_timestamp
EXPLAIN
SELECT movement_id, batch_id, movement_type, quantity_delta, movement_timestamp
FROM stock_movement_log
WHERE movement_type = 'DISPENSING'
ORDER BY movement_timestamp DESC;

-- ----------------------------------------------------------------------------
-- 2. CREATE COMPOSITE B-TREE INDEXES
-- ----------------------------------------------------------------------------

-- INDEX 1: Covering composite index for FEFO batch allocation
-- Justification: Eliminates costly "Using filesort" and full medication partition scans
-- during sp_dispense_medication_fefo execution by serving the filter, sort, and projection directly from the B-Tree.
CREATE INDEX idx_batch_fefo_lookup
ON stock_batch (medication_id, batch_status, expiration_date, current_quantity);

-- INDEX 2: Composite index on the high-growth stock movement audit ledger
-- Justification: Replaces a Full Table Scan (type = ALL + Using filesort) with an ordered
-- index lookup (type = ref) when filtering by movement_type and sorting chronologically.
CREATE INDEX idx_movement_type_date
ON stock_movement_log (movement_type, movement_timestamp DESC);

-- INDEX 3: Composite index on prescription date and status for reporting dashboards
CREATE INDEX idx_prescription_date_status
ON prescription (prescription_date, prescription_status);

-- ----------------------------------------------------------------------------
-- 3. AFTER INDEX CREATION: Compare optimized execution plans with EXPLAIN
-- ----------------------------------------------------------------------------
-- Expected Result on Query A:
-- BEFORE: key = fk_batch_medication, Extra = "Using where; Using filesort"
-- AFTER : key = idx_batch_fefo_lookup, Extra = "Using where; Using index" (Covering Index, 0 filesort)
EXPLAIN
SELECT batch_id, manufacturer_batch_number, current_quantity, expiration_date
FROM stock_batch
WHERE medication_id = 1
  AND batch_status = 'AVAILABLE'
  AND expiration_date >= CURDATE()
ORDER BY expiration_date ASC;

-- Expected Result on Query B:
-- BEFORE: type = ALL (Full Table Scan), key = NULL, Extra = "Using where; Using filesort"
-- AFTER : type = ref, key = idx_movement_type_date, Extra = "Using where" (Ordered index scan)
EXPLAIN
SELECT movement_id, batch_id, movement_type, quantity_delta, movement_timestamp
FROM stock_movement_log
WHERE movement_type = 'DISPENSING'
ORDER BY movement_timestamp DESC;
