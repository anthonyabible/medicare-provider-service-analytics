-- ============================================================
-- Medicare Payment Intelligence Dashboard
-- File: sql/02_clean_and_validate.sql
-- Purpose: Validate import quality and build typed analytical table
-- ============================================================

USE medicare_analysis;

DROP TABLE IF EXISTS load_metadata;
CREATE TABLE load_metadata (
    load_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    source_filename VARCHAR(255),
    source_year SMALLINT NOT NULL,
    raw_row_count BIGINT,
    clean_row_count BIGINT,
    pct_retained DECIMAL(8,2),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- 1) Raw import checks
-- ------------------------------------------------------------
SELECT COUNT(*) AS raw_rows
FROM provider_service_raw;

SELECT
    SUM(CASE WHEN NULLIF(TRIM(Rndrng_NPI), '') IS NULL THEN 1 ELSE 0 END) AS missing_npi_rows,
    SUM(CASE WHEN NULLIF(TRIM(Rndrng_Prvdr_State_Abrvtn), '') IS NULL THEN 1 ELSE 0 END) AS missing_state_rows,
    SUM(CASE WHEN NULLIF(TRIM(Rndrng_Prvdr_Type), '') IS NULL THEN 1 ELSE 0 END) AS missing_provider_type_rows,
    SUM(CASE WHEN NULLIF(TRIM(HCPCS_Cd), '') IS NULL THEN 1 ELSE 0 END) AS missing_hcpcs_rows,
    SUM(CASE WHEN NULLIF(TRIM(Avg_Mdcr_Pymt_Amt), '') IS NULL THEN 1 ELSE 0 END) AS missing_payment_rows
FROM provider_service_raw;

SELECT Avg_Mdcr_Pymt_Amt, COUNT(*) AS row_count
FROM provider_service_raw
WHERE Avg_Mdcr_Pymt_Amt IS NOT NULL
  AND TRIM(Avg_Mdcr_Pymt_Amt) <> ''
  AND TRIM(Avg_Mdcr_Pymt_Amt) NOT REGEXP '^-?[0-9]+(\.[0-9]+)?$'
GROUP BY Avg_Mdcr_Pymt_Amt
ORDER BY row_count DESC
LIMIT 25;

DROP TABLE IF EXISTS provider_service_clean;

CREATE TABLE provider_service_clean (
    row_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    source_year SMALLINT NOT NULL,
    provider_npi CHAR(10),
    provider_last_org_name VARCHAR(255),
    provider_first_name VARCHAR(255),
    provider_mi VARCHAR(20),
    provider_credentials VARCHAR(50),
    provider_entity_code VARCHAR(10),
    provider_address_1 VARCHAR(255),
    provider_address_2 VARCHAR(255),
    provider_city VARCHAR(100),
    provider_state VARCHAR(10),
    provider_state_fips VARCHAR(10),
    provider_zip5 CHAR(5),
    provider_ruca VARCHAR(20),
    provider_ruca_desc VARCHAR(255),
    provider_country VARCHAR(10),
    provider_type VARCHAR(255),
    medicare_participating_ind VARCHAR(10),
    hcpcs_code VARCHAR(20),
    hcpcs_desc VARCHAR(255),
    hcpcs_drug_ind VARCHAR(10),
    place_of_service VARCHAR(20),
    total_beneficiaries BIGINT UNSIGNED,
    total_services DECIMAL(18,2),
    total_bene_day_services DECIMAL(18,2),
    avg_submitted_charge DECIMAL(18,4),
    avg_medicare_allowed_amount DECIMAL(18,4),
    avg_medicare_payment_amount DECIMAL(18,4),
    avg_medicare_standardized_amount DECIMAL(18,4),
    est_total_medicare_payment DECIMAL(22,4),
    est_total_standardized_payment DECIMAL(22,4),
    est_total_submitted_charge DECIMAL(22,4),
    submitted_to_payment_ratio DECIMAL(18,6),
    payment_to_standardized_ratio DECIMAL(18,6),
    drug_group VARCHAR(20)
);

