from pathlib import Path
import sys
import pandas as pd
import streamlit as st
import plotly.express as px

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "src"))
from analytics import load_data, calculate_kpis, validate_data

st.set_page_config(page_title="MSME Lending Analytics", page_icon="📊", layout="wide")
st.title("MSME Lending Analytics")
st.caption("Synthetic Indian MSME lending portfolio | Snapshot date: 31 Dec 2025 | INR")

@st.cache_data
def get_data():
    return load_data()

data = get_data()
businesses, products = data["businesses"], data["products"]
applications, loans = data["applications"], data["loans"]
snap, installments, repayments = data["loan_snapshot"], data["loan_installments"], data["repayments"]

apps = applications.merge(businesses, on="business_id", how="left").merge(products[["product_id","product_name"]], on="product_id", how="left")
loan_view = loans.merge(businesses, on="business_id", how="left").merge(products[["product_id","product_name"]], on="product_id", how="left").merge(snap, on=["loan_id","business_id","product_id","disbursement_date","sanctioned_amount_inr"], how="left", suffixes=("","_snapshot"))

st.sidebar.header("Dashboard filters")
min_date = pd.to_datetime(apps["application_date"]).min().date()
max_date = pd.to_datetime(apps["application_date"]).max().date()
date_range = st.sidebar.date_input("Application date range", value=(min_date,max_date), min_value=min_date, max_value=max_date)
min_disb_date = pd.to_datetime(loan_view["disbursement_date"]).min().date()
max_disb_date = pd.to_datetime(loan_view["disbursement_date"]).max().date()
disb_date_range = st.sidebar.date_input("Disbursement date range", value=(min_disb_date,max_disb_date), min_value=min_disb_date, max_value=max_disb_date)
states = ["All"] + sorted(businesses["state"].dropna().unique().tolist())
state_filter = st.sidebar.selectbox("State", states)
sizes = ["All"] + sorted(businesses["business_size"].dropna().unique().tolist())
size_filter = st.sidebar.selectbox("Business size", sizes)
product_names = ["All"] + sorted(products["product_name"].dropna().unique().tolist())
product_filter = st.sidebar.selectbox("Loan product", product_names)

if isinstance(date_range, tuple) and len(date_range)==2:
    start_dt, end_dt = pd.Timestamp(date_range[0]), pd.Timestamp(date_range[1])
else:
    start_dt, end_dt = pd.Timestamp(min_date), pd.Timestamp(max_date)
if isinstance(disb_date_range, tuple) and len(disb_date_range)==2:
    loan_start_dt, loan_end_dt = pd.Timestamp(disb_date_range[0]), pd.Timestamp(disb_date_range[1])
else:
    loan_start_dt, loan_end_dt = pd.Timestamp(min_disb_date), pd.Timestamp(max_disb_date)

apps["application_date"] = pd.to_datetime(apps["application_date"])
loan_view["disbursement_date"] = pd.to_datetime(loan_view["disbursement_date"])
apps_f = apps[(apps.application_date>=start_dt)&(apps.application_date<=end_dt)]
loans_f = loan_view[(loan_view.disbursement_date>=loan_start_dt)&(loan_view.disbursement_date<=loan_end_dt)]
if state_filter != "All":
    apps_f = apps_f[apps_f.state==state_filter]
    loans_f = loans_f[loans_f.state==state_filter]
if size_filter != "All":
    apps_f = apps_f[apps_f.business_size==size_filter]
    loans_f = loans_f[loans_f.business_size==size_filter]
if product_filter != "All":
    apps_f = apps_f[apps_f.product_name==product_filter]
    loans_f = loans_f[loans_f.product_name==product_filter]

page = st.sidebar.radio("Navigate", ["Executive Overview","Application Funnel","Portfolio & Risk","Collections","Data Quality"])

def inr(value):
    return f"₹{value/10000000:,.2f} Cr" if abs(value)>=10000000 else f"₹{value/100000:,.2f} L"

# Snapshot risk is calculated across all loans at 31-Dec-2025; filters slice the selected disbursement cohorts.
snap_f = loans_f
total_outstanding = float(snap_f["outstanding_principal_inr"].sum()) if len(snap_f) else 0
par30_amt = float(snap_f.loc[snap_f.dpd_days>=30,"outstanding_principal_inr"].sum()) if len(snap_f) else 0
par90_amt = float(snap_f.loc[snap_f.dpd_days>=90,"outstanding_principal_inr"].sum()) if len(snap_f) else 0
decided_f = apps_f[apps_f.application_status.isin(["Approved","Rejected"])]
approval_rate = (apps_f.application_status.eq("Approved").sum()/len(decided_f)) if len(decided_f) else 0

if page == "Executive Overview":
    st.subheader("Portfolio at a glance")
    c1,c2,c3,c4 = st.columns(4)
    c1.metric("Applications", f"{apps_f.application_id.nunique():,}")
    c2.metric("Approval rate", f"{approval_rate:.1%}")
    c3.metric("Disbursed amount", inr(loans_f.sanctioned_amount_inr.sum() if len(loans_f) else 0))
    c4.metric("Outstanding principal", inr(total_outstanding))
    c5,c6,c7,c8 = st.columns(4)
    c5.metric("Disbursed loans", f"{loans_f.loan_id.nunique():,}")
    c6.metric("Avg decision TAT", f"{decided_f.decision_tat_days.mean():.1f} days" if len(decided_f) else "N/A")
    c7.metric("PAR 30+", f"{par30_amt/total_outstanding:.1%}" if total_outstanding else "N/A")
    c8.metric("PAR 90+", f"{par90_amt/total_outstanding:.1%}" if total_outstanding else "N/A")
    left,right = st.columns(2)
    with left:
        trend = loans_f.assign(month=loans_f.disbursement_date.dt.to_period("M").astype(str)).groupby("month",as_index=False).agg(disbursed_amount_inr=("sanctioned_amount_inr","sum"))
        st.plotly_chart(px.line(trend,x="month",y="disbursed_amount_inr",markers=True,title="Monthly disbursement amount"),use_container_width=True)
    with right:
        status = apps_f.groupby("application_status",as_index=False).size()
        st.plotly_chart(px.pie(status,names="application_status",values="size",hole=.45,title="Application status mix"),use_container_width=True)
    st.download_button("Download filtered applications", apps_f.to_csv(index=False).encode("utf-8"), "filtered_applications.csv", "text/csv")

elif page == "Application Funnel":
    st.subheader("Application funnel and decision turnaround")
    left,right = st.columns(2)
    with left:
        status = apps_f.groupby("application_status",as_index=False).size()
        st.plotly_chart(px.bar(status,x="application_status",y="size",text="size",title="Applications by status"),use_container_width=True)
    with right:
        tat = apps_f[apps_f.application_status.isin(["Approved","Rejected"])].groupby("application_status",as_index=False).decision_tat_days.mean()
        st.plotly_chart(px.bar(tat,x="application_status",y="decision_tat_days",text_auto=".1f",title="Average decision TAT (days)"),use_container_width=True)
    product_funnel = apps_f.groupby(["product_name","application_status"],as_index=False).size()
    st.plotly_chart(px.bar(product_funnel,x="product_name",y="size",color="application_status",barmode="group",title="Application status by product"),use_container_width=True)
    st.dataframe(apps_f[["application_id","business_name","state","business_size","product_name","application_date","requested_amount_inr","application_status","decision_tat_days","disbursed_flag"]],use_container_width=True)

