# Import CSV files into MySQL

## Recommended: MySQL Workbench Table Data Import Wizard

Run `01_schema_mysql.sql` first to create the database and tables. Then import CSVs in this exact order because foreign keys depend on earlier tables:

1. `data/businesses.csv` → `businesses`
2. `data/products.csv` → `products`
3. `data/applications.csv` → `applications`
4. `data/application_events.csv` → `application_events`
5. `data/loans.csv` → `loans`
6. `data/loan_installments.csv` → `loan_installments`
7. `data/repayments.csv` → `repayments`
8. `data/loan_snapshot.csv` → `loan_snapshot`

For each file:
1. In MySQL Workbench, connect to your local MySQL server.
2. In the SCHEMAS panel, expand `msme_analytics`.
3. Right-click the target table and choose **Table Data Import Wizard** (or use the wizard from the table context menu).
4. Browse to the matching CSV in the extracted project's `data` folder.
5. Choose the existing target table; do not create a new table.
6. Confirm that each CSV column maps to the matching table column.
7. Finish the import and check the row count.

Expected row counts:
- businesses: 800
- products: 4
- applications: 1,500
- application_events: 5,802
- loans: 754
- loan_installments: 11,538
- repayments: 8,487
- loan_snapshot: 754

If Workbench reports an import error, stop and inspect the error instead of importing the same file repeatedly. Check that blank values in `decision_date` and `decision_tat_days` are imported as NULL.

## Alternative: LOAD DATA LOCAL INFILE

The Workbench wizard is easier for a first-time setup. If you prefer SQL bulk loading, enable `local_infile` in both the MySQL server and client, then use a `LOAD DATA LOCAL INFILE` statement with the full absolute path to each CSV. Do not paste a guessed path. Windows paths need escaped backslashes or forward slashes.

## Run analysis

After importing all eight CSVs:
1. Open and execute `02_create_views_mysql.sql`.
2. Open and execute `03_analysis_queries_mysql.sql` query-by-query.
3. Open and execute `04_data_quality_checks_mysql.sql`.
4. Compare the summary results with `data/sample_metrics.json`.

The `loan_snapshot` table is the supplied, reproducible snapshot used by the dashboard and Power BI. The recalculated view `v_loan_snapshot_recalculated` independently derives the same type of snapshot from loans, installments and repayments; compare it with `loan_snapshot` as a validation exercise.
