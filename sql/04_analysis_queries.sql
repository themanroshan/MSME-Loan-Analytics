SET search_path TO msme;

-- 1. Executive portfolio summary
SELECT COUNT(*) AS disbursed_loans,
       SUM(sanctioned_amount_inr) AS total_disbursed_inr,
       AVG(sanctioned_amount_inr) AS average_ticket_size_inr,
       AVG(interest_rate_pa_pct) AS average_interest_rate_pct
FROM loans;

-- 2. Application funnel by status
SELECT application_status, COUNT(*) AS applications,
       SUM(requested_amount_inr) AS requested_amount_inr
FROM applications
GROUP BY application_status
ORDER BY applications DESC;

-- 3. Approval rate: pending and withdrawn are excluded from the denominator
SELECT
  COUNT(*) FILTER (WHERE application_status='Approved') AS approved,
  COUNT(*) FILTER (WHERE application_status='Rejected') AS rejected,
  ROUND(
    COUNT(*) FILTER (WHERE application_status='Approved')::NUMERIC /
    NULLIF(COUNT(*) FILTER (WHERE application_status IN ('Approved','Rejected')),0), 4
  ) AS approval_rate
FROM applications;

-- 4. Average decision turnaround time for decided applications
SELECT application_status, ROUND(AVG(decision_tat_days),2) AS avg_decision_tat_days
FROM applications
WHERE application_status IN ('Approved','Rejected')
GROUP BY application_status;

-- 5. Application-to-disbursement conversion by product
SELECT p.product_name,
       COUNT(DISTINCT a.application_id) FILTER (WHERE a.application_status='Approved') AS approved_apps,
       COUNT(DISTINCT l.loan_id) AS disbursed_loans,
       ROUND(COUNT(DISTINCT l.loan_id)::NUMERIC /
         NULLIF(COUNT(DISTINCT a.application_id) FILTER (WHERE a.application_status='Approved'),0),4) AS conversion_rate
FROM products p
LEFT JOIN applications a ON a.product_id=p.product_id
LEFT JOIN loans l ON l.application_id=a.application_id
GROUP BY p.product_name
ORDER BY disbursed_loans DESC;

-- 6. Monthly disbursement trend
SELECT DATE_TRUNC('month', disbursement_date)::DATE AS disbursement_month,
       COUNT(*) AS loans_disbursed,
       SUM(sanctioned_amount_inr) AS disbursed_amount_inr
FROM loans
GROUP BY 1 ORDER BY 1;

-- 7. Portfolio outstanding and PAR metrics (snapshot date: 2025-12-31)
SELECT SUM(outstanding_principal_inr) AS outstanding_principal_inr,
       SUM(outstanding_principal_inr) FILTER (WHERE dpd_days >= 30) AS par30_amount_inr,
       ROUND(SUM(outstanding_principal_inr) FILTER (WHERE dpd_days >= 30) /
         NULLIF(SUM(outstanding_principal_inr),0),4) AS par30_ratio,
       SUM(outstanding_principal_inr) FILTER (WHERE dpd_days >= 90) AS par90_amount_inr,
       ROUND(SUM(outstanding_principal_inr) FILTER (WHERE dpd_days >= 90) /
         NULLIF(SUM(outstanding_principal_inr),0),4) AS par90_ratio
FROM v_loan_snapshot;

-- 8. DPD bucket distribution
SELECT dpd_bucket, COUNT(*) AS loan_count,
       SUM(outstanding_principal_inr) AS outstanding_principal_inr
FROM v_loan_snapshot
GROUP BY dpd_bucket
ORDER BY CASE dpd_bucket WHEN 'Current' THEN 1 WHEN '1-30' THEN 2
         WHEN '31-60' THEN 3 WHEN '61-90' THEN 4 ELSE 5 END;

-- 9. PAR30 by product
SELECT p.product_name,
       SUM(s.outstanding_principal_inr) AS outstanding_principal_inr,
       SUM(s.outstanding_principal_inr) FILTER (WHERE s.dpd_days >= 30) AS par30_amount_inr,
       ROUND(SUM(s.outstanding_principal_inr) FILTER (WHERE s.dpd_days >= 30) /
         NULLIF(SUM(s.outstanding_principal_inr),0),4) AS par30_ratio
FROM v_loan_snapshot s
JOIN products p USING (product_id)
GROUP BY p.product_name
ORDER BY par30_ratio DESC NULLS LAST;

-- 10. Portfolio concentration by state
SELECT b.state, COUNT(DISTINCT l.loan_id) AS loans,
       SUM(l.sanctioned_amount_inr) AS disbursed_amount_inr,
       SUM(s.outstanding_principal_inr) AS outstanding_principal_inr
FROM loans l
JOIN businesses b USING (business_id)
JOIN v_loan_snapshot s USING (loan_id)
GROUP BY b.state ORDER BY outstanding_principal_inr DESC;

-- 11. Portfolio by business size
SELECT b.business_size, COUNT(DISTINCT l.loan_id) AS loans,
       SUM(l.sanctioned_amount_inr) AS disbursed_amount_inr,
       SUM(s.outstanding_principal_inr) AS outstanding_principal_inr,
       ROUND(SUM(s.outstanding_principal_inr) FILTER (WHERE s.dpd_days>=30) /
         NULLIF(SUM(s.outstanding_principal_inr),0),4) AS par30_ratio
FROM loans l
JOIN businesses b USING (business_id)
JOIN v_loan_snapshot s USING (loan_id)
GROUP BY b.business_size ORDER BY loans DESC;

-- 12. Collection efficiency on installments due by snapshot date
WITH due AS (
  SELECT SUM(total_due_inr) AS due_amount
  FROM loan_installments WHERE due_date <= DATE '2025-12-31'
), paid AS (
  SELECT SUM(payment_amount_inr) AS paid_amount
  FROM repayments WHERE payment_date <= DATE '2025-12-31'
)
SELECT due_amount, paid_amount,
       ROUND(paid_amount/NULLIF(due_amount,0),4) AS collection_efficiency
FROM due CROSS JOIN paid;

-- 13. Top 10 businesses by outstanding principal
SELECT b.business_id, b.business_name, b.industry, b.state,
       SUM(s.outstanding_principal_inr) AS outstanding_principal_inr
FROM v_loan_snapshot s
JOIN businesses b USING (business_id)
GROUP BY b.business_id,b.business_name,b.industry,b.state
ORDER BY outstanding_principal_inr DESC LIMIT 10;

-- 14. Repeat borrowers
SELECT business_id, COUNT(*) AS loan_count,
       SUM(sanctioned_amount_inr) AS total_disbursed_inr
FROM loans
GROUP BY business_id
HAVING COUNT(*) > 1
ORDER BY loan_count DESC, total_disbursed_inr DESC;

-- 15. Quarterly disbursement cohort and PAR30
SELECT DATE_TRUNC('quarter', l.disbursement_date)::DATE AS disbursement_quarter,
       COUNT(*) AS loans,
       SUM(s.outstanding_principal_inr) AS outstanding_principal_inr,
       ROUND(SUM(s.outstanding_principal_inr) FILTER (WHERE s.dpd_days>=30) /
         NULLIF(SUM(s.outstanding_principal_inr),0),4) AS par30_ratio
FROM loans l
JOIN v_loan_snapshot s USING (loan_id)
GROUP BY 1 ORDER BY 1;