elif page == "Portfolio & Risk":
    st.subheader("Disbursement portfolio and credit risk")
    c1,c2,c3 = st.columns(3)
    c1.metric("Outstanding principal",inr(total_outstanding))
    c2.metric("PAR 30+",f"{par30_amt/total_outstanding:.1%}" if total_outstanding else "N/A")
    c3.metric("PAR 90+",f"{par90_amt/total_outstanding:.1%}" if total_outstanding else "N/A")
    left,right = st.columns(2)
    with left:
        by_product = loans_f.groupby("product_name",as_index=False).outstanding_principal_inr.sum()
        st.plotly_chart(px.bar(by_product,x="product_name",y="outstanding_principal_inr",title="Outstanding principal by product"),use_container_width=True)
    with right:
        buckets = loans_f.groupby("dpd_bucket",as_index=False).agg(loan_count=("loan_id","nunique"),outstanding=("outstanding_principal_inr","sum"))
        order=["Current","1-30","31-60","61-90","90+"]
        buckets["dpd_bucket"] = pd.Categorical(buckets.dpd_bucket,categories=order,ordered=True)
        buckets=buckets.sort_values("dpd_bucket")
        st.plotly_chart(px.bar(buckets,x="dpd_bucket",y="loan_count",title="Loan count by DPD bucket"),use_container_width=True)
    risk_table = loans_f[["loan_id","business_name","state","product_name","risk_band","sanctioned_amount_inr","outstanding_principal_inr","dpd_days","dpd_bucket"]].sort_values("dpd_days",ascending=False)
    st.dataframe(risk_table,use_container_width=True)
    st.download_button("Download filtered loan risk snapshot",risk_table.to_csv(index=False).encode("utf-8"),"loan_risk_snapshot.csv","text/csv")

elif page == "Collections":
    st.subheader("Repayment and collections performance")
    loan_ids = set(loans_f.loan_id)
    inst_f = installments[installments.loan_id.isin(loan_ids)].copy()
    inst_f["due_date"] = pd.to_datetime(inst_f.due_date)
    inst_due = inst_f[inst_f.due_date <= pd.Timestamp("2025-12-31")]
    inst_ids = set(inst_f.installment_id)
    rep_f = repayments[repayments.installment_id.isin(inst_ids)].copy()
    rep_f["payment_date"] = pd.to_datetime(rep_f.payment_date)
    due_amount = float(inst_due.total_due_inr.sum())
    paid_amount = float(rep_f.payment_amount_inr.sum())
    efficiency = paid_amount/due_amount if due_amount else 0
    c1,c2,c3 = st.columns(3)
    c1.metric("Scheduled dues by snapshot",inr(due_amount))
    c2.metric("Collections received",inr(paid_amount))
    c3.metric("Collection efficiency",f"{efficiency:.1%}")
    monthly = rep_f.assign(month=rep_f.payment_date.dt.to_period("M").astype(str)).groupby("month",as_index=False).payment_amount_inr.sum()
    st.plotly_chart(px.bar(monthly,x="month",y="payment_amount_inr",title="Monthly collections received"),use_container_width=True)
    st.caption("Collection efficiency = repayments received by 31-Dec-2025 divided by scheduled installment amounts due by 31-Dec-2025. This is a synthetic portfolio metric, not a regulatory collection measure.")
    st.dataframe(rep_f,use_container_width=True)

else:
    st.subheader("Data quality checks")
    checks = validate_data(data)
    dq = pd.DataFrame([{"check":k,"exceptions":v,"status":"PASS" if v==0 else "REVIEW"} for k,v in checks.items()])
    st.dataframe(dq,use_container_width=True)
    st.write("Dataset row counts")
    counts = pd.DataFrame([{"table":k,"rows":len(v)} for k,v in data.items()])
    st.dataframe(counts,use_container_width=True)
    st.caption("All records are synthetic. No real borrower or lender information is included.")

st.divider()
st.caption("Portfolio snapshot: 31-Dec-2025 | All amounts in INR | Synthetic educational case study. DPD is an analytical delinquency measure, not a regulatory NPA classification.")
