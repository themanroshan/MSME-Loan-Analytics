# Interview walkthrough: MSME Lending Analytics

## 60-second project explanation
"I built an end-to-end analytics case study for a fictional Indian MSME lender. I generated a synthetic relational dataset covering businesses, products, applications, loans, installment schedules and repayment transactions. I used SQL to model the lending lifecycle and calculate application funnel, decision TAT, disbursements, collections and portfolio-at-risk indicators. I created an Excel KPI workbook, prepared a Power BI semantic model with DAX measures, and built an interactive Streamlit dashboard. The main business questions were where applications drop off, how quickly decisions are made, how the portfolio is distributed, and how much outstanding principal is exposed to 30+ and 90+ DPD."

## Questions you should be ready to answer
1. Why exclude Pending and Withdrawn from the approval-rate denominator?
2. What is the difference between approval rate and application-to-disbursement conversion?
3. Why is PAR 30+ calculated using outstanding principal rather than overdue installment amount?
4. How did you calculate DPD when a loan has multiple installments?
5. What is the difference between scheduled dues and collections received?
6. Why can collection efficiency be above or below 100% in some real portfolios?
7. What data-quality checks did you run across foreign keys and repayment allocations?
8. What would change if the lender used daily accrual, restructures, waivers or prepayments?
9. Why is the dataset synthetic, and what can/cannot be inferred from it?
10. How would you design row-level security and refresh for a production Power BI report?

## Honest wording
Say "synthetic lending portfolio case study" or "simulated MSME lender". Do not say "I analysed a real NBFC portfolio", "built a production credit-risk model", or "predicted NPAs".
