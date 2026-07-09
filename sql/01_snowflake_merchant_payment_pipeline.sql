-- ============================================================
-- MERCHANT PAYMENT PROFIT INTELLIGENCE PIPELINE
-- Platform: Snowflake CoCo
-- Author: M Priyadarsini | Compounding Mind
-- Domain: Financial Services — Payment Processing
-- Description: Snowflake merchant payment profit pipeline
--              with 25 merchants, MSF + Auth fees,
--              and live Streamlit dashboard
-- GitHub: github.com/mama-collab/bigquery-snowflake-merchant-payment-pipeline
-- ============================================================

-- ============================================================
-- SECTION 1: DATABASE & SCHEMA SETUP
-- ============================================================
CREATE DATABASE IF NOT EXISTS MERCHANT_PAYMENTS;
USE DATABASE MERCHANT_PAYMENTS;
CREATE SCHEMA IF NOT EXISTS RAW;
USE SCHEMA RAW;

-- ============================================================
-- SECTION 2: TABLE CREATION
-- ============================================================

CREATE OR REPLACE TABLE MERCHANTS (
  ACCOUNT_NUMBER      VARCHAR(20),
  MERCHANT_ID         INTEGER,
  PROCESSOR_ID        INTEGER,
  FRONT_END_ID        INTEGER,
  MERCHANT_NAME       VARCHAR(100),
  STATUS              VARCHAR(20),
  FIRST_ACTIVITY_DATE DATE
);

CREATE OR REPLACE TABLE FEE_HISTORY (
  ACCOUNT_NUMBER      VARCHAR(20),
  TABLE_RECORD_ID     VARCHAR(5),
  FEE_SEQUENCE        VARCHAR(10),
  RETAIL_TRAN_COUNT   INTEGER,
  RETAIL_AMOUNT       NUMBER(18,2),
  MONTH_END_DATE      DATE
);

CREATE OR REPLACE TABLE INTERNAL_PRODUCT_FEES (
  FEE_CODE            VARCHAR(20),
  BILLING_SYSTEM_ID   VARCHAR(5),
  PROCESSOR_ID        INTEGER,
  FRONT_END_ID        INTEGER,
  FEE_DESCRIPTION     VARCHAR(100),
  STATEMENT_DESC      VARCHAR(100),
  INCOME_GL_CODE      INTEGER,
  EXPENSE_GL_CODE     INTEGER,
  IS_COMMISSIONABLE   VARCHAR(5)
);

CREATE OR REPLACE TABLE PRICING_MODEL (
  ACCOUNT_NUMBER          VARCHAR(20),
  PROCESSOR_ID            INTEGER,
  FRONT_END_ID            INTEGER,
  EXPENSE_SCHEDULE_CODE   VARCHAR(20),
  SETTLEMENT_ID           INTEGER
);

CREATE OR REPLACE TABLE SCHEDULE_EXPENSE (
  SCHEDULE_ID             INTEGER,
  EXPENSE_SCHEDULE_CODE   VARCHAR(20),
  PROCESSOR_ID            INTEGER,
  FRONT_END_ID            INTEGER
);

CREATE OR REPLACE TABLE SCHEDULE_FEE_COST (
  FEE_CODE                VARCHAR(20),
  SCHEDULE_ID             INTEGER,
  BASE_COST               NUMBER(18,2)
);

-- FIX 1: PROFIT_DETAIL created as permanent table
-- FEE_CATEGORY VARCHAR(10) to accommodate both 'MSF' and 'AUTH'
-- FEE_ITEM VARCHAR(100) for full fee descriptions
CREATE OR REPLACE TABLE PROFIT_DETAIL (
  ACCOUNT_NUMBER      VARCHAR(20),
  MERCHANT_NAME       VARCHAR(100),
  FEE_CATEGORY        VARCHAR(10),
  FEE_ITEM            VARCHAR(100),
  TOTAL_TRANSACTIONS  INTEGER,
  INCOME              NUMBER(18,2),
  EXPENSE             NUMBER(18,2),
  NET_PROFIT          NUMBER(18,2),
  GL_CODE             INTEGER,
  IS_COMMISSIONABLE   VARCHAR(5)
);

-- ============================================================
-- SECTION 3: SAMPLE DATA — 25 MERCHANTS
-- Realistic anonymized payment processing data
-- Mixed industries, fee tiers, processor/frontend combos
-- ============================================================

