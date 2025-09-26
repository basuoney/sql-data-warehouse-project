/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'Silver' schema from 'Bronze' schema. 
    It performs the following actions:
    - Truncates the silver tables before loading data.
    - Uses the `INSERT INTO` command to insert data from bronze tables to silver tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/

create or alter procedure silver.load_silver as
begin
	DECLARE @start_time datetime, @end_time datetime, @start_time_all datetime
	begin try
		set @start_time_all = GETDATE()
		PRINT '================================================';
		PRINT 'Loading Silver Layer';
		PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		set @start_time = getdate();
		print '>> truncating table: silver.crm_cust_info'
		truncate table silver.crm_cust_info
		print '>> inserting data into table: silver.crm_cust_info'
		INSERT INTO silver.crm_cust_info  
		(
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date
		)
		select 
			cst_id,
			cst_key,
			trim(cst_firstname) as cst_firstname,
			trim(cst_lastname)as cst_lastname,
			case
				when upper(trim(cst_marital_status)) = 'M' then 'Married'
				when upper(trim(cst_marital_status)) = 'S' then 'Single'
				else 'n/a'
				end cst_marital_status,
			case 
				when upper(trim(cst_gndr)) = 'M' then 'Male' 
				when upper(trim(cst_gndr)) = 'F' then 'Female'
				else 'n/a'
				end cst_gndr,
			cst_create_Date
		from (
				select *,
				ROW_NUMBER () over (partition by cst_id order by cst_create_Date) as flag_last
				from
					bronze.crm_cust_info
				where cst_id is not null
			) t
		where flag_last =1;
		set @end_time = GETDATE()
		print '>> LOAD DURATION: ' + cast(datediff(second, @start_time, @end_time) as varchar) + 'seconds';
		print '---------------------------------';
		-------------------------------------------------------------------------------------------------------
		set @start_time = GETDATE();
		print '>> truncating table: silver.crm_prd_info'
		truncate table silver.crm_prd_info
		print '>> inserting data into table: silver.crm_prd_info'
		insert into silver.crm_prd_info (
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
		)
		select 
		prd_id,
		REPLACE(substring(prd_key,1,5), '-', '_') AS cat_id,
		SUBSTRING(prd_key,7, len(prd_key)) as prd_key,
		prd_nm,
		ISNULL(prd_cost, 0) as prd_cost,
		case upper(trim(prd_line))
			when 'M' then 'Mounain'
			when 'R' then 'Road'
			when 'S' then 'Other Sales'
			when 'T' then 'Touring'
			else 'n/a'
			end as prd_line,
		cast(prd_start_dt as date) as prd_start_date,
		cast(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt) - 1 as date) as prd_end_dt
		from bronze.crm_prd_info;
		set @end_time = GETDATE()
		print 'LOADING DURATION: ' + cast(datediff(second, @start_time, @end_time) as varchar) + 'seconds';
		print '--------------------------------------------------'
		----------------------------------------------------------------------------
		set @start_time = GETDATE()
		print '>> truncating table: silver.crm_sales_details'
		truncate table silver.crm_sales_details
		print '>> inserting data into table: silver.crm_sales_details'
		insert into silver.crm_sales_details (
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
		)
		select 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		case 
			when sls_order_dt <= 0 or len(sls_order_dt) != 8 then null
			else cast(cast(sls_order_dt as varchar) as date) 
		end as sls_order_dt,
		case
			when sls_ship_dt <= 0 or len(sls_ship_dt) != 8 then null
			else cast(cast(sls_ship_dt as varchar) as date)
		end as sls_ship_dt,
		case
			when sls_due_dt <= 0 or len(sls_due_dt) != 8 then null
			else cast(cast(sls_due_dt as varchar) as date)
		end as sls_due_dt,
		case
			when sls_sales is null or sls_sales <= 0 or sls_sales != abs(sls_price) * sls_quantity 
				then sls_quantity * abs(sls_price)
			else sls_sales
		end as sls_sales,
		sls_quantity,
		case
			when sls_price is null or sls_price = 0 then sls_sales / nullif(sls_quantity,0)
			when sls_price < 0 then abs(sls_price)
			else sls_price
		end as sls_price
		from bronze.crm_sales_details;
		set @end_time = GETDATE()
		print 'LOADING DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) as varchar) + 'seconds';
		print '----------------------------------------------------'
		----------------------------------------------------------------------------
		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';

		set @start_time = GETDATE()
		print '>> truncating table: silver.erp_cust_az12'
		truncate table silver.erp_cust_az12
		print '>> inserting data into table: silver.erp_cust_az12'
		insert into silver.erp_cust_az12 (CID, BDATE, GEN)
		select
		case
			when CID like 'NAS%' then SUBSTRING(CID,4, len(CID))
			else CID
		end as CID,
		case 
			when BDATE > GETDATE() then null
			else BDATE
		end as BDATE,
		case 
			when UPPER(TRIM(GEN)) in ('F', 'Female') then 'Female'
			when UPPER(TRIM(GEN)) in ('M', 'Male') then 'Male'
			else 'n/a'
		end as GEN
		from bronze.erp_cust_az12;
		set @end_time = GETDATE()
		print 'LOADING DURATION: ' + CAST(DATEDIFF(SECOND,@start_time, @end_time) as varchar) + 'seconds';
		print '----------------------------------------------------------'
		--------------------------------------------------------------------------
		set @start_time = GETDATE()
		print '>> truncating table: silver.erp_loc_a101'
		truncate table silver.erp_loc_a101
		print '>> inserting data into table: silver.erp_loc_a101'
		insert into silver.erp_loc_a101 (CID, CNTRY)
		select
		replace(CID,'-','') as CID, 
		case
			when trim(CNTRY) = 'DE' then 'Germany'
			when trim(CNTRY) in ('US', 'USA') then 'United States'
			when TRIM(cntry) = '' or CNTRY is null then 'n/a'
			else TRIM(cntry)
		end as CNTRY
		from bronze.erp_loc_a101;
		set @end_time = GETDATE()
		print 'LOADING DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) as varchar) + 'seconds';
		print '-------------------------------------'
		--------------------------------------------------
		set @start_time = GETDATE()
		print '>> truncating table: silver.erp_px_cat_g1v2'
		truncate table silver.erp_px_cat_g1v2
		print '>> inserting data into table: silver.erp_px_cat_g1v2'
		insert into silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
		select id, cat, subcat, maintenance
		from bronze.erp_px_cat_g1v2;
		set @end_time = GETDATE()
		print 'LOADING DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) as varchar) + 'seconds';
		print '-------------------------------------'
		----------------------------------------------------------------------
		SET @end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time_all, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='

	end try
	begin catch
		print '===============================================================================';
		print 'ERROR OCCURED DURING LOADING SILVER LAYER';
		PRINT 'EEROR MESSAGE' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER' + CAST(ERROR_NUMBER() AS VARCHAR);
		PRINT 'ERROR STATE' + CAST(ERROR_STATE() AS VARCHAR);
		PRINT '================================================================================';
	end catch
end
