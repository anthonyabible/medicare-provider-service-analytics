# Power BI Build Sequence

## Recommended order

1. Load `vw_dashboard_kpis`
2. Load `vw_dashboard_provider_type_summary`
3. Load `vw_dashboard_hcpcs_summary`
4. Load `vw_dashboard_state_ranked`
5. Load `vw_dashboard_pos_summary`
6. Load `vw_dashboard_ct_spotlight`
7. Optional: load `vw_dashboard_ct_vs_national`, `vw_dashboard_provider_hcpcs_top_outliers`, and the dimensional views

## Page order

- top row: KPI cards
- left: provider-type chart
- middle: HCPCS chart
- right: state ranking or Connecticut callout
- bottom left: facility vs non-facility
- bottom middle: Connecticut spotlight
- bottom right: three-bullet insight box
