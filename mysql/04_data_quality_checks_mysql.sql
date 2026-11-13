USE msme_analytics;

-- These orphan queries should return zero rows.
SELECT a.application_id
FROM applications a LEFT JOIN businesses b ON b.business_id=a.business_id
WHERE b.business_id IS NULL;

SELECT a.application_id
FROM applications a LEFT JOIN products p ON p.product_id=a.product_id
WHERE p.product_id IS NULL;

SELECT l.loan_id
FROM loans l LEFT JOIN applications a ON a.application_id=l.application_id
WHERE a.application_id IS NULL OR a.application_status<>'Approved';

SELECT i.installment_id
FROM loan_installments i LEFT JOIN loans l ON l.loan_id=i.loan_id
WHERE l.loan_id IS NULL;

SELECT r.repayment_id
FROM repayments r LEFT JOIN loan_installments i ON i.installment_id=r.installment_id
WHERE i.installment_id IS NULL;

-- Repayment allocations should not exceed the installment amount.
SELECT i.installment_id,i.total_due_inr,
       COALESCE(SUM(r.payment_amount_inr),0) AS paid_amount_inr
FROM loan_installments i
LEFT JOIN repayments r ON r.installment_id=i.installment_id
GROUP BY i.installment_id,i.total_due_inr
HAVING COALESCE(SUM(r.payment_amount_inr),0)>i.total_due_inr+1;

-- Scheduled principal should reconcile to sanctioned amount.
SELECT l.loan_id,l.sanctioned_amount_inr,SUM(i.principal_due_inr) AS scheduled_principal_inr
FROM loans l
JOIN loan_installments i ON i.loan_id=l.loan_id
GROUP BY l.loan_id,l.sanctioned_amount_inr
HAVING ABS(l.sanctioned_amount_inr-SUM(i.principal_due_inr))>2;

-- Snapshot table should contain one row for every disbursed loan.
SELECT
  (SELECT COUNT(*) FROM loans) AS loan_count,
  (SELECT COUNT(*) FROM loan_snapshot) AS snapshot_count;
