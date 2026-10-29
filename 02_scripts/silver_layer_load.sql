-- ===============================================================================
-- Purpose: Load and Transform Data into the Silver Layer From Bronze Layer
-- ===============================================================================
-- This script  performs the ETL (Extract, Transform, Load) process to
-- populate the 'silver' schema tables from the 'bronze' schema.
-- First, it extracts raw data from the Bronze layer tables, applies data cleansing
-- and transformation rules, and loads the processed data into the Silver layer tables.
-- Actions Performed:
-- 1. Truncates Silver tables.
-- 2. Transofrm the data. This include:
--     1. Remove duplicate customer records, retaining the most recent entries.
--     2. Trim whitespace and standardize categorical values.
--     3. Handle missing, NULL, and invalid values.
--     4. Standardize date formats and calculate product validity periods.
--     5. Validate and correct sales amounts and prices.
--     6. Standardize customer identifiers across CRM and ERP systems.
--     7. Normalize gender, marital status, product lines, and country names.
-- 3. Insert the cleaned data into silver schema tables. 
-- ===============================================================================

select '===loading silver layer tables===' as info;

select '===loading tables from crm csv files===' as info;
TRUNCATE TABLE silver.crm_cust_info;
INSERT INTO silver.crm_cust_info(cst_id,cst_key,cst_firstname,cst_lastname,cst_marital_status,cst_gndr,cst_create_date)
SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname) as cst_firstname,
    TRIM(cst_lastname) as cst_lastname ,
    CASE 
        WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
        ELSE 'n/a'
    END as cst_material_status,
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        ELSE 'n/a'
    END as cst_gndr,
    cst_create_date,
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
    FROM 
        bronze.crm_cust_info
) 
WHERE flag_last = 1;

TRUNCATE TABLE silver.crm_prd_info;
INSERT INTO silver.crm_prd_info(prd_id,cat_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt)
SELECT 
    prd_id,
    replace(substring(prd_key,1,5),'-','_') as cat_id,
    substring(prd_key,7,len(prd_key)) as prd_key,
    trim(prd_nm) as prd_nm,
    COALESCE(prd_cost,0) as prd_cost,
    CASE upper(trim(prd_line))
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Sales'
        WHEN 'M' THEN 'Mountain'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
    END as prd_line, 
    prd_start_dt::DATE as prd_start_dt,
    (LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL 1 DAY)::DATE as prd_end_dt,
FROM 
    bronze.crm_prd_info;

TRUNCATE TABLE silver.crm_sales_details;
INSERT INTO silver.crm_sales_details(sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,sls_sales,sls_price,sls_quantity)
SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE
        WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::VARCHAR) !=8 THEN NULL 
        ELSE STRPTIME(sls_order_dt::VARCHAR, '%Y%m%d')::DATE
    END as sls_order_dt, 
    CASE
        WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::VARCHAR) !=8 THEN NULL 
        ELSE STRPTIME(sls_ship_dt::VARCHAR, '%Y%m%d')::DATE
    END as sls_ship_dt, 
    CASE
        WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::VARCHAR) !=8 THEN NULL 
        ELSE STRPTIME(sls_due_dt::VARCHAR, '%Y%m%d')::DATE
    END as sls_due_dt, 
    CASE 
        WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * abs(sls_price) THEN sls_sales = sls_quantity * abs(sls_price) 
        ELSE sls_sales
    END as sls_sales,
    CASE    
        WHEN sls_price IS NULL OR sls_price <=0 THEN sls_price = sls_sales / NULLIF(sls_quantity,0)
        ELSE sls_price
    END as sls_price,
    sls_quantity
FROM 
    bronze.crm_sales_details;

select '===loading tables from erp csv files===' as info;
TRUNCATE TABLE silver.erp_CUST_AZ12;
INSERT INTO silver.erp_CUST_AZ12(cid,bdate,gen)
SELECT 
    CASE 
        WHEN cid LIKE 'NAS%' THEN substring(cid,4,len(cid))
        ELSE cid 
    END as cid,
    CASE 
        WHEN bdate > CURRENT_TIMESTAMP THEN NULL 
        ELSE bdate
    END as bdate,
    CASE 
        WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
        ELSE 'n/a'
    END as gen
FROM 
    bronze.erp_CUST_AZ12;

TRUNCATE TABLE silver.erp_LOC_A101;
INSERT INTO silver.erp_LOC_A101(cid,cntry)
SELECT
    replace(cid,'-','') as cid,
    CASE 
        WHEN trim(cntry) = 'DE' THEN 'GERMANY'
        WHEN trim(cntry) IN ('US','USA') THEN 'United States' 
        WHEN trim(cntry) = '' OR cntry IS NULL THEN 'n/a'
        ELSE cntry
    END as cntry
FROM 
    bronze.erp_LOC_A101;

TRUNCATE TABLE silver.erp_PX_CAT_G1V2;
INSERT INTO silver.erp_PX_CAT_G1V2(id,cat,subcat,maintenance)
SELECT
    id,
    cat,
    subcat,
    maintenance
FROM 
    bronze.erp_PX_CAT_G1V2;

-- data checking quries

-- check if there is duplicate value in primary key column 
-- SELECT cst_id, count(*) 
-- FROM bronze.crm_cust_info 
-- GROUP BY cst_id 
-- HAVING count(*) > 1 OR cst_id IS NULL;

-- add a column that rank the duplicates based on creation date and only select the latest row. 
-- SELECT * FROM (
-- SELECT 
--     *,
--     ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
-- FROM 
--     bronze.crm_cust_info
-- ) WHERE flag_last = 1;

-- check for spaces in string values 
-- SELECT cst_firstname FROM bronze.crm_cust_info WHERE cst_firstname != trim(cst_firstname);

-- check for data standardization & consistency
-- SELECT DISTINCT cst_material_status from bronze.crm_cust_info;
-- SELECT DISTINCT cst_gndr from bronze.crm_cust_info;

-- check for invalid dates when converting date from integers values 
-- select sls_order_dt from bronze.crm_sales_details where sls_order_dt <=0 OR LENGTH(sls_order_dt::VARCHAR)!=8 OR sls_order_dt > 20500101 OR sls_order_dt < 19900101;