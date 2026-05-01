-- ============================================================
-- Medicare Payment Intelligence Dashboard
-- File: sql/03_analysis_queries.sql
-- Purpose: Core business analysis queries
-- Notes:
--   - Uses weighted metrics where appropriate
-- ============================================================

USE medicare_analysis;

-- 1) Overall dataset footprint
SELECT
    COUNT(*) AS records,
    COUNT(DISTINCT provider_npi) AS distinct_providers,
    COUNT(DISTINCT provider_type) AS distinct_provider_types,
    COUNT(DISTINCT provider_state) AS distinct_states,
    COUNT(DISTINCT hcpcs_code) AS distinct_hcpcs_codes,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_medicare_payment,
    ROUND(SUM(est_total_standardized_payment), 2) AS total_est_standardized_payment,
    ROUND(SUM(est_total_submitted_charge), 2) AS total_est_submitted_charge
FROM provider_service_clean;

-- 2) Top provider types nationally
SELECT
    provider_type,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment,
    ROUND(SUM(est_total_standardized_payment), 2) AS total_est_standardized_payment,
    ROUND(SUM(total_services), 0) AS total_services,
    ROUND(SUM(total_beneficiaries), 0) AS total_beneficiaries,
    ROUND(SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0), 2) AS std_payment_per_service,
    ROUND(SUM(est_total_medicare_payment) / NULLIF(SUM(total_services), 0), 2) AS weighted_payment_per_service
FROM provider_service_clean
GROUP BY provider_type
ORDER BY total_est_payment DESC
LIMIT 15;

-- 3) Top HCPCS procedures nationally
SELECT
    hcpcs_code,
    hcpcs_desc,
    drug_group,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment,
    ROUND(SUM(total_services), 0) AS total_services,
    ROUND(SUM(total_beneficiaries), 0) AS total_beneficiaries,
    ROUND(SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0), 2) AS std_payment_per_service,
    ROUND(SUM(est_total_medicare_payment) / NULLIF(SUM(total_services), 0), 2) AS weighted_payment_per_service
FROM provider_service_clean
GROUP BY hcpcs_code, hcpcs_desc, drug_group
ORDER BY total_est_payment DESC
LIMIT 20;

-- 4) State ranking by standardized payment per service
SELECT
    provider_state,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment,
    ROUND(SUM(est_total_standardized_payment), 2) AS total_est_standardized_payment,
    ROUND(SUM(total_services), 0) AS total_services,
    ROUND(SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0), 2) AS std_payment_per_service,
    RANK() OVER (
        ORDER BY SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0) DESC
    ) AS std_payment_rank
FROM provider_service_clean
GROUP BY provider_state
ORDER BY std_payment_rank, provider_state;

-- 5) Connecticut vs national benchmark
WITH national AS (
    SELECT
        SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0) AS national_std_payment_per_service
    FROM provider_service_clean
),
connecticut AS (
    SELECT
        SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0) AS ct_std_payment_per_service
    FROM provider_service_clean
    WHERE provider_state = 'CT'
)
SELECT
    ROUND(c.ct_std_payment_per_service, 2) AS ct_std_payment_per_service,
    ROUND(n.national_std_payment_per_service, 2) AS national_std_payment_per_service,
    ROUND(c.ct_std_payment_per_service - n.national_std_payment_per_service, 2) AS ct_minus_national,
    ROUND((c.ct_std_payment_per_service / NULLIF(n.national_std_payment_per_service, 0) - 1) * 100, 2) AS pct_diff
FROM connecticut c
CROSS JOIN national n;

-- 6) Facility vs non-facility comparison
SELECT
    place_of_service,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment,
    ROUND(SUM(est_total_standardized_payment), 2) AS total_est_standardized_payment,
    ROUND(SUM(total_services), 0) AS total_services,
    ROUND(SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0), 2) AS std_payment_per_service
FROM provider_service_clean
GROUP BY place_of_service
ORDER BY std_payment_per_service DESC;

-- 7) Drug vs non-drug payment share
SELECT
    drug_group,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment,
    ROUND(
        100 * SUM(est_total_medicare_payment) /
        NULLIF((SELECT SUM(est_total_medicare_payment) FROM provider_service_clean), 0),
        2
    ) AS payment_share_pct
FROM provider_service_clean
GROUP BY drug_group
ORDER BY total_est_payment DESC;

-- 8) Connecticut provider types
SELECT
    provider_type,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment,
    ROUND(SUM(total_services), 0) AS total_services,
    ROUND(SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0), 2) AS std_payment_per_service
FROM provider_service_clean
WHERE provider_state = 'CT'
GROUP BY provider_type
ORDER BY total_est_payment DESC
LIMIT 15;

-- 9) High-volume outlier candidates
WITH combo_summary AS (
    SELECT
        provider_type,
        hcpcs_code,
        hcpcs_desc,
        ROUND(SUM(total_services), 0) AS total_services,
        SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0) AS combo_std_payment_per_service
    FROM provider_service_clean
    GROUP BY provider_type, hcpcs_code, hcpcs_desc
),
provider_baseline AS (
    SELECT
        provider_type,
        SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0) AS provider_type_baseline
    FROM provider_service_clean
    GROUP BY provider_type
)
SELECT
    c.provider_type,
    c.hcpcs_code,
    c.hcpcs_desc,
    c.total_services,
    ROUND(c.combo_std_payment_per_service, 2) AS combo_std_payment_per_service,
    ROUND(b.provider_type_baseline, 2) AS provider_type_baseline,
    ROUND(c.combo_std_payment_per_service - b.provider_type_baseline, 2) AS above_baseline
FROM combo_summary c
JOIN provider_baseline b
  ON c.provider_type = b.provider_type
WHERE c.total_services >= 1000
ORDER BY above_baseline DESC, c.total_services DESC
LIMIT 20;
