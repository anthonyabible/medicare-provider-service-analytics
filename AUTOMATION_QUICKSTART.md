# Automation Quickstart

This is the least-effort route.

## 1) Put the official CSV here

`data/raw/MUP_PHY_R25_P05_V20_D23_Prov_Svc.csv`

## 2) Install Python packages once

```bash
pip install -r requirements.txt
```

## 3) Generate ready-to-paste outputs

```bash
python scripts/auto_finish_from_csv.py --csv data/raw/MUP_PHY_R25_P05_V20_D23_Prov_Svc.csv --out outputs
python scripts/build_sample_recruiter_snapshot.py
```

## 4) Use the generated files

- `outputs/key_findings.md` -> paste into README
- `outputs/executive_summary.md` -> use in applications or project summary
- `outputs/top_provider_types.csv` -> import to Power BI
- `outputs/top_hcpcs.csv` -> import to Power BI
- `outputs/state_standardized_payment_per_service.csv` -> import to Power BI
- `assets/recruiter_snapshot.png` -> add to GitHub or LinkedIn

## Why this path matters

It cuts the last manual steps out of the project. You still keep the MySQL and Power BI workflow for portfolio credibility, but you no longer need to hand-calculate findings or manually rewrite summary numbers.
