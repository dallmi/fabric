# UV Aggregation Strategy

Complete documentation for calculating Unique Visitor (UV) metrics across aggregated levels (Site, Division, Region) for a **130,000 employee intranet** with 774 sites and 40,000 articles.

## 📁 Main Files

### Primary Deliverables

| File | Description | Use For |
|------|-------------|---------|
| **uv_aggregation_strategy_proposal_formatted.docx** | Full business proposal with TOC | Executive review, stakeholder meetings |
| **uv_aggregation_strategy_proposal.md** | Source markdown (for edits) | Making updates, version control |
| **unique_reach_calculation_guide.xlsx** | Interactive Excel workbook with visual examples | Training, demonstrations, business meetings |
| **DELIVERABLES_SUMMARY.md** | Package overview and quick start guide | Understanding what's included |

### Key Features

- ✅ **All 4 time periods:** 7, 14, 21, 28 days post-publishing
- ✅ **3 filter scenarios:** Site only, Division only, Combined filters
- ✅ **130K employee context:** Tailored specifically for internal intranet
- ✅ **Visual examples:** Color-coded Excel sheets for easy understanding
- ✅ **% of Company metrics:** Executive-ready KPIs

## 📊 Excel File (RECOMMENDED FOR MEETINGS)

**File:** `unique_reach_calculation_guide.xlsx`

**5 Worksheets:**
1. Overview & Sample Data
2. Site Filter Scenario (News & Events)
3. Division Filter Scenario (Marketing)
4. Combined Filter Scenario (Site + Division)
5. Summary & Comparison

**Color Coding:**
- 🟢 Green = Counted / Within window
- 🔴 Red = Not counted / Outside window
- 🟡 Yellow = Key metrics

## 📄 Word Document

**File:** `uv_aggregation_strategy_proposal_formatted.docx`

**Contents:**
- Executive summary
- Problem statement
- Section 5: Why 130K employee count matters
- 3 solution options (Total Interactions, Unique Reach, Hybrid)
- Visual step-by-step guide (non-technical)
- Dashboard mockup with "% of Company"
- Technical implementation (SQL)
- Migration plan
- Open questions for discussion
- 3 appendices

**Pages:** ~35 pages
**Ready for:** Executive presentation and business review

## 📚 Supporting Guides

Located in `guides/` subdirectory:

| File | Description |
|------|-------------|
| **EXCEL_GUIDE.md** | Complete guide to using the Excel workbook |
| **130K_EMPLOYEE_UPDATES.md** | Why 130K employee context matters |
| **CONVERSION_GUIDE.md** | How to convert markdown to Word |

## 🎯 Quick Start

### For Business Stakeholder Meeting:
1. Open `unique_reach_calculation_guide.xlsx`
2. Start with Sheet 5 (Summary)
3. Walk through Sheet 2 (detailed example)
4. Discuss open questions from Word doc Section 10

### For Executive Presentation:
1. Review `DELIVERABLES_SUMMARY.md` first
2. Present Excel Sheet 5 (Summary)
3. Use Word doc Sections 5-6 for business case
4. Reference Word doc Section 10 for decisions needed

### For Technical Implementation:
1. Read Word doc Section 8 (Technical Implementation)
2. Review Word doc Appendix C (Technical Advantages)
3. Validate with Excel file examples

## 🔑 Key Concepts

### Unique Reach (Deduplicated)
Count each employee **once** even if they visited multiple articles during launch periods.

**Example:**
- Employee visits 3 articles → Counted as 1 unique employee
- Shows true audience size: "5 employees (0.004% of company)"

### Total Interactions (With Duplicates)
Count each visit separately.

**Example:**
- Employee visits 3 articles → Counted as 3 interactions
- Shows engagement volume: "6 total visits"

### Why Deduplication Matters
- **Without:** 6 visits → Incorrectly report "6 visitors"
- **With:** 5 unique employees → Correct count (one visited 2 articles)
- **Impact:** Prevents 20-50% overcount

## 📈 Business Value

1. **Accurate Metrics:** No double-counting of engaged employees
2. **% of Company:** Executive-friendly KPIs (e.g., "2.4% of company engaged")
3. **Division Comparison:** "Marketing 64% vs Sales 45%" engagement
4. **Realistic Targets:** Industry standard 5-15% monthly active for intranets
5. **Fast Queries:** Sub-second performance (thanks to 130K fixed user base)

## 🚀 Next Steps

1. **Review** Excel file with 2-3 business stakeholders
2. **Present** to executive sponsor
3. **Discuss** open questions (Word doc Section 10)
4. **Approve** Hybrid Approach recommendation
5. **Begin** Phase 1 implementation (validation)

## 📞 Questions?

See:
- **Excel usage:** `guides/EXCEL_GUIDE.md`
- **Business case:** Word doc Section 5
- **Technical details:** Word doc Section 8
- **Package overview:** `DELIVERABLES_SUMMARY.md`

---

**Created:** October 2025
**For:** 130K employee intranet
**Status:** Ready for business review
