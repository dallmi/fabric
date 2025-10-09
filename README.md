# Fabric Analytics Repository

This repository contains two main analytics projects for SharePoint/Intranet:

---

## 📊 Projects

### 1. [UV Aggregation Strategy](./uv-aggregation-strategy/) ⭐ NEW
**Comprehensive documentation for calculating deduplicated employee engagement metrics**

Complete business proposal and technical implementation for Unique Visitor (UV) metrics calculation across a **130,000 employee intranet** with 774 sites and 40,000 articles.

**📁 Key Deliverables:**
- 📊 **Interactive Excel workbook** - Visual step-by-step examples with color coding
- 📄 **Business proposal (Word)** - 35-page executive-ready document
- 📚 **Supporting guides** - Usage guides and context documentation

**✨ Features:**
- All 4 time periods: 7, 14, 21, 28 days post-publishing
- 3 filter scenarios: Site only, Division only, Combined filters
- Deduplication methodology with visual examples
- "% of Company" executive metrics
- Sub-second query performance

**👉 [View UV Aggregation Strategy Details →](./uv-aggregation-strategy/)**

---

### 2. [SQL Analysis](./sql-analysis/)
**SharePoint analytics SQL code and data model documentation**

Analysis and documentation of SharePoint analytics SQL code with complete data model and sample data generation.

**📁 Contents:**
- Fixed and optimized SQL code
- Comprehensive data model documentation
- Sample data generation tools
- Excel file with complete test data

**👉 [View SQL Analysis Details →](./sql-analysis/)**

---

## 🚀 Quick Start

### For Business Stakeholders:
1. Navigate to **[uv-aggregation-strategy/](./uv-aggregation-strategy/)**
2. Open `unique_reach_calculation_guide.xlsx` for interactive visual examples
3. Review `uv_aggregation_strategy_proposal_formatted.docx` for full business proposal

### For Technical Teams:
1. Review **[uv-aggregation-strategy/](./uv-aggregation-strategy/)** for UV calculation methodology
2. Check **[sql-analysis/](./sql-analysis/)** for data model and SQL implementation
3. See `extracted_code_FIXED.sql` for optimized SQL code

### For Executives:
1. Open **[uv-aggregation-strategy/unique_reach_calculation_guide.xlsx](./uv-aggregation-strategy/unique_reach_calculation_guide.xlsx)**
2. Start with Sheet 5 (Summary & Comparison)
3. Review key insights showing "% of Company" metrics

---

## 📂 Repository Structure

```
Fabric/
├── README.md (this file)
├── uv-aggregation-strategy/          # UV metrics calculation project
│   ├── README.md
│   ├── unique_reach_calculation_guide.xlsx
│   ├── uv_aggregation_strategy_proposal_formatted.docx
│   ├── uv_aggregation_strategy_proposal.md
│   ├── DELIVERABLES_SUMMARY.md
│   └── guides/
│       ├── EXCEL_GUIDE.md
│       ├── 130K_EMPLOYEE_UPDATES.md
│       └── CONVERSION_GUIDE.md
│
└── sql-analysis/                     # SQL code and data model
    ├── README.md
    ├── extracted_code_FIXED.sql
    ├── extracted_code.sql
    ├── code_analysis_report.md
    ├── sharepoint_analytics_sample_data.xlsx
    └── generate_complete_sample.py
```

---

## 🎯 Key Features

### UV Aggregation Strategy Project:
- ✅ **Visual Learning:** Color-coded Excel examples (Green = counted, Red = not counted)
- ✅ **All Time Periods:** Comprehensive coverage of 7, 14, 21, 28-day windows
- ✅ **Executive Ready:** "% of Company" metrics for 130K employee base
- ✅ **Non-Technical:** Business-friendly language and visual examples
- ✅ **Implementation Ready:** Complete SQL code and migration plan

### SQL Analysis Project:
- ✅ **Optimized Code:** Fixed SQL with performance improvements
- ✅ **Complete Data Model:** All dimensions and facts documented
- ✅ **Sample Data:** Excel file with test data for validation
- ✅ **Pre-Aggregation:** Fast Power BI reports through SQL pre-calculation

---

## 📝 Recent Updates

**October 2025:**
- ✅ Added comprehensive UV aggregation strategy documentation package
- ✅ Created interactive Excel workbook with 5 worksheets and color-coded examples
- ✅ Integrated 130K employee context across all documentation
- ✅ Organized repository into logical project folders
- ✅ Added detailed READMEs for navigation
- ✅ Removed duplicate/unformatted files

---

## 🔗 Related Documentation

- **UV Calculation Methodology:** [uv-aggregation-strategy/](./uv-aggregation-strategy/)
- **Excel Guide:** [uv-aggregation-strategy/guides/EXCEL_GUIDE.md](./uv-aggregation-strategy/guides/EXCEL_GUIDE.md)
- **Technical Advantages:** See Word doc Appendix C
- **SQL Data Model:** [sql-analysis/code_analysis_report.md](./sql-analysis/code_analysis_report.md)

---

## 📞 Support

**For questions about:**
- **UV metrics calculation:** See [uv-aggregation-strategy/DELIVERABLES_SUMMARY.md](./uv-aggregation-strategy/DELIVERABLES_SUMMARY.md)
- **Excel workbook usage:** See [uv-aggregation-strategy/guides/EXCEL_GUIDE.md](./uv-aggregation-strategy/guides/EXCEL_GUIDE.md)
- **SQL implementation:** See [sql-analysis/](./sql-analysis/)
- **130K employee context:** See [uv-aggregation-strategy/guides/130K_EMPLOYEE_UPDATES.md](./uv-aggregation-strategy/guides/130K_EMPLOYEE_UPDATES.md)

---

**Last Updated:** October 2025
**Status:** Ready for business review and implementation
