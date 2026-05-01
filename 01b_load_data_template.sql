-- ============================================================
-- File: sql/01b_load_data_template.sql
-- Purpose: Optional SQL-based load for the official CMS CSV
-- Notes:
--   1) Update the file path below to match your machine.
--   2) Enable LOCAL INFILE if needed in MySQL Workbench / server settings.
-- ============================================================

USE medicare_analysis;

TRUNCATE TABLE provider_service_raw;

LOAD DATA LOCAL INFILE '/full/path/to/MUP_PHY_R25_P05_V20_D23_Prov_Svc.csv'
INTO TABLE provider_service_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '
'
IGNORE 1 LINES
(
    Rndrng_NPI,
    Rndrng_Prvdr_Last_Org_Name,
    Rndrng_Prvdr_First_Name,
    Rndrng_Prvdr_MI,
    Rndrng_Prvdr_Crdntls,
    Rndrng_Prvdr_Ent_Cd,
    Rndrng_Prvdr_St1,
    Rndrng_Prvdr_St2,
    Rndrng_Prvdr_City,
    Rndrng_Prvdr_State_Abrvtn,
    Rndrng_Prvdr_State_FIPS,
    Rndrng_Prvdr_Zip5,
    Rndrng_Prvdr_RUCA,
    Rndrng_Prvdr_RUCA_Desc,
    Rndrng_Prvdr_Cntry,
    Rndrng_Prvdr_Type,
    Rndrng_Prvdr_Mdcr_Prtcptg_Ind,
    HCPCS_Cd,
    HCPCS_Desc,
    HCPCS_Drug_Ind,
    Place_Of_Srvc,
    Tot_Benes,
    Tot_Srvcs,
    Tot_Bene_Day_Srvcs,
    Avg_Sbmtd_Chrg,
    Avg_Mdcr_Alowd_Amt,
    Avg_Mdcr_Pymt_Amt,
    Avg_Mdcr_Stdzd_Amt
);

SELECT COUNT(*) AS imported_rows
FROM provider_service_raw;
