-- ============================================================
-- Medicare Payment Intelligence Dashboard
-- File: sql/04_dashboard_views.sql
-- Purpose: Build Power BI-ready views
-- ============================================================

USE medicare_analysis;

DROP VIEW IF EXISTS vw_dashboard_kpis;
CREATE VIEW vw_dashboard_kpis AS
SELECT
    COUNT(*) AS records,
    COUNT(DISTINCT provider_npi) AS distinct_providers,
    COUNT(DISTINCT provider_state) AS distinct_states,
    COUNT(DISTINCT provider_type) AS distinct_provider_types,
    COUNT(DISTINCT hcpcs_code) AS distinct_hcpcs_codes,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment,
    ROUND(SUM(est_total_standardized_payment), 2) AS total_est_standardized_payment,
    ROUND(SUM(total_services), 0) AS total_services,
    ROUND(SUM(total_beneficiaries), 0) AS total_beneficiaries,
    ROUND(SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0), 2) AS std_payment_per_service
FROM provider_service_clean;

DROP VIEW IF EXISTS vw_dashboard_provider_type_summary;
CREATE VIEW vw_dashboard_provider_type_summary AS
SELECT
    provider_type,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment,
    ROUND(SUM(est_total_standardized_payment), 2) AS total_est_standardized_payment,
    ROUND(SUM(total_services), 0) AS total_services,
    ROUND(SUM(total_beneficiaries), 0) AS total_beneficiaries,
    ROUND(SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0), 2) AS std_payment_per_service,
    ROUND(SUM(est_total_medicare_payment) / NULLIF(SUM(total_services), 0), 2) AS payment_per_service
FROM provider_service_clean
GROUP BY provider_type;

DROP VIEW IF EXISTS vw_dashboard_hcpcs_summary;
CREATE VIEW vw_dashboard_hcpcs_summary AS
SELECT
    hcpcs_code,
    hcpcs_desc,
    drug_group,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment,
    ROUND(SUM(est_total_standardized_payment), 2) AS total_est_standardized_payment,
    ROUND(SUM(total_services), 0) AS total_services,
    ROUND(SUM(total_beneficiaries), 0) AS total_beneficiaries,
    ROUND(SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0), 2) AS std_payment_per_service,
    ROUND(SUM(est_total_medicare_payment) / NULLIF(SUM(total_services), 0), 2) AS payment_per_service
FROM provider_service_clean
GROUP BY hcpcs_code, hcpcs_desc, drug_group;

DROP VIEW IF EXISTS vw_dashboard_pos_summary;
CREATE VIEW vw_dashboard_pos_summary AS
SELECT
    place_of_service,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment,
    ROUND(SUM(est_total_standardized_payment), 2) AS total_est_standardized_payment,
    ROUND(SUM(total_services), 0) AS total_services,
    ROUND(SUM(total_beneficiaries), 0) AS total_beneficiaries,
    ROUND(SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0), 2) AS std_payment_per_service
FROM provider_service_clean
GROUP BY place_of_service;

DROP VIEW IF EXISTS vw_dashboard_state_summary;
CREATE VIEW vw_dashboard_state_summary AS
SELECT
    provider_state,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment,
    ROUND(SUM(est_total_standardized_payment), 2) AS total_est_standardized_payment,
    ROUND(SUM(total_services), 0) AS total_services,
    ROUND(SUM(total_beneficiaries), 0) AS total_beneficiaries,
    ROUND(SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0), 2) AS std_payment_per_service,
    ROUND(SUM(est_total_medicare_payment) / NULLIF(SUM(total_services), 0), 2) AS payment_per_service
FROM provider_service_clean
GROUP BY provider_state;

DROP VIEW IF EXISTS vw_dashboard_state_ranked;
CREATE VIEW vw_dashboard_state_ranked AS
SELECT
    provider_state,
    total_est_payment,
    total_est_standardized_payment,
    total_services,
    total_beneficiaries,
    std_payment_per_service,
    payment_per_service,
    RANK() OVER (ORDER BY std_payment_per_service DESC) AS std_payment_rank
FROM vw_dashboard_state_summary;

DROP VIEW IF EXISTS vw_dashboard_ct_spotlight;
CREATE VIEW vw_dashboard_ct_spotlight AS
SELECT
    provider_type,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment,
    ROUND(SUM(est_total_standardized_payment), 2) AS total_est_standardized_payment,
    ROUND(SUM(total_services), 0) AS total_services,
    ROUND(SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0), 2) AS std_payment_per_service
FROM provider_service_clean
WHERE provider_state = 'CT'
GROUP BY provider_type;

DROP VIEW IF EXISTS vw_dashboard_provider_hcpcs_combo;
CREATE VIEW vw_dashboard_provider_hcpcs_combo AS
SELECT
    provider_type,
    hcpcs_code,
    hcpcs_desc,
    drug_group,
    ROUND(SUM(est_total_medicare_payment), 2) AS total_est_payment,
    ROUND(SUM(est_total_standardized_payment), 2) AS total_est_standardized_payment,
    ROUND(SUM(total_services), 0) AS total_services,
    ROUND(SUM(est_total_standardized_payment) / NULLIF(SUM(total_services), 0), 2) AS std_payment_per_service
FROM provider_service_clean
GROUP BY provider_type, hcpcs_code, hcpcs_desc, drug_group;

DROP VIEW IF EXISTS vw_fact_provider_service;
CREATE VIEW vw_fact_provider_service AS
SELECT
    row_id,
    source_year,
    provider_state,
    provider_type,
    hcpcs_code,
    place_of_service,
    drug_group,
    total_beneficiaries,
    total_services,
    total_bene_day_services,
    avg_submitted_charge,
    avg_medicare_allowed_amount,
    avg_medicare_payment_amount,
    avg_medicare_standardized_amount,
    est_total_medicare_payment,
    est_total_standardized_payment,
    est_total_submitted_charge,
    submitted_to_payment_ratio,
    payment_to_standardized_ratio
FROM provider_service_clean;

DROP VIEW IF EXISTS vw_dim_state;
CREATE VIEW vw_dim_state AS
SELECT DISTINCT provider_state, provider_state_fips, provider_country
FROM provider_service_clean
WHERE provider_state IS NOT NULL AND provider_state <> '';

DROP VIEW IF EXISTS vw_dim_provider_type;
CREATE VIEW vw_dim_provider_type AS
SELECT DISTINCT provider_type, medicare_participating_ind
FROM provider_service_clean
WHERE provider_type IS NOT NULL AND provider_type <> '';

DROP VIEW IF EXISTS vw_dim_hcpcs;
CREATE VIEW vw_dim_hcpcs AS
SELECT DISTINCT hcpcs_code, hcpcs_desc, hcpcs_drug_ind, drug_group
FROM provider_service_clean
WHERE hcpcs_code IS NOT NULL AND hcpcs_code <> '';

DROP VIEW IF EXISTS vw_dim_place_of_service;
CREATE VIEW vw_dim_place_of_service AS
SELECT DISTINCT place_of_service
FROM provider_service_clean
WHERE place_of_service IS NOT NULL AND place_of_service <> '';
