-- ============================================================
-- Medicare Payment Intelligence Dashboard
-- File: sql/06_data_quality_audit.sql
-- Purpose: Quick quality and modeling audit for portfolio proof
-- ============================================================

USE medicare_analysis;

-- 1) Row retention after cleaning
SELECT
    (SELECT COUNT(*) FROM provider_service_raw) AS raw_rows,
    (SELECT COUNT(*) FROM provider_service_clean) AS clean_rows,
    ROUND(100 * (SELECT COUNT(*) FROM provider_service_clean) / NULLIF((SELECT COUNT(*) FROM provider_service_raw), 0), 2) AS pct_retained;

-- 2) Potential duplicate business keys
SELECT
    provider_npi,
    hcpcs_code,
    place_of_service,
    provider_state,
    COUNT(*) AS duplicate_rows
FROM provider_service_clean
GROUP BY provider_npi, hcpcs_code, place_of_service, provider_state
HAVING COUNT(*) > 1
ORDER BY duplicate_rows DESC
LIMIT 25;

-- 3) Null / blank audit for core reporting fields
SELECT
    SUM(CASE WHEN provider_state IS NULL OR provider_state = '' THEN 1 ELSE 0 END) AS missing_state_rows,
    SUM(CASE WHEN provider_type IS NULL OR provider_type = '' THEN 1 ELSE 0 END) AS missing_provider_type_rows,
    SUM(CASE WHEN hcpcs_code IS NULL OR hcpcs_code = '' THEN 1 ELSE 0 END) AS missing_hcpcs_rows,
    SUM(CASE WHEN place_of_service IS NULL OR place_of_service = '' THEN 1 ELSE 0 END) AS missing_pos_rows,
    SUM(CASE WHEN total_services IS NULL OR total_services <= 0 THEN 1 ELSE 0 END) AS invalid_service_rows
FROM provider_service_clean;

-- 4) Largest provider types by standardized payment share
SELECT
    provider_type,
    ROUND(SUM(est_total_standardized_payment), 2) AS total_est_standardized_payment,
    ROUND(100 * SUM(est_total_standardized_payment) / NULLIF((SELECT SUM(est_total_standardized_payment) FROM provider_service_clean), 0), 2) AS payment_share_pct
FROM provider_service_clean
GROUP BY provider_type
ORDER BY total_est_standardized_payment DESC
LIMIT 15;

-- 5) State coverage sanity check
SELECT
    provider_state,
    COUNT(*) AS rows_in_state,
    ROUND(SUM(total_services), 0) AS total_services,
    ROUND(SUM(est_total_standardized_payment), 2) AS total_est_standardized_payment
FROM provider_service_clean
GROUP BY provider_state
ORDER BY total_est_standardized_payment DESC
LIMIT 15;