INSERT INTO MERCHANTS VALUES
('ACC100001', 1001, 3, 1, 'Maple Leaf Retail Inc',        'ACTIVE', '2021-03-15'),
('ACC100002', 1002, 3, 1, 'Northern Foods Ltd',           'ACTIVE', '2020-08-01'),
('ACC100003', 1003, 3, 2, 'Pacific Auto Group',           'ACTIVE', '2022-01-10'),
('ACC100004', 1004, 3, 1, 'Great Lakes Pharma',           'ACTIVE', '2019-11-20'),
('ACC100005', 1005, 3, 2, 'Prairie Tech Solutions',       'ACTIVE', '2023-02-05'),
('ACC100006', 1006, 3, 1, 'Atlantic Hospitality Group',   'ACTIVE', '2021-06-15'),
('ACC100007', 1007, 3, 2, 'Rocky Mountain Sports',        'ACTIVE', '2022-09-01'),
('ACC100008', 1008, 3, 1, 'Ontario Medical Supplies',     'ACTIVE', '2020-04-20'),
('ACC100009', 1009, 3, 1, 'Coastal Beauty Co',            'ACTIVE', '2023-05-10'),
('ACC100010', 1010, 3, 2, 'Heartland Agriculture',        'ACTIVE', '2019-07-15'),
('ACC100011', 1011, 3, 1, 'Metro Electronics Corp',       'ACTIVE', '2021-12-01'),
('ACC100012', 1012, 3, 2, 'Lakeview Construction',        'ACTIVE', '2022-03-20'),
('ACC100013', 1013, 3, 1, 'Capital City Fitness',         'ACTIVE', '2020-10-05'),
('ACC100014', 1014, 3, 1, 'Northwood Financial Services', 'ACTIVE', '2023-01-15'),
('ACC100015', 1015, 3, 2, 'Sunrise Logistics Inc',        'ACTIVE', '2021-08-30'),
('ACC100016', 1016, 3, 1, 'Harbour View Hotels',          'ACTIVE', '2019-05-20'),
('ACC100017', 1017, 3, 2, 'Clearwater Energy Ltd',        'ACTIVE', '2022-07-10'),
('ACC100018', 1018, 3, 1, 'Summit Insurance Brokers',     'ACTIVE', '2020-02-15'),
('ACC100019', 1019, 3, 1, 'Ridgeline Software Inc',       'ACTIVE', '2023-04-01'),
('ACC100020', 1020, 3, 2, 'Bayshore Marine Group',        'ACTIVE', '2021-09-15'),
('ACC100021', 1021, 3, 1, 'Meadowbrook Dental Clinics',   'ACTIVE', '2022-11-20'),
('ACC100022', 1022, 3, 2, 'Ironbridge Manufacturing',     'ACTIVE', '2020-06-10'),
('ACC100023', 1023, 3, 1, 'Pinecrest Education Group',    'ACTIVE', '2023-03-05'),
('ACC100024', 1024, 3, 1, 'Silverstone Jewellers',        'ACTIVE', '2021-01-25'),
('ACC100025', 1025, 3, 2, 'Tundra Media Productions',     'ACTIVE', '2022-05-15');

-- MSF Fee History
INSERT INTO FEE_HISTORY VALUES
('ACC100001', 'F', 'MSF', 1250, 49.99,  '2026-05-31'),
('ACC100002', 'F', 'MSF', 3200, 49.99,  '2026-05-31'),
('ACC100003', 'F', 'MSF',  890, 29.99,  '2026-05-31'),
('ACC100004', 'F', 'MSF', 5600, 99.99,  '2026-05-31'),
('ACC100005', 'F', 'MSF',  420, 19.99,  '2026-05-31'),
('ACC100006', 'F', 'MSF', 2800, 49.99,  '2026-05-31'),
('ACC100007', 'F', 'MSF',  760, 29.99,  '2026-05-31'),
('ACC100008', 'F', 'MSF', 4100, 99.99,  '2026-05-31'),
('ACC100009', 'F', 'MSF',  380, 19.99,  '2026-05-31'),
('ACC100010', 'F', 'MSF', 6200, 99.99,  '2026-05-31'),
('ACC100011', 'F', 'MSF', 1800, 49.99,  '2026-05-31'),
('ACC100012', 'F', 'MSF',  950, 29.99,  '2026-05-31'),
('ACC100013', 'F', 'MSF', 2100, 49.99,  '2026-05-31'),
('ACC100014', 'F', 'MSF', 3800, 99.99,  '2026-05-31'),
('ACC100015', 'F', 'MSF', 1400, 29.99,  '2026-05-31'),
('ACC100016', 'F', 'MSF', 7200, 99.99,  '2026-05-31'),
('ACC100017', 'F', 'MSF',  680, 19.99,  '2026-05-31'),
('ACC100018', 'F', 'MSF', 2400, 49.99,  '2026-05-31'),
('ACC100019', 'F', 'MSF',  520, 19.99,  '2026-05-31'),
('ACC100020', 'F', 'MSF', 1100, 29.99,  '2026-05-31'),
('ACC100021', 'F', 'MSF', 1650, 49.99,  '2026-05-31'),
('ACC100022', 'F', 'MSF', 4800, 99.99,  '2026-05-31'),
('ACC100023', 'F', 'MSF',  290, 19.99,  '2026-05-31'),
('ACC100024', 'F', 'MSF',  870, 29.99,  '2026-05-31'),
('ACC100025', 'F', 'MSF', 1320, 29.99,  '2026-05-31');

