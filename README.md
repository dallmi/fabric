# SharePoint Analytics Data Model - Business Documentation

## Overview

This SQL query creates a pre-aggregated fact table (`sharepoint_gold.pbi_db_overview_fact_tbl`) that calculates unique visitors (UV) and other metrics at various levels of granularity. Instead of calculating these metrics on-the-fly in Power BI (which is slow with large datasets), we pre-calculate them in the database layer to improve performance.

## Why This Approach?

**Problem:** Our Power BI reports were slow because they calculated unique visitors across millions of interaction records in real-time.

**Solution:** Pre-aggregate the data in SQL and store it in a fact table. Power BI then reads pre-calculated results instead of processing raw data.

## Input Data Sources

The query combines data from several source tables:

1. **sharepoint_gold.pbi_db_interactions_metrics**
   - Raw interaction data (views, visits, likes, comments)
   - Contains: `viewingcontactid`, `marketingPageId`, `visitdatekey`, `views`, `visits`, `comments`, `marketingPageIdliked`

2. **sharepoint_gold.pbi_db_dim_date**
   - Date dimension table
   - Contains: `date_key`, `date` (for filtering by year)

3. **sharepoint_gold.pbi_db_employeecontact**
   - Employee information
   - Contains: `contactid`, `employeebusinessdivision`, `employeeregion`

4. **sharepoint_gold.pbi_db_website_page_inventory**
   - Website and page metadata
   - Contains: `marketingPageId`, `websitename`

## What The Query Does

The query creates multiple "views" of the data called CTEs (Common Table Expressions). Each CTE pre-calculates metrics at different levels of detail:

### Base Preparation CTEs

1. **minpagedate**: Finds the first date each marketing page was visited
2. **site_page_inventory**: Creates a lookup between pages and websites
3. **final**: Enriches interaction data with employee division and region (replaces NULL values with "Unknown")

### All-Time Metrics (No Date Filter)

These CTEs aggregate data across all time periods:

| CTE Name | Level of Detail | Metrics |
|----------|----------------|---------|
| `page` / `div_reg` | Marketing Page + Division + Region | UV, Likes, Views, Visits, Comments |
| `div_` | Business Division only | UV |
| `reg_` | Region only | UV |
| `site_` | Website only | UV |
| `site_div_` | Website + Division | UV |
| `site_reg_` | Website + Region | UV |
| `site_div_reg_` | Website + Division + Region | UV |

### Current Year Metrics (Filtered by Year)

These CTEs calculate the same metrics but only for the current year (using `YEAR(date) = YEAR(NOW())`):

| CTE Name | Level of Detail | Metrics |
|----------|----------------|---------|
| `div_req_ty` | Marketing Page + Division + Region (this year) | UV, Likes, Views, Visits, Comments |
| `div_ty` | Business Division (this year) | UV |
| `reg_ty` | Region (this year) | UV |
| `site_ty` | Website (this year) | UV |
| `site_div_ty` | Website + Division (this year) | UV |
| `site_reg_ty` | Website + Region (this year) | UV |

## Output Table Structure

The final fact table will contain pre-calculated aggregations. Each row represents a unique combination of dimensions with pre-calculated metrics.

### Example Output Rows:

**Page-level (div_reg):**
```
marketingPageId | websitename | employeebusinessdivision | employeeregion | uniquevisitor | likes | views | visits | comments
12345          | IntranetSite | Sales                    | EMEA          | 450          | 23    | 1200  | 890   | 45
```

**Division-level (div_):**
```
employeebusinessdivision | uniquevisitor
Sales                    | 2500
Marketing                | 1800
```

**Website + Division (site_div_):**
```
websitename  | employeebusinessdivision | uniquevisitor
IntranetSite | Sales                    | 1200
IntranetSite | Marketing                | 890
```

## Key Metrics Explained

- **uniquevisitor (UV)**: Count of distinct employees (`viewingcontactid`) who interacted with the content
- **likes**: Count of distinct pages that were liked by users
- **views**: Total number of page views
- **visits**: Total number of visits (sessions)
- **comments**: Total number of comments made

## Important Limitations & Considerations

### 1. **Granularity Trade-off**
- ✅ **What you CAN do:** Get pre-calculated UV at specific aggregation levels (e.g., "UV by Division", "UV by Website and Region")
- ❌ **What you CANNOT do:** Drill down into custom combinations not pre-calculated (e.g., if you want "UV by Division + Date + Specific Page", but only pre-calculated "UV by Division", you can't get accurate results)

### 2. **Data Freshness**
- This table is a **snapshot** that needs to be refreshed regularly
- If the source data changes, you must re-run this query to update the fact table
- Current year metrics (`_ty` CTEs) will change as the year progresses

### 3. **Year Filter Limitation**
- Current year metrics use `YEAR(NOW())`, which means:
  - ✅ Automatically updates to the current year when the query runs
  - ❌ Historical year-over-year comparisons require additional CTEs (e.g., `_ly` for last year)

### 4. **Unknown Values**
- If an employee's division or region is missing in the source data, it's replaced with `"Unknown"`
- This ensures all interactions are counted, but you may have an "Unknown" category in reports

### 5. **Unique Visitor Calculation**
- UV is counted using `COUNT(DISTINCT viewingcontactid)`
- **Important:** You cannot simply add UV numbers across different aggregations
  - Example: If "Sales" has 100 UV and "Marketing" has 80 UV, the total is NOT necessarily 180 (some employees may be in both)

### 6. **Missing Time Dimensions**
- Currently, the query does not aggregate by:
  - Specific dates (daily, weekly, monthly trends)
  - Date ranges beyond "current year"
- If you need time-series analysis, additional CTEs would be required

### 7. **Performance vs. Flexibility**
- ✅ **Benefit:** Extremely fast Power BI reports because data is pre-aggregated
- ❌ **Trade-off:** Less flexible - you can only analyze the pre-calculated combinations

## How To Use This in Power BI

1. **Import the fact table** into Power BI as a data source
2. **Use the appropriate CTE result** based on your reporting needs:
   - Need division-level metrics? → Use `div_` or `div_ty`
   - Need page-level with region? → Use `div_reg` or `div_req_ty`
   - Need website trends? → Use `site_` or `site_ty`
3. **Do NOT try to calculate UV across different levels** - use the pre-calculated UV for each specific level
4. **Refresh the data model regularly** to keep metrics current

## When To Add New Aggregations

Consider adding new CTEs if you need:
- Historical year comparisons (e.g., `_ly` for last year, `_2y` for 2 years ago)
- Date-based aggregations (daily, weekly, monthly)
- Additional dimension combinations not currently pre-calculated
- Different time windows (e.g., last 30 days, last 90 days)

## Performance Impact

**Before (without this approach):**
- Power BI processes millions of rows on every report refresh
- Slow filters, slow visuals, poor user experience

**After (with this approach):**
- Power BI reads pre-aggregated rows (thousands instead of millions)
- Fast reports, instant filters, better user experience
- Trade-off: Less ad-hoc flexibility, but dramatically faster performance