INSERT INTO provider_service_clean (
    source_year, provider_npi, provider_last_org_name, provider_first_name, provider_mi,
    provider_credentials, provider_entity_code, provider_address_1, provider_address_2,
    provider_city, provider_state, provider_state_fips, provider_zip5, provider_ruca,
    provider_ruca_desc, provider_country, provider_type, medicare_participating_ind,
    hcpcs_code, hcpcs_desc, hcpcs_drug_ind, place_of_service, total_beneficiaries,
    total_services, total_bene_day_services, avg_submitted_charge,
    avg_medicare_allowed_amount, avg_medicare_payment_amount,
    avg_medicare_standardized_amount, est_total_medicare_payment,
    est_total_standardized_payment, est_total_submitted_charge,
    submitted_to_payment_ratio, payment_to_standardized_ratio, drug_group
)
SELECT
    2023,
    LPAD(TRIM(Rndrng_NPI), 10, '0'),
    NULLIF(TRIM(Rndrng_Prvdr_Last_Org_Name), ''),
    NULLIF(TRIM(Rndrng_Prvdr_First_Name), ''),
    NULLIF(TRIM(Rndrng_Prvdr_MI), ''),
    NULLIF(TRIM(Rndrng_Prvdr_Crdntls), ''),
    NULLIF(TRIM(Rndrng_Prvdr_Ent_Cd), ''),
    NULLIF(TRIM(Rndrng_Prvdr_St1), ''),
    NULLIF(TRIM(Rndrng_Prvdr_St2), ''),
    NULLIF(TRIM(Rndrng_Prvdr_City), ''),
    NULLIF(TRIM(Rndrng_Prvdr_State_Abrvtn), ''),
    NULLIF(TRIM(Rndrng_Prvdr_State_FIPS), ''),
    LPAD(TRIM(Rndrng_Prvdr_Zip5), 5, '0'),
    NULLIF(TRIM(Rndrng_Prvdr_RUCA), ''),
    NULLIF(TRIM(Rndrng_Prvdr_RUCA_Desc), ''),
    NULLIF(TRIM(Rndrng_Prvdr_Cntry), ''),
    NULLIF(TRIM(Rndrng_Prvdr_Type), ''),
    NULLIF(TRIM(Rndrng_Prvdr_Mdcr_Prtcptg_Ind), ''),
    NULLIF(TRIM(HCPCS_Cd), ''),
    NULLIF(TRIM(HCPCS_Desc), ''),
    NULLIF(TRIM(HCPCS_Drug_Ind), ''),
    CASE
        WHEN TRIM(Place_Of_Srvc) = 'F' THEN 'Facility'
        WHEN TRIM(Place_Of_Srvc) = 'O' THEN 'Non-Facility'
        ELSE NULLIF(TRIM(Place_Of_Srvc), '')
    END,
    CAST(NULLIF(TRIM(Tot_Benes), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(Tot_Srvcs), '') AS DECIMAL(18,2)),
    CAST(NULLIF(TRIM(Tot_Bene_Day_Srvcs), '') AS DECIMAL(18,2)),
    CAST(NULLIF(TRIM(Avg_Sbmtd_Chrg), '') AS DECIMAL(18,4)),
    CAST(NULLIF(TRIM(Avg_Mdcr_Alowd_Amt), '') AS DECIMAL(18,4)),
    CAST(NULLIF(TRIM(Avg_Mdcr_Pymt_Amt), '') AS DECIMAL(18,4)),
    CAST(NULLIF(TRIM(Avg_Mdcr_Stdzd_Amt), '') AS DECIMAL(18,4)),
    CAST(NULLIF(TRIM(Tot_Srvcs), '') AS DECIMAL(18,2)) * CAST(NULLIF(TRIM(Avg_Mdcr_Pymt_Amt), '') AS DECIMAL(18,4)),
    CAST(NULLIF(TRIM(Tot_Srvcs), '') AS DECIMAL(18,2)) * CAST(NULLIF(TRIM(Avg_Mdcr_Stdzd_Amt), '') AS DECIMAL(18,4)),
    CAST(NULLIF(TRIM(Tot_Srvcs), '') AS DECIMAL(18,2)) * CAST(NULLIF(TRIM(Avg_Sbmtd_Chrg), '') AS DECIMAL(18,4)),
    CASE
        WHEN CAST(NULLIF(TRIM(Avg_Mdcr_Pymt_Amt), '') AS DECIMAL(18,4)) > 0 THEN
            CAST(NULLIF(TRIM(Avg_Sbmtd_Chrg), '') AS DECIMAL(18,4)) /
            CAST(NULLIF(TRIM(Avg_Mdcr_Pymt_Amt), '') AS DECIMAL(18,4))
        ELSE NULL
    END,
    CASE
        WHEN CAST(NULLIF(TRIM(Avg_Mdcr_Stdzd_Amt), '') AS DECIMAL(18,4)) > 0 THEN
            CAST(NULLIF(TRIM(Avg_Mdcr_Pymt_Amt), '') AS DECIMAL(18,4)) /
            CAST(NULLIF(TRIM(Avg_Mdcr_Stdzd_Amt), '') AS DECIMAL(18,4))
        ELSE NULL
    END,
    CASE WHEN TRIM(HCPCS_Drug_Ind) = 'Y' THEN 'Drug' ELSE 'Non-Drug' END
