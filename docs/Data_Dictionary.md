# Data dictionary

| File / table | Grain | Primary key | Description |
|---|---|---|---|
| businesses | One row per MSME | business_id | Synthetic business profile and geography |
| products | One row per loan product | product_id | Product catalogue and indicative pricing |
| applications | One row per application | application_id | Application amount, status, channel and decision TAT |
| application_events | One row per workflow event | event_id | Application process milestones |
| loans | One row per disbursed loan | loan_id | Sanctioned amount, rate, tenure and risk band |
| loan_installments | One row per scheduled installment | installment_id | Principal and interest due by date |
| repayments | One row per repayment transaction | repayment_id | Amount allocated to principal and interest |
| loan_snapshot | One row per loan at 31-Dec-2025 | loan_id | Derived outstanding principal, DPD and PAR flags |

## Join keys
- applications.business_id → businesses.business_id
- applications.product_id → products.product_id
- loans.application_id → applications.application_id
- loans.business_id → businesses.business_id
- loans.product_id → products.product_id
- loan_installments.loan_id → loans.loan_id
- repayments.installment_id → loan_installments.installment_id
- loan_snapshot.loan_id → loans.loan_id
