# Power BI Semantic Layer Design - SharePoint Analytics

**Version:** 1.0
**Date:** 2025-10-21
**Purpose:** Hybrid architecture combining aggregated historical data with detailed recent contact-level data

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    POWER BI SEMANTIC LAYER                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌────────────────────┐              ┌────────────────────┐   │
│  │  REPORT TYPE 1:    │              │  REPORT TYPE 2:    │   │
│  │  General Audience  │              │  Power Users       │   │
│  │                    │              │                    │   │
│  │  - Historical      │              │  - Last 90 days    │   │
│  │    trends          │              │  - Contact detail  │   │
│  │  - Aggregated      │              │  - Flexible dates  │   │
│  │    metrics         │              │  - Deep analysis   │   │
│  └────────────────────┘              └────────────────────┘   │
│           │                                     │              │
│           │                                     │              │
│           ▼                                     ▼              │
│  ┌─────────────────────┐            ┌─────────────────────┐  │
│  │ Fact: Aggregated    │            │ Fact: Contact Level │  │
│  │ (Historical)        │            │ (Last 90 Days)      │  │
│  └─────────────────────┘            └─────────────────────┘  │
│           │                                     │              │
│           └──────────────┬──────────────────────┘              │
│                          │                                     │
│                          ▼                                     │
│         ┌────────────────────────────────────┐                │
│         │     SHARED DIMENSIONS              │                │
│         │  - dim_employee                    │                │
│         │  - dim_website_page                │                │
│         │  - dim_date                        │                │
│         │  - dim_referrer                    │                │
│         └────────────────────────────────────┘                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Tables

### Fact Tables

#### 1. **fact_aggregated** (Historical - All Time)
**Source:** `sharepoint_gold.pbi_db_overview_fact_tbl` (Overview_fact_table_FIXED.sql)

**Grain:** `marketingPageId + employeebusinessdivision + employeeregion + websitename`

**Timeframe:** All historical data (no time limit)

**Key Metrics:**
- Pre-calculated UV for various timeframes (all-time, TY, 28/21/14/7 days)
- Views, Visits, Likes, Comments (aggregated)

**Usage:**
- General audience dashboards
- Historical trend analysis
- Long-term comparisons
- High-level KPIs

**Storage Mode:** Import (recommended)

**Estimated Size:** ~100K-500K rows

---

#### 2. **fact_90days_contact_level**
**Source:** `sharepoint_gold.pbi_db_overview_fact_tbl_90days_contact` (Overview_fact_table_90days_contact_level.sql)

**Grain:** `Contact_ID + Marketing_Page_ID + Date` (full granularity)

**Timeframe:** Rolling last 90 days

**Key Metrics:**
- Views, Visits, Likes, Comments (raw, per interaction)
- Duration_Sum, Duration_Avg (interaction duration metrics)
- Flag (interaction flag)
- Contact_ID (for UV calculation)

**Usage:**
- Power user detailed analysis
- Contact-level drill-downs
- Flexible date range analysis
- Custom segmentation

**Storage Mode:** DirectQuery or Import with Incremental Refresh

**Estimated Size:** ~8M rows

---

#### 3. **fact_unified** (OPTIONAL - Combined)
**Source:** `sharepoint_gold.pbi_db_overview_fact_tbl_unified` (Overview_fact_table_UNIFIED.sql)

**Grain:** Mixed (contact-level for recent, aggregated for historical)

**Timeframe:** All time (combines both above)

**Key Features:**
- `Data_Source` flag: 'RECENT_DETAIL' vs 'HISTORICAL_AGG'
- `Has_Contact_Detail` boolean flag
- Contact_ID populated only for recent data

**Usage:**
- Single unified interface
- Automatic routing based on date filter
- Simplified model management

**Storage Mode:** Import with smart filtering

**Estimated Size:** Variable (depends on historical data volume)

---

### Dimension Tables

#### 1. **dim_employee**
**Source:** `sharepoint_gold.dim_employee` (Dimensions_for_Semantic_Layer.sql)

**Grain:** One row per contact

**Key Attributes:**
- Contact_ID (PK)
- Employee_business_division
- Employee_class
- OU_LVL_1 through OU_LVL_5
- Employee_rank
- Employee_region
- Employee_work_country

**Relationships:**
- `dim_employee[Contact_ID]` → `fact_90days_contact_level[Contact_ID]` (many-to-one)
- `dim_employee[Contact_ID]` → `fact_unified[Contact_ID]` (many-to-one, inactive for historical)

**Estimated Size:** ~10K-50K rows

---

#### 2. **dim_website_page**
**Source:** `sharepoint_gold.dim_website_page` (Dimensions_for_Semantic_Layer.sql)

