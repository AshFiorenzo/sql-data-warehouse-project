/*
===============================================================================
Purpose: Initialize the Data Warehouse Database
===============================================================================
This script creates the 'datawarehouse' database and sets up three schemas
to support the Medallion Architecture:
    - bronze: Stores raw data ingested from source systems.
    - silver: Stores cleaned and transformed data.
    - gold:   Stores business-ready data for reporting and analytics.
===============================================================================
*/

CREATE database datawarehouse;

show databases; --check if the database creation is successful. 

USE datawarehouse; 

-- Connect to the 'datawarehouse' database before executing the statements below.

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;