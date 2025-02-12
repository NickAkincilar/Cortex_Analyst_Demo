-- CONTOSO DEMO INSTRUCTIONS

-- 1. Run Part-1 of the script to create necessary objects

-- 2. DRAG & DROP the 4 files(3 Sample parquet files + ContosoDemo.yaml) into ANALYST_STAGE via Snowsight before running the next set of scripts

-- 3. Run Part-2 of the script to ingest the data & create search service for Fuzzy searching Customer & Product Names

-- 4. Open the **"cortex_contoso_demo_sis.py"** file with a text editor & Copy all of the code.
   
-- 5. Create a new StreamLit app in Snowsight & Paste the code from **"cortex_contoso_demo_sis.py"** file replacing all the existing code,

-- 6. Run the Streamlit App in Snowsight




-- Demo Talk Track:

-- 1. SHOW ME TOP 15 PRODUCTS SOLD IN TX IN TERMS OF REVENUE  
-- Comments: Point out 
--           a)  "TX" does not match the data in the table where the real value is TEXAS. Show the query where it is filtering on TEXAS
--           b) Because we didnt specified a time range, LLM will use the entire time time period for revenue
--           c) Explain how results can be displayed as Table, Charts BUT ALSO as a business summary & insights using CORTEX.COMPLETE via Mistral_Large2
--              It drives insights using product descptions such as Brand or Product Type even if those are not actual data columns


-- 2. WHAT ABOUT IN 2009?
-- Comments: Point out this is a follow up to first question where Analyst will apply the YEAR=2009 to previous question

-- 3. HOW ABOUT IN FL? 
-- Comments: Another follow up where we are switching to Sales in Florida during 2009

-- 4. Sales revenue for product categories & sub catergories sold in FL in 2009 & YOY % growth?
-- Comments: Pretty complex question. Show how YOY% was interpreted by LLM as Year-over-Year

-- 5. Who are the top 5 customers who purchased cameras in FL


-- 6. How much did Rachel Gordon spent in different product categories in Florida during 2009?

--  Comments: Explain name format in the table is "Gordon, Rachel" . Cortex_Search Hybrid search was able to identify the right name.
--  Show SQL where NAME = 'Gordon, Rachel'. It is not using LIKE + % to find a partial match but using Vector search to locate the actual name


-- 7. How much did Rachal Gordn spent in different product categories in Florida during 2009?  

-- Explain we just butchered both the first & last names with misspellings
-- Show SQL where NAME = 'Gordon, Rachel'. 
-- Explain Cortex_Search allows users to make mistakes & not have to be precise with their search criteria & still get proper resulst

-- 8. Show the Yaml file. 
-- a. Explain Symantic Generator auto splits columns in ach table into Dimensions, Measures, Time_Dimensions
-- b. Each Column has Synonyms to allow additional business terminalogy to be recognized
-- c. Show JOINS section 
-- d. Show UNITPRICE measure in SALES table where description was edited to tell Analyst how to properly calculate revenue
--    W/o the additional description, Revenue questions were using NETPRICE column assuming it contained total sales amount 
--    but the data in table is wrong and actual calcualtion should be as follows:
--    description: Unit Price of a Product sold where Sales Revenue = UNITPRICE * QUANTITY
--    This is how easy it is to fix potential problems



----> START OF PART-1 
USE ROLE ACCOUNTADMIN;

create database cortex_demos;
use database cortex_demos;


create schema cortex_demos.contoso;
use schema cortex_demos.contoso;

-- This is an option but the new internal LLMs are just as fast & accurate
--ALTER ACCOUNT SET ENABLE_CORTEX_ANALYST_MODEL_AZURE_OPENAI = TRUE;

create WAREHOUSE DEMO_WH 
WAREHOUSE_SIZE = 'X-Small'
AUTO_RESUME = true 
AUTO_SUSPEND = 300 
WAREHOUSE_TYPE = 'STANDARD' ;


create or replace stage analyst_stage directory = (enable = true);

create file format MY_PARQUET type =  PARQUET;

create or replace TABLE CUSTOMER (
	CUSTOMERKEY NUMBER(38,0),
	CUSTOMERCODE VARCHAR(16777216),
	TITLE VARCHAR(16777216),
	NAME VARCHAR(16777216),
	BIRTHDATE TIMESTAMP_NTZ(9),
	MARITALSTATUS VARCHAR(16777216),
	GENDER VARCHAR(16777216),
	EDUCATION VARCHAR(16777216),
	OCCUPATION VARCHAR(16777216),
	CONTINENT VARCHAR(16777216),
	CITY VARCHAR(16777216),
	STATE VARCHAR(16777216),
	COUNTRYREGION VARCHAR(16777216),
	ADDRESS1 VARCHAR(16777216),
	ADDRESS2 VARCHAR(16777216),
	PHONE VARCHAR(16777216),
	CUSTOMERTYPE VARCHAR(16777216),
	primary key (CUSTOMERKEY)
);


create or replace TABLE CORTEX_DEMOS.CONTOSO.PRODUCT (
	PRODUCTKEY NUMBER(38,0),
	PRODUCTCODE NUMBER(38,0),
	PRODUCTNAME VARCHAR(16777216),
	MANUFACTURER VARCHAR(16777216),
	BRAND VARCHAR(16777216),
	SUBCATEGORY VARCHAR(16777216),
	CATEGORY VARCHAR(16777216),
	COLOR VARCHAR(16777216),
	primary key (PRODUCTKEY)
);

