import sys
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))
from analytics import load_data, validate_data, calculate_kpis

def test_primary_keys_are_unique():
    d = load_data()
    for table, key in [
        ("businesses","business_id"),("products","product_id"),
        ("applications","application_id"),("loans","loan_id"),
        ("loan_installments","installment_id"),("repayments","repayment_id")
    ]:
        assert d[table][key].is_unique

def test_foreign_keys_reconcile():
    d = load_data()
    checks = validate_data(d)
    assert all(v == 0 for v in checks.values())

def test_approval_rate_excludes_pending_and_withdrawn():
    d = load_data()
    apps = d["applications"]
    decided = apps[apps.application_status.isin(["Approved","Rejected"])]
    expected = (apps.application_status=="Approved").sum()/len(decided)
    assert abs(calculate_kpis(d)["approval_rate"]-expected) < 1e-10

def test_installment_principal_reconciles_to_sanctioned_amount():
    d = load_data()
    scheduled = d["loan_installments"].groupby("loan_id").principal_due_inr.sum()
    sanctioned = d["loans"].set_index("loan_id").sanctioned_amount_inr
    diff = (scheduled-sanctioned).abs()
    assert (diff < 2.0).all()

def test_repayments_do_not_exceed_installment_total():
    d = load_data()
    paid = d["repayments"].groupby("installment_id").payment_amount_inr.sum()
    due = d["loan_installments"].set_index("installment_id").total_due_inr
    assert (paid <= due.loc[paid.index] + 1.0).all()

def test_snapshot_has_one_row_per_loan_and_valid_dpd():
    d = load_data()
    s = d["loan_snapshot"]
    assert s.loan_id.is_unique
    assert set(s.loan_id) == set(d["loans"].loan_id)
    assert (s.dpd_days >= 0).all()
    assert (s.outstanding_principal_inr >= -0.01).all()
    assert (s.loc[s.dpd_days>=30,"par30_flag"]).all()
