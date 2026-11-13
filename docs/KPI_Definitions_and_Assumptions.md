# KPI definitions, assumptions and limitations

| KPI | Definition used in this project | Important caveat |
|---|---|---|
| Approval rate | Approved / (Approved + Rejected) | Pending and withdrawn applications are excluded. |
| Decision TAT | Decision date minus application date | Calculated only for approved/rejected applications. |
| Disbursement conversion | Disbursed loans / approved applications | Measures post-approval conversion, not approval rate. |
| Average ticket size | Total sanctioned amount / number of disbursed loans | Uses sanctioned amount, not requested amount. |
| Outstanding principal | Scheduled principal less principal repaid by 31-Dec-2025 | Includes principal due in future installments. |
| DPD | Days since the oldest installment due date with unpaid principal or interest at snapshot | A simplified loan-level delinquency calculation. |
| PAR 30+ | Outstanding principal on loans with DPD >= 30 / total outstanding principal | Analytical portfolio-at-risk proxy, not regulatory reporting. |
| PAR 90+ | Outstanding principal on loans with DPD >= 90 / total outstanding principal | Analytical portfolio-at-risk proxy, not regulatory reporting. |
| Collection efficiency | Payments received by snapshot / scheduled dues with due date on or before snapshot | Simple cash collection ratio; not a vintage-adjusted or regulatory measure. |

## Data assumptions
- All names, businesses, applications, loans, installments and repayments are synthetic.
- All currency values are INR.
- The snapshot date is fixed at 31 December 2025 for reproducibility.
- A loan is generated only from an approved application that is assumed to have converted to disbursement.
- Each installment has scheduled principal and interest. Repayment transactions are allocated to principal and interest.
- Payments after the snapshot date are not included.
- The dataset is designed to create a realistic mix of current and delinquent accounts for analytics practice. It is not calibrated to any real lender's portfolio.

## Known limitations
- No real bureau data, bank statements, GST filings, collateral valuations, fraud labels or verified borrower financials.
- No credit decision model is trained. Risk bands are synthetic scenario labels and must not be presented as a validated credit score.
- No interest accrual, penal interest, restructuring, moratorium, write-off, pre-closure fee or legal recovery logic.
- PAR/DPD definitions are simplified and should not be used for regulatory or accounting decisions.
- Collection efficiency is a simple portfolio cash ratio and does not adjust for collection timing, waivers or reversals.
- The project is an educational analytics simulation, not a lending system or investment recommendation.