-- Authorization Fee History
INSERT INTO FEE_HISTORY VALUES
('ACC100001', 'F', 'AUTH', 1250,  62.50, '2026-05-31'),
('ACC100002', 'F', 'AUTH', 3200, 160.00, '2026-05-31'),
('ACC100003', 'F', 'AUTH',  890,  44.50, '2026-05-31'),
('ACC100004', 'F', 'AUTH', 5600, 280.00, '2026-05-31'),
('ACC100005', 'F', 'AUTH',  420,  21.00, '2026-05-31'),
('ACC100006', 'F', 'AUTH', 2800, 140.00, '2026-05-31'),
('ACC100007', 'F', 'AUTH',  760,  38.00, '2026-05-31'),
('ACC100008', 'F', 'AUTH', 4100, 205.00, '2026-05-31'),
('ACC100009', 'F', 'AUTH',  380,  19.00, '2026-05-31'),
('ACC100010', 'F', 'AUTH', 6200, 310.00, '2026-05-31'),
('ACC100011', 'F', 'AUTH', 1800,  90.00, '2026-05-31'),
('ACC100012', 'F', 'AUTH',  950,  47.50, '2026-05-31'),
('ACC100013', 'F', 'AUTH', 2100, 105.00, '2026-05-31'),
('ACC100014', 'F', 'AUTH', 3800, 190.00, '2026-05-31'),
('ACC100015', 'F', 'AUTH', 1400,  70.00, '2026-05-31'),
('ACC100016', 'F', 'AUTH', 7200, 360.00, '2026-05-31'),
('ACC100017', 'F', 'AUTH',  680,  34.00, '2026-05-31'),
('ACC100018', 'F', 'AUTH', 2400, 120.00, '2026-05-31'),
('ACC100019', 'F', 'AUTH',  520,  26.00, '2026-05-31'),
('ACC100020', 'F', 'AUTH', 1100,  55.00, '2026-05-31'),
('ACC100021', 'F', 'AUTH', 1650,  82.50, '2026-05-31'),
('ACC100022', 'F', 'AUTH', 4800, 240.00, '2026-05-31'),
('ACC100023', 'F', 'AUTH',  290,  14.50, '2026-05-31'),
('ACC100024', 'F', 'AUTH',  870,  43.50, '2026-05-31'),
('ACC100025', 'F', 'AUTH', 1320,  66.00, '2026-05-31');

-- Internal product fees
-- Both processor/frontend combos for full coverage
INSERT INTO INTERNAL_PRODUCT_FEES VALUES
('MSF',  '6', 3, 1, 'Monthly Service Fee', 'MSF Charge', 4001, 5001, '1'),
('MSF',  '6', 3, 2, 'Monthly Service Fee', 'MSF Charge', 4001, 5001, '1'),
('AUTH', '6', 3, 1, 'Authorization Fee',   'Auth Fee',   4002, 5002, '1'),
('AUTH', '6', 3, 2, 'Authorization Fee',   'Auth Fee',   4002, 5002, '1');

-- Pricing model — one row per merchant
INSERT INTO PRICING_MODEL VALUES
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

-- Schedule expense
INSERT INTO SCHEDULE_EXPENSE VALUES
(101, 'SCH_BASIC',      3, 1),
(102, 'SCH_BASIC',      3, 2),
(103, 'SCH_STANDARD',   3, 1),
(104, 'SCH_PREMIUM',    3, 1),
(105, 'SCH_PREMIUM',    3, 2),
(106, 'SCH_ENTERPRISE', 3, 1),
(107, 'SCH_ENTERPRISE', 3, 2);

