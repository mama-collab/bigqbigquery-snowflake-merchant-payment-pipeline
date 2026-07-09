-- ============================================================
-- MERCHANT PAYMENT PROFIT INTELLIGENCE PIPELINE
-- Platform: Google BigQuery
-- Author: M Priyadarsini | Compounding Mind
-- Domain: Financial Services — Payment Processing
-- Description: Calculates merchant-level profit across MSF
--              and Authorization fee categories with full
--              income, expense and net profit breakdown
-- Dataset: merchant_payments
-- ============================================================

-- ============================================================
-- SECTION 1: DATASET & TABLE SETUP
-- Run once to create all required tables
-- NOTE: Create dataset first via BigQuery console or:
-- bq mk --dataset merchant_payments
-- ============================================================
CREATE SCHEMA IF NOT EXISTS merchant_payments
OPTIONS (location = 'US');
-- Merchant master table
CREATE TABLE IF NOT EXISTS merchant_payments.merchants (
  account_number      STRING,
  merchant_id         INT64,
  processor_id        INT64,
  front_end_id        INT64,
  merchant_name       STRING,
  status              STRING,
  first_activity_date DATE
);

-- Fee history table
-- fee_sequence: 'MSF' = Monthly Service Fee, 'AUTH' = Authorization Fee
CREATE TABLE IF NOT EXISTS merchant_payments.fee_history (
  account_number      STRING,
  table_record_id     STRING,
  fee_sequence        STRING,
  retail_tran_count   INT64,
  retail_amount       NUMERIC,
  month_end_date      DATE
);

-- Internal product fee mapping
-- Links fee codes to GL codes and billing systems
CREATE TABLE IF NOT EXISTS merchant_payments.internal_product_fees (
  fee_code            STRING,
  billing_system_id   STRING,
  processor_id        INT64,
  front_end_id        INT64,
  fee_description     STRING,
  statement_desc      STRING,
  income_gl_code      INT64,
  expense_gl_code     INT64,
  is_commissionable   STRING
);

-- Pricing model — merchant fee schedule assignments
CREATE TABLE IF NOT EXISTS merchant_payments.pricing_model (
  account_number          STRING,
  processor_id            INT64,
  front_end_id            INT64,
  expense_schedule_code   STRING,
  settlement_id           INT64
);

-- Schedule expense — maps schedule codes to IDs
CREATE TABLE IF NOT EXISTS merchant_payments.schedule_expense (
  schedule_id             INT64,
  expense_schedule_code   STRING,
  processor_id            INT64,
  front_end_id            INT64
);

-- Schedule fee costs — MSF expense per schedule tier
CREATE TABLE IF NOT EXISTS merchant_payments.schedule_fee_cost (
  fee_code                STRING,
  schedule_id             INT64,
  base_cost               NUMERIC
);

-- Profit detail — permanent pipeline output table
-- FEE_CATEGORY must be VARCHAR(10) to hold 'AUTH' and 'MSF'
CREATE TABLE IF NOT EXISTS merchant_payments.profit_detail (
  account_number      STRING,
  merchant_name       STRING,
  fee_category        STRING,
  fee_item            STRING,
  total_transactions  INT64,
  income              NUMERIC,
  expense             NUMERIC,
  net_profit          NUMERIC,
  gl_code             INT64,
  is_commissionable   STRING
);

-- ============================================================
-- SECTION 2: SAMPLE DATA — 25 MERCHANTS
-- Realistic anonymized payment processing data
-- Mixed industries, fee tiers, processor/frontend combos
-- ============================================================

