# Power BI DAX Measures

These are optional starter measures if you load the fact view.

```DAX
Total Est Payment = SUM(vw_fact_provider_service[est_total_medicare_payment])

Total Est Standardized Payment = SUM(vw_fact_provider_service[est_total_standardized_payment])

Total Services = SUM(vw_fact_provider_service[total_services])

Total Beneficiaries = SUM(vw_fact_provider_service[total_beneficiaries])

Std Payment Per Service =
DIVIDE(
    [Total Est Standardized Payment],
    [Total Services]
)

Payment Per Service =
DIVIDE(
    [Total Est Payment],
    [Total Services]
)
```

If you want the dashboard to look like you know what you're doing, use measures instead of relying only on automatic visual totals.
