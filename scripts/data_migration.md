# Data Migration
The Access data need uploaded to the MS SQL server for us to start working with it. To achieve this first I need:

### Prerequsites
1. **Microsoft SQL server Databae**
- I spin a docker this server in a docker container:

```bash
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=dM758099130!" \
  -p 1433:1433 --name mssql_server \
  -v mssql_data:/var/opt/mssql \
  -d mcr.microsoft.com/mssql/server:2022-latest
```

2. **MS SQL Server Access Client:**
- Since I'm running on Linux machine, I went with **Azure Data Studio**.

Infrastructure is set:

Next, to load data to the database, first I needed to extract them into csv files, using mdb package I installed.

```bash
# Extract CSV files from the accdb
mdb-export -D '%m/%d/%Y %I:%M:%S' -Q registration.accdb dim_crop > dim_crop.csv
mdb-export -D '%m/%d/%Y %I:%M:%S' -Q registration.accdb dim_license > dim_license.csv
mdb-export -D '%m/%d/%Y %I:%M:%S' -Q registration.accdb dim_member > dim_member.csv
mdb-export -D '%m/%d/%Y %I:%M:%S' -Q registration.accdb dim_site > dim_site.csv
mdb-export -D '%m/%d/%Y %I:%M:%S' -Q registration.accdb fct_registration > fct_registration.csv
mdb-export -D '%m/%d/%Y %I:%M:%S' -Q registration.accdb dim_farm > dim_farm.csv
```

### Verification No Data Lose
- I connected to `registration.accdb` database and count records for each table:

```bash
$ mdb-sql registration.accdb
1 => select count(*) from dim_crop;
+------------------------------+
|count                         |
+------------------------------+
|215                           |
+------------------------------+
1 Row retrieved
1 => select count(*) from dim_license;
+------------------------------+
|count                         |
+------------------------------+
|271                           |
+------------------------------+
1 Row retrieved
1 => select count(*) from dim_member;
+------------------------------+
|count                         |
+------------------------------+
|200                           |
+------------------------------+
1 Row retrieved
1 => select count(*) from dim_site;
+------------------------------+
|count                         |
+------------------------------+
|1806                          |
+------------------------------+
1 Row retrieved
1 => select count(*) from fct_registration;
+------------------------------+
|count                         |
+------------------------------+
|8869                          |
+------------------------------+
1 Row retrieved
1 => select count(*) from dim_farm;
+------------------------------+
|count                         |
+------------------------------+
|5658                          |
+------------------------------+
1 Row retrieved
1 => 
```

Also, I counted records in each csv extracted:

```bash
# wc each file:
for f in dim_crop.csv dim_license.csv dim_member.csv dim_site.csv fct_registration.csv dim_farm.csv; do
  total=$(wc -l < "$f")
  data_rows=$((total - 1))
  echo "$f: $data_rows data rows"
done

# Expected output
dim_crop.csv: 215 data rows
dim_license.csv: 271 data rows
dim_member.csv: 200 data rows
dim_site.csv: 1806 data rows
fct_registration.csv: 8869 data rows
dim_farm.csv: 5658 data rows
```

By record count, no data was lost. Also we have 5 dimensional tables and one fact tables, which we will use to create insights. The data is already modeled following star schema as represente in the diagram below:

![]()

To start working with the data, I had to, first load it into the MS SQL server docker container file system, from where I loaded it into the database running inside the contianer.

```bash
# Copying data into the MS SQL server container
docker cp dim_crop.csv mssql_server:/var/opt/mssql/
docker cp dim_license.csv mssql_server:/var/opt/mssql/
docker cp dim_member.csv mssql_server:/var/opt/mssql/
docker cp dim_site.csv mssql_server:/var/opt/mssql/
docker cp fct_registration.csv mssql_server:/var/opt/mssql/
docker cp dim_farm.csv mssql_server:/var/opt/mssql/
```

Connected to the MS SQL serever database with `Azure Data Studio` client, I run the following init script to create database, create schema, ddl, and load data into appropraite tables:

```sql
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

--==========================
-- Take a Look at the data
--==========================
SELECT * FROM gold.dim_crop;
SELECT count(*) FROM gold.dim_crop;

SELECT * FROM gold.dim_license;
SELECT count(*) FROM gold.dim_license;

SELECT * FROM gold.dim_member;
SELECT count(*) FROM gold.dim_member;

SELECT * FROM gold.dim_site;
SELECT count(*) FROM gold.dim_site;

SELECT * FROM gold.fct_registration;
SELECT count(*) FROM gold.fct_registration;

SELECT * FROM gold.dim_farm;
SELECT count(*) FROM gold.dim_farm;
```

- Verfy the count is the same as the one on the source system:

### Data is loaded
Now we start the project!!!
