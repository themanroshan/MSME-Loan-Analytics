# Power BI model and build guide

## 1. Import the data
In Power BI Desktop choose **Home → Get data → Text/CSV** and import:
- `data/businesses.csv` as `Businesses`
- `data/products.csv` as `Products`
- `data/applications.csv` as `Applications`
- `data/loans.csv` as `Loans`
- `data/loan_installments.csv` as `Loan_Installments`
- `data/repayments.csv` as `Repayments`
- `data/loan_snapshot.csv` as `Loan_Snapshot`

`application_events.csv` is optional for an application-stage timeline page. Use Power Query to set date columns to Date and INR fields to Decimal Number. Keep IDs as Text.

## 2. Relationships (single direction)
Create these relationships:
- `Businesses[business_id]` 1 → * `Applications[business_id]`
- `Products[product_id]` 1 → * `Applications[product_id]`
- `Applications[application_id]` 1 → 0..1 `Loans[application_id]`
- `Loans[loan_id]` 1 → * `Loan_Installments[loan_id]`
- `Loan_Installments[installment_id]` 1 → * `Repayments[installment_id]`
- `Loans[loan_id]` 1 → 1 `Loan_Snapshot[loan_id]`

Use single-direction filtering from the left/one side to the right/many side. Do **not** also create direct Businesses → Loans or Products → Loans relationships in this model: the application-to-loan path already carries those filters and extra active paths can create ambiguous filter propagation. Check that `Loan_Snapshot` has one row per loan.

## 3. Create measures
Open `DAX_Measures.dax`, copy each measure into **Modeling → New measure**. DAX measures are provided as a text reference; they are not automatically installed in a PBIX file.

## 4. Suggested report pages

### Page 1 — Executive Summary
Cards: Total Applications, Approval Rate, Disbursed Loans, Total Disbursed, Outstanding Principal, PAR 30+ %, PAR 90+ %.
Visuals: monthly disbursement trend, application status mix, outstanding by product, portfolio by state.
Slicers: application date, disbursement date (separate), state, business size, product.

### Page 2 — Application Funnel
Visuals: application count by status, approval rate by product, average decision TAT by status/product, application channel mix, application amount distribution.
Use only Approved + Rejected in the approval-rate denominator.

### Page 3 — Portfolio Quality
Visuals: DPD bucket distribution, PAR 30+ and PAR 90+ by product, outstanding principal by business size/state, risk-band distribution.
Include a note that DPD/PAR are analytical measures for this synthetic project, not regulatory NPA reporting.

### Page 4 — Collections
Visuals: scheduled dues vs collections by month, collection efficiency, repayment mode mix, overdue principal by DPD bucket.
Do not count future installments as due.

## 5. Formatting
- Use INR currency format; display large amounts in ₹ lakh / ₹ crore.
- Use consistent labels and descriptive titles.
- Add a footer: "Synthetic educational dataset | Snapshot 31-Dec-2025".
- Add alt text and avoid cluttered visuals.
- Save as `MSME_Lending_Analytics.pbix` in this folder.

## 6. Publish
In Power BI Desktop select **Home → Publish**, sign in, choose a workspace, then copy the report link. Publishing and sharing may require an eligible Power BI license and tenant permissions. Do not use "Publish to web" for confidential or real customer data. This project uses synthetic data, but use normal authenticated sharing where possible.