-- Merchants
INSERT INTO merchant_payments.merchants VALUES
('ACC100001', 1001, 3, 1, 'Maple Leaf Retail Inc',        'ACTIVE', DATE '2021-03-15'),
('ACC100002', 1002, 3, 1, 'Northern Foods Ltd',           'ACTIVE', DATE '2020-08-01'),
('ACC100003', 1003, 3, 2, 'Pacific Auto Group',           'ACTIVE', DATE '2022-01-10'),
('ACC100004', 1004, 3, 1, 'Great Lakes Pharma',           'ACTIVE', DATE '2019-11-20'),
('ACC100005', 1005, 3, 2, 'Prairie Tech Solutions',       'ACTIVE', DATE '2023-02-05'),
('ACC100006', 1006, 3, 1, 'Atlantic Hospitality Group',   'ACTIVE', DATE '2021-06-15'),
('ACC100007', 1007, 3, 2, 'Rocky Mountain Sports',        'ACTIVE', DATE '2022-09-01'),
('ACC100008', 1008, 3, 1, 'Ontario Medical Supplies',     'ACTIVE', DATE '2020-04-20'),
('ACC100009', 1009, 3, 1, 'Coastal Beauty Co',            'ACTIVE', DATE '2023-05-10'),
('ACC100010', 1010, 3, 2, 'Heartland Agriculture',        'ACTIVE', DATE '2019-07-15'),
('ACC100011', 1011, 3, 1, 'Metro Electronics Corp',       'ACTIVE', DATE '2021-12-01'),
('ACC100012', 1012, 3, 2, 'Lakeview Construction',        'ACTIVE', DATE '2022-03-20'),
('ACC100013', 1013, 3, 1, 'Capital City Fitness',         'ACTIVE', DATE '2020-10-05'),
('ACC100014', 1014, 3, 1, 'Northwood Financial Services', 'ACTIVE', DATE '2023-01-15'),
('ACC100015', 1015, 3, 2, 'Sunrise Logistics Inc',        'ACTIVE', DATE '2021-08-30'),
('ACC100016', 1016, 3, 1, 'Harbour View Hotels',          'ACTIVE', DATE '2019-05-20'),
('ACC100017', 1017, 3, 2, 'Clearwater Energy Ltd',        'ACTIVE', DATE '2022-07-10'),
('ACC100018', 1018, 3, 1, 'Summit Insurance Brokers',     'ACTIVE', DATE '2020-02-15'),
('ACC100019', 1019, 3, 1, 'Ridgeline Software Inc',       'ACTIVE', DATE '2023-04-01'),
('ACC100020', 1020, 3, 2, 'Bayshore Marine Group',        'ACTIVE', DATE '2021-09-15'),
('ACC100021', 1021, 3, 1, 'Meadowbrook Dental Clinics',   'ACTIVE', DATE '2022-11-20'),
('ACC100022', 1022, 3, 2, 'Ironbridge Manufacturing',     'ACTIVE', DATE '2020-06-10'),
('ACC100023', 1023, 3, 1, 'Pinecrest Education Group',    'ACTIVE', DATE '2023-03-05'),
('ACC100024', 1024, 3, 1, 'Silverstone Jewellers',        'ACTIVE', DATE '2021-01-25'),
('ACC100025', 1025, 3, 2, 'Tundra Media Productions',     'ACTIVE', DATE '2022-05-15');

-- MSF Fee History
INSERT INTO merchant_payments.fee_history VALUES
('ACC100001', 'F', 'MSF', 1250, 49.99,  DATE '2026-05-31'),
('ACC100002', 'F', 'MSF', 3200, 49.99,  DATE '2026-05-31'),
('ACC100003', 'F', 'MSF',  890, 29.99,  DATE '2026-05-31'),
('ACC100004', 'F', 'MSF', 5600, 99.99,  DATE '2026-05-31'),
('ACC100005', 'F', 'MSF',  420, 19.99,  DATE '2026-05-31'),
('ACC100006', 'F', 'MSF', 2800, 49.99,  DATE '2026-05-31'),
('ACC100007', 'F', 'MSF',  760, 29.99,  DATE '2026-05-31'),
('ACC100008', 'F', 'MSF', 4100, 99.99,  DATE '2026-05-31'),
('ACC100009', 'F', 'MSF',  380, 19.99,  DATE '2026-05-31'),
('ACC100010', 'F', 'MSF', 6200, 99.99,  DATE '2026-05-31'),
('ACC100011', 'F', 'MSF', 1800, 49.99,  DATE '2026-05-31'),
('ACC100012', 'F', 'MSF',  950, 29.99,  DATE '2026-05-31'),
('ACC100013', 'F', 'MSF', 2100, 49.99,  DATE '2026-05-31'),
('ACC100014', 'F', 'MSF', 3800, 99.99,  DATE '2026-05-31'),
('ACC100015', 'F', 'MSF', 1400, 29.99,  DATE '2026-05-31'),
('ACC100016', 'F', 'MSF', 7200, 99.99,  DATE '2026-05-31'),
('ACC100017', 'F', 'MSF',  680, 19.99,  DATE '2026-05-31'),
('ACC100018', 'F', 'MSF', 2400, 49.99,  DATE '2026-05-31'),
('ACC100019', 'F', 'MSF',  520, 19.99,  DATE '2026-05-31'),
('ACC100020', 'F', 'MSF', 1100, 29.99,  DATE '2026-05-31'),
('ACC100021', 'F', 'MSF', 1650, 49.99,  DATE '2026-05-31'),
('ACC100022', 'F', 'MSF', 4800, 99.99,  DATE '2026-05-31'),
('ACC100023', 'F', 'MSF',  290, 19.99,  DATE '2026-05-31'),
('ACC100024', 'F', 'MSF',  870, 29.99,  DATE '2026-05-31'),
('ACC100025', 'F', 'MSF', 1320, 29.99,  DATE '2026-05-31');