FROM provider_service_raw
WHERE NULLIF(TRIM(Rndrng_NPI), '') IS NOT NULL
  AND NULLIF(TRIM(HCPCS_Cd), '') IS NOT NULL
  AND NULLIF(TRIM(Rndrng_Prvdr_Type), '') IS NOT NULL
  AND NULLIF(TRIM(Avg_Mdcr_Pymt_Amt), '') IS NOT NULL
  AND TRIM(Avg_Mdcr_Pymt_Amt) REGEXP '^-?[0-9]+(\.[0-9]+)?$'
  AND CAST(NULLIF(TRIM(Avg_Mdcr_Pymt_Amt), '') AS DECIMAL(18,4)) > 0
  AND NULLIF(TRIM(Tot_Srvcs), '') IS NOT NULL
  AND TRIM(Tot_Srvcs) REGEXP '^-?[0-9]+(\.[0-9]+)?$'
  AND CAST(NULLIF(TRIM(Tot_Srvcs), '') AS DECIMAL(18,2)) > 0;

ALTER TABLE provider_service_clean
    ADD INDEX idx_state (provider_state),
    ADD INDEX idx_provider_type (provider_type(100)),
    ADD INDEX idx_hcpcs (hcpcs_code),
    ADD INDEX idx_pos (place_of_service),
    ADD INDEX idx_drug_group (drug_group),
    ADD INDEX idx_state_provider_type (provider_state, provider_type(100)),
    ADD INDEX idx_state_hcpcs (provider_state, hcpcs_code),
    ADD INDEX idx_source_year (source_year),
    ADD INDEX idx_provider_npi (provider_npi);

INSERT INTO load_metadata (source_filename, source_year, raw_row_count, clean_row_count, pct_retained)
SELECT
    'MUP_PHY_R25_P05_V20_D23_Prov_Svc.csv',
    2023,
    (SELECT COUNT(*) FROM provider_service_raw),
    (SELECT COUNT(*) FROM provider_service_clean),
    ROUND(100 * (SELECT COUNT(*) FROM provider_service_clean) / NULLIF((SELECT COUNT(*) FROM provider_service_raw), 0), 2);

-- ------------------------------------------------------------
-- 2) Post-clean quality checks
-- ------------------------------------------------------------
SELECT COUNT(*) AS clean_rows
FROM provider_service_clean;

SELECT
    ROUND(100 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM provider_service_raw), 0), 2) AS pct_of_raw_rows_retained
FROM provider_service_clean;

SELECT
    SUM(CASE WHEN provider_state IS NULL OR provider_state = '' THEN 1 ELSE 0 END) AS clean_missing_state_rows,
    SUM(CASE WHEN provider_type IS NULL OR provider_type = '' THEN 1 ELSE 0 END) AS clean_missing_provider_type_rows,
    SUM(CASE WHEN hcpcs_code IS NULL OR hcpcs_code = '' THEN 1 ELSE 0 END) AS clean_missing_hcpcs_rows,
    SUM(CASE WHEN total_services IS NULL OR total_services <= 0 THEN 1 ELSE 0 END) AS clean_invalid_service_rows
FROM provider_service_clean;

SELECT * FROM load_metadata ORDER BY load_id DESC LIMIT 1;
