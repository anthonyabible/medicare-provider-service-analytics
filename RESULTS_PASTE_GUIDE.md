# Results Paste Guide

## Fastest way to finish the README

Run these files in order:

1. `sql/05_readme_key_findings.sql`
2. `sql/08_exec_summary_output.sql`

Then copy the returned values into:

- `README.md` under **Key findings**
- `docs/README_FINDINGS_TEMPLATE.md`
- your Power BI insight text box

## Paste order

1. dataset footprint
2. Connecticut vs national comparison
3. Connecticut rank
4. top provider type
5. top HCPCS code
6. drug vs non-drug share
7. facility vs non-facility result
8. top Connecticut provider type
9. above-baseline high-volume combo
10. executive-summary paragraph from `sql/08_exec_summary_output.sql`

## Final polish

- keep all money values rounded exactly as returned
- keep provider and HCPCS names as returned
- do not add clinical interpretations that the data cannot support
