-- MySQL 8.0+ | MSME Lending Analytics
CREATE DATABASE IF NOT EXISTS msme_analytics
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE msme_analytics;

CREATE TABLE IF NOT EXISTS businesses (
  business_id VARCHAR(20) PRIMARY KEY,
  business_name VARCHAR(150) NOT NULL,
  industry VARCHAR(80) NOT NULL,
  business_size VARCHAR(20) NOT NULL,
  state VARCHAR(60) NOT NULL,
  city VARCHAR(60) NOT NULL,
  registration_type VARCHAR(40) NOT NULL,
  years_in_operation INT NOT NULL,
  employee_count INT NOT NULL,
  annual_turnover_inr DECIMAL(18,2) NOT NULL,
  onboarding_date DATE NOT NULL,
  INDEX idx_business_state (state),
  INDEX idx_business_size (business_size)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS products (
  product_id VARCHAR(20) PRIMARY KEY,
  product_name VARCHAR(100) NOT NULL,
  product_description VARCHAR(255),
  min_amount_inr DECIMAL(18,2) NOT NULL,
  max_amount_inr DECIMAL(18,2) NOT NULL,
  indicative_rate_pa_pct DECIMAL(6,2) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS applications (
  application_id VARCHAR(20) PRIMARY KEY,
  business_id VARCHAR(20) NOT NULL,
  product_id VARCHAR(20) NOT NULL,
  application_date DATE NOT NULL,
  requested_amount_inr DECIMAL(18,2) NOT NULL,
  application_status VARCHAR(20) NOT NULL,
  decision_date DATE NULL,
  decision_tat_days INT NULL,
  application_channel VARCHAR(40) NOT NULL,
  loan_purpose VARCHAR(60) NOT NULL,
  disbursed_flag TINYINT(1) NOT NULL DEFAULT 0,
  INDEX idx_app_date (application_date),
  INDEX idx_app_status (application_status),
  CONSTRAINT fk_app_business FOREIGN KEY (business_id) REFERENCES businesses(business_id),
  CONSTRAINT fk_app_product FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS application_events (
  event_id VARCHAR(20) PRIMARY KEY,
  application_id VARCHAR(20) NOT NULL,
  event_type VARCHAR(50) NOT NULL,
  event_timestamp DATETIME NOT NULL,
  event_sequence INT NOT NULL,
  INDEX idx_event_app (application_id),
  CONSTRAINT fk_event_application FOREIGN KEY (application_id) REFERENCES applications(application_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS loans (
  loan_id VARCHAR(20) PRIMARY KEY,
  application_id VARCHAR(20) NOT NULL UNIQUE,
  business_id VARCHAR(20) NOT NULL,
  product_id VARCHAR(20) NOT NULL,
  disbursement_date DATE NOT NULL,
  sanctioned_amount_inr DECIMAL(18,2) NOT NULL,
  interest_rate_pa_pct DECIMAL(6,2) NOT NULL,
  tenure_months INT NOT NULL,
  risk_band VARCHAR(20) NOT NULL,
  underwriting_risk_score DECIMAL(5,3) NOT NULL,
  loan_status VARCHAR(20) NOT NULL,
  INDEX idx_loan_disb_date (disbursement_date),
  CONSTRAINT fk_loan_application FOREIGN KEY (application_id) REFERENCES applications(application_id),
  CONSTRAINT fk_loan_business FOREIGN KEY (business_id) REFERENCES businesses(business_id),
  CONSTRAINT fk_loan_product FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS loan_installments (
  installment_id VARCHAR(20) PRIMARY KEY,
  loan_id VARCHAR(20) NOT NULL,
  installment_no INT NOT NULL,
  due_date DATE NOT NULL,
  principal_due_inr DECIMAL(18,2) NOT NULL,
  interest_due_inr DECIMAL(18,2) NOT NULL,
  total_due_inr DECIMAL(18,2) NOT NULL,
  UNIQUE KEY uq_loan_installment (loan_id, installment_no),
  INDEX idx_installment_due (due_date),
  CONSTRAINT fk_installment_loan FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS repayments (
  repayment_id VARCHAR(20) PRIMARY KEY,
  installment_id VARCHAR(20) NOT NULL,
  payment_date DATE NOT NULL,
  principal_paid_inr DECIMAL(18,2) NOT NULL,
  interest_paid_inr DECIMAL(18,2) NOT NULL,
  payment_amount_inr DECIMAL(18,2) NOT NULL,
  payment_mode VARCHAR(30) NOT NULL,
  INDEX idx_repayment_date (payment_date),
  CONSTRAINT fk_repayment_installment FOREIGN KEY (installment_id) REFERENCES loan_installments(installment_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS loan_snapshot (
  loan_id VARCHAR(20) PRIMARY KEY,
  business_id VARCHAR(20) NOT NULL,
  product_id VARCHAR(20) NOT NULL,
  disbursement_date DATE NOT NULL,
  sanctioned_amount_inr DECIMAL(18,2) NOT NULL,
  outstanding_principal_inr DECIMAL(18,2) NOT NULL,
  overdue_principal_inr DECIMAL(18,2) NOT NULL,
  overdue_total_inr DECIMAL(18,2) NOT NULL,
  dpd_days INT NOT NULL,
  dpd_bucket VARCHAR(20) NOT NULL,
  par30_flag TINYINT(1) NOT NULL,
  par90_flag TINYINT(1) NOT NULL,
  loan_status VARCHAR(20) NOT NULL,
  snapshot_date DATE NOT NULL,
  INDEX idx_snapshot_dpd (dpd_days),
  CONSTRAINT fk_snapshot_loan FOREIGN KEY (loan_id) REFERENCES loans(loan_id),
  CONSTRAINT fk_snapshot_business FOREIGN KEY (business_id) REFERENCES businesses(business_id),
  CONSTRAINT fk_snapshot_product FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB;