**Grain:** One row per marketing page

**Key Attributes:**
- Marketing_Page_ID (PK)
- Site_name
- URL
- Page_name

**Relationships:**
- `dim_website_page[Marketing_Page_ID]` → `fact_aggregated[marketingPageId]` (many-to-one)
- `dim_website_page[Marketing_Page_ID]` → `fact_90days_contact_level[Marketing_Page_ID]` (many-to-one)

**Estimated Size:** ~1K-10K rows

---

#### 3. **dim_referrer**
**Source:** `sharepoint_gold.dim_referrer` (Dimensions_for_Semantic_Layer.sql)

**Grain:** One row per referrer application

**Key Attributes:**
- Referrer_Application_ID (PK)
- Referrer_application

**Relationships:**
- `dim_referrer[Referrer_Application_ID]` → `fact_90days_contact_level[Referrer_Application_ID]` (many-to-one)

**Estimated Size:** ~10-100 rows

---

#### 4. **dim_date**
**Source:** `sharepoint_gold.dim_date` (Dimensions_for_Semantic_Layer.sql)

**Grain:** One row per date

**Key Attributes:**
- Date_Key (PK)
- Date (alternate key)
- Year, Quarter_name, Quarter_number, Month, Week_of_Year, Day
- Day_type (Weekday/Weekend)
- Day_name, Month_name
- Year_Month, Year_Quarter
- Flags: Is_Last_90_Days, Is_Last_30_Days, Is_Last_7_Days, Is_Current_Year

**Relationships:**
- `dim_date[Date]` → `fact_90days_contact_level[Date]` (many-to-one)
- `dim_date[Date]` → `fact_unified[Date]` (many-to-one)
- Can also use Date_Key for relationships

**Estimated Size:** ~3K-10K rows (10+ years)

---

## Power BI Model Design

### Star Schema

```
                    dim_date
                       │
                       │ 1
                       │
                       ▼ ∞
         ┌─────────────────────────┐
         │  fact_90days_contact    │
         │  (or fact_unified)      │
         └─────────────────────────┘
           ▲         ▲         ▲
         ∞ │       ∞ │       ∞ │
           │ 1       │ 1       │ 1
           │         │         │
    dim_employee  dim_website  dim_referrer
                   _page
```

---

## DAX Measures

### For Contact-Level Fact Table (Last 90 Days)

```dax
// ============================================================================
// Unique Visitors (Correct calculation for contact-level data)
// ============================================================================
Unique Visitors =
    DISTINCTCOUNT('fact_90days_contact'[Contact_ID])

// ============================================================================
// Total Metrics
// ============================================================================
Total Views = SUM('fact_90days_contact'[Views])

Total Visits = SUM('fact_90days_contact'[Visits])

Total Likes = SUM('fact_90days_contact'[Likes])

Total Comments = SUM('fact_90days_contact'[Comments])

// ============================================================================
// Duration Metrics
// ============================================================================
Total Duration = SUM('fact_90days_contact'[Duration_Sum])

Average Duration per Interaction =
    DIVIDE(
        SUM('fact_90days_contact'[Duration_Sum]),
        COUNTROWS('fact_90days_contact'),
        0
    )

// Or use pre-calculated average
Avg Duration = AVERAGE('fact_90days_contact'[Duration_Avg])

// ============================================================================
// Calculated Metrics
// ============================================================================
Views per Visitor =
    DIVIDE([Total Views], [Unique Visitors], 0)

Engagement Rate =
    DIVIDE(
        [Total Likes] + [Total Comments],
        [Total Views],
        0
    )

Average Views per Visit =
    DIVIDE([Total Views], [Total Visits], 0)

Average Duration per Visit =
    DIVIDE([Total Duration], [Total Visits], 0)

Average Duration per Visitor =
    DIVIDE([Total Duration], [Unique Visitors], 0)

// ============================================================================
// Time Intelligence (using dim_date)
// ============================================================================
UV Last 7 Days =
    CALCULATE(
        [Unique Visitors],
        dim_date[Is_Last_7_Days] = TRUE
    )

UV Last 30 Days =
    CALCULATE(
        [Unique Visitors],
        dim_date[Is_Last_30_Days] = TRUE
    )

UV Last 90 Days =
    CALCULATE(
        [Unique Visitors],
        dim_date[Is_Last_90_Days] = TRUE
    )

// ============================================================================
// Previous Period Comparisons
// ============================================================================
UV Previous Period =
    CALCULATE(
        [Unique Visitors],
        DATEADD(dim_date[Date], -1, MONTH)
    )

UV Change = [Unique Visitors] - [UV Previous Period]

UV Change % =
    DIVIDE(
        [UV Change],
        [UV Previous Period],
        0
    )
```