-- Authorization Fee History
INSERT INTO merchant_payments.fee_history VALUES
('ACC100001', 'F', 'AUTH', 1250,  62.50, DATE '2026-05-31'),
('ACC100002', 'F', 'AUTH', 3200, 160.00, DATE '2026-05-31'),
('ACC100003', 'F', 'AUTH',  890,  44.50, DATE '2026-05-31'),
('ACC100004', 'F', 'AUTH', 5600, 280.00, DATE '2026-05-31'),
('ACC100005', 'F', 'AUTH',  420,  21.00, DATE '2026-05-31'),
('ACC100006', 'F', 'AUTH', 2800, 140.00, DATE '2026-05-31'),
('ACC100007', 'F', 'AUTH',  760,  38.00, DATE '2026-05-31'),
('ACC100008', 'F', 'AUTH', 4100, 205.00, DATE '2026-05-31'),
('ACC100009', 'F', 'AUTH',  380,  19.00, DATE '2026-05-31'),
('ACC100010', 'F', 'AUTH', 6200, 310.00, DATE '2026-05-31'),
('ACC100011', 'F', 'AUTH', 1800,  90.00, DATE '2026-05-31'),
('ACC100012', 'F', 'AUTH',  950,  47.50, DATE '2026-05-31'),
('ACC100013', 'F', 'AUTH', 2100, 105.00, DATE '2026-05-31'),
('ACC100014', 'F', 'AUTH', 3800, 190.00, DATE '2026-05-31'),
('ACC100015', 'F', 'AUTH', 1400,  70.00, DATE '2026-05-31'),
('ACC100016', 'F', 'AUTH', 7200, 360.00, DATE '2026-05-31'),
('ACC100017', 'F', 'AUTH',  680,  34.00, DATE '2026-05-31'),
('ACC100018', 'F', 'AUTH', 2400, 120.00, DATE '2026-05-31'),
('ACC100019', 'F', 'AUTH',  520,  26.00, DATE '2026-05-31'),
('ACC100020', 'F', 'AUTH', 1100,  55.00, DATE '2026-05-31'),
('ACC100021', 'F', 'AUTH', 1650,  82.50, DATE '2026-05-31'),
('ACC100022', 'F', 'AUTH', 4800, 240.00, DATE '2026-05-31'),
('ACC100023', 'F', 'AUTH',  290,  14.50, DATE '2026-05-31'),
('ACC100024', 'F', 'AUTH',  870,  43.50, DATE '2026-05-31'),
('ACC100025', 'F', 'AUTH', 1320,  66.00, DATE '2026-05-31');

-- Internal product fees
-- Both processor/frontend combos for full coverage
INSERT INTO merchant_payments.internal_product_fees VALUES
('MSF',  '6', 3, 1, 'Monthly Service Fee', 'MSF Charge', 4001, 5001, '1'),
('MSF',  '6', 3, 2, 'Monthly Service Fee', 'MSF Charge', 4001, 5001, '1'),
('AUTH', '6', 3, 1, 'Authorization Fee',   'Auth Fee',   4002, 5002, '1'),
('AUTH', '6', 3, 2, 'Authorization Fee',   'Auth Fee',   4002, 5002, '1');

-- Pricing model — one row per merchant
INSERT INTO merchant_payments.pricing_model VALUES
('ACC100001', 3, 1, 'SCH_STANDARD',   2),
('ACC100002', 3, 1, 'SCH_STANDARD',   2),
('ACC100003', 3, 2, 'SCH_PREMIUM',    2),
('ACC100004', 3, 1, 'SCH_ENTERPRISE', 2),
('ACC100005', 3, 2, 'SCH_BASIC',      2),
('ACC100006', 3, 1, 'SCH_STANDARD',   2),
('ACC100007', 3, 2, 'SCH_PREMIUM',    2),
('ACC100008', 3, 1, 'SCH_ENTERPRISE', 2),
('ACC100009', 3, 1, 'SCH_BASIC',      2),
('ACC100010', 3, 2, 'SCH_ENTERPRISE', 2),
('ACC100011', 3, 1, 'SCH_STANDARD',   2),
('ACC100012', 3, 2, 'SCH_PREMIUM',    2),
('ACC100013', 3, 1, 'SCH_STANDARD',   2),
('ACC100014', 3, 1, 'SCH_ENTERPRISE', 2),
('ACC100015', 3, 2, 'SCH_PREMIUM',    2),
('ACC100016', 3, 1, 'SCH_ENTERPRISE', 2),
('ACC100017', 3, 2, 'SCH_BASIC',      2),
('ACC100018', 3, 1, 'SCH_STANDARD',   2),
('ACC100019', 3, 1, 'SCH_BASIC',      2),
('ACC100020', 3, 2, 'SCH_PREMIUM',    2),
('ACC100021', 3, 1, 'SCH_STANDARD',   2),
('ACC100022', 3, 2, 'SCH_ENTERPRISE', 2),
('ACC100023', 3, 1, 'SCH_BASIC',      2),
('ACC100024', 3, 1, 'SCH_PREMIUM',    2),
('ACC100025', 3, 2, 'SCH_PREMIUM',    2);

-- Schedule expense — maps schedule codes to IDs per processor/frontend
INSERT INTO merchant_payments.schedule_expense VALUES
(101, 'SCH_BASIC',      3, 1),
(102, 'SCH_BASIC',      3, 2),
(103, 'SCH_STANDARD',   3, 1),
(104, 'SCH_PREMIUM',    3, 1),
(105, 'SCH_PREMIUM',    3, 2),
(106, 'SCH_ENTERPRISE', 3, 1),
(107, 'SCH_ENTERPRISE', 3, 2);

-- Schedule fee costs — MSF expense by tier
INSERT INTO merchant_payments.schedule_fee_cost VALUES
('MSF', 101,  6.00),   -- Basic
('MSF', 102,  6.00),   -- Basic
('MSF', 103,  9.50),   -- Standard
('MSF', 104, 12.00),   -- Premium
('MSF', 105, 12.00),   -- Premium
('MSF', 106, 18.00),   -- Enterprise
('MSF', 107, 18.00);   -- Enterprise

-- ============================================================
-- SECTION 3: PRICING VIEW
-- Deduped pricing model joined to schedule IDs
-- Created as a view for reuse across pipeline steps
-- ============================================================

CREATE OR REPLACE VIEW merchant_payments.pricing_view AS
WITH pricing_dedup AS (
  SELECT
    account_number,
    ANY_VALUE(processor_id)           AS processor_id,
    ANY_VALUE(front_end_id)           AS front_end_id,
    ANY_VALUE(expense_schedule_code)  AS expense_schedule_code,
    ANY_VALUE(settlement_id)          AS settlement_id
  FROM merchant_payments.pricing_model
  WHERE account_number IS NOT NULL
  GROUP BY account_number
)
SELECT
  p.account_number,
  p.processor_id,
  p.front_end_id,
  p.expense_schedule_code,
  p.settlement_id,
  se.schedule_id
