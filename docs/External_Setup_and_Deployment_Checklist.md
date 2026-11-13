# External setup and deployment checklist

This repository is prepared locally. These are the remaining actions that require your own accounts or desktop applications.

## A. Unzip and inspect
1. Extract `MSME_Lending_Analytics_Project.zip`.
2. Open the extracted `msme_lending_analytics_project` folder.
3. Check that `README.md`, `app.py`, `data/`, `sql/`, `excel/` and `powerbi/` are present.

## B. Run the Streamlit dashboard locally
Install Python 3.11 or 3.12, then open a terminal in the project root.

Windows PowerShell:
```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
streamlit run app.py
```

macOS/Linux:
```bash
python3.12 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
streamlit run app.py
```

Open the local URL shown in the terminal (usually `http://localhost:8501`). Check all five pages, filters, tables and CSV downloads.

## C. Set up MySQL and execute the SQL work
Use the `mysql/` folder, not the PostgreSQL-specific `sql/` folder. Open `mysql/README_MySQL_Import_Guide.md` and follow it. In short: execute `mysql/01_schema_mysql.sql`, import the eight CSV files into their matching tables in the documented order using MySQL Workbench Table Data Import Wizard, then execute `02_create_views_mysql.sql`, `03_analysis_queries_mysql.sql`, `04_data_quality_checks_mysql.sql` and `05_verification_mysql.sql`. Save 2–3 screenshots of query results: approval rate/TAT, disbursement by product, and PAR30/PAR90 by product.

## D. Use the Excel deliverable
1. Open `excel/MSME_Lending_Analytics.xlsx` in Microsoft Excel.
2. Allow formulas to recalculate if prompted.
3. Review the Dashboard and KPI Definitions sheets.
4. Save a screenshot of the dashboard for your portfolio evidence.
5. Do not overwrite source CSVs with manually edited values.

## E. Create the actual Power BI report
Power BI Desktop is a separate Windows application. The project includes the CSVs, model guide and DAX measures, but **not a finished `.pbix` file**.

1. Install/open Power BI Desktop.
2. Import the seven CSVs listed in `powerbi/Model_Relationships_and_Build_Guide.md`.
3. Set IDs to Text, dates to Date, and INR fields to Decimal Number in Power Query.
4. Create the relationships in the model guide.
5. Copy measures from `powerbi/DAX_Measures.dax` into Modeling → New measure, one at a time.
6. Build four pages: Executive Summary, Application Funnel, Portfolio Quality, Collections.
7. Add slicers for date, state, business size and product. Use separate date slicers for application and disbursement date if needed.
8. Save the file as `powerbi/MSME_Lending_Analytics.pbix`.
9. Publish using Home → Publish, sign in, and choose your workspace. Copy the report URL.

Power BI Desktop can create reports without a paid license, but publishing/sharing permissions depend on your account and workspace. A Pro/PPU license may be required for sharing in non-premium workspaces. Avoid "Publish to web" unless you deliberately want the report and underlying model data to be publicly accessible.

## F. Push the project to GitHub
1. Create a new repository named `msme-lending-analytics`.
2. Upload the extracted project files, keeping the folder structure intact.
3. Make sure `requirements.txt` and `app.py` are in the repository root.
4. Do not upload `.venv`, passwords, API keys, or `.streamlit/secrets.toml`.
5. Add the finished Power BI `.pbix` only if you want it in GitHub; large PBIX files can make the repository heavy. A report link or screenshots may be better.

Suggested Git commands from the project root:
```bash
git init
git add .
git commit -m "Build MSME lending analytics project"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/msme-lending-analytics.git
git push -u origin main
```
Replace `YOUR_USERNAME` with your actual GitHub username.

## G. Deploy Streamlit Community Cloud
1. Open https://share.streamlit.io and sign in with GitHub.
2. Connect/authorize the GitHub repository if asked.
3. Select **Create app**.
4. Choose repository `YOUR_USERNAME/msme-lending-analytics`, branch `main`, and entrypoint `app.py`.
5. Deploy and wait for the app to build.
6. Open the generated `*.streamlit.app` URL and test every page.
7. Add the live URL to the GitHub README and resume only after it works.

The app reads the included synthetic CSVs locally from the repository, so no database secrets are required for this demo deployment.

## H. Evidence to collect before adding it to your resume
- GitHub repository URL
- Live Streamlit dashboard URL
- Power BI `.pbix` file and/or published report URL
- Excel dashboard screenshot
- 2–3 SQL query screenshots
- A short note explaining that the dataset is synthetic

## Do not claim these as completed until you personally finish them
- PostgreSQL scripts executed successfully
- Power BI report created and published
- Streamlit dashboard deployed and tested
- GitHub repository pushed

The local project files are prepared; those external steps are yours to complete and verify.
