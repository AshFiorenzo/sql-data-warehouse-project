-- ===============================================================================
-- Purpose: Create Gold Layer (Business-Ready Data)
-- ===============================================================================
-- This script creates views in the Gold layer using cleaned and transformed
-- data from the Silver layer, following a Star Schema design.
-- The Gold layer provides business-ready data for reporting, analytics, and business intelligence.

-- Process:
--  1. Integrate customer information from CRM and ERP systems.
--  2. Integrate product information with product categories.
--  3. Filter historical product records to retain current products.
--  4. Generate surrogate keys for customer and product dimensions.
--  5. Create a sales fact view linked to customer and product dimensions.

-- Gold Layer Views:
--  - gold.dim_customers: Consolidated customer information.
--  - gold.dim_products: Current product details and classifications.
--  - gold.fact_sales: Sales transactions and financial metrics.

-- Data Model:
--  Star Schema with 2 Dimension Views & 1 Fact View
-- ===============================================================================
CREATE VIEW gold.dim_customers AS 
SELECT 
    --generate a key to uniquely identify each row in this newly created table
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) as customer_key,
    ci.cst_id as customer_id,
    ci.cst_key as customer_number,
    ci.cst_firstname as first_name,
    ci.cst_lastname as last_name,
    la.cntry as country,
    ci.cst_marital_status as martial_status,
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END as gender,
    ca.bdate as birthday,
    ci.cst_create_date as created_date
FROM 
    silver.crm_cust_info as ci
LEFT JOIN 
    silver.erp_CUST_AZ12 as ca
ON ci.cst_key = ca.cid
LEFT JOIN 
    silver.erp_LOC_A101 as la
ON ci.cst_key = la.cid;

CREATE VIEW gold.dim_products AS 
SELECT
    ROW_NUMBER() OVER(ORDER BY pi.prd_start_dt,pi.prd_key) as product_key,
    pi.prd_id as product_id,
    pi.prd_key as product_number,
    pi.prd_nm as product_name,
    pi.cat_id as category_id,
    pcg.cat as category,
    pcg.subcat as sub_category,
    pcg.maintenance as maintenance,
    pi.prd_cost as product_cost,
    pi.prd_line as product_line,
    pi.prd_start_dt as start_line
FROM 
    silver.crm_prd_info as pi 
LEFT JOIN 
    silver.erp_PX_CAT_G1V2 as pcg 
ON pi.cat_id = pcg.id
WHERE 
    pi.prd_end_dt IS NULL; --filter out historial data and only select the latest one

CREATE VIEW gold.fact_sales as 
SELECT
    sd.sls_ord_num as order_number,
    dp.product_key, --connect with product dimension table 
    dc.customer_key, -- connect with customer dimension table
    sd.sls_order_dt as order_date,
    sd.sls_ship_dt as shipping_date,
    sd.sls_due_dt as due_date,
    sd.sls_sales as sales_amount,
    sd.sls_quantity as quantity,
    sd.sls_price as price
FROM 
    silver.crm_sales_details as sd
LEFT JOIN gold.dim_products as dp
ON sd.sls_prd_key = dp.product_number
LEFT JOIN gold.dim_customers as dc 
ON sd.sls_cust_id = dc.customer_id;

-- check the foreign key integrity of fact table and dimension tables 
SELECT * FROM gold.fact_sales as fs
LEFT JOIN gold.dim_customers as dc
ON dc.customer_key = fs.customer_key
LEFT JOIN gold.dim_products as dp
ON dp.product_key = fs.product_key;