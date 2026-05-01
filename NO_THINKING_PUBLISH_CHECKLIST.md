# No-Thinking Publish Checklist

1. Put the CMS CSV in `data/raw/`
2. Run:
   - `pip install -r requirements.txt`
   - `python scripts/auto_finish_from_csv.py --csv data/raw/MUP_PHY_R25_P05_V20_D23_Prov_Svc.csv --out outputs`
   - `python scripts/build_sample_recruiter_snapshot.py`
3. Copy `outputs/key_findings.md` into `README.md`
4. Copy `outputs/executive_summary.md` into `docs/EXECUTIVE_SUMMARY.md` if you want refreshed numbers
5. Add `assets/recruiter_snapshot.png` and one Power BI screenshot to the repo
6. Publish to GitHub
7. Use text from `docs/RECRUITER_LANGUAGE_BY_ROLE.md` on LinkedIn, resume, and applications
