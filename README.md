# Cortex_Analyst_Demo
Snowflake Cortex Analyst Demo in &lt; 10 mins

Setup this demo to see the power of Conversational Analytics against structured datasets.

#### Notice: This demo has an additional step of summarizing the resultset via LLM calls to show art of the possible. This is not part of Cortex Analyst functionality & can be disabled!

<img src="https://github.com/NickAkincilar/Cortex_Analyst_Demo/blob/main/Images/Cortex1.png?raw=true" alt="drawing" width="500"/>


### CONTOSO DEMO SETUP INSTRUCTIONS:

1. Run Script Part-1 from the **/Files/Setup_Script.sql** to create the necessary objects

2. DRAG & DROP the 4 files(3 Sample parquet files + ContosoDemo.yaml) into ANALYST_STAGE via Snowsight before running the next set of scripts

3. Run Script Part-2 from the **/Files/Setup_Script.sql** to ingest the data & create search service for Fuzzy searching Customer & Product Names

4. Open the **"cortex_contoso_demo_sis.py"** file with a text editor & Copy all of the code.
   
5. Create a new StreamLit app in Snowsight & Paste the code from **"cortex_contoso_demo_sis.py"** file replacing all the existing code,

6. Run the Streamlit App in Snowsight


<BR/><BR/><BR/>



####  SAMPLE TALK TRACK:


1. **SHOW ME TOP 15 PRODUCTS SOLD IN TX IN TERMS OF REVENUE**  
    - "TX" does not match the data in the table where the real value is TEXAS. Show the query where it is filtering on TEXAS
    - Because we didnt specified a time range, LLM will use the entire time time period for revenue
    - Notice how results can be displayed as Table, Charts but also as a business summary & insights using **[CORTEX.COMPLETE()](https://docs.snowflake.com/en/sql-reference/functions/complete-snowflake-cortex)** function via Mistral_Large2
    - It drives insights using product descriptions such as Brand or Product Type even if those are not actual data columns
2. **WHAT ABOUT IN 2009?**
    - Notice this is a follow up to first question where Analyst will apply the YEAR=2009 to the previous question

4. **HOW ABOUT IN FL?**
    - Another follow up where we are switching to Sales in Florida during 2009

4. **Sales revenue for product categories & sub catergories sold in FL in 2009 & YOY % growth?**
    - This is a pretty complex question.
    - Notice how YOY% was interpreted by LLM as Year-over-Year & it figured out to compare to 2008

5. **Who are the top 5 customers who purchased cameras in FL**


6. **How much did Rachel Gordon spent in different product categories in Florida during 2009?**   
    - Notice the name format in the table is "**Gordon, Rachel**". **[CORTEX_SEARCH()](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview)**  Hybrid(Vector+Text) service was able to identify the correct name.
    - Look at the SQL: **WHERE NAME = 'Gordon, Rachel'**. Query is NOT using LIKE + % to find a partial match but uses Vector search to locate the actual name


7. **How much did Rachal Gordn spent in different product categories in Florida during 2009?**  (Notice the bad spelling for Rachel Gordon!)

    - We just butchered both the first & last names
    - Notice the SQL WHERE NAME = 'Gordon, Rachel'. 
    - Cortex_Search service allows users to make mistakes via Fuzzy Vector Search & not have to be precise with their search criteria & still get proper results

8. **Open & View the Yaml file.** 
    - Explain Symantic Generator auto splits columns in ach table into Dimensions, Measures, Time_Dimensions
    - Each Column has Synonyms to allow additional business terminology to be recognized
    - Look at the JOINS section 
    - Look at thge UNITPRICE measure in SALES table where the description was edited to tell Analyst how to properly calculate revenue
   W/o the additional description, Revenue questions were using NETPRICE column assuming it contained total sales amount 
   but the data in table is wrong and actual calcualtion should be as follows:
   description: Unit Price of a Product sold where Sales Revenue = UNITPRICE * QUANTITY
   This is how easy it is to fix potential problems