FROM pricing_dedup p
LEFT JOIN merchant_payments.schedule_expense se
  ON  se.expense_schedule_code = p.expense_schedule_code
  AND se.processor_id          = p.processor_id
  AND se.front_end_id          = p.front_end_id;

-- Verify pricing view
SELECT COUNT(*) AS merchant_count FROM merchant_payments.pricing_view;
DECLARE profit_date DATE DEFAULT LAST_DAY(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH));

-- ============================================================
-- SECTION 4: PIPELINE EXECUTION
-- Loads all MSF income, MSF expense, and Auth income
-- into permanent profit_detail table using UNION ALL
-- ============================================================

-- Clear existing data before reload
TRUNCATE TABLE merchant_payments.profit_detail;

-- Load all three fee categories in one statement
INSERT INTO merchant_payments.profit_detail

-- MSF Income
SELECT
  fh.account_number,
  m.merchant_name,
  'MSF'                               AS fee_category,
  COALESCE(ipf.statement_desc,
           ipf.fee_description,
           'Monthly Service Fee')     AS fee_item,
  SUM(fh.retail_tran_count)           AS total_transactions,
  SUM(fh.retail_amount)               AS income,
  CAST(0 AS NUMERIC)                  AS expense,
  SUM(fh.retail_amount)               AS net_profit,
  ipf.income_gl_code                  AS gl_code,
  ipf.is_commissionable
FROM merchant_payments.fee_history fh
INNER JOIN merchant_payments.pricing_view pv
  ON  pv.account_number = fh.account_number
INNER JOIN merchant_payments.merchants m
  ON  m.account_number  = fh.account_number
LEFT JOIN merchant_payments.internal_product_fees ipf
  ON  ipf.fee_code          = fh.fee_sequence
  AND ipf.billing_system_id = '6'
  AND ipf.processor_id      = COALESCE(pv.processor_id, 3)
  AND ipf.front_end_id      = COALESCE(pv.front_end_id, 1)
WHERE LAST_DAY(fh.month_end_date, MONTH) = profit_date--DATE '2026-05-31'
  AND fh.table_record_id = 'F'
  AND fh.fee_sequence    = 'MSF'
GROUP BY 1, 2, 3, 4, 9, 10

UNION ALL

-- MSF Expense
SELECT
  pv.account_number,
  m.merchant_name,
  'MSF'                               AS fee_category,
  COALESCE(ipf.statement_desc,
           ipf.fee_description,
           'Monthly Service Fee')     AS fee_item,
  0                                   AS total_transactions,
  CAST(0 AS NUMERIC)                  AS income,
  sfc.base_cost                       AS expense,
  sfc.base_cost * -1                  AS net_profit,
  ipf.expense_gl_code                 AS gl_code,
  ipf.is_commissionable
FROM merchant_payments.pricing_view pv
INNER JOIN merchant_payments.merchants m
  ON  m.account_number  = pv.account_number
LEFT JOIN merchant_payments.internal_product_fees ipf
  ON  ipf.fee_code          = 'MSF'
  AND ipf.billing_system_id = '6'
  AND ipf.processor_id      = COALESCE(pv.processor_id, 3)
  AND ipf.front_end_id      = COALESCE(pv.front_end_id, 1)
INNER JOIN merchant_payments.schedule_fee_cost sfc
  ON  sfc.fee_code    = 'MSF'
  AND sfc.schedule_id = pv.schedule_id

UNION ALL

-- Authorization Fee Income
SELECT
  fh.account_number,
  m.merchant_name,
  'AUTH'                              AS fee_category,
  ipf.fee_description                 AS fee_item,
  SUM(fh.retail_tran_count)           AS total_transactions,
  SUM(fh.retail_amount)               AS income,
  CAST(0 AS NUMERIC)                  AS expense,
  SUM(fh.retail_amount)               AS net_profit,
  ipf.income_gl_code                  AS gl_code,
  ipf.is_commissionable
