from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
AS_OF_DATE = pd.Timestamp("2025-12-31")

def load_data():
    names = ["businesses","products","applications","application_events","loans",
             "loan_installments","repayments","loan_snapshot"]
    data = {n: pd.read_csv(DATA / f"{n}.csv") for n in names}
    for table, cols in {
        "businesses":["onboarding_date"],
        "applications":["application_date","decision_date"],
        "application_events":["event_timestamp"],
        "loans":["disbursement_date"],
        "loan_installments":["due_date"],
        "repayments":["payment_date"],
        "loan_snapshot":["disbursement_date","snapshot_date"],
    }.items():
        for col in cols:
            data[table][col] = pd.to_datetime(data[table][col], errors="coerce")
    return data

def calculate_kpis(data):
    apps, loans, snap = data["applications"], data["loans"], data["loan_snapshot"]
    decided = apps[apps["application_status"].isin(["Approved","Rejected"])]
    approved = int((apps["application_status"]=="Approved").sum())
    rejected = int((apps["application_status"]=="Rejected").sum())
    outstanding = float(snap["outstanding_principal_inr"].sum())
    par30_amt = float(snap.loc[snap["dpd_days"]>=30,"outstanding_principal_inr"].sum())
    par90_amt = float(snap.loc[snap["dpd_days"]>=90,"outstanding_principal_inr"].sum())
    due = data["loan_installments"]
    due = due[pd.to_datetime(due["due_date"]) <= AS_OF_DATE]
    collected = float(data["repayments"]["payment_amount_inr"].sum())
    scheduled = float(due["total_due_inr"].sum())
    return {
        "businesses": int(data["businesses"]["business_id"].nunique()),
        "applications": int(apps["application_id"].nunique()),
        "approval_rate": approved/(approved+rejected) if approved+rejected else 0,
        "avg_decision_tat_days": float(decided["decision_tat_days"].mean()) if len(decided) else 0,
        "disbursed_loans": int(loans["loan_id"].nunique()),
        "disbursed_amount_inr": float(loans["sanctioned_amount_inr"].sum()),
        "outstanding_principal_inr": outstanding,
        "par30": par30_amt/outstanding if outstanding else 0,
        "par90": par90_amt/outstanding if outstanding else 0,
        "collection_efficiency": collected/scheduled if scheduled else 0,
    }

def validate_data(data):
    checks = {}
    checks["applications_without_business"] = int((~data["applications"]["business_id"].isin(data["businesses"]["business_id"])).sum())
    checks["applications_without_product"] = int((~data["applications"]["product_id"].isin(data["products"]["product_id"])).sum())
    checks["loans_without_application"] = int((~data["loans"]["application_id"].isin(data["applications"]["application_id"])).sum())
    checks["installments_without_loan"] = int((~data["loan_installments"]["loan_id"].isin(data["loans"]["loan_id"])).sum())
    checks["repayments_without_installment"] = int((~data["repayments"]["installment_id"].isin(data["loan_installments"]["installment_id"])).sum())
    checks["duplicate_business_ids"] = int(data["businesses"]["business_id"].duplicated().sum())
    checks["duplicate_application_ids"] = int(data["applications"]["application_id"].duplicated().sum())
    checks["duplicate_loan_ids"] = int(data["loans"]["loan_id"].duplicated().sum())
    return checks
