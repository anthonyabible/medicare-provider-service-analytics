# Power BI Model Notes

## Fastest route
Load only the summary views.

## Better route
Use:
- `vw_fact_provider_service`
- `vw_dim_state`
- `vw_dim_provider_type`
- `vw_dim_hcpcs`
- `vw_dim_place_of_service`

Create one-to-many relationships from each dimension to the fact table. That gives you a cleaner semantic model and makes the project look more like real BI work.
