USE msme_analytics;

CREATE OR REPLACE VIEW v_loan_snapshot_recalculated AS
WITH repayment_by_installment AS (
    SELECT installment_id,
           SUM(principal_paid_inr) AS principal_paid_inr,
           SUM(interest_paid_inr) AS interest_paid_inr
    FROM repayments
    WHERE payment_date <= '2025-12-31'
    GROUP BY installment_id
),
installment_balances AS (
    SELECT i.loan_id, i.due_date,
           GREATEST(i.principal_due_inr-COALESCE(r.principal_paid_inr,0),0) AS principal_unpaid_inr,
           GREATEST(i.interest_due_inr-COALESCE(r.interest_paid_inr,0),0) AS interest_unpaid_inr
    FROM loan_installments i
    LEFT JOIN repayment_by_installment r ON r.installment_id=i.installment_id
),
loan_rollup AS (
    SELECT loan_id,
           SUM(principal_unpaid_inr) AS outstanding_principal_inr,
           SUM(CASE WHEN due_date<='2025-12-31' THEN principal_unpaid_inr ELSE 0 END) AS overdue_principal_inr,
           SUM(CASE WHEN due_date<='2025-12-31' THEN principal_unpaid_inr+interest_unpaid_inr ELSE 0 END) AS overdue_total_inr,
           MIN(CASE WHEN due_date<='2025-12-31' AND principal_unpaid_inr+interest_unpaid_inr>1 THEN due_date ELSE NULL END) AS oldest_unpaid_due_date
    FROM installment_balances
    GROUP BY loan_id
),
dpd_calc AS (
    SELECT l.loan_id,l.business_id,l.product_id,l.disbursement_date,l.sanctioned_amount_inr,
           COALESCE(r.outstanding_principal_inr,0) AS outstanding_principal_inr,
           COALESCE(r.overdue_principal_inr,0) AS overdue_principal_inr,
           COALESCE(r.overdue_total_inr,0) AS overdue_total_inr,
           CASE WHEN r.oldest_unpaid_due_date IS NULL THEN 0
                ELSE GREATEST(0,DATEDIFF('2025-12-31',r.oldest_unpaid_due_date)) END AS dpd_days
    FROM loans l
    LEFT JOIN loan_rollup r ON r.loan_id=l.loan_id
)
SELECT *,
       CASE WHEN dpd_days=0 THEN 'Current'
            WHEN dpd_days<=30 THEN '1-30'
            WHEN dpd_days<=60 THEN '31-60'
            WHEN dpd_days<=90 THEN '61-90'
            ELSE '90+' END AS dpd_bucket,
       (dpd_days>=30) AS par30_flag,
       (dpd_days>=90) AS par90_flag,
       CASE WHEN outstanding_principal_inr<=1 THEN 'Closed' ELSE 'Active' END AS snapshot_loan_status,
       DATE('2025-12-31') AS snapshot_date
FROM dpd_calc;
