# Excel File Guide: Unique Reach Calculation

## File Location
`/Users/micha/Documents/Fabric/unique_reach_calculation_guide.xlsx`

## Purpose
This Excel workbook provides **visual, step-by-step examples** of how Unique Reach (deduplicated employee counts) is calculated across **all 4 time periods** (7, 14, 21, 28 days) for three different filter scenarios.

**Target Audience:** Business stakeholders and executives who need to understand the calculation process without technical jargon.

---

## Workbook Structure (5 Sheets)

### Sheet 1: Overview & Sample Data
**What it shows:**
- Context: 130K employees, 774 sites, 40K articles
- The 3 scenarios covered
- Sample articles with their time windows for all 4 periods
- Sample employee visits with flags showing which time windows they fall into

**Color Coding:**
- ✓ = Green = Visit occurred within time window
- ✗ = Red = Visit occurred outside time window

**Key Feature:** Shows all 4 time windows (7, 14, 21, 28 days) for each article

---

### Sheet 2: Scenario 1 - Site Filter ("News & Events")
**Business Question:** "What % of our 130,000 employees engaged with News & Events?"

**3-Step Visual Process:**

#### STEP 1: Flag Visits
- Shows all employees who visited "News & Events" articles
- Flags whether each visit was within 7d, 14d, 21d, or 28d windows
- **Color coded:** Green = within window, Red = outside window
- Example: E004 Emma visited on day 10 → ✗ NO for 7d, but ✓ YES for 14d/21d/28d

#### STEP 2: Deduplicate by Employee
- Consolidates multiple visits per employee
- Shows which employees are counted in each time period
- Highlights: E001 John visited 2 articles (counted once), E004 Emma only in 14d+
- **Color coded:** Green = ✓ COUNT this employee, Red = ✗ NO don't count

#### STEP 3: Final Results
- **Yellow highlight** on "Unique Employees" column (the key metric!)
- Shows results for all 4 time periods:
  - First 7 Days: 4 employees (0.003% of company)
  - First 14 Days: 5 employees (0.004% of company)
  - First 21 Days: 5 employees (0.004% of company)
  - First 28 Days: 5 employees (0.004% of company)
- Includes Total Interactions and Overlap Rate
- Interpretation column explains what the numbers mean

**Key Insight Box:**
- "News & Events reached 5 unique employees (0.004% of 130K company)"
- Shows that without deduplication (6 visits) vs with deduplication (5 employees)

---

### Sheet 3: Scenario 2 - Division Filter ("Marketing")
**Business Question:** "What % of Marketing division engaged with ANY content?"

**3-Step Visual Process:**

#### STEP 1: Flag Marketing Employee Visits
- Shows only Marketing employees (E001, E003, E005)
- **Note section** explains: E002 (Sales) and E004 (Engineering) filtered out
- Shows visits to ANY site (News & Events, HR Updates, Tech Blog)
- All 4 time periods flagged

#### STEP 2: Deduplicate Marketing Employees
- Consolidates to 3 unique Marketing employees
- Shows article count per employee
- E001 John read 2 articles (multi-reader)

#### STEP 3: Final Results
- **Yellow highlight** on "% of Marketing (5K)" column
- All 4 time periods show same result:
  - 3 employees (0.06% of 5,000 Marketing division)
  - 4 total visits
  - 1.3 avg articles per employee

**Key Insight:**
- "3 Marketing employees engaged (0.06% of 5,000 Marketing division)"
- Can compare divisions: "Marketing 0.06% vs Sales 0.04%"

---

### Sheet 4: Scenario 3 - Combined Filter (Site + Division)
**Business Question:** "What % of Marketing engaged with News & Events?"

