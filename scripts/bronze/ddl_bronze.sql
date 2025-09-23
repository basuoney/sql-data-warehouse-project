/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/

IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info (
cst_id int,
cst_key varchar(50),
cst_firstname varchar(50),
cst_lastname varchar(50),
cst_marital_status nvarchar(50),
cst_gndr nvarchar(50),
cst_create_date date
);
go

IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
	DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info (
prd_id int,
prd_key	varchar(50),
prd_nm	varchar(255),
prd_cost INT,
prd_line varchar(255),
prd_start_dt datetime,
prd_end_dt datetime
);
go

IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details (
sls_ord_num	varchar(50),
sls_prd_key	varchar(50),
sls_cust_id	int,
sls_order_dt int,
sls_ship_dt	int,
sls_due_dt	int,
sls_sales	int,
sls_quantity int,
sls_price int
);
go

IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
	DROP TABLE bronze.erp_cust_az12;
GO

CREATE TABLE bronze.erp_cust_az12 (
CID nvarchar(50),
BDATE date,
GEN nvarchar(50)
);
go

IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO

CREATE TABLE bronze.erp_loc_a101 (
CID nvarchar(50),	
CNTRY nvarchar(50)
);
go

IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO

CREATE TABLE bronze.erp_px_cat_g1v2 (
id NVARCHAR(50),
cat NVARCHAR(50),
subcat NVARCHAR(50),
maintenance NVARCHAR(50)
);
GO