create or replace TABLE CORTEX_DEMOS.CONTOSO.SALES (
	STOREKEY NUMBER(38,0),
	PRODUCTKEY NUMBER(38,0),
	PROMOTIONKEY NUMBER(38,0),
	CURRENCYKEY NUMBER(38,0),
	CUSTOMERKEY NUMBER(38,0),
	ORDERDATEKEY NUMBER(38,0),
	ORDERDATE TIMESTAMP_NTZ(9),
	DELIVERYDATE TIMESTAMP_NTZ(9),
	ORDERNUMBER VARCHAR(16777216),
	ORDERLINENUMBER NUMBER(38,0),
	QUANTITY NUMBER(38,0),
	UNITPRICE NUMBER(38,3),
	UNITDISCOUNT NUMBER(38,0),
	UNITCOST NUMBER(38,2),
	NETPRICE NUMBER(38,3),
	ORDERKEY VARCHAR(16777216),
	primary key (ORDERKEY)
);

----> END OF PART-1 




--- DRAG & DROP 3 Sample parquet files & the Contoso.YAML into ANALYST_STAGE 
--- via Snowsight before running the next set of scripts




----> START OF PART-2 

COPY INTO CORTEX_DEMOS.CONTOSO.PRODUCT
FROM (
SELECT $1:PRODUCTKEY::NUMBER(38, 0), $1:PRODUCTCODE::NUMBER(38, 0), $1:PRODUCTNAME::VARCHAR, $1:MANUFACTURER::VARCHAR, $1:BRAND::VARCHAR, $1:SUBCATEGORY::VARCHAR, $1:CATEGORY::VARCHAR, $1:COLOR::VARCHAR 
from '@CORTEX_DEMOS.CONTOSO.ANALYST_STAGE'
)
FILES = ('Product.parquet') FILE_FORMAT = 'MY_PARQUET' ON_ERROR=ABORT_STATEMENT;

COPY INTO CORTEX_DEMOS.CONTOSO.CUSTOMER
FROM (
SELECT $1:CUSTOMERKEY::NUMBER(38, 0), $1:CUSTOMERCODE::VARCHAR, $1:TITLE::VARCHAR, $1:NAME::VARCHAR, $1:BIRTHDATE::TIMESTAMP_NTZ, $1:MARITALSTATUS::VARCHAR, $1:GENDER::VARCHAR, $1:EDUCATION::VARCHAR, $1:OCCUPATION::VARCHAR, $1:CONTINENT::VARCHAR, $1:CITY::VARCHAR, $1:STATE::VARCHAR, $1:COUNTRYREGION::VARCHAR, $1:ADDRESS1::VARCHAR, $1:ADDRESS2::VARCHAR, $1:PHONE::VARCHAR, $1:CUSTOMERTYPE::VARCHAR 
from '@CORTEX_DEMOS.CONTOSO.ANALYST_STAGE'
)
FILES = ('Customer.parquet') FILE_FORMAT = 'MY_PARQUET' ON_ERROR=ABORT_STATEMENT;

COPY INTO CORTEX_DEMOS.CONTOSO.SALES
FROM (
    SELECT $1:STOREKEY::NUMBER(38, 0), $1:PRODUCTKEY::NUMBER(38, 0), $1:PROMOTIONKEY::NUMBER(38, 0), $1:CURRENCYKEY::NUMBER(38, 0), $1:CUSTOMERKEY::NUMBER(38, 0), $1:ORDERDATEKEY::NUMBER(38, 0), $1:ORDERDATE::TIMESTAMP_NTZ, $1:DELIVERYDATE::TIMESTAMP_NTZ, $1:ORDERNUMBER::VARCHAR, $1:ORDERLINENUMBER::NUMBER(38, 0), $1:QUANTITY::NUMBER(38, 0), $1:UNITPRICE::NUMBER(38, 3), $1:UNITDISCOUNT::NUMBER(38, 0), $1:UNITCOST::NUMBER(38, 2), $1:NETPRICE::NUMBER(38, 3), $1:ORDERKEY::VARCHAR
    FROM '@CORTEX_DEMOS.CONTOSO.ANALYST_STAGE'
)
FILES = ('Sales.parquet')
FILE_FORMAT = 'MY_PARQUET'
ON_ERROR=ABORT_STATEMENT;



create or replace dynamic table CUSTOMER_DIM(
	NAME,
	CITY,
	STATE
) target_lag = '5 minutes' refresh_mode = AUTO initialize = ON_CREATE warehouse = DEMO_WH
 as
SELECT NAME, CITY, STATE FROM CUSTOMER GROUP BY ALL;



CREATE OR REPLACE CORTEX SEARCH SERVICE search_product_name
ON PRODUCTNAME 
ATTRIBUTES
	 MANUFACTURER, CATEGORY, SUBCATEGORY 
WAREHOUSE = DEMO_WH 
TARGET_LAG = '5 mins' 
AS (
	SELECT
		PRODUCTNAME, MANUFACTURER, CATEGORY, SUBCATEGORY
	FROM CORTEX_DEMOS.CONTOSO.PRODUCT
);


CREATE OR REPLACE CORTEX SEARCH SERVICE search_customer_name
ON NAME 
ATTRIBUTES
	CITY, STATE
WAREHOUSE = DEMO_WH 
TARGET_LAG = '5 mins' 
AS (
	SELECT
		NAME, CITY, STATE  
	FROM CORTEX_DEMOS.CONTOSO.CUSTOMER_DIM
);

----> END OF PART-2 

