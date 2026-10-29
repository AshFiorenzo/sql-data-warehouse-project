-- Script Purpose:
-- This sql file loads data into the 'bronze' schema from external CSV files.
-- It performs the following actions:
-- - Truncates the bronze tables before loading data.
-- - Copy the data from external csv data files to bronze tables.
-- - check whether data insertion is correct by selecting the output from tables. 

-- make sure table is empty before loading data from csv file 
TRUNCATE TABLE bronze.crm_cust_info;

select '=====loading bronze layer=====' as info;

select '=====loading crm csv files=====' as info;

-- load the data from csv file
COPY bronze.crm_cust_info
FROM './01_data_sets/source_crm/cust_info.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

TRUNCATE TABLE bronze.crm_prd_info;
COPY bronze.crm_prd_info
FROM './01_data_sets/source_crm/prd_info.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

TRUNCATE TABLE bronze.crm_sales_details;
COPY bronze.crm_sales_details
FROM './01_data_sets/source_crm/sales_details.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);
select '=====loading erp csv files=====' as info;

TRUNCATE TABLE bronze.erp_CUST_AZ12;
COPY bronze.erp_CUST_AZ12
FROM './01_data_sets/source_erp/CUST_AZ12.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

TRUNCATE TABLE bronze.erp_LOC_A101;
COPY bronze.erp_LOC_A101
FROM './01_data_sets/source_erp/LOC_A101.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

TRUNCATE TABLE bronze.erp_PX_CAT_G1V2;
COPY bronze.erp_PX_CAT_G1V2
FROM './01_data_sets/source_erp/PX_CAT_G1V2.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

-- check if data insertion is in right columns and amount is correct 
select * from bronze.crm_cust_info limit 5;
select count(*) from bronze.crm_cust_info;

select * from bronze.crm_prd_info limit 5;
select count(*) from bronze.crm_prd_info;

select * from bronze.crm_sales_details limit 5;
select count(*) from bronze.crm_sales_details;

select * from bronze.erp_CUST_AZ12 limit 5;
select count(*) from bronze.erp_CUST_AZ12;

select * from bronze.erp_LOC_A101 limit 5;
select count(*) from bronze.erp_LOC_A101;

select * from bronze.erp_PX_CAT_G1V2 limit 5;
select count(*) from bronze.erp_PX_CAT_G1V2;