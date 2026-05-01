# Data Dictionary

## Key source fields
- `Rndrng_NPI`: rendering provider NPI
- `Rndrng_Prvdr_Type`: provider specialty or provider type
- `HCPCS_Cd`: procedure or service code
- `HCPCS_Desc`: procedure or service description
- `Place_Of_Srvc`: facility or non-facility
- `Tot_Benes`: total beneficiaries
- `Tot_Srvcs`: total services
- `Avg_Mdcr_Pymt_Amt`: average Medicare payment amount
- `Avg_Mdcr_Stdzd_Amt`: average Medicare standardized amount

## Derived fields
- `est_total_medicare_payment`: total_services × avg_medicare_payment_amount
- `est_total_standardized_payment`: total_services × avg_medicare_standardized_amount
- `est_total_submitted_charge`: total_services × avg_submitted_charge
- `submitted_to_payment_ratio`: avg_submitted_charge ÷ avg_medicare_payment_amount
- `payment_to_standardized_ratio`: avg_medicare_payment_amount ÷ avg_medicare_standardized_amount
- `drug_group`: Drug or Non-Drug
