# MSME Lending Analytics — End-to-End Data Analyst Project

**Business context:** A fictional Indian NBFC-style lender evaluating an MSME lending portfolio.  
**Data:** Entirely synthetic; no real borrower, lender, or financial account data.  
**Currency:** INR. **Portfolio snapshot:** 31 December 2025.

## Project objective
Build an end-to-end lending analytics workflow covering:
1. Business and product master data
2. Loan application funnel and decision turnaround time
3. Sanctions and disbursements
4. Repayment schedules and collections
5. Delinquency, DPD buckets, PAR 30+ and PAR 90+
6. Executive reporting using Excel, SQL, Power BI and Streamlit

## Tech stack
- **Excel:** KPI workbook with source-data tabs, formula-based executive summary and KPI definitions.
- **SQL (MySQL 8.0+):** Relational schema, CSV import guide, analytical views, business queries and data-quality checks. PostgreSQL alternatives are retained separately.
- **Power BI:** CSV import instructions, model relationships, DAX measures and report-page blueprint.
- **Python:** Synthetic data generation, validation, KPI calculations and dashboard data handling.
- **Streamlit + Plotly:** Interactive deployed dashboard.

## Repository structure
```text
msme-lending-analytics/
├── app.py
├── requirements.txt
├── data/
│   ├── businesses.csv
│   ├── products.csv
│   ├── applications.csv
│   ├── application_events.csv
│   ├── loans.csv
│   ├── loan_installments.csv
│   ├── repayments.csv
│   ├── loan_snapshot.csv
│   └── sample_metrics.json
├── excel/MSME_Lending_Analytics.xlsx
├── sql/
│   ├── 01_schema.sql
│   ├── 02_import_csv.psql
│   ├── 03_views.sql
│   ├── 04_analysis_queries.sql
│   └── 05_data_quality_checks.sql
├── powerbi/
│   ├── DAX_Measures.dax
│   └── Model_Relationships_and_Build_Guide.md
├── src/analytics.py
├── tests/test_data_quality.py
└── docs/
```

## Dataset scale
The included deterministic synthetic dataset contains:
- 800 businesses
- 1,500 applications
- 754 disbursed loans
- 11,538 scheduled installments
- 8,487 repayment transactions

See `data/sample_metrics.json` for the calculated sample snapshot.

## Run locally
Use Python 3.11 or 3.12 if possible.

```bash
python -m venv .venv
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

pip install -r requirements.txt
streamlit run app.py
```

## Run tests
```bash
python -m pytest -q
```

## SQL setup (MySQL 8.0+)
Use the `mysql/` folder, not the PostgreSQL-specific `sql/` folder:
1. Execute `mysql/01_schema_mysql.sql` in MySQL Workbench.
2. Import the eight CSV files into their matching tables in the order listed in `mysql/README_MySQL_Import_Guide.md`.
3. Execute `mysql/02_create_views_mysql.sql`.
4. Run `mysql/03_analysis_queries_mysql.sql` query-by-query.
5. Run `mysql/04_data_quality_checks_mysql.sql` and `mysql/05_verification_mysql.sql`.

The original `sql/` folder is retained as an optional PostgreSQL alternative. Do not run those PostgreSQL scripts in MySQL Workbench.

## Excel
Open `excel/MSME_Lending_Analytics.xlsx`. The Dashboard sheet contains formulas and KPI definitions. Excel recalculates formulas when the workbook opens. Source tabs are formatted as tables and can be filtered.

## Power BI
Follow `powerbi/Model_Relationships_and_Build_Guide.md`. Import the CSV files, create the documented relationships, add measures from `DAX_Measures.dax`, build the four report pages and save your own `.pbix` file. A `.pbix` is not included because it must be created and saved in Power BI Desktop.

## Deploy Streamlit dashboard
1. Push this project folder to a GitHub repository.
2. Go to https://share.streamlit.io and sign in with GitHub.
3. Select **Create app**, choose the repository, branch and `app.py`.
4. Deploy. Keep `requirements.txt` at the repository root.
5. Copy the generated `streamlit.app` URL into your resume/portfolio only after testing the live app.

## KPI definitions and limitations
See `docs/KPI_Definitions_and_Assumptions.md`.

## Important integrity note
This is a synthetic portfolio simulation for demonstrating data analytics. Do not claim it represents a real NBFC, real lending decisions, actual borrower behaviour, regulatory reporting, or a production credit-risk model. The DPD/PAR calculations are simplified analytical indicators and are not a regulatory NPA classification.

## Remaining external steps
Follow `mysql/README_MySQL_Import_Guide.md` for MySQL setup, and `docs/External_Setup_and_Deployment_Checklist.md` for Power BI Desktop report creation, GitHub upload and Streamlit Community Cloud deployment. The `.pbix` and live deployment URL must be created by you after testing.


**Database note:** MySQL-specific SQL scripts are in `mysql/`. The original `sql/` folder is retained as a PostgreSQL alternative and should not be run in MySQL Workbench.
