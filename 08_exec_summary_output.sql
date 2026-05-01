-- ============================================================
-- File: sql/08_exec_summary_output.sql
-- Purpose: Produce a concise narrative output for the README or dashboard
-- ============================================================

USE medicare_analysis;

WITH footprint AS (
    SELECT
        COUNT(*) AS records,
        COUNT(DISTINCT provider_npi) AS providers,
        COUNT(DISTINCT provider_state) AS states,
        COUNT(DISTINCT hcpcs_code) AS hcpcs_codes,
        ROUND(SUM(est_total_medicare_payment) / 1000000000, 2) AS total_payment_b,
        ROUND(SUM(est_total_standardized_payment) / 1000000000, 2) AS total_standardized_b
    FROM provider_service_clean
),
ct_benchmark AS (
    SELECT * FROM vw_dashboard_ct_vs_national
),
state_rank AS (
    SELECT provider_state, std_payment_rank
    FROM vw_dashboard_state_ranked
    WHERE provider_state = 'CT'
),
provider_leader AS (
    SELECT provider_type
    FROM vw_dashboard_provider_type_summary
    ORDER BY total_est_payment DESC
    LIMIT 1
),
outlier AS (
    SELECT provider_type, hcpcs_code
    FROM vw_dashboard_provider_hcpcs_top_outliers
    LIMIT 1
)
SELECT CONCAT(
    'Built on ', f.records, ' cleaned rows across ', f.providers, ' providers, ',
    f.states, ' states, and ', f.hcpcs_codes, ' HCPCS codes, this project summarizes about $',
    f.total_payment_b, 'B in estimated Medicare payment and $', f.total_standardized_b,
    'B in estimated standardized payment. Connecticut shows a standardized payment per service of $',
    c.ct_std_payment_per_service, ' versus a national benchmark of $', c.national_std_payment_per_service,
    ' and ranks #', r.std_payment_rank, ' nationally. The largest payment-driving provider type is ',
    p.provider_type, ', while the highest-volume above-baseline provider-type and HCPCS combination begins with ',
    o.provider_type, ' / ', o.hcpcs_code, '.'
) AS executive_summary
FROM footprint f
CROSS JOIN ct_benchmark c
CROSS JOIN state_rank r
CROSS JOIN provider_leader p
CROSS JOIN outlier o;