### For Aggregated Fact Table (Historical)

```dax
// ============================================================================
// Use pre-calculated UV from fact table
// ============================================================================
UV All Time = SUM('fact_aggregated'[div_reg_uniquevisitor])

UV This Year = SUM('fact_aggregated'[div_reg_uniquevisitorty])

UV First 28 Days = SUM('fact_aggregated'[div_reg_uniquevisitor28])

// ============================================================================
// Other Metrics
// ============================================================================
Views All Time = SUM('fact_aggregated'[div_reg_views])

Visits All Time = SUM('fact_aggregated'[div_reg_visits])

Likes All Time = SUM('fact_aggregated'[div_reg_likes])

Comments All Time = SUM('fact_aggregated'[div_reg_comments])
```

### For Unified Fact Table (Both)

```dax
// ============================================================================
// Smart UV Calculation (uses appropriate method based on data source)
// ============================================================================
UV Smart =
    IF(
        // Check if we have contact-level detail
        COUNTROWS(
            FILTER(
                'fact_unified',
                'fact_unified'[Has_Contact_Detail] = TRUE
            )
        ) > 0,
        // Use contact-level calculation
        DISTINCTCOUNT('fact_unified'[Contact_ID]),
        // Use aggregated data (needs dimension join)
        // This requires more complex logic or fallback measure
        [UV from Aggregated Source]
    )

// ============================================================================
// Flag-based measures
// ============================================================================
Is Recent Data =
    IF(
        COUNTROWS(
            FILTER(
                'fact_unified',
                'fact_unified'[Data_Source] = "RECENT_DETAIL"
            )
        ) > 0,
        TRUE,
        FALSE
    )
```

---

## Report Deployment Strategy

### **Report 1: Executive Dashboard (General Audience)**

**Target Users:** Management, General stakeholders

**Data Source:** `fact_aggregated` (Historical)

**Key Features:**
- High-level KPIs (UV, Views, Engagement)
- Historical trends (YoY, QoQ comparisons)
- Pre-filtered to common timeframes
- Fast, responsive (all Import mode)

**Example Visuals:**
- UV trend over time (monthly/quarterly)
- Top performing pages/sites
- Division/Region breakdowns
- Year-over-year comparisons

**Performance Target:** <2 seconds for all visuals

---

### **Report 2: Detailed Analytics (Power Users)**

**Target Users:** Analysts, Marketing team, Data scientists

**Data Source:** `fact_90days_contact_level` (Recent Detail)

**Key Features:**
- Contact-level drill-downs
- Flexible date range selection
- Custom segmentation by OU levels
- Referrer analysis
- Individual contact journeys

**Example Visuals:**
- Contact-level table with drill-through
- Daily UV trends with custom date filters
- Heatmap by OU_LVL hierarchy
- Referrer application breakdown
- Contact cohort analysis

**Performance Target:** <10 seconds for complex queries

---

### **Optional Report 3: Unified View**

**Target Users:** Advanced users who need both historical and recent

**Data Source:** `fact_unified` (Combined)

**Key Features:**
- Automatic switching based on date selection
- Seamless experience across time periods
- Data source transparency (show which source is used)

**Example Visuals:**
- All-time trend with drill-down to contact level for recent periods
- Comparison of historical vs. recent patterns

---

## Implementation Steps

### Step 1: Deploy Dimension Tables
```sql
-- Run Dimensions_for_Semantic_Layer.sql
-- This creates:
-- - dim_employee
-- - dim_website_page
-- - dim_referrer
-- - dim_date
```

### Step 2: Deploy Fact Tables

**Option A: Separate Fact Tables (Recommended)**
```sql
-- Already exists: fact_aggregated (Overview_fact_table_FIXED.sql)
-- Already created: fact_90days_contact_level (Overview_fact_table_90days_contact_level.sql)
```

**Option B: Unified Fact Table**
```sql
-- Run Overview_fact_table_UNIFIED.sql
-- Creates: fact_unified
```

### Step 3: Power BI Model Setup

1. **Connect to Data Sources**
   - Use Fabric/Azure Databricks connector
   - Connect to `sharepoint_gold` schema

2. **Import Tables**
   - Import all dimension tables (small, fast)
   - Import `fact_aggregated` (moderate size)
   - Import or DirectQuery `fact_90days_contact_level` (based on performance needs)

