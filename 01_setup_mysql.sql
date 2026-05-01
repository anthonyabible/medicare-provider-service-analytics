-- ============================================================
-- Medicare Payment Intelligence Dashboard
-- File: sql/01_setup_mysql.sql
-- Purpose: Create database and raw staging table
-- Target: MySQL 8+
-- ============================================================

DROP DATABASE IF EXISTS medicare_analysis;
CREATE DATABASE medicare_analysis
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE medicare_analysis;

DROP TABLE IF EXISTS provider_service_raw;

CREATE TABLE provider_service_raw (
    Rndrng_NPI VARCHAR(50),
    Rndrng_Prvdr_Last_Org_Name VARCHAR(255),
    Rndrng_Prvdr_First_Name VARCHAR(255),
    Rndrng_Prvdr_MI VARCHAR(20),
    Rndrng_Prvdr_Crdntls VARCHAR(50),
    Rndrng_Prvdr_Ent_Cd VARCHAR(10),
    Rndrng_Prvdr_St1 VARCHAR(255),
    Rndrng_Prvdr_St2 VARCHAR(255),
    Rndrng_Prvdr_City VARCHAR(100),
    Rndrng_Prvdr_State_Abrvtn VARCHAR(10),
    Rndrng_Prvdr_State_FIPS VARCHAR(10),
    Rndrng_Prvdr_Zip5 VARCHAR(20),
    Rndrng_Prvdr_RUCA VARCHAR(20),
    Rndrng_Prvdr_RUCA_Desc VARCHAR(255),
    Rndrng_Prvdr_Cntry VARCHAR(10),
    Rndrng_Prvdr_Type VARCHAR(255),
    Rndrng_Prvdr_Mdcr_Prtcptg_Ind VARCHAR(10),
    HCPCS_Cd VARCHAR(20),
    HCPCS_Desc VARCHAR(255),
    HCPCS_Drug_Ind VARCHAR(10),
    Place_Of_Srvc VARCHAR(10),
    Tot_Benes VARCHAR(50),
    Tot_Srvcs VARCHAR(50),
    Tot_Bene_Day_Srvcs VARCHAR(50),
    Avg_Sbmtd_Chrg VARCHAR(50),
    Avg_Mdcr_Alowd_Amt VARCHAR(50),
    Avg_Mdcr_Pymt_Amt VARCHAR(50),
    Avg_Mdcr_Stdzd_Amt VARCHAR(50)
);

SELECT COUNT(*) AS imported_rows
FROM provider_service_raw;
