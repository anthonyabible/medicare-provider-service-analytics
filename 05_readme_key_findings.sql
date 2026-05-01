-- ============================================================
-- Medicare Payment Intelligence Dashboard
-- File: sql/05_readme_key_findings.sql
-- Purpose: Pull the exact outputs needed for the README
-- ============================================================

USE medicare_analysis;

-- 1) Overall volume and dollars
SELECT
    COUNT(*) AS records,
    COUNT(DISTINCT provider_npi) AS providers,
    COUNT(DISTINCT provider_state) AS states,
    COUNT(DISTINCT hcpcs_code) AS hcpcs_codes,
    ROUND(SUM(est_total_medicare_payment) / 1000000000, 2) AS total_est_medicare_payment_billions,
    ROUND(SUM(est_total_standardized_payment) / 1000000000, 2) AS total_est_standardized_payment_billions
FROM provider_service_clean;

-- 2) Connecticut vs national
WITH national AS (
    SELECT SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0) AS national_std_payment_per_service
    FROM provider_service_clean
),
connecticut AS (
    SELECT SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0) AS ct_std_payment_per_service
    FROM provider_service_clean
    WHERE provider_state = 'CT'
)
SELECT
    ROUND(c.ct_std_payment_per_service, 2) AS ct_std_payment_per_service,
    ROUND(n.national_std_payment_per_service, 2) AS national_std_payment_per_service,
    ROUND((c.ct_std_payment_per_service / NULLIF(n.national_std_payment_per_service, 0) - 1) * 100, 2) AS pct_diff
FROM connecticut c
CROSS JOIN national n;

-- 3) Connecticut state rank
SELECT
    provider_state,
    std_payment_rank,
    std_payment_per_service
FROM (
    SELECT
        provider_state,
        ROUND(SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0), 2) AS std_payment_per_service,
        RANK() OVER (ORDER BY SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0) DESC) AS std_payment_rank
    FROM provider_service_clean
    GROUP BY provider_state
) ranked
WHERE provider_state = 'CT';

-- 4) Top provider type nationally
SELECT
    provider_type,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment
FROM provider_service_clean
GROUP BY provider_type
ORDER BY total_est_payment DESC
LIMIT 1;

-- 5) Top HCPCS nationally
SELECT
    hcpcs_code,
    hcpcs_desc,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment
FROM provider_service_clean
GROUP BY hcpcs_code, hcpcs_desc
ORDER BY total_est_payment DESC
LIMIT 1;

-- 6) Drug share
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

-- 7) Higher standardized-payment setting
SELECT
    place_of_service,
    ROUND(SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0), 2) AS std_payment_per_service
FROM provider_service_clean
GROUP BY place_of_service
ORDER BY std_payment_per_service DESC;

-- 8) Top Connecticut provider type
SELECT
    provider_type,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment
FROM provider_service_clean
WHERE provider_state = 'CT'
GROUP BY provider_type
ORDER BY total_est_payment DESC
LIMIT 1;

-- 9) Most notable high-volume outlier candidate
WITH combo_summary AS (
    SELECT
        provider_type,
        hcpcs_code,
        hcpcs_desc,
        SUM(total_services) AS total_services,
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
    ROUND(c.total_services, 0) AS total_services,
    ROUND(c.combo_std_payment_per_service, 2) AS combo_std_payment_per_service,
    ROUND(b.provider_type_baseline, 2) AS provider_type_baseline,
    ROUND(c.combo_std_payment_per_service - b.provider_type_baseline, 2) AS above_baseline
FROM combo_summary c
JOIN provider_baseline b
  ON c.provider_type = b.provider_type
WHERE c.total_services >= 1000
ORDER BY above_baseline DESC, c.total_services DESC
LIMIT 1;