-- Schedule fee costs — MSF expense by tier
INSERT INTO SCHEDULE_FEE_COST VALUES
('MSF', 101,  6.00),   -- Basic
('MSF', 102,  6.00),   -- Basic
('MSF', 103,  9.50),   -- Standard
('MSF', 104, 12.00),   -- Premium
('MSF', 105, 12.00),   -- Premium
('MSF', 106, 18.00),   -- Enterprise
('MSF', 107, 18.00);   -- Enterprise

-- ============================================================
-- SECTION 4: PIPELINE EXECUTION
-- FIX 2: Using $PROFIT_DATE variable consistently throughout
-- FIX 3: PRICING_VIEW as permanent view
-- ============================================================

-- Set profit date dynamically — no hardcoded dates
SET PROFIT_DATE = LAST_DAY(DATEADD(MONTH, -1, CURRENT_DATE()));

-- Verify date
SELECT $PROFIT_DATE AS profit_date;

-- Create PRICING_VIEW as permanent view
-- Deduped pricing model joined to schedule IDs
CREATE OR REPLACE VIEW MERCHANT_PAYMENTS.RAW.PRICING_VIEW AS
WITH pricing_dedup AS (
  SELECT
    ACCOUNT_NUMBER,
    ANY_VALUE(PROCESSOR_ID)           AS PROCESSOR_ID,
    ANY_VALUE(FRONT_END_ID)           AS FRONT_END_ID,
    ANY_VALUE(EXPENSE_SCHEDULE_CODE)  AS EXPENSE_SCHEDULE_CODE,
    ANY_VALUE(SETTLEMENT_ID)          AS SETTLEMENT_ID
  FROM MERCHANT_PAYMENTS.RAW.PRICING_MODEL
  WHERE ACCOUNT_NUMBER IS NOT NULL
  GROUP BY ACCOUNT_NUMBER
)
SELECT
  p.ACCOUNT_NUMBER,
  p.PROCESSOR_ID,
  p.FRONT_END_ID,
  p.EXPENSE_SCHEDULE_CODE,
  p.SETTLEMENT_ID,
  se.SCHEDULE_ID
FROM pricing_dedup p
LEFT JOIN MERCHANT_PAYMENTS.RAW.SCHEDULE_EXPENSE se
  ON  se.EXPENSE_SCHEDULE_CODE = p.EXPENSE_SCHEDULE_CODE
  AND se.PROCESSOR_ID          = p.PROCESSOR_ID
  AND se.FRONT_END_ID          = p.FRONT_END_ID;

-- Verify pricing view — should show 25 merchants
SELECT COUNT(*) AS merchant_count
FROM MERCHANT_PAYMENTS.RAW.PRICING_VIEW;

-- Clear and reload PROFIT_DETAIL
TRUNCATE TABLE MERCHANT_PAYMENTS.RAW.PROFIT_DETAIL;

-- Load all three fee categories in one statement using UNION ALL
INSERT INTO MERCHANT_PAYMENTS.RAW.PROFIT_DETAIL

-- MSF Income
SELECT
  fh.ACCOUNT_NUMBER,
  m.MERCHANT_NAME,
  'MSF'                               AS FEE_CATEGORY,
  COALESCE(ipf.STATEMENT_DESC,
           ipf.FEE_DESCRIPTION,
           'Monthly Service Fee')     AS FEE_ITEM,
  SUM(fh.RETAIL_TRAN_COUNT)           AS TOTAL_TRANSACTIONS,
  SUM(fh.RETAIL_AMOUNT)               AS INCOME,
  0::NUMBER(18,2)                     AS EXPENSE,
  SUM(fh.RETAIL_AMOUNT)               AS NET_PROFIT,
  ipf.INCOME_GL_CODE                  AS GL_CODE,
  ipf.IS_COMMISSIONABLE
FROM MERCHANT_PAYMENTS.RAW.FEE_HISTORY fh
INNER JOIN MERCHANT_PAYMENTS.RAW.PRICING_VIEW pv
  ON  pv.ACCOUNT_NUMBER = fh.ACCOUNT_NUMBER
INNER JOIN MERCHANT_PAYMENTS.RAW.MERCHANTS m
  ON  m.ACCOUNT_NUMBER  = fh.ACCOUNT_NUMBER
