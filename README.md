# Medicare Provider Service Analytics

Healthcare analytics portfolio project using the official CMS Medicare Physician & Other Practitioners by Provider and Service dataset.

This project analyzes Medicare provider-service payment patterns using Python, DuckDB/SQL-style analysis, and Power BI-ready outputs. The goal is to identify payment drivers, high-volume provider types, top HCPCS service codes, state-level standardized payment differences, and Connecticut vs. national benchmarks.

## Project Highlights

- Analyzed 9,660,581 clean Medicare provider-service records.
- Included 1,175,272 distinct providers across 62 states/territories.
- Reviewed 6,405 HCPCS service codes.
- Estimated total Medicare payment was approximately $93.72B.
- Estimated standardized Medicare payment was approximately $92.81B.
- Connecticut standardized payment per service was $42.89 compared with the national average of $35.08.
- Connecticut ranked 10th by standardized payment per service.
- Connecticut was approximately 22.27% above the national standardized payment-per-service benchmark.
- Top provider type by Medicare payment: Clinical Laboratory, approximately $7.37B.
- Top HCPCS service by payment: 99214, established patient office/outpatient visit, approximately $8.23B.
- Connecticut’s top provider type by Medicare payment: Ophthalmology, approximately $84.62M.

## Tools Used

- Python
- Pandas
- DuckDB / SQL-style analysis
- Power BI
- GitHub
- Official CMS public-use data

## Dashboard and Visual Outputs

This project includes Power BI-ready output files and generated chart assets for:

- Top provider types by Medicare payment
- Top HCPCS services by Medicare payment
- State standardized payment per service
- Connecticut provider types by Medicare payment

Included visual assets:

- `top_provider_types.png`
- `top_hcpcs.png`
- `state_rankings.png`
- `dashboard_mockup.png`
- `workflow_diagram.png`
- `schema_mockup.png`

## Dataset

The project uses the official CMS Medicare Physician & Other Practitioners by Provider and Service public-use file:

`MUP_PHY_R25_P05_V20_D23_Prov_Svc.csv`

The raw CSV is not included in this repository because it is several gigabytes in size.

To reproduce the analysis, download the official CMS 2023 CSV and place it in:

`data/raw/`

## Project Workflow

1. Download the official CMS provider-service CSV.
2. Place the raw CSV in `data/raw/`.
3. Run the Python automation script.
4. Generate summary outputs and Power BI-ready CSV files.
5. Build a Power BI dashboard using the generated outputs.
6. Review national and Connecticut-level payment benchmarks.

## Key Files

- `auto_finish_from_csv.py` - Processes the CMS CSV and generates summary outputs.
- `key_findings.md` - Generated findings from the project.
- `executive_summary.md` - Executive summary of the analysis.
- `summary_metrics.json` - Main project metrics.
- `top_provider_types.csv` - Power BI-ready provider type output.
- `top_hcpcs.csv` - Power BI-ready HCPCS output.
- `state_standardized_payment_per_service.csv` - State benchmark output.
- `ct_provider_types.csv` - Connecticut-specific provider output.
- `requirements.txt` - Python package requirements.

## Business Value

This project demonstrates the ability to work with large public healthcare datasets, automate analytical workflows, generate business-readable findings, and build dashboard-ready outputs for decision support.

The analysis helps identify:

- Which provider types drive the largest Medicare payments.
- Which HCPCS service codes account for the largest payment totals.
- How Connecticut compares with national standardized payment benchmarks.
- Which Connecticut provider categories represent major Medicare payment areas.

## Reproducibility

To reproduce the project locally:

```bash
pip install -r requirements.txt
python auto_finish_from_csv.py --csv data/raw/MUP_PHY_R25_P05_V20_D23_Prov_Svc.csv --out outputs
