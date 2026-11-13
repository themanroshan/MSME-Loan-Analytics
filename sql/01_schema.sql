-- PostgreSQL 14+ | Synthetic MSME Lending Analytics
CREATE SCHEMA IF NOT EXISTS msme;
SET search_path TO msme;

CREATE TABLE IF NOT EXISTS businesses (
  business_id TEXT PRIMARY KEY,
  business_name TEXT NOT NULL,
  industry TEXT NOT NULL,
  business_size TEXT NOT NULL CHECK (business_size IN ('Micro','Small','Medium')),
  state TEXT NOT NULL,
  city TEXT NOT NULL,
  registration_type TEXT NOT NULL,
  years_in_operation INTEGER NOT NULL CHECK (years_in_operation >= 0),
  employee_count INTEGER NOT NULL CHECK (employee_count >= 0),
  annual_turnover_inr NUMERIC(18,2) NOT NULL CHECK (annual_turnover_inr >= 0),
  onboarding_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS products (
  product_id TEXT PRIMARY KEY,
  product_name TEXT NOT NULL,
  product_description TEXT,
  min_amount_inr NUMERIC(18,2) NOT NULL,
  max_amount_inr NUMERIC(18,2) NOT NULL,
  indicative_rate_pa_pct NUMERIC(6,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS applications (
  application_id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(business_id),
  product_id TEXT NOT NULL REFERENCES products(product_id),
  application_date DATE NOT NULL,
  requested_amount_inr NUMERIC(18,2) NOT NULL CHECK (requested_amount_inr > 0),
  application_status TEXT NOT NULL CHECK (application_status IN ('Approved','Rejected','Pending','Withdrawn')),
  decision_date DATE,
  decision_tat_days INTEGER,
  application_channel TEXT NOT NULL,
  loan_purpose TEXT NOT NULL,
  disbursed_flag BOOLEAN NOT NULL DEFAULT FALSE,
  CHECK (decision_tat_days IS NULL OR decision_tat_days >= 0)
);

CREATE TABLE IF NOT EXISTS application_events (
  event_id TEXT PRIMARY KEY,
  application_id TEXT NOT NULL REFERENCES applications(application_id),
  event_type TEXT NOT NULL,
  event_timestamp TIMESTAMP NOT NULL,
  event_sequence INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS loans (
  loan_id TEXT PRIMARY KEY,
  application_id TEXT NOT NULL UNIQUE REFERENCES applications(application_id),
  business_id TEXT NOT NULL REFERENCES businesses(business_id),
  product_id TEXT NOT NULL REFERENCES products(product_id),
  disbursement_date DATE NOT NULL,
  sanctioned_amount_inr NUMERIC(18,2) NOT NULL CHECK (sanctioned_amount_inr > 0),
  interest_rate_pa_pct NUMERIC(6,2) NOT NULL,
  tenure_months INTEGER NOT NULL CHECK (tenure_months > 0),
  risk_band TEXT NOT NULL CHECK (risk_band IN ('Low','Medium','High')),
  underwriting_risk_score NUMERIC(5,3) NOT NULL,
  loan_status TEXT NOT NULL CHECK (loan_status IN ('Active','Closed'))
);

CREATE TABLE IF NOT EXISTS loan_installments (
  installment_id TEXT PRIMARY KEY,
  loan_id TEXT NOT NULL REFERENCES loans(loan_id),
  installment_no INTEGER NOT NULL,
  due_date DATE NOT NULL,
  principal_due_inr NUMERIC(18,2) NOT NULL,
  interest_due_inr NUMERIC(18,2) NOT NULL,
  total_due_inr NUMERIC(18,2) NOT NULL,
  UNIQUE (loan_id, installment_no)
);

CREATE TABLE IF NOT EXISTS repayments (
  repayment_id TEXT PRIMARY KEY,
  installment_id TEXT NOT NULL REFERENCES loan_installments(installment_id),
  payment_date DATE NOT NULL,
  principal_paid_inr NUMERIC(18,2) NOT NULL,
  interest_paid_inr NUMERIC(18,2) NOT NULL,
  payment_amount_inr NUMERIC(18,2) NOT NULL,
  payment_mode TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_applications_date ON applications(application_date);
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(application_status);
CREATE INDEX IF NOT EXISTS idx_loans_disbursement_date ON loans(disbursement_date);
CREATE INDEX IF NOT EXISTS idx_installments_due_date ON loan_installments(due_date);
CREATE INDEX IF NOT EXISTS idx_repayments_payment_date ON repayments(payment_date);
