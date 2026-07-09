# 💳 Merchant Payment Profit Intelligence Pipeline
### BigQuery · Snowflake · Looker Studio or Data Studio · Streamlit  · Financial Services

![BigQuery](https://img.shields.io/badge/BigQuery-Google-4285F4?logo=google-cloud)
![Snowflake](https://img.shields.io/badge/Snowflake-CoCo-29B5E8?logo=snowflake)
![Streamlit](https://img.shields.io/badge/Dashboard-Streamlit-FF4B4B)
![Looker](https://img.shields.io/badge/Dashboard-Looker%20Studio-4285F4)
![Status](https://img.shields.io/badge/Status-Live-brightgreen)

> *Production-grade merchant payment profit pipeline built on  
> both BigQuery and Snowflake — same logic, two platforms.*  
> *M Priyadarsini | Compounding Mind*

---

## 🎯 The Problem

Payment processing companies manage thousands of merchant
accounts — each with complex fee structures across Monthly
Service Fees (MSF) and Authorization fees. Calculating
merchant-level profit manually is error-prone, slow, and
not scalable.

---

## ✅ The Solution

A multi-step SQL pipeline calculating merchant-level profit:

✅ MSF Income — Monthly service fee revenue per merchant
✅ MSF Expense — Cost to service each merchant by schedule tier
✅ Authorization Fee Income — Per-transaction fee revenue
✅ Net Profit — Income minus expense per merchant
✅ Live Dashboard — Looker Studio + Snowflake Streamlit

---

## 🏗 Pipeline Architecture

Raw Data (Merchants + Fee History + Pricing Model)
↓
Pricing View (deduped + schedule joined)
↓
┌─────────────────┬──────────────────┬──────────────────┐
│  MSF Income     │  MSF Expense     │  Auth Income     │
│  (fee revenue)  │  (cost by tier)  │  (per txn fee)   │
└─────────────────┴──────────────────┴──────────────────┘
↓
Profit Detail Table (permanent)
↓
Dashboard View
↓
Live Dashboard (Income · Expense · Net Profit · Status)

---

## 📊 Sample Output

### Pipeline Summary
| Fee Category | Merchants | Total Income | Total Expense | Net Profit |
|---|---|---|---|---|
| AUTH | 25 | $2,824.00 | $0.00 | $2,824.00 |
| MSF | 25 | $1,259.75 | $288.50 | $971.25 |
| **Total** | **25** | **$4,083.75** | **$288.50** | **$3,795.25** |

### Top Merchants by Profit
| Merchant | Income | Expense | Net Profit |
|---|---|---|---|
| Harbour View Hotels | $459.99 | $18.00 | $441.99 |
| Heartland Agriculture | $409.99 | $18.00 | $391.99 |
| Great Lakes Pharma | $379.99 | $9.50 | $370.49 |

---

## 🔑 Key Technical Decisions

- **Permanent tables** — not temp tables — survive session end
- **UNION ALL pattern** — single INSERT for all fee categories
- **Pricing VIEW** — permanent, reusable across pipeline steps
- **VARCHAR(10)** for fee_category — accommodates 'AUTH' + 'MSF'
- **Cross-platform** — identical logic in BigQuery + Snowflake

---

## 🔄 Cross-Platform Syntax Reference

| Pattern | BigQuery | Snowflake |
|---|---|---|
| Safe casting | `SAFE_CAST` | `TRY_CAST` |
| Month end | `LAST_DAY(d, MONTH)` | `LAST_DAY(d)` |
| Conditional | `IF()` | `IFF()` |
| Null handling | `IFNULL` | `COALESCE` |
| Numeric literal | `CAST(0 AS NUMERIC)` | `0::NUMBER(18,2)` |
| Date literal | `DATE '2026-05-31'` | `'2026-05-31'` |

---

## 📁 Repository Structure

snowflake-merchant-payment-pipeline/
│
├── sql/
│   ├── 01_snowflake_merchant_payment_pipeline.sql
│   └── 02_bigquery_merchant_payment_pipeline.sql
│
├── streamlit/
│   └── streamlit_app.py
│
└── README.md

---

## 🚀 How to Run

### Snowflake
```sql
-- Run top to bottom in Snowflake CoCo SQL editor
-- Creates all tables, loads 25 merchants, runs pipeline
-- Then create Streamlit app using streamlit/streamlit_app.py
```

### BigQuery
```sql
-- 1. Create dataset: merchant_payments
-- 2. Run top to bottom in BigQuery Studio SQL editor
-- 3. Connect to Looker Studio for live dashboard
```

---

## 📊 Live Dashboards

- 📊 **Looker Studio (BigQuery):** https://datastudio.google.com/s/iMvZsM6IO3U
- ❄️ **Streamlit (Snowflake):** Available on request

---

## 🔗 Related Projects

| Project | Platform | Domain |
|---|---|---|
| [Customer Feedback Intelligence](../snowflake-cortex-feedback-pipeline) | Snowflake Cortex | AI/Retail |
| Merchant Payment Pipeline (this) | BigQuery + Snowflake | Financial Services |
| [Insurance Fraud Detection](../databricks-insurance-fraud-detection) | Databricks | Insurance |

---

## 💼 Work With Me

- 📅 [Book a free 15-min call](https://calendly.com/mama-priyadarsini/15-minute-business-strategy-call)
- 🔗 [LinkedIn](https://www.linkedin.com/in/m-priyadarsini-00427141))
- 🎥 [YouTube — Compounding Mind](https://youtube.com/@compoundingmind)

*Remote consulting · Canada + US time zones*

---

*© 2026 M Priyadarsini*