LEFT JOIN MERCHANT_PAYMENTS.RAW.INTERNAL_PRODUCT_FEES ipf
  ON  ipf.FEE_CODE          = fh.FEE_SEQUENCE
  AND ipf.BILLING_SYSTEM_ID = '6'
  AND ipf.PROCESSOR_ID      = COALESCE(pv.PROCESSOR_ID, 3)
  AND ipf.FRONT_END_ID      = COALESCE(pv.FRONT_END_ID, 1)
WHERE LAST_DAY(fh.MONTH_END_DATE) = $PROFIT_DATE
  AND fh.TABLE_RECORD_ID = 'F'
  AND fh.FEE_SEQUENCE    = 'MSF'
GROUP BY 1, 2, 3, 4, 9, 10

UNION ALL

-- MSF Expense
SELECT
  pv.ACCOUNT_NUMBER,
  m.MERCHANT_NAME,
  'MSF'                               AS FEE_CATEGORY,
  COALESCE(ipf.STATEMENT_DESC,
           ipf.FEE_DESCRIPTION,
           'Monthly Service Fee')     AS FEE_ITEM,
  0                                   AS TOTAL_TRANSACTIONS,
  0::NUMBER(18,2)                     AS INCOME,
  sfc.BASE_COST                       AS EXPENSE,
  sfc.BASE_COST * -1                  AS NET_PROFIT,
  ipf.EXPENSE_GL_CODE                 AS GL_CODE,
  ipf.IS_COMMISSIONABLE
FROM MERCHANT_PAYMENTS.RAW.PRICING_VIEW pv
INNER JOIN MERCHANT_PAYMENTS.RAW.MERCHANTS m
  ON  m.ACCOUNT_NUMBER  = pv.ACCOUNT_NUMBER
LEFT JOIN MERCHANT_PAYMENTS.RAW.INTERNAL_PRODUCT_FEES ipf
  ON  ipf.FEE_CODE          = 'MSF'
  AND ipf.BILLING_SYSTEM_ID = '6'
  AND ipf.PROCESSOR_ID      = COALESCE(pv.PROCESSOR_ID, 3)
  AND ipf.FRONT_END_ID      = COALESCE(pv.FRONT_END_ID, 1)
INNER JOIN MERCHANT_PAYMENTS.RAW.SCHEDULE_FEE_COST sfc
  ON  sfc.FEE_CODE    = 'MSF'
  AND sfc.SCHEDULE_ID = pv.SCHEDULE_ID

UNION ALL

-- Authorization Fee Income
SELECT
  fh.ACCOUNT_NUMBER,
  m.MERCHANT_NAME,
  'AUTH'                              AS FEE_CATEGORY,
  ipf.FEE_DESCRIPTION                 AS FEE_ITEM,
  SUM(fh.RETAIL_TRAN_COUNT)           AS TOTAL_TRANSACTIONS,
  SUM(fh.RETAIL_AMOUNT)               AS INCOME,
  0::NUMBER(18,2)                     AS EXPENSE,
  SUM(fh.RETAIL_AMOUNT)               AS NET_PROFIT,
  ipf.INCOME_GL_CODE                  AS GL_CODE,
  ipf.IS_COMMISSIONABLE
FROM MERCHANT_PAYMENTS.RAW.FEE_HISTORY fh
INNER JOIN MERCHANT_PAYMENTS.RAW.PRICING_VIEW pv
  ON  pv.ACCOUNT_NUMBER = fh.ACCOUNT_NUMBER
INNER JOIN MERCHANT_PAYMENTS.RAW.MERCHANTS m
  ON  m.ACCOUNT_NUMBER  = fh.ACCOUNT_NUMBER
INNER JOIN MERCHANT_PAYMENTS.RAW.INTERNAL_PRODUCT_FEES ipf
  ON  ipf.FEE_CODE          = fh.FEE_SEQUENCE
  AND ipf.BILLING_SYSTEM_ID = '6'
  AND ipf.PROCESSOR_ID      = pv.PROCESSOR_ID
  AND ipf.FRONT_END_ID      = pv.FRONT_END_ID
WHERE LAST_DAY(fh.MONTH_END_DATE) = $PROFIT_DATE
  AND fh.TABLE_RECORD_ID = 'F'
  AND fh.FEE_SEQUENCE    = 'AUTH'
GROUP BY 1, 2, 3, 4, 9, 10;

