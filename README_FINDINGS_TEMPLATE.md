# README Findings Template

Paste the outputs from `sql/05_readme_key_findings.sql` into this wording.

- The cleaned dataset contains **[records] records**, **[providers] providers**, **[states] states**, and **[hcpcs_codes] HCPCS codes**, representing about **$[medicare_payment_b]B** in estimated Medicare payment and **$[standardized_payment_b]B** in estimated standardized payment.
- Connecticut’s standardized payment per service is **$[ct_std]**, compared with a national benchmark of **$[national_std]**, a difference of **[pct_diff]%**.
- Connecticut ranks **#[ct_rank]** nationally on standardized payment per service.
- The top provider specialty by estimated Medicare payment is **[top_provider_type]**.
- The top HCPCS procedure by estimated Medicare payment is **[top_hcpcs_code] - [top_hcpcs_desc]**.
- **[drug_group]** services account for the larger share of estimated Medicare payment.
- The higher standardized-payment setting is **[place_of_service]**.
- In Connecticut, the top provider specialty by estimated Medicare payment is **[ct_top_provider_type]**.
- A notable high-volume outlier candidate is **[provider_type] / [hcpcs_code]**, which is **$[above_baseline]** above its provider-type baseline standardized payment per service.
