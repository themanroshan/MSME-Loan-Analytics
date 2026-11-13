USE msme_analytics;

SELECT 'businesses' AS table_name, COUNT(*) AS row_count FROM businesses
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'applications', COUNT(*) FROM applications
UNION ALL SELECT 'application_events', COUNT(*) FROM application_events
UNION ALL SELECT 'loans', COUNT(*) FROM loans
UNION ALL SELECT 'loan_installments', COUNT(*) FROM loan_installments
UNION ALL SELECT 'repayments', COUNT(*) FROM repayments
UNION ALL SELECT 'loan_snapshot', COUNT(*) FROM loan_snapshot;

SELECT
  SUM(application_status='Approved') AS approved,
  SUM(application_status='Rejected') AS rejected,
  ROUND(SUM(application_status='Approved') /
        NULLIF(SUM(application_status IN ('Approved','Rejected')),0)*100,2) AS approval_rate_pct
FROM applications;

SELECT
  SUM(sanctioned_amount_inr) AS total_disbursed_inr,
  SUM(outstanding_principal_inr) AS outstanding_principal_inr,
  ROUND(SUM(CASE WHEN dpd_days>=30 THEN outstanding_principal_inr ELSE 0 END) /
        NULLIF(SUM(outstanding_principal_inr),0)*100,2) AS par30_pct,
  ROUND(SUM(CASE WHEN dpd_days>=90 THEN outstanding_principal_inr ELSE 0 END) /
        NULLIF(SUM(outstanding_principal_inr),0)*100,2) AS par90_pct
FROM loans l JOIN loan_snapshot s ON s.loan_id=l.loan_id;