**Shows:**
- Direct final results (skips detailed steps since they're shown in Sheets 2 & 3)
- **Yellow highlight** on "% of Marketing"
- All 4 time periods:
  - 3 employees (0.06% of Marketing, 0.002% of company)
  - 4 visits total
  - 25% overlap rate

**Key Concept:**
- Combined filters = INTERSECTION (not union)
- Lists the 3 employees: E001 John, E003 Michael, E005 Carlos
- All are Marketing AND all visited News & Events

---

### Sheet 5: Summary & Comparison
**What it shows:**
- **Side-by-side comparison** of all 3 scenarios across all 4 time periods
- Comparison table with yellow highlights on employee counts

**Summary Table:**
| Scenario | Filter | 7 Days | 14 Days | 21 Days | 28 Days | Interactions | Overlap |
|----------|--------|--------|---------|---------|---------|--------------|---------|
| Site Only | News & Events | 4 emp | 5 emp | 5 emp | 5 emp | 6 visits | 17% |
| Division Only | Marketing | 3 emp | 3 emp | 3 emp | 3 emp | 4 visits | 25% |
| Site + Division | Both | 3 emp | 3 emp | 3 emp | 3 emp | 4 visits | 25% |

**Key Observations:**
1. Most engagement happens in first 7-14 days
2. Combined filters show INTERSECTION (not union)
3. Deduplication is critical for accurate employee reach metrics

---

## Color Coding Legend

| Color | Meaning |
|-------|---------|
| **Blue header** | Section headers and titles |
| **Light blue** | Column headers |
| **Green** | Step 1 sections (Flagging) |
| **Orange** | Step 2 sections (Deduplication) |
| **Light blue** | Step 3 sections (Final Results) |
| **Yellow highlight** | Key metrics (Unique Employees, %) |
| **Green cells** | ✓ YES / ✓ COUNT (within window, counted) |
| **Red cells** | ✗ NO (outside window, not counted) |

---

## How to Use This File

### For Business Stakeholders:
1. **Start with Sheet 1** to understand the sample data
2. **Go to Sheet 2** to see the full step-by-step process
3. **Look for yellow highlights** - these are your key metrics
4. **Read "KEY INSIGHT" boxes** at the bottom of each scenario
5. **Use Sheet 5** for quick comparison across scenarios

### For Executive Presentations:
1. **Use Sheet 5 Summary** as your main slide
2. **Reference specific scenarios** from Sheets 2-4 if questioned
3. **Show Sheet 2 STEP 2** to explain deduplication concept
4. **Highlight yellow cells** when discussing "% of Company"

### For Training Sessions:
1. **Walk through Sheet 2** step-by-step (most detailed)
2. **Show color coding** to illustrate which visits count
3. **Compare results** across all 4 time periods
4. **Demonstrate filter impact** using Sheet 5 comparison

---

## Key Messages to Convey

### 1. Time Periods Matter
- **All 4 periods analyzed:** 7, 14, 21, 28 days
- **Most growth in first 7-14 days:** Little new engagement after day 14
- **Example:** News & Events reached 4 employees in 7 days, 5 employees by day 14, then plateaued

### 2. Deduplication is Critical
- **Without deduplication:** 6 total visits → Would report "6 visitors"
- **With deduplication:** 5 unique employees → Correct count
- **Impact:** One employee (John) visited 2 articles but is only counted once

### 3. Filter Combinations
- **Site filter:** Tracks engagement with specific content (News & Events)
- **Division filter:** Tracks engagement from specific employees (Marketing)
- **Combined:** Tracks INTERSECTION (Marketing employees who visited News & Events)

### 4. % of Company is the Key Metric
- **Absolute numbers** are less meaningful (5 employees)
- **Percentage** provides context (0.004% of 130K company)
- **For divisions:** Show % of division (0.06% of 5K Marketing)

---

## Technical Notes

### Why Sample Data?
- Real data would have thousands of rows
- Sample data (5 employees, 3 articles) makes the process visible
- All calculations scale to full dataset (130K employees, 40K articles)

### Why All 4 Time Periods?
- Business originally mentioned 7, 14, 21, 28 days
- Showing all 4 demonstrates how engagement grows (or plateaus) over time
- Stakeholders can choose which period to focus on

### Color Coding Methodology
- **Consistent across all sheets** for easy recognition
- **Green/Red for binary states** (yes/no, count/don't count)
- **Yellow for key metrics** that stakeholders care about most

---

## Common Questions & Answers

**Q: Why does "First 7 Days" show 4 employees but "First 14 Days" shows 5?**
A: Because E004 Emma visited on day 10, which is outside the 7-day window but within the 14-day window.

**Q: Why is overlap rate different across scenarios?**
A: Overlap rate = (Interactions - Unique) / Interactions. Different scenarios have different numbers of multi-article readers.

**Q: Why are all time periods the same for Division and Combined filters?**
A: In this sample data, all Marketing employees visited within the first 7 days. In real data, you'd see variation.

**Q: Can we add more time periods?**
A: Yes! The methodology works for any time period (30, 60, 90 days). Just need to add columns.

---

## Next Steps

### To Customize for Your Data:
1. Replace sample employees with real employee IDs
2. Replace sample articles with real article data
3. Add actual visit timestamps
4. Expand to more rows (currently ~10, could be thousands)

### To Add More Scenarios:
- Add sheets for Region filters
- Add sheets for combined Site + Region
- Add sheets for Site + Division + Region

### To Add Visualizations:
- Create pivot charts from the summary table
- Add timeline charts showing engagement over 28 days
- Add comparison bar charts for division-level engagement

---

## Files in This Package

1. **unique_reach_calculation_guide.xlsx** (this file)
   - 5 sheets with visual examples
   - All 4 time periods (7, 14, 21, 28 days)
   - 3 filter scenarios

2. **uv_aggregation_strategy_proposal.docx**
   - Full business proposal
   - Technical implementation details
   - For executive review

3. **130K_EMPLOYEE_UPDATES.md**
   - Summary of why 130K employee context matters
   - Business and technical implications

4. **CONVERSION_GUIDE.md**
   - How to convert markdown to Word
   - Document formatting tips

---

## Support

If you have questions about:
- **The calculation methodology:** See main proposal document
- **How to use the Excel file:** Refer to this guide
- **Technical implementation:** See Section 8 of proposal document
- **Business questions:** See Section 10 of proposal document

---

**Document Version:** 1.0
**Last Updated:** 2025-10-09
**Created by:** Data Engineering Team
**File Size:** 12 KB
**Sheets:** 5
**Target Audience:** Business stakeholders, executives, non-technical users
