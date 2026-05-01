# Power BI Guide

## Goal

Build **one clean page** that feels like an analyst dashboard, not a carnival booth.

## Recommended layout

### Top row: KPI cards
- Total Estimated Payment
- Total Estimated Standardized Payment
- Total Services
- CT Standardized Payment per Service
- CT Rank

### Middle row
- Bar chart: Top Provider Types by Estimated Payment
- Bar chart: Top HCPCS Procedures by Estimated Payment
- Map or ranked bar chart: State Standardized Payment per Service

### Bottom row
- Clustered column chart: Facility vs Non-Facility
- Connecticut spotlight chart by provider type
- Small insight box with 3 written takeaways

## Best views to load

Fast route:
- `vw_dashboard_kpis`
- `vw_dashboard_provider_type_summary`
- `vw_dashboard_hcpcs_summary`
- `vw_dashboard_state_ranked`
- `vw_dashboard_pos_summary`
- `vw_dashboard_ct_spotlight`

More advanced route:
- `vw_fact_provider_service`
- `vw_dim_state`
- `vw_dim_provider_type`
- `vw_dim_hcpcs`
- `vw_dim_place_of_service`

## Visual rules

- avoid more than one page
- use short titles
- sort bars descending
- show currency in billions where needed
- avoid cluttered legends
- keep whitespace
- use one note box that explains why standardized payment is the better comparison metric

## Screenshot rule

Your final screenshot should show:
- top KPI cards
- at least one state comparison
- at least one provider-type comparison
- at least one Connecticut-specific visual

Use `assets/dashboard_mockup.png` as your starting layout.