3. **Create Relationships**
   ```
   dim_employee[Contact_ID] → fact_90days_contact[Contact_ID] (Many-to-One, Active)
   dim_website_page[Marketing_Page_ID] → fact_90days_contact[Marketing_Page_ID] (Many-to-One, Active)
   dim_website_page[Marketing_Page_ID] → fact_aggregated[marketingPageId] (Many-to-One, Active)
   dim_referrer[Referrer_Application_ID] → fact_90days_contact[Referrer_Application_ID] (Many-to-One, Active)
   dim_date[Date] → fact_90days_contact[Date] (Many-to-One, Active)
   ```

4. **Create DAX Measures**
   - Copy measures from DAX section above
   - Organize into measure groups (UV, Engagement, Time Intelligence)

5. **Configure Incremental Refresh** (if using Import for fact_90days_contact)
   - Set range to 90 days
   - Daily refresh schedule
   - Archive older data

6. **Test Performance**
   - Test queries on both fact tables
   - Verify UV calculations
   - Check relationship filtering

### Step 4: Create Reports

1. **Create Report 1** (General Audience)
   - Use `fact_aggregated` only
   - Pre-filter to common scenarios
   - Publish to workspace

2. **Create Report 2** (Power Users)
   - Use `fact_90days_contact_level` only
   - Enable all slicers/filters
   - Publish to separate workspace or app

3. **Set Permissions**
   - Report 1: Broad access
   - Report 2: Restricted to analysts

### Step 5: Certify & Document

1. **Certify Dataset** in Power BI Service
2. **Document measures** with descriptions
3. **Create user guides** for each report
4. **Set up scheduled refresh**

---

## Performance Optimization

### For Aggregated Fact Table
- **Storage Mode:** Import (fastest)
- **Refresh:** Daily or less frequent
- **Partitioning:** Not needed (already small)

### For Contact-Level Fact Table
- **Option 1: Import with Incremental Refresh**
  - Pros: Best query performance
  - Cons: Larger dataset refresh time
  - Recommended if: <10M rows

- **Option 2: DirectQuery**
  - Pros: Always fresh data, no refresh needed
  - Cons: Slower query performance
  - Recommended if: >10M rows or real-time needs

- **Option 3: Composite Model**
  - Import dimensions + aggregated fact
  - DirectQuery contact-level fact
  - Best of both worlds

### Database Optimizations
```sql
-- Optimize Delta tables
OPTIMIZE sharepoint_gold.pbi_db_overview_fact_tbl_90days_contact
ZORDER BY (Date, Employee_business_division);

-- Analyze tables for statistics
ANALYZE TABLE sharepoint_gold.dim_employee COMPUTE STATISTICS;
ANALYZE TABLE sharepoint_gold.dim_website_page COMPUTE STATISTICS;
```

---

## Maintenance & Monitoring

### Daily Tasks
- Monitor incremental refresh (if enabled)
- Check for failed refreshes
- Validate data freshness

### Weekly Tasks
- Review query performance logs
- Check for slow-running queries
- Monitor data growth

### Monthly Tasks
- Review usage analytics
- Optimize underperforming visuals
- Update documentation

---

## Field Mapping from Source Tables

### interactions_metrics Table Fields:
- `visitdatekey` → Date key for joining to dim_date
- `referrerapplicationid` → FK to dim_referrer
- `marketingPageId` → FK to dim_website_page
- `viewingcontactid` → Contact ID (used for UV calculation)
- `views` → Number of views
- `visits` → Number of visits
- `comment` → Number of comments (singular, not "comments")
- `marketingPageIdliked` → If not NULL, user liked the page
- `durationsum` → Total duration of interaction
- `durationavg` → Average duration of interaction
- `flag` → Interaction flag

**Important Notes:**
- `comment` is singular in the source table
- UV is calculated as `COUNT(DISTINCT viewingcontactid)`
- Likes are derived from `marketingPageIdliked IS NOT NULL`

---

## Troubleshooting

### Issue: UV counts don't match
**Cause:** Mixing aggregated and detail tables
**Solution:** Ensure measures use correct fact table

### Issue: Slow performance on contact-level queries
**Cause:** DirectQuery on large dataset without optimization
**Solution:**
- Enable Z-Ordering on Delta table
- Switch to Import mode with Incremental Refresh
- Add database indexes

### Issue: Relationships not working
**Cause:** Key mismatch or inactive relationships
**Solution:** Verify column names and data types match exactly

---

## Future Enhancements

1. **Add more pre-aggregated timeframes** (e.g., weekly, monthly grains)
2. **Implement role-based security** (RLS) on employee dimensions
3. **Create calculated tables** for common analysis patterns
4. **Add data quality measures** (e.g., % unknown employees)
5. **Implement composite aggregations** (Power BI Premium feature)

---

## Contact & Support

For questions or issues with this semantic layer design, contact the data team.

**Last Updated:** 2025-10-21
**Maintained By:** Data Engineering Team
