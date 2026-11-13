USE msme_analytics;

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

-- 3. Approval rate: pending and withdrawn excluded from denominator
SELECT
  SUM(application_status='Approved') AS approved,
  SUM(application_status='Rejected') AS rejected,
  ROUND(
    SUM(application_status='Approved') /
    NULLIF(SUM(application_status IN ('Approved','Rejected')),0), 4
  ) AS approval_rate
FROM applications;

-- 4. Average decision turnaround time
SELECT application_status, ROUND(AVG(decision_tat_days),2) AS avg_decision_tat_days
FROM applications
WHERE application_status IN ('Approved','Rejected')
GROUP BY application_status;

-- 5. Application-to-disbursement conversion by product
SELECT p.product_name,
       COUNT(DISTINCT CASE WHEN a.application_status='Approved' THEN a.application_id END) AS approved_apps,
       COUNT(DISTINCT l.loan_id) AS disbursed_loans,
       ROUND(
         COUNT(DISTINCT l.loan_id) /
         NULLIF(COUNT(DISTINCT CASE WHEN a.application_status='Approved' THEN a.application_id END),0), 4
       ) AS conversion_rate
FROM products p
LEFT JOIN applications a ON a.product_id=p.product_id
LEFT JOIN loans l ON l.application_id=a.application_id
GROUP BY p.product_name
ORDER BY disbursed_loans DESC;

-- 6. Monthly disbursement trend
SELECT DATE_FORMAT(disbursement_date,'%Y-%m-01') AS disbursement_month,
       COUNT(*) AS loans_disbursed,
       SUM(sanctioned_amount_inr) AS disbursed_amount_inr
FROM loans
GROUP BY DATE_FORMAT(disbursement_date,'%Y-%m-01')
ORDER BY disbursement_month;

-- 7. Portfolio outstanding and PAR metrics (snapshot: 31-Dec-2025)
SELECT SUM(outstanding_principal_inr) AS outstanding_principal_inr,
       SUM(CASE WHEN dpd_days>=30 THEN outstanding_principal_inr ELSE 0 END) AS par30_amount_inr,
       ROUND(SUM(CASE WHEN dpd_days>=30 THEN outstanding_principal_inr ELSE 0 END) /
         NULLIF(SUM(outstanding_principal_inr),0),4) AS par30_ratio,
       SUM(CASE WHEN dpd_days>=90 THEN outstanding_principal_inr ELSE 0 END) AS par90_amount_inr,
       ROUND(SUM(CASE WHEN dpd_days>=90 THEN outstanding_principal_inr ELSE 0 END) /
         NULLIF(SUM(outstanding_principal_inr),0),4) AS par90_ratio
FROM loan_snapshot;

-- 8. DPD bucket distribution
SELECT dpd_bucket, COUNT(*) AS loan_count,
       SUM(outstanding_principal_inr) AS outstanding_principal_inr
FROM loan_snapshot
GROUP BY dpd_bucket
ORDER BY FIELD(dpd_bucket,'Current','1-30','31-60','61-90','90+');

-- 9. PAR30 by product
SELECT p.product_name,
       SUM(s.outstanding_principal_inr) AS outstanding_principal_inr,
       SUM(CASE WHEN s.dpd_days>=30 THEN s.outstanding_principal_inr ELSE 0 END) AS par30_amount_inr,
       ROUND(SUM(CASE WHEN s.dpd_days>=30 THEN s.outstanding_principal_inr ELSE 0 END) /
         NULLIF(SUM(s.outstanding_principal_inr),0),4) AS par30_ratio
FROM loan_snapshot s
JOIN products p ON p.product_id=s.product_id
GROUP BY p.product_name
ORDER BY par30_ratio DESC;

-- 10. Portfolio concentration by state
SELECT b.state, COUNT(DISTINCT l.loan_id) AS loans,
       SUM(l.sanctioned_amount_inr) AS disbursed_amount_inr,
       SUM(s.outstanding_principal_inr) AS outstanding_principal_inr
FROM loans l
JOIN businesses b ON b.business_id=l.business_id
JOIN loan_snapshot s ON s.loan_id=l.loan_id
GROUP BY b.state
ORDER BY outstanding_principal_inr DESC;

-- 11. Portfolio by business size
SELECT b.business_size, COUNT(DISTINCT l.loan_id) AS loans,
       SUM(l.sanctioned_amount_inr) AS disbursed_amount_inr,
       SUM(s.outstanding_principal_inr) AS outstanding_principal_inr,
       ROUND(SUM(CASE WHEN s.dpd_days>=30 THEN s.outstanding_principal_inr ELSE 0 END) /
         NULLIF(SUM(s.outstanding_principal_inr),0),4) AS par30_ratio
FROM loans l
JOIN businesses b ON b.business_id=l.business_id
JOIN loan_snapshot s ON s.loan_id=l.loan_id
GROUP BY b.business_size
ORDER BY loans DESC;

-- 12. Collection efficiency on installments due by snapshot date
WITH due AS (
  SELECT SUM(total_due_inr) AS due_amount
  FROM loan_installments
  WHERE due_date <= '2025-12-31'
), paid AS (
  SELECT SUM(payment_amount_inr) AS paid_amount
  FROM repayments
  WHERE payment_date <= '2025-12-31'
)
SELECT due_amount, paid_amount,
       ROUND(paid_amount/NULLIF(due_amount,0),4) AS collection_efficiency
FROM due CROSS JOIN paid;

-- 13. Top 10 businesses by outstanding principal
SELECT b.business_id, b.business_name, b.industry, b.state,
       SUM(s.outstanding_principal_inr) AS outstanding_principal_inr
FROM loan_snapshot s
JOIN businesses b ON b.business_id=s.business_id
GROUP BY b.business_id,b.business_name,b.industry,b.state
ORDER BY outstanding_principal_inr DESC
LIMIT 10;

-- 14. Repeat borrowers
SELECT business_id, COUNT(*) AS loan_count,
       SUM(sanctioned_amount_inr) AS total_disbursed_inr
FROM loans
GROUP BY business_id
HAVING COUNT(*) > 1
ORDER BY loan_count DESC,total_disbursed_inr DESC;

-- 15. Quarterly disbursement and PAR30
SELECT CONCAT(YEAR(l.disbursement_date),'-Q',QUARTER(l.disbursement_date)) AS disbursement_quarter,
       COUNT(*) AS loans,
       SUM(s.outstanding_principal_inr) AS outstanding_principal_inr,
       ROUND(SUM(CASE WHEN s.dpd_days>=30 THEN s.outstanding_principal_inr ELSE 0 END) /
         NULLIF(SUM(s.outstanding_principal_inr),0),4) AS par30_ratio
FROM loans l
JOIN loan_snapshot s ON s.loan_id=l.loan_id
GROUP BY YEAR(l.disbursement_date),QUARTER(l.disbursement_date)
ORDER BY YEAR(l.disbursement_date),QUARTER(l.disbursement_date);
