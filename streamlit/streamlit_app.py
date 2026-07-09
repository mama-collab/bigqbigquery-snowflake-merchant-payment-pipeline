# ============================================================
# MERCHANT PAYMENT PROFIT INTELLIGENCE DASHBOARD
# Platform: Snowflake Streamlit
# Author: M Priyadarsini | Compounding Mind
# Domain: Financial Services — Payment Processing
# ============================================================

import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session

# Page config
st.set_page_config(
    page_title="Merchant Payment Profit Intelligence",
    page_icon="💳",
    layout="wide"
)

# Get Snowflake session
session = get_active_session()

# ── Load data ────────────────────────────────────────────────
@st.cache_data
def load_data():
    return session.sql("""
        SELECT * FROM MERCHANT_PAYMENTS.RAW.PROFIT_DASHBOARD_VIEW
    """).to_pandas()

df = load_data()

# ── Header ───────────────────────────────────────────────────
st.title("💳 Merchant Payment Profit Intelligence")
st.markdown("*Built with Snowflake · By Priya @ Compounding Mind*")
st.divider()

# ── Sidebar filters ──────────────────────────────────────────
st.sidebar.title("🔍 Filters")

merchants = ["All"] + sorted(df["MERCHANT_NAME"].unique().tolist())
selected_merchant = st.sidebar.selectbox("Merchant", merchants)

categories = ["All", "MSF", "AUTH"]
selected_category = st.sidebar.selectbox("Fee Category", categories)

statuses = ["All", "Profitable", "Low Margin", "Loss"]
selected_status = st.sidebar.selectbox("Profit Status", statuses)

# Apply filters
filtered_df = df.copy()
if selected_merchant != "All":
    filtered_df = filtered_df[
        filtered_df["MERCHANT_NAME"] == selected_merchant]
if selected_category != "All":
    filtered_df = filtered_df[
        filtered_df["FEE_CATEGORY"] == selected_category]
if selected_status != "All":
    filtered_df = filtered_df[
        filtered_df["PROFIT_STATUS"] == selected_status]

# ── KPI metrics ──────────────────────────────────────────────
st.subheader("📊 Overview")
col1, col2, col3, col4, col5 = st.columns(5)

total_merchants = filtered_df["MERCHANT_NAME"].nunique()
total_income    = filtered_df["TOTAL_INCOME"].sum()
total_expense   = filtered_df["TOTAL_EXPENSE"].sum()
total_profit    = filtered_df["TOTAL_NET_PROFIT"].sum()
loss_count      = filtered_df[filtered_df["PROFIT_STATUS"] == "Loss"][
                    "MERCHANT_NAME"].nunique()

with col1:
    st.metric("Total Merchants", total_merchants)
with col2:
    st.metric("Total Income",  f"${total_income:,.0f}")
with col3:
    st.metric("Total Expense", f"${total_expense:,.0f}")
with col4:
    st.metric("Net Profit",    f"${total_profit:,.0f}")
with col5:
    st.metric("Loss Merchants", loss_count,
              delta=f"{loss_count} need attention",
              delta_color="inverse")

st.divider()

# ── Section 1: Profit by Merchant ────────────────────────────
st.subheader("💰 Profit by Merchant")

merchant_summary = (
    filtered_df.groupby("MERCHANT_NAME")
    .agg(
        TOTAL_INCOME    =("TOTAL_INCOME",     "sum"),
        TOTAL_EXPENSE   =("TOTAL_EXPENSE",    "sum"),
        TOTAL_NET_PROFIT=("TOTAL_NET_PROFIT", "sum")
    )
    .reset_index()
    .sort_values("TOTAL_NET_PROFIT", ascending=False)
)

col1, col2 = st.columns(2)

with col1:
    st.markdown("**Net Profit by Merchant**")
    st.bar_chart(
        merchant_summary.set_index("MERCHANT_NAME")["TOTAL_NET_PROFIT"]
    )

with col2:
    st.markdown("**Income vs Expense by Merchant**")
    st.bar_chart(
        merchant_summary.set_index("MERCHANT_NAME")[
            ["TOTAL_INCOME", "TOTAL_EXPENSE"]
        ]
    )

st.divider()

# ── Section 2: MSF vs Auth Breakdown ─────────────────────────
st.subheader("📈 MSF vs Authorization Fee Breakdown")

fee_summary = (
    df.groupby("FEE_CATEGORY")
    .agg(
        MERCHANT_COUNT  =("MERCHANT_NAME",    "nunique"),
        TOTAL_INCOME    =("TOTAL_INCOME",     "sum"),
        TOTAL_EXPENSE   =("TOTAL_EXPENSE",    "sum"),
        TOTAL_NET_PROFIT=("TOTAL_NET_PROFIT", "sum")
    )
    .reset_index()
)

col1, col2, col3 = st.columns(3)

with col1:
    st.markdown("**Income by Fee Type**")
    st.bar_chart(
        fee_summary.set_index("FEE_CATEGORY")["TOTAL_INCOME"]
    )

with col2:
    st.markdown("**Expense by Fee Type**")
    st.bar_chart(
        fee_summary.set_index("FEE_CATEGORY")["TOTAL_EXPENSE"]
    )

with col3:
    st.markdown("**Net Profit by Fee Type**")
    st.bar_chart(
        fee_summary.set_index("FEE_CATEGORY")["TOTAL_NET_PROFIT"]
    )

# Fee category metrics
col1, col2 = st.columns(2)
for i, row in fee_summary.iterrows():
    col = col1 if i == 0 else col2
    with col:
        st.info(
            f"**{row['FEE_CATEGORY']}** — "
            f"Income: ${row['TOTAL_INCOME']:,.2f} | "
            f"Expense: ${row['TOTAL_EXPENSE']:,.2f} | "
            f"Net: ${row['TOTAL_NET_PROFIT']:,.2f}"
        )

st.divider()

# ── Section 3: Loss-making Merchants Alert ───────────────────
st.subheader("🚨 Loss-Making Merchants — Needs Attention")

loss_merchants = (
    df.groupby(["MERCHANT_NAME", "ACCOUNT_NUMBER"])
    .agg(
        TOTAL_INCOME    =("TOTAL_INCOME",     "sum"),
        TOTAL_EXPENSE   =("TOTAL_EXPENSE",    "sum"),
        TOTAL_NET_PROFIT=("TOTAL_NET_PROFIT", "sum"),
        TOTAL_TRANS     =("TOTAL_TRANSACTIONS","sum")
    )
    .reset_index()
)
loss_merchants = loss_merchants[
    loss_merchants["TOTAL_NET_PROFIT"] < 0
].sort_values("TOTAL_NET_PROFIT")

if len(loss_merchants) > 0:
    st.error(
        f"⚠️ {len(loss_merchants)} merchant(s) are currently "
        f"loss-making — immediate review recommended"
    )
    for _, row in loss_merchants.iterrows():
        with st.expander(
            f"🔴 {row['MERCHANT_NAME']} — "
            f"Net Loss: ${row['TOTAL_NET_PROFIT']:,.2f}"
        ):
            c1, c2, c3, c4 = st.columns(4)
            c1.metric("Account",      row['ACCOUNT_NUMBER'])
            c2.metric("Total Income", f"${row['TOTAL_INCOME']:,.2f}")
            c3.metric("Total Expense",f"${row['TOTAL_EXPENSE']:,.2f}")
            c4.metric("Transactions", int(row['TOTAL_TRANS']))
else:
    st.success("✅ No loss-making merchants for selected filters!")

st.divider()

# ── Section 4: Full Data Table ───────────────────────────────
st.subheader("🔍 Full Profit Detail")
st.dataframe(
    filtered_df[[
        "MERCHANT_NAME",
        "FEE_CATEGORY",
        "FEE_ITEM",
        "TOTAL_TRANSACTIONS",
        "TOTAL_INCOME",
        "TOTAL_EXPENSE",
        "TOTAL_NET_PROFIT",
        "PROFIT_STATUS"
    ]].sort_values("TOTAL_NET_PROFIT", ascending=False),
    use_container_width=True,
    hide_index=True
)

st.divider()

# ── Footer ───────────────────────────────────────────────────
st.markdown("""
*Built with 💳 Snowflake · By Priya @ Compounding Mind*
*youtube.com/@compoundingmind*
""")
