%sql
-- CREATE OR REPLACE TABLE sharepoint_gold.pbi_db_overview_fact_tbl using delta
location 'abfss://gold@d6476p1s05sweugempI.dfs.core.windows.net/employee_analytics/pbi_db_overview_fact_tbl'

--div_reg: Aggregates interaction metrics (unique visitors, likes, views, visits, comments) for each marketing page, grouped by Business division and region.
WITH minpagedate as (
    select MIN(d.date) as mindate ,m.marketingPageId
    FROM
        sharepoint_gold.pbi_db_interactions_metrics AS m
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = m.visitdatekey
    GROUP BY m.marketingPageId
),
site_page_inventory as (select distinct marketingPageId,websitename from sharepoint_gold.pbi_db_website_page_inventory),
final as (select f.*, case when e.employeebusinessdivision is null then 'Unknown' else e.employeebusinessdivision end as employeebusinessdivision,
        case when e.employeeregion is null then 'Unknown' else e.employeeregion end as employeeregion from sharepoint_gold.pbi_db_interactions_metrics F
LEFT JOIN sharepoint_gold.pbi_db_employeecontact AS e on f.viewingcontactid = e.contactid),

div_reg AS (
    SELECT
        f.marketingPageId,
        f.employeebusinessdivision,
        f.employeeregion,
        w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor,
        COUNT(DISTINCT marketingPageIdliked) AS likes,
        SUM(views) AS views,
        SUM(visits) AS visits,
        SUM(comments) AS comments
    FROM
        final AS f
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    GROUP BY
        f.marketingPageId,
        w.websitename,
        f.employeebusinessdivision,
        f.employeeregion
),
--div_: Counts unique visitors per business division.
div_ AS (
    SELECT
        f.employeebusinessdivision,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    GROUP BY
        f.employeebusinessdivision
),
--reg_: Counts unique visitors per region.
reg_AS (
    SELECT
        f.employeeregion,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    GROUP BY
        f.employeeregion
),
------------------
--div_: Counts unique visitors per site and business division by site.
site_ AS (
    SELECT
        w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    GROUP BY
        w.websitename,
        
),

site_div_ AS (
    SELECT
        f.employeebusinessdivision, w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    GROUP BY
        w.websitename,
        f.employeebusinessdivision
),
--reg_: Counts unique visitors per region by site.
site_reg_ AS (
    SELECT
        f.employeeregion,w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    GROUP BY
        w.websitename,
        f.employeeregion
),
