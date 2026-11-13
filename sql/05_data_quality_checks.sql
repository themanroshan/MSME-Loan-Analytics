SET search_path TO msme;

-- All queries below should return zero rows / zero counts for clean referential integrity.
SELECT a.application_id FROM applications a
LEFT JOIN businesses b USING (business_id) WHERE b.business_id IS NULL;

SELECT a.application_id FROM applications a
LEFT JOIN products p USING (product_id) WHERE p.product_id IS NULL;

SELECT l.loan_id FROM loans l
LEFT JOIN applications a USING (application_id)
WHERE a.application_id IS NULL OR a.application_status <> 'Approved';

SELECT i.installment_id FROM loan_installments i
LEFT JOIN loans l USING (loan_id) WHERE l.loan_id IS NULL;

SELECT r.repayment_id FROM repayments r
LEFT JOIN loan_installments i USING (installment_id) WHERE i.installment_id IS NULL;

-- Payment allocations must not exceed the installment amount.
SELECT i.installment_id,
       i.total_due_inr,
       COALESCE(SUM(r.payment_amount_inr),0) AS paid_amount_inr
FROM loan_installments i
LEFT JOIN repayments r USING (installment_id)
GROUP BY i.installment_id,i.total_due_inr
HAVING COALESCE(SUM(r.payment_amount_inr),0) > i.total_due_inr + 1;

-- Scheduled principal across a loan should reconcile to the sanctioned amount.
SELECT l.loan_id, l.sanctioned_amount_inr,
       SUM(i.principal_due_inr) AS scheduled_principal_inr
FROM loans l JOIN loan_installments i USING (loan_id)
GROUP BY l.loan_id,l.sanctioned_amount_inr
HAVING ABS(l.sanctioned_amount_inr-SUM(i.principal_due_inr)) > 2;
