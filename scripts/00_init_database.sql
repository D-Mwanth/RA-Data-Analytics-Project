/*
=============================================================
Create and Load Database: ra_registration_db
=============================================================

Script Purpose:
    This script creates a new database 'ra_registration_db'.
    If it exists, it is dropped and recreated.
    All tables are created in the 'gold' schema.
    Data is loaded using BULK INSERT from CSV files.

WARNING:
    Running this will delete all existing data in the database.
    Ensure proper backups before executing.
*/

USE master;
GO

-- Drop and recreate the database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'ra_registration_db')
BEGIN
    ALTER DATABASE ra_registration_db SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ra_registration_db;
END;
GO

CREATE DATABASE ra_registration_db;
GO

USE ra_registration_db;
GO

-- ===============================
-- Create schema
-- ===============================

CREATE SCHEMA gold;
GO

-- ===============================
-- Create Tables
-- ===============================

CREATE TABLE gold.dim_crop (
    dim_crop_id NVARCHAR(255),
    dim_source NVARCHAR(255),
    dim_load_date DATETIME,
    crop NVARCHAR(255)
);
GO

CREATE TABLE gold.dim_license (
    dim_license_id NVARCHAR(255),
    dim_source NVARCHAR(255),
    dim_load_date DATETIME,
    license_id NVARCHAR(255),
    certificationoption NVARCHAR(255),
    gmr_download_status NVARCHAR(255),
    date_requirements_viewed NVARCHAR(255),
    date_selfassessment_uploaded NVARCHAR(255),
    date_gmr_uploaded NVARCHAR(255),
    contract_sign_status NVARCHAR(255),
    date_contract_signed NVARCHAR(255),
    license_type NVARCHAR(255),
    license_status NVARCHAR(255),
    license_standard NVARCHAR(255),
    start_date_license NVARCHAR(255),
    end_date_license NVARCHAR(255),
    original_end_date NVARCHAR(255),
    legalagreementchecked NVARCHAR(255),
    scheme_owner NVARCHAR(255),
    license_year NVARCHAR(255)
);
GO

CREATE TABLE gold.dim_member (
    dim_member_id NVARCHAR(255),
    dim_source NVARCHAR(255),
    dim_load_date DATETIME,
    member_id NVARCHAR(255),
    member_name NVARCHAR(255),
    country NVARCHAR(255),
    region NVARCHAR(255),
    tandc_version NVARCHAR(255),
    tandc_type NVARCHAR(255),
    tandc_signdate DATETIME,
    date_registered DATETIME,
    date_validated DATETIME
);
GO

CREATE TABLE gold.dim_site (
    dim_site_id NVARCHAR(255),
    dim_source NVARCHAR(255),
    dim_load_date DATETIME,
    site_name NVARCHAR(255),
    on_sitehousing NVARCHAR(255),
    createdon DATETIME,
    updatedon DATETIME,
    verificationlevel NVARCHAR(255),
    visiting_country NVARCHAR(255),
    visiting_region NVARCHAR(255),
    is_certification_scope NVARCHAR(255)
);
GO

CREATE TABLE gold.dim_farm (
    dim_farm_id NVARCHAR(255),
    dim_source NVARCHAR(255),
    dim_load_date DATETIME,
    farm_name NVARCHAR(255),
    farmtype NVARCHAR(255),
    totalareainha NVARCHAR(255),
    firstyearofcertification INT,
    on_sitehousing NVARCHAR(255),
    createdon DATETIME,
    updatedon DATETIME,
    is_certification_scope NVARCHAR(255)
);
GO

CREATE TABLE gold.fct_registration (
    fact_registration_id NVARCHAR(255),
    fact_source NVARCHAR(255),
    fact_load_date DATETIME,
    dim_member_id NVARCHAR(255),
    dim_license_id NVARCHAR(255),
    dim_crop_id NVARCHAR(255),
    dim_site_id NVARCHAR(255),
    dim_farm_id NVARCHAR(255),
    date_crop_registered DATETIME
);
GO

-- ===============================
-- Data Load Section
-- ===============================

-- dim_crop
TRUNCATE TABLE gold.dim_crop;
GO
BULK INSERT gold.dim_crop
FROM '/var/opt/mssql/dim_crop.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- dim_license
TRUNCATE TABLE gold.dim_license;
GO
BULK INSERT gold.dim_license
FROM '/var/opt/mssql/dim_license.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- dim_member
TRUNCATE TABLE gold.dim_member;
GO
BULK INSERT gold.dim_member
FROM '/var/opt/mssql/dim_member.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- dim_site
TRUNCATE TABLE gold.dim_site;
GO
BULK INSERT gold.dim_site
FROM '/var/opt/mssql/dim_site.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- dim_farm
TRUNCATE TABLE gold.dim_farm;
GO
BULK INSERT gold.dim_farm
FROM '/var/opt/mssql/dim_farm.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- fct_registration
TRUNCATE TABLE gold.fct_registration;
GO
BULK INSERT gold.fct_registration
FROM '/var/opt/mssql/fct_registration.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO