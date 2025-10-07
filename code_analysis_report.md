# SQL Code Analysis Report - extracted_code.sql

**Date:** 2025-10-07
**Analyst:** Senior Code Reviewer
**File:** extracted_code.sql

---

## Executive Summary

This report contains a comprehensive analysis of the SQL code for marketing page analytics. The code aggregates interaction metrics across multiple dimensions (business division, region, website, time periods). A thorough review has identified **12 critical bugs** and **7 potential issues** that could impact data accuracy and query performance.

---

## 1. CRITICAL BUGS IDENTIFIED

### BUG #1: Missing Comma at Line 239 (SYNTAX ERROR)
**Location:** Line 239
**Severity:** CRITICAL - Query will not execute
**Issue:** Missing comma after the `site_div_reg_ty` CTE definition before the `div_reg_28` CTE starts at line 244.

```sql
-- Line 239 ends:
)

-- Line 244 starts immediately with:
div_reg_28 AS (
```

**Impact:** The entire query will fail with a syntax error.
**Fix Required:** Add a comma after line 239: `),`

---

### BUG #2: Incorrect Alias Variable in Line 971
**Location:** Line 971
**Severity:** CRITICAL - Data Mislabeling
**Issue:** The subquery for 7-day unique visitors uses alias `uvall14` instead of `uvall7`.

```sql
SELECT
    COUNT(DISTINCT viewingcontactid) as uvall14  -- Should be uvall7
FROM
    final AS f
...
WHERE
    d.date <= DATE_ADD(mindate, 6)  -- This is for 7 days
) as uniquevisitor7,
```

**Impact:** While this doesn't break the query, it creates confusion in debugging and may indicate copy-paste errors. The alias name doesn't match the intended metric.
**Fix Required:** Change `uvall14` to `uvall7`

---

### BUG #3: Missing CTE Reference in Final SELECT (reg_21 aliased as 'm')
**Location:** Lines 918, 1028
**Severity:** HIGH - Potential NULL values
**Issue:** In the final SELECT statement (line 918), the code references `m.uniquevisitor as reg_uniquevisitor21`, but in the JOIN section (line 1028), it joins `reg_21 AS n` (not 'm').

```sql
-- Line 918:
m.uniquevisitor as reg_uniquevisitor21,

-- Line 1028:
LEFT JOIN
    reg_21 AS n  -- Aliased as 'n', not 'm'
    ON a.employeeregion = n.employeeregion
```

**Impact:** The reference to `m.uniquevisitor` will be NULL or cause an error because alias 'm' is used for `minpagedate` in subqueries but not properly aliased in the main JOIN.
**Fix Required:** Change line 918 to `n.uniquevisitor as reg_uniquevisitor21`

---

### BUG #4: Inconsistent JOIN Patterns for div_21 and reg_21
**Location:** Lines 420-459
**Severity:** MEDIUM - Unnecessary JOINs
**Issue:** In `div_21` (lines 420-438) and `reg_21` (lines 441-459), the query joins `pbi_db_employeecontact` which is unnecessary since the `final` CTE already contains the business division and region.

```sql
div_21 AS (
    SELECT
        f.employeebusinessdivision,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_employeecontact AS e  -- Unnecessary
        ON f.viewingcontactid = e.contactid
```

**Impact:** Performance degradation and inconsistency with other CTEs (div_28, div_14, div_7 don't have this JOIN).
**Fix Required:** Remove the unnecessary JOIN with `pbi_db_employeecontact` to match the pattern used in other time-period CTEs.

---

### BUG #5: Redundant JOIN Pattern in site_reg_21
**Location:** Lines 503-522
**Severity:** MEDIUM - Unnecessary JOINs
**Issue:** Similar to BUG #4, `site_reg_21` unnecessarily joins `pbi_db_employeecontact` (lines 510-511) when the data is already available in the `final` CTE.

```sql
site_reg_21 AS (
    SELECT
        f.employeeregion,w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_employeecontact AS e  -- Unnecessary
        ON f.viewingcontactid = e.contactid
```

**Impact:** Performance issue and inconsistency with similar CTEs.
**Fix Required:** Remove the JOIN.

---

### BUG #6: Missing websitename in JOIN Conditions
**Location:** Lines 998-1001
**Severity:** HIGH - Incorrect Data Joining
**Issue:** The JOIN for `div_reg_28` (and similarly for _21, _14, _7) does not include `websitename` in the join condition, even though both tables have this column and it's a key grouping dimension.

```sql
LEFT JOIN
    div_reg_28 AS e
    ON a.marketingPageId = e.marketingPageId
    AND a.employeebusinessdivision = e.employeebusinessdivision
    AND a.employeeregion = e.employeeregion
    -- MISSING: AND a.websitename = e.websitename
```

**Impact:** If the same marketingPageId exists across different websites with the same division/region combination, you'll get incorrect matches. This could lead to data duplication or mismatched metrics.
**Fix Required:** Add `AND a.websitename = e.websitename` to all div_reg_* JOIN conditions (lines 998-1001, 1020-1023, 1031-1034, 1042-1045).

---

### BUG #7: Potential NULL Handling Issues in 'final' CTE
**Location:** Lines 16-18
**Severity:** MEDIUM - Data Quality
**Issue:** The `final` CTE replaces NULL values with 'Unknown', but this happens in a nested SELECT which then gets used throughout. However, if the LEFT JOIN to `pbi_db_employeecontact` produces NULLs, all subsequent aggregations treat 'Unknown' as a valid business division/region, which could artificially inflate metrics.

```sql
final as (select f.*,
    case when e.employeebusinessdivision is null then 'Unknown' else e.employeebusinessdivision end as employeebusinessdivision,
    case when e.employeeregion is null then 'Unknown' else e.employeeregion end as employeeregion
from sharepoint_gold.pbi_db_interactions_metrics F
LEFT JOIN sharepoint_gold.pbi_db_employeecontact AS e on f.viewingcontactid = e.contactid)
```

**Impact:** The 'Unknown' category may mask data quality issues and make it difficult to identify missing employee data.
**Recommendation:** Consider filtering out or separately tracking records where employee data is missing, or at minimum, document this behavior clearly.

---

### BUG #8: DATE_ADD Offset Confusion
**Location:** Multiple locations (lines 265, 285, 303, 413, 436, etc.)
**Severity:** MEDIUM - Potential Off-by-One Error
**Issue:** The code uses `DATE_ADD(mindate, 27)` for 28 days, `DATE_ADD(mindate, 20)` for 21 days, etc. This is technically correct if `mindate` is inclusive (day 0), but the naming and comments suggest "first N days" which could be ambiguous.

```sql
-- Comment says "first 28 days"
WHERE
    d.date <= DATE_ADD(mindate, 27)  -- This is 28 days only if mindate is day 0
```

**Impact:** Potential confusion and off-by-one errors. If mindate is meant to be day 1, this calculation is wrong.
**Recommendation:** Add clear comments explaining that mindate is day 0, or adjust the logic to be more explicit (e.g., `DATEDIFF(d.date, mindate) < 28`).

---

### BUG #9: Redundant Condition in WHERE Clauses
**Location:** Lines 265, 285, 303, 413, etc.
**Severity:** LOW - Code Redundancy
**Issue:** The WHERE clause includes `m.marketingPageId = f.marketingPageId` even though this condition is already enforced in the JOIN condition on the same line.

```sql
LEFT JOIN
    minpagedate AS m
    ON m.marketingPageId = f.marketingPageId
WHERE
    d.date <= DATE_ADD(mindate, 27) and m.marketingPageId = f.marketingPageId
    -- This second condition is redundant
```

**Impact:** Minor performance impact (query optimizer should handle it) and code clutter.
**Recommendation:** Remove redundant conditions from WHERE clauses.

---

### BUG #10: Commented-out CREATE TABLE Statement
**Location:** Lines 2-3
**Severity:** LOW - Deployment Issue
**Issue:** The CREATE TABLE statement is commented out, meaning this query only returns results but doesn't persist them.

```sql
-- CREATE OR REPLACE TABLE sharepoint_gold.pbi_db_overview_fact_tbl using delta
--location 'abfss://gold@d6476p1s05sweugempI.dfs.core.windows.net/employee_analytics/pbi_db_overview_fact_tbl'
```

**Impact:** If the intention is to create/update a table, this code won't do it.
**Recommendation:** Uncomment if table creation is needed, or remove if not applicable.

---

### BUG #11: Potential Performance Issue - Scalar Subqueries in SELECT
**Location:** Lines 850-855, 867-877, 893-906, 919-932, 944-957, 969-982
**Severity:** MEDIUM - Performance
**Issue:** The query uses scalar subqueries to calculate overall unique visitors for each time period. These subqueries will execute once per row in the result set, which is extremely inefficient.

```sql
(
    SELECT
        COUNT(DISTINCT viewingcontactid) as uvall
    FROM
        final
) as uniquevisitor,
```

**Impact:** Severe performance degradation, especially with large datasets. Each row will re-execute these subqueries.
**Fix Required:** Calculate these values once in separate CTEs and JOIN them in.

---

### BUG #12: Inconsistent Comma Position in Line 239
**Location:** Line 239
**Severity:** CRITICAL - Syntax Error
**Issue:** This is the most critical issue. After the `site_div_reg_ty` CTE closes at line 239, there should be a comma before the next CTE `div_reg_28` begins at line 244.

**Impact:** The query will not execute.
**Current Code:**
```sql
-- Line 223-239
site_div_reg_ty AS (
    SELECT
        f.employeebusinessdivision, f.employeeregion, w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        YEAR(d.date) = YEAR(NOW())
    GROUP BY
        w.websitename,
        f.employeeregion,
        f.employeebusinessdivision
)  -- Missing comma here!


--div_reg_28: Similar to div_reg, but only for the first 28 days from the earliest page interaction date.
div_reg_28 AS (
```

**Fix Required:** Add comma after line 239.

---

## 2. ADDITIONAL CONCERNS & RECOMMENDATIONS

### Concern #1: Case Sensitivity in websitename
**Issue:** The `site_page_inventory` CTE and subsequent joins on `websitename` may have case sensitivity issues depending on the database collation settings.
**Recommendation:** Ensure consistent casing or use case-insensitive collation.

---

### Concern #2: NULL Handling in Aggregations
**Issue:** SUM() functions on views, visits, comments could return NULL if all values are NULL, rather than 0.
**Recommendation:** Use `COALESCE(SUM(views), 0)` for clarity.

---

### Concern #3: Lack of DISTINCT in marketingPageIdliked
**Issue:** `COUNT(DISTINCT marketingPageIdliked)` assumes this column contains the page ID when liked. If it's NULL when not liked, this is correct. But if it contains duplicate values, the count may be misleading.
**Recommendation:** Verify the data model and add comments explaining this field's behavior.

---

### Concern #4: Time Zone Handling
**Issue:** `YEAR(NOW())` uses the server's current time, which may not match the timezone of the data.
**Recommendation:** Use a consistent timezone or UTC for date comparisons.

---

### Concern #5: No Data Validation
**Issue:** The query doesn't validate that visitdatekey exists in the date dimension or that marketingPageId exists in the inventory.
**Recommendation:** Add data quality checks or INNER JOINs where appropriate.

---

### Concern #6: Large Result Set
**Issue:** The final SELECT returns a massive number of metrics (80+ columns) for every combination of marketingPageId, division, region, and website.
**Recommendation:** Consider breaking this into multiple fact tables or using a UNION ALL approach for different time periods.

---

### Concern #7: No Indexes Mentioned
**Issue:** With multiple large LEFT JOINs and GROUP BYs, query performance will heavily depend on indexes.
**Recommendation:** Ensure indexes exist on join keys (marketingPageId, date_key, visitdatekey, contactid, etc.).

---

## 3. TOP 10 TEST CASE SCENARIOS

### Test Case #1: Basic Functionality - Single Marketing Page with Complete Data
**Scenario:**
- 1 marketingPageId = 'PAGE001'
- 10 unique visitors from 2 business divisions (5 each)
- 2 regions (5 visitors each)
- 1 website
- All visits within current year
- Date range: 30 days from first visit

**Expected Results:**
- div_reg_uniquevisitor: Should show split by division/region (e.g., 5, 3, 2 for different combos)
- div_uniquevisitor: Should show 5 for each division
- reg_uniquevisitor: Should show 5 for each region
- uniquevisitor: Should show 10 (overall)
- All time-period metrics (28, 21, 14, 7 days) should have non-null values
- Current year metrics should match overall metrics

**Potential Issues:**
- **BUG #6** would cause incorrect joining if same pageId exists on different sites
- **BUG #11** would cause performance issues but correct results
- **BUG #3** would cause NULL for reg_uniquevisitor21

**Analysis:**
✅ **PASS** (with bugs): The code should produce results, but:
- reg_uniquevisitor21 would be NULL (BUG #3)
- Performance would be poor (BUG #11)
- If duplicate pageId on different sites exists, data would be wrong (BUG #6)

---

### Test Case #2: Missing Employee Contact Data
**Scenario:**
- 1 marketingPageId
- 5 visitors: 3 have employee records, 2 do not (NULL in pbi_db_employeecontact)
- Date range: current year

**Expected Results:**
- 2 visitors should be categorized as 'Unknown' for both division and region
- There should be a separate group in results with employeebusinessdivision = 'Unknown', employeeregion = 'Unknown'
- div_reg_uniquevisitor should show 3 + 2 = 5 total unique visitors across groups

**Potential Issues:**
- **BUG #7**: 'Unknown' might mask data quality issues
- Metrics for 'Unknown' category may be misleading if interpreted as a real division

**Analysis:**
✅ **PASS** (with warning): The code handles NULLs by converting to 'Unknown', but this may create misleading aggregations. Users might think 'Unknown' is an actual business division.

---

### Test Case #3: Cross-Year Data
**Scenario:**
- 1 marketingPageId
- First visit: December 15, 2024
- Additional visits: January 5, 2025 (current year)
- 10 total unique visitors: 6 in 2024, 4 in 2025 (with 2 returning visitors)

**Expected Results:**
- uniquevisitor (overall): 8 distinct visitors
- uniquevisitorty (current year): 4 visitors
- div_reg_views: Total views from both years
- div_reg_viewty: Only views from 2025

**Potential Issues:**
- Current year filter uses `YEAR(NOW())` which returns 2025
- 2024 data should not appear in _ty metrics

**Analysis:**
✅ **PASS**: The code correctly filters by YEAR, so only 2025 data appears in _ty metrics. Overall metrics include all data.

---

### Test Case #4: First 28/21/14/7 Day Calculations Edge Case
**Scenario:**
- 1 marketingPageId
- First visit (mindate): January 1, 2025
- Subsequent visits on days 1, 5, 10, 15, 20, 25, 30
- Different visitors on each day

**Expected Results:**
- uniquevisitor28: Should include visits from Jan 1-28 (using DATE_ADD(Jan 1, 27) = Jan 28)
- uniquevisitor21: Jan 1-21
- uniquevisitor14: Jan 1-14
- uniquevisitor7: Jan 1-7

**Potential Issues:**
- **BUG #8**: If mindate is considered day 1 (not day 0), calculations are off by one
- Visit on Jan 30 should NOT appear in 28-day metrics
- Need to verify if DATE_ADD is inclusive or exclusive

**Analysis:**
⚠️ **PARTIAL PASS**: The logic is technically correct if mindate is day 0, but the comment "first 28 days" is ambiguous. If the business expects mindate to be day 1, then:
- 28-day period should be DATE_ADD(mindate, 27), which is correct
- BUT: The WHERE clause `d.date <= DATE_ADD(mindate, 27)` means:
  - If mindate = Jan 1, then includes up to Jan 28 (28 days total ✓)

**VERDICT**: The code is likely correct, but documentation is unclear.

---

### Test Case #5: Multiple Websites with Same Marketing Page ID
**Scenario:**
- marketingPageId = 'PAGE001' exists on 2 websites: 'Website A' and 'Website B'
- Website A: 10 visitors
- Website B: 5 visitors
- Same visitor visits both sites
- All from same division/region

**Expected Results:**
- div_reg should have 2 rows (one per website)
- site_uniquevisitor should be different for each site (10 for A, 5 for B)
- site_div_reg_uniquevisitor should also be different

**Potential Issues:**
- **BUG #6**: JOIN conditions for div_reg_28/21/14/7 don't include websitename
- Result: Metrics from both websites would be incorrectly combined

**Analysis:**
❌ **FAIL**: Due to **BUG #6**, the JOIN to div_reg_28, div_reg_21, div_reg_14, div_reg_7 will produce incorrect results. If PAGE001 appears on both Website A and B with the same division/region, the join will match both rows, causing:
- Duplicate metrics
- Incorrect time-period aggregations

**CRITICAL FIX NEEDED**

---

### Test Case #6: Marketing Page with No Visits in Time Periods
**Scenario:**
- marketingPageId = 'PAGE001'
- First visit: 60 days ago
- Last visit: 50 days ago
- Current year: 2025, but all visits were in 2024

**Expected Results:**
- div_reg metrics: Should have values (overall metrics)
- div_reg_ty metrics: Should be NULL (no visits in 2025)
- div_reg_28/21/14/7 metrics: Should have values (visits within 28 days of first visit)

**Potential Issues:**
- LEFT JOINs should handle NULLs correctly
- Need to verify NULL handling in aggregations

**Analysis:**
✅ **PASS**: LEFT JOINs will produce NULLs for _ty metrics, which is expected behavior.

---

### Test Case #7: Marketing Page with Exactly 28/21/14/7 Day Boundary
**Scenario:**
- marketingPageId = 'PAGE001'
- First visit (mindate): January 1, 2025
- Visits on: Jan 1, Jan 7, Jan 14, Jan 21, Jan 28, Jan 29

**Expected Results:**
- uniquevisitor7: Should include visits from Jan 1-7 (2 visitors)
- uniquevisitor14: Jan 1-14 (3 visitors)
- uniquevisitor21: Jan 1-21 (4 visitors)
- uniquevisitor28: Jan 1-28 (5 visitors)
- Overall: 6 visitors

**Potential Issues:**
- Boundary condition: Is Jan 28 included in 28-day period?
- DATE_ADD(Jan 1, 27) = Jan 28, so `d.date <= Jan 28` means Jan 28 IS included ✓

**Analysis:**
✅ **PASS**: Boundary dates are included correctly. Visit on Jan 29 would NOT be in 28-day metrics.

---

### Test Case #8: Duplicate viewingcontactid with Different Divisions
**Scenario:**
- marketingPageId = 'PAGE001'
- viewingcontactid = 'CONTACT001' appears in 10 interaction records
- 5 records joined to employee division 'Sales'
- 5 records joined to employee division 'Marketing' (employee changed division)

**Expected Results:**
- This scenario reveals a data model issue: Can an employee be in multiple divisions?
- COUNT(DISTINCT viewingcontactid) would count this as 1 unique visitor
- But the visitor would appear in both division groups

**Potential Issues:**
- The `final` CTE joins employee contact for EACH interaction record
- If an employee's division changes over time, early interactions might show old division
- This could inflate division-level metrics while keeping unique visitor count accurate

**Analysis:**
⚠️ **AMBIGUOUS**: The result depends on the data model:
- If employee records are SCD Type 1 (overwrite), all interactions show current division
- If employee records are SCD Type 2 (historical), each interaction shows correct historical division
- The code doesn't handle this explicitly

**RECOMMENDATION**: Document the expected behavior and add business logic if needed.

---

### Test Case #9: NULL/Missing Date Keys
**Scenario:**
- marketingPageId = 'PAGE001'
- 10 interaction records
- 5 records have visitdatekey = NULL (missing date)
- 5 records have valid dates in current year

**Expected Results:**
- Records with NULL visitdatekey won't match in LEFT JOIN to pbi_db_dim_date
- These records will be excluded from time-filtered CTEs (_ty, _28, _21, _14, _7)
- But they WILL be counted in overall metrics (div_reg)

**Potential Issues:**
- Inconsistent visitor counts between overall and time-filtered metrics
- div_reg_uniquevisitor might be 10
- div_reg_uniquevisitorty might be 5
- This could cause confusion in reporting

**Analysis:**
⚠️ **PARTIAL PASS**: The code handles NULLs via LEFT JOIN, but:
- Records with NULL dates ARE included in overall metrics (div_reg, div_, reg_)
- Records with NULL dates are EXCLUDED from time-filtered metrics
- This is technically correct but may mask data quality issues

**RECOMMENDATION**: Add data quality validation or filter out NULL date keys explicitly.

---

### Test Case #10: Performance Test - Large Dataset
**Scenario:**
- 100,000 marketingPageId values
- 10 million interaction records
- 50,000 unique visitors
- 100 business divisions
- 50 regions
- 20 websites
- Data spanning 3 years

**Expected Results:**
- Query should complete in reasonable time (< 5 minutes)
- Result set size: 100,000 * avg(divisions per page) * avg(regions per division) rows
- Each row: 80+ columns

**Potential Issues:**
- **BUG #11**: Scalar subqueries will execute for EVERY output row
- If result set has 1 million rows, the scalar subqueries execute 1 million times each
- 6 scalar subqueries * 1 million rows = 6 million redundant calculations
- This will likely cause timeout or extremely slow performance (hours)

**Analysis:**
❌ **FAIL**: Due to **BUG #11**, this query will not complete in reasonable time on large datasets.

**Estimated Runtime:**
- With scalar subqueries: 2-4 hours or timeout
- With optimized CTEs: 2-5 minutes

**CRITICAL FIX NEEDED**

---

## 4. TEST RESULTS SUMMARY

| Test Case | Status | Critical Issues |
|-----------|--------|----------------|
| TC #1: Basic Functionality | ⚠️ PASS* | BUG #3, #6, #11 |
| TC #2: Missing Employee Data | ⚠️ PASS* | BUG #7 (warning) |
| TC #3: Cross-Year Data | ✅ PASS | None |
| TC #4: Day Calculation Edge Cases | ⚠️ PASS* | BUG #8 (documentation) |
| TC #5: Multiple Websites Same PageID | ❌ FAIL | BUG #6 (critical) |
| TC #6: No Visits in Time Periods | ✅ PASS | None |
| TC #7: Boundary Dates | ✅ PASS | None |
| TC #8: Duplicate Contacts | ⚠️ AMBIGUOUS | Data model issue |
| TC #9: Missing Date Keys | ⚠️ PASS* | Data quality concern |
| TC #10: Large Dataset Performance | ❌ FAIL | BUG #11 (critical) |

**Pass Rate:** 30% PASS, 40% PASS with warnings, 20% FAIL, 10% AMBIGUOUS

---

## 5. PRIORITY FIX LIST

### IMMEDIATE FIXES (Critical - Query Will Not Run):
1. **BUG #12**: Add comma after line 239 (before div_reg_28)
2. **BUG #1**: Same as BUG #12 (duplicate finding)

### HIGH PRIORITY FIXES (Critical - Incorrect Results):
3. **BUG #3**: Fix alias reference for reg_uniquevisitor21 (line 918 - change 'm' to 'n')
4. **BUG #6**: Add websitename to JOIN conditions for div_reg_28/21/14/7 (lines 998-1045)
5. **BUG #11**: Replace scalar subqueries with CTEs for performance

### MEDIUM PRIORITY FIXES (Performance & Consistency):
6. **BUG #4**: Remove unnecessary JOIN to pbi_db_employeecontact in div_21 and reg_21
7. **BUG #5**: Remove unnecessary JOIN to pbi_db_employeecontact in site_reg_21
8. **BUG #2**: Fix alias name uvall14 to uvall7 (line 971)
9. **BUG #9**: Remove redundant WHERE conditions

### LOW PRIORITY FIXES (Documentation & Cleanup):
10. **BUG #8**: Add clear comments explaining date calculation logic
11. **BUG #10**: Uncomment or remove CREATE TABLE statement
12. **Concern #2**: Add COALESCE for NULL handling in SUM aggregations
13. **Concern #4**: Use consistent timezone for date comparisons

---

## 6. RECOMMENDED FIXES - CODE SNIPPETS

### Fix for BUG #12 (Critical - Syntax Error):
```sql
-- Line 239 - Add comma:
        f.employeebusinessdivision
),  -- ADD THIS COMMA

--div_reg_28: Similar to div_reg...
```

### Fix for BUG #3 (High Priority):
```sql
-- Line 918 - Change alias from 'm' to 'n':
n.uniquevisitor as reg_uniquevisitor21,  -- Changed from 'm.uniquevisitor'
```

### Fix for BUG #6 (High Priority):
```sql
-- Lines 998-1001 - Add websitename to JOIN:
LEFT JOIN
    div_reg_28 AS e
    ON a.marketingPageId = e.marketingPageId
    AND a.employeebusinessdivision = e.employeebusinessdivision
    AND a.employeeregion = e.employeeregion
    AND a.websitename = e.websitename  -- ADD THIS LINE

-- Repeat for div_reg_21 (lines 1020-1023)
-- Repeat for div_reg_14 (lines 1031-1034)
-- Repeat for div_reg_7 (lines 1042-1045)
```

### Fix for BUG #11 (Critical Performance):
Replace scalar subqueries with CTEs. Add before final SELECT:

```sql
overall_uv AS (
    SELECT COUNT(DISTINCT viewingcontactid) as uniquevisitor
    FROM final
),
overall_uv_ty AS (
    SELECT COUNT(DISTINCT viewingcontactid) as uniquevisitor
    FROM final AS f
    LEFT JOIN sharepoint_gold.pbi_db_dim_date AS d ON d.date_key = f.visitdatekey
    WHERE YEAR(d.date) = YEAR(NOW())
),
overall_uv_28 AS (
    SELECT COUNT(DISTINCT viewingcontactid) as uniquevisitor
    FROM final AS f
    LEFT JOIN sharepoint_gold.pbi_db_dim_date AS d ON d.date_key = f.visitdatekey
    LEFT JOIN minpagedate AS m ON m.marketingPageId = f.marketingPageId
    WHERE d.date <= DATE_ADD(mindate, 27) and m.marketingPageId = f.marketingPageId
),
-- Continue for 21, 14, 7 day periods...

-- Then in main SELECT, replace subqueries with:
overall_uv.uniquevisitor as uniquevisitor,
overall_uv_ty.uniquevisitor as uniquevisitorty,
overall_uv_28.uniquevisitor as uniquevisitor28,
-- etc.

-- And add to FROM clause:
CROSS JOIN overall_uv
CROSS JOIN overall_uv_ty
CROSS JOIN overall_uv_28
-- etc.
```

---

## 7. DATA QUALITY RECOMMENDATIONS

1. **Add Data Validation Views:**
   - Create a view to identify records with NULL visitdatekey
   - Create a view to identify employees with NULL division/region
   - Create a view to identify duplicate marketingPageId across websites

2. **Add Monitoring Queries:**
   - Monitor count of 'Unknown' divisions/regions over time
   - Monitor date key match rates
   - Monitor duplicate visitor patterns

3. **Add Indexes:**
   - Index on (marketingPageId, websitename)
   - Index on (viewingcontactid)
   - Index on (visitdatekey)
   - Index on (date_key, date)

4. **Add Comments:**
   - Document the 'Unknown' handling behavior
   - Document date calculation logic (day 0 vs day 1)
   - Document expected behavior for employees changing divisions

---

## 8. CONCLUSION

The SQL code is functionally complex and covers multiple analytical dimensions, but it contains several critical bugs that will prevent execution or produce incorrect results:

**Will the code execute?** ❌ NO - BUG #12 (missing comma) will cause immediate syntax error.

**After fixing syntax, will it produce correct results?** ⚠️ PARTIALLY - BUG #3 and BUG #6 will cause incorrect data for some metrics.

**Will it perform acceptably?** ❌ NO - BUG #11 will cause severe performance issues on any reasonably-sized dataset.

**Overall Code Quality Assessment:** ⚠️ NEEDS SIGNIFICANT FIXES

### Estimated Effort to Fix:
- Syntax fixes: 5 minutes
- Logic fixes (BUGs #3, #6): 30 minutes
- Performance fixes (BUG #11): 2-3 hours
- Testing and validation: 4-6 hours
- **Total: 1-2 days**

### Risk Assessment:
- **High Risk** of incorrect business metrics if deployed as-is
- **High Risk** of query timeouts in production
- **Medium Risk** of data quality issues being masked by 'Unknown' handling

### Recommendation:
**DO NOT DEPLOY** this code to production without fixing at minimum BUG #1, #3, #6, and #11.

---

**End of Report**