FROM merchant_payments.fee_history fh
INNER JOIN merchant_payments.pricing_view pv
  ON  pv.account_number = fh.account_number
INNER JOIN merchant_payments.merchants m
  ON  m.account_number  = fh.account_number
INNER JOIN merchant_payments.internal_product_fees ipf
  ON  ipf.fee_code          = fh.fee_sequence
  AND ipf.billing_system_id = '6'
  AND ipf.processor_id      = pv.processor_id
  AND ipf.front_end_id      = pv.front_end_id
WHERE LAST_DAY(fh.month_end_date, MONTH) = profit_date--DATE '2026-05-31'
  AND fh.table_record_id = 'F'
  AND fh.fee_sequence    = 'AUTH'
GROUP BY 1, 2, 3, 4, 9, 10;

-- ============================================================
-- SECTION 5: DASHBOARD VIEW
-- Production-ready view for BI and Streamlit consumption
-- ============================================================
CREATE OR REPLACE VIEW merchant_payments.profit_dashboard_view AS
SELECT
  account_number,
  merchant_name,
  fee_category,
  fee_item,
  SUM(total_transactions)       AS total_transactions,
  ROUND(SUM(income), 2)         AS total_income,
  ROUND(SUM(expense), 2)        AS total_expense,
  ROUND(SUM(net_profit), 2)     AS total_net_profit,
  CASE
    WHEN SUM(net_profit) < 0    THEN 'Loss'
    WHEN SUM(net_profit) < 20   THEN 'Low Margin'
    ELSE 'Profitable'
  END                           AS profit_status
FROM merchant_payments.profit_detail
GROUP BY 1, 2, 3, 4;

-- ============================================================
-- SECTION 6: VALIDATION QUERIES
-- Verify pipeline loaded correctly — screenshot these!
-- ============================================================

-- Pipeline summary by fee category 
SELECT
  fee_category,
  COUNT(*)                AS record_count,
  SUM(total_transactions) AS total_trans,
  ROUND(SUM(income), 2)   AS total_income,
  ROUND(SUM(expense), 2)  AS total_expense,
  ROUND(SUM(net_profit),2) AS total_profit
FROM merchant_payments.profit_detail
GROUP BY fee_category
ORDER BY fee_category;

-- Top 10 most profitable merchants 
SELECT
  account_number,
  merchant_name,
  ROUND(SUM(income), 2)     AS total_income,
  ROUND(SUM(expense), 2)    AS total_expense,
  ROUND(SUM(net_profit), 2) AS total_net_profit,
  CASE
    WHEN SUM(net_profit) < 0  THEN 'Loss'
    WHEN SUM(net_profit) < 20 THEN 'Low Margin'
    ELSE 'Profitable'
  END                       AS profit_status
FROM merchant_payments.profit_detail
GROUP BY 1, 2
ORDER BY total_net_profit DESC
LIMIT 10;

-- MSF vs Auth comparison 
SELECT
  fee_category,
  COUNT(DISTINCT account_number)  AS merchant_count,
  ROUND(SUM(income), 2)           AS total_income,
  ROUND(SUM(expense), 2)          AS total_expense,
  ROUND(SUM(net_profit), 2)       AS total_net_profit
FROM merchant_payments.profit_detail
GROUP BY 1
ORDER BY total_net_profit DESC;

-- Loss-making merchants alert
SELECT
  account_number,
  merchant_name,
  ROUND(SUM(income), 2)     AS total_income,
  ROUND(SUM(expense), 2)    AS total_expense,
  ROUND(SUM(net_profit), 2) AS total_net_profit
FROM merchant_payments.profit_detail
GROUP BY 1, 2
HAVING SUM(net_profit) < 0
ORDER BY total_net_profit ASC;

-- ============================================================
-- END OF BIGQUERY PIPELINE
-- Key differences from Snowflake version:
--   LAST_DAY(d, MONTH)  vs  LAST_DAY(d)
--   CAST(0 AS NUMERIC)  vs  0::NUMBER(18,2)
--   DATE '2026-05-31'   vs  '2026-05-31'
--   CREATE VIEW         vs  CREATE OR REPLACE VIEW
-- ============================================================
