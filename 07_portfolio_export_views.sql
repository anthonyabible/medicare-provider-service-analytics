-- ============================================================
-- File: sql/07_portfolio_export_views.sql
-- Purpose: Build focused views that are fast to consume in Power BI
-- ============================================================

USE medicare_analysis;

DROP VIEW IF EXISTS vw_dashboard_ct_vs_national;
CREATE VIEW vw_dashboard_ct_vs_national AS
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
    ROUND(c.ct_std_payment_per_service - n.national_std_payment_per_service, 2) AS ct_minus_national,
    ROUND((c.ct_std_payment_per_service / NULLIF(n.national_std_payment_per_service, 0) - 1) * 100, 2) AS pct_diff
FROM connecticut c
CROSS JOIN national n;

DROP VIEW IF EXISTS vw_dashboard_provider_type_top15;
CREATE VIEW vw_dashboard_provider_type_top15 AS
SELECT *
FROM vw_dashboard_provider_type_summary
ORDER BY total_est_payment DESC
LIMIT 15;

DROP VIEW IF EXISTS vw_dashboard_hcpcs_top15;
CREATE VIEW vw_dashboard_hcpcs_top15 AS
SELECT *
FROM vw_dashboard_hcpcs_summary
ORDER BY total_est_payment DESC
LIMIT 15;

DROP VIEW IF EXISTS vw_dashboard_provider_hcpcs_top_outliers;
CREATE VIEW vw_dashboard_provider_hcpcs_top_outliers AS
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
LIMIT 25;
