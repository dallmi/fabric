-- =====================================================================================
-- SharePoint Analytics - Dimension Tables for Power BI Semantic Layer
-- =====================================================================================
-- Description: Shared dimension tables to be used with both fact tables
--              (aggregated historical and contact-level detail)
--
-- Purpose:     Create normalized star schema for Power BI
--              - Reduce data redundancy
--              - Improve query performance
--              - Enable proper relationships in Power BI
--
-- Date:        2025-10-21
-- =====================================================================================

-- =====================================================================================
-- DIMENSION 1: Employee/Contact
-- =====================================================================================
-- Purpose: All employee/contact attributes
-- Grain:   One row per unique contact
-- =====================================================================================

%sql
CREATE OR REPLACE TABLE sharepoint_gold.dim_employee USING delta
LOCATION 'abfss://gold@d6476p1s05sweugempI.dfs.core.windows.net/employee_analytics/dim_employee'
AS
SELECT DISTINCT
    contactid AS Contact_ID,

    -- Employee Business Information
    CASE
        WHEN employeebusinessdivision IS NULL THEN 'Unknown'
        ELSE employeebusinessdivision
    END AS Employee_business_division,

    CASE
        WHEN employeeClass IS NULL THEN 'Unknown'
        ELSE employeeClass
    END AS Employee_class,

    -- Organizational Unit Hierarchy
    COALESCE(OU_LVL_1, 'Unknown') AS OU_LVL_1,
    COALESCE(OU_LVL_2, 'Unknown') AS OU_LVL_2,
    COALESCE(OU_LVL_3, 'Unknown') AS OU_LVL_3,
    COALESCE(OU_LVL_4, 'Unknown') AS OU_LVL_4,
    COALESCE(OU_LVL_5, 'Unknown') AS OU_LVL_5,

    -- Employee Rank and Location
    CASE
        WHEN employeeRank IS NULL THEN 'Unknown'
        ELSE employeeRank
    END AS Employee_rank,

    CASE
        WHEN employeeregion IS NULL THEN 'Unknown'
        ELSE employeeregion
    END AS Employee_region,

    CASE
        WHEN employeeWorkCountry IS NULL THEN 'Unknown'
        ELSE employeeWorkCountry
    END AS Employee_work_country

FROM
    sharepoint_gold.pbi_db_employeecontact
WHERE
    contactid IS NOT NULL;

-- =====================================================================================
-- DIMENSION 2: Website & Page
-- =====================================================================================
-- Purpose: Website and marketing page details
-- Grain:   One row per unique marketing page
-- =====================================================================================

%sql
CREATE OR REPLACE TABLE sharepoint_gold.dim_website_page USING delta
LOCATION 'abfss://gold@d6476p1s05sweugempI.dfs.core.windows.net/employee_analytics/dim_website_page'
AS
SELECT DISTINCT
    marketingPageId AS Marketing_Page_ID,

    -- Website Information
    COALESCE(websitename, 'Unknown') AS Site_name,

    -- Page URL
    COALESCE(fullpageurl, 'Unknown') AS URL,

    -- Additional page attributes (if available)
    -- Add more fields here as needed from the inventory table
    COALESCE(pagename, 'Unknown') AS Page_name

FROM
    sharepoint_gold.pbi_db_website_page_investory
WHERE
    marketingPageId IS NOT NULL;

-- =====================================================================================
-- DIMENSION 3: Referrer Application
-- =====================================================================================
-- Purpose: Referrer application lookup
-- Grain:   One row per unique referrer application
-- =====================================================================================

%sql
CREATE OR REPLACE TABLE sharepoint_gold.dim_referrer USING delta
LOCATION 'abfss://gold@d6476p1s05sweugempI.dfs.core.windows.net/employee_analytics/dim_referrer'
AS
SELECT DISTINCT
    referrerapplicationid AS Referrer_Application_ID,

    COALESCE(referrerapplication, 'Unknown') AS Referrer_application

FROM
    sharepoint_gold.pbi_db_referrer_application
WHERE
    referrerapplicationid IS NOT NULL;

-- =====================================================================================
-- DIMENSION 4: Date (Enhanced)
-- =====================================================================================
-- Purpose: Date dimension with all time attributes
-- Grain:   One row per date
-- Note:    Using existing pbi_db_dim_date but with enhanced formatting
-- =====================================================================================

%sql
CREATE OR REPLACE TABLE sharepoint_gold.dim_date USING delta
LOCATION 'abfss://gold@d6476p1s05sweugempI.dfs.core.windows.net/employee_analytics/dim_date'
AS
SELECT
    date_key AS Date_Key,
    date AS Date,

    -- Year, Quarter, Month, Week
    year AS Year,
    CONCAT('Q', quarter) AS Quarter_name,
    quarter AS Quarter_number,
    month AS Month,
    week AS Week_of_Year,
    day AS Day,

    -- Additional useful date attributes
    CASE
        WHEN DAYOFWEEK(date) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS Day_type,

    DAYNAME(date) AS Day_name,
    MONTHNAME(date) AS Month_name,

    -- Year-Month for grouping
    CONCAT(year, '-', LPAD(month, 2, '0')) AS Year_Month,

    -- Year-Quarter for grouping
    CONCAT(year, '-Q', quarter) AS Year_Quarter,

    -- Relative date flags (useful for filters)
    CASE
        WHEN date >= DATE_SUB(CURRENT_DATE(), 90) THEN TRUE
        ELSE FALSE
    END AS Is_Last_90_Days,

    CASE
        WHEN date >= DATE_SUB(CURRENT_DATE(), 30) THEN TRUE
        ELSE FALSE
    END AS Is_Last_30_Days,

    CASE
        WHEN date >= DATE_SUB(CURRENT_DATE(), 7) THEN TRUE
        ELSE FALSE
    END AS Is_Last_7_Days,

    CASE
        WHEN YEAR(date) = YEAR(CURRENT_DATE()) THEN TRUE
        ELSE FALSE
    END AS Is_Current_Year

FROM
    sharepoint_gold.pbi_db_dim_date;

-- =====================================================================================
-- END OF DIMENSION DEFINITIONS
-- =====================================================================================

-- =====================================================================================
-- RELATIONSHIP MAPPING (for documentation)
-- =====================================================================================
--
-- Power BI Relationships:
--
-- dim_employee[Contact_ID] 1 ──→ ∞ fact_90days_contact[Contact_ID]
-- dim_employee[Contact_ID] 1 ──→ ∞ fact_unified[Contact_ID]
--
-- dim_website_page[Marketing_Page_ID] 1 ──→ ∞ fact_90days_contact[Marketing_Page_ID]
-- dim_website_page[Marketing_Page_ID] 1 ──→ ∞ fact_unified[Marketing_Page_ID]
-- dim_website_page[Marketing_Page_ID] 1 ──→ ∞ fact_aggregated[marketingPageId]
--
-- dim_referrer[Referrer_Application_ID] 1 ──→ ∞ fact_90days_contact[Referrer_Application_ID]
-- dim_referrer[Referrer_Application_ID] 1 ──→ ∞ fact_unified[Referrer_Application_ID]
--
-- dim_date[Date_Key] 1 ──→ ∞ fact_90days_contact[Visit_Date_Key]
-- dim_date[Date_Key] 1 ──→ ∞ fact_unified[Visit_Date_Key]
-- dim_date[Date_Key] 1 ──→ ∞ fact_aggregated[visitdatekey]
--
-- dim_date[Date] 1 ──→ ∞ fact_90days_contact[Date]
-- dim_date[Date] 1 ──→ ∞ fact_unified[Date]
--
-- =====================================================================================