-- ============================================================
-- SECTION 5: DASHBOARD VIEW
-- Production-ready view for Streamlit dashboard consumption
-- ============================================================
CREATE OR REPLACE VIEW MERCHANT_PAYMENTS.RAW.PROFIT_DASHBOARD_VIEW AS
SELECT
  ACCOUNT_NUMBER,
  MERCHANT_NAME,
  FEE_CATEGORY,
  FEE_ITEM,
  SUM(TOTAL_TRANSACTIONS)     AS TOTAL_TRANSACTIONS,
  ROUND(SUM(INCOME), 2)       AS TOTAL_INCOME,
  ROUND(SUM(EXPENSE), 2)      AS TOTAL_EXPENSE,
  ROUND(SUM(NET_PROFIT), 2)   AS TOTAL_NET_PROFIT,
  CASE
    WHEN SUM(NET_PROFIT) < 0  THEN 'Loss'
    WHEN SUM(NET_PROFIT) < 20 THEN 'Low Margin'
    ELSE 'Profitable'
  END                         AS PROFIT_STATUS
FROM MERCHANT_PAYMENTS.RAW.PROFIT_DETAIL
GROUP BY 1, 2, 3, 4;

-- ============================================================
-- SECTION 6: VALIDATION QUERIES
-- Verify pipeline loaded correctly — screenshot for portfolio!
-- ============================================================

-- Pipeline summary by fee category ⭐
SELECT
  FEE_CATEGORY,
  COUNT(*)                AS RECORD_COUNT,
  SUM(TOTAL_TRANSACTIONS) AS TOTAL_TRANS,
  ROUND(SUM(INCOME), 2)   AS TOTAL_INCOME,
  ROUND(SUM(EXPENSE), 2)  AS TOTAL_EXPENSE,
  ROUND(SUM(NET_PROFIT),2) AS TOTAL_PROFIT
FROM MERCHANT_PAYMENTS.RAW.PROFIT_DETAIL
GROUP BY FEE_CATEGORY
ORDER BY FEE_CATEGORY;

-- Top 10 most profitable merchants ⭐
SELECT
  ACCOUNT_NUMBER,
  MERCHANT_NAME,
  ROUND(SUM(INCOME), 2)     AS TOTAL_INCOME,
  ROUND(SUM(EXPENSE), 2)    AS TOTAL_EXPENSE,
  ROUND(SUM(NET_PROFIT), 2) AS TOTAL_NET_PROFIT,
  CASE
    WHEN SUM(NET_PROFIT) < 0  THEN 'Loss'
    WHEN SUM(NET_PROFIT) < 20 THEN 'Low Margin'
    ELSE 'Profitable'
  END                       AS PROFIT_STATUS
FROM MERCHANT_PAYMENTS.RAW.PROFIT_DETAIL
GROUP BY 1, 2
ORDER BY TOTAL_NET_PROFIT DESC
LIMIT 10;

-- MSF vs Auth comparison ⭐
SELECT
  FEE_CATEGORY,
  COUNT(DISTINCT ACCOUNT_NUMBER)  AS MERCHANT_COUNT,
  ROUND(SUM(INCOME), 2)           AS TOTAL_INCOME,
  ROUND(SUM(EXPENSE), 2)          AS TOTAL_EXPENSE,
  ROUND(SUM(NET_PROFIT), 2)       AS TOTAL_NET_PROFIT
FROM MERCHANT_PAYMENTS.RAW.PROFIT_DETAIL
GROUP BY FEE_CATEGORY
ORDER BY TOTAL_NET_PROFIT DESC;

-- Loss-making merchants alert
SELECT
  ACCOUNT_NUMBER,
  MERCHANT_NAME,
  ROUND(SUM(INCOME), 2)     AS TOTAL_INCOME,
  ROUND(SUM(EXPENSE), 2)    AS TOTAL_EXPENSE,
  ROUND(SUM(NET_PROFIT), 2) AS TOTAL_NET_PROFIT
FROM MERCHANT_PAYMENTS.RAW.PROFIT_DETAIL
GROUP BY 1, 2
HAVING SUM(NET_PROFIT) < 0
ORDER BY TOTAL_NET_PROFIT ASC;

-- Dashboard view preview
SELECT * FROM MERCHANT_PAYMENTS.RAW.PROFIT_DASHBOARD_VIEW
ORDER BY TOTAL_NET_PROFIT DESC
LIMIT 5;

-- ============================================================
-- END OF SNOWFLAKE PIPELINE
-- Live Streamlit Dashboard: Available on request
-- Live Looker Studio (BigQuery): https://datastudio.google.com/s/iMvZsM6IO3U
-- GitHub: github.com/mama-collab/bigquery-snowflake-merchant-payment-pipeline
-- YouTube: youtube.com/@compoundingmind
-- ============================================================
