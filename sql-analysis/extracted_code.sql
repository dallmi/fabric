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
site_div_reg_ AS (
    SELECT
        f.employeebusinessdivision,f.employeeregion,w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    GROUP BY
        w.websitename,
        f.employeeregion,
        f.employeebusinessdivision
),

------------------

--div_req_ty: Similar to div_reg, but only for the current year.
div_req_ty AS (
    SELECT
        f.marketingPageId,
        w.websitename,
        f.employeebusinessdivision,
        f.employeeregion,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor,
        COUNT(DISTINCT marketingPageIdliked) AS likes,
        SUM(views) AS views,
        SUM(visits) AS visits,
        SUM(comments) AS comments
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        YEAR(d.date) = YEAR(NOW())
    GROUP BY
        f.marketingPageId,
        w.websitename,
        f.employeebusinessdivision,
        f.employeeregion
),
--div_ty: Counts unique visitors per business division for the current year.
div_ty AS (
    SELECT
        f.employeebusinessdivision,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    WHERE
        YEAR(d.date) = YEAR(NOW())
    GROUP BY
        f.employeebusinessdivision
),
--reg_ty: Counts unique visitors per region for the current year.
reg_ty AS (
    SELECT
        f.employeeregion,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    WHERE
        YEAR(d.date) = YEAR(NOW())
    GROUP BY
        f.employeeregion
),

site_ty AS (
    SELECT
        w.websitename,
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
        w.websitename

),


-- div_ty: Counts unique visitors per business division for the current year.
site_div_ty AS (
    SELECT
        f.employeebusinessdivision, 
        w.websitename,
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
        f.employeebusinessdivision
),
--reg_ty: Counts unique visitors per region for the current year.
site_reg_ty AS (
    SELECT
        f.employeeregion,
        w.websitename,
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
        f.employeeregion
),
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
),



--div_reg_28: Similar to div_reg, but only for the first 28 days from the earliest page interaction date.
div_reg_28 AS (
    SELECT
        f.marketingPageId,
        w.websitename,
        f.employeebusinessdivision,
        f.employeeregion,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor,
        COUNT(DISTINCT marketingPageIdliked) AS likes,
        SUM(views) AS views,
        SUM(visits) AS visits,
        SUM(comments) AS comments
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 27) and m.marketingPageId = f.marketingPageId
    GROUP BY
        f.marketingPageId, w.websitename,
        f.employeebusinessdivision,
        f.employeeregion
),
--div_28: Counts unique visitors per business division for the first 28 days from the earliest page interaction date.
div_28 AS (
    SELECT
        f.employeebusinessdivision,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 27) and m.marketingPageId = f.marketingPageId
    GROUP BY
        f.employeebusinessdivision
),
--reg_28: Counts unique visitors per region for the first 28 days from the earliest page interaction date.
reg_28 AS (
    SELECT
        f.employeeregion,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 27) and m.marketingPageId = f.marketingPageId
    GROUP BY
        f.employeeregion
),

site_28 AS (
    SELECT
        w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 27) and m.marketingPageId = f.marketingPageId
    GROUP BY
        w.websitename

),

-- div_28: Counts unique visitors per business division for the first 28 days from the earliest page interaction date.
site_div_28 AS (
    SELECT
        f.employeebusinessdivision, w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 27) and m.marketingPageId = f.marketingPageId
    GROUP BY w.websitename,
        f.employeebusinessdivision
),
--reg_28: Counts unique visitors per region for the first 28 days from the earliest
site_reg_28 AS (
    SELECT
        f.employeeregion,w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 27) and m.marketingPageId = f.marketingPageId
    GROUP BY w.websitename,
        f.employeeregion
),
site_div_reg_28 AS (
    SELECT
        f.employeebusinessdivision,f.employeeregion,w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 27) and m.marketingPageId = f.marketingPageId
    GROUP BY 
        w.websitename,
        f.employeeregion,
        f.employeebusinessdivision
),





--div_reg_21: Similar to div_reg, but only for the first 21 days from the earliest page interaction date.
div_reg_21 AS (
    SELECT
        f.marketingPageId, w.websitename,
        f.employeebusinessdivision,
        f.employeeregion,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor,
        COUNT(DISTINCT marketingPageIdliked) AS likes,
        SUM(views) AS views,
        SUM(visits) AS visits,
        SUM(comments) AS comments
    FROM
        final AS f

    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 20) and m.marketingPageId = f.marketingPageId
    GROUP BY
        f.marketingPageId, w.websitename,
        f.employeebusinessdivision,
        f.employeeregion
),
--div_21: Counts unique visitors per business division for the first 21 days from the earliest page interaction date.
div_21 AS (
    SELECT
        f.employeebusinessdivision,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_employeecontact AS e
        ON f.viewingcontactid = e.contactid
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 20) and m.marketingPageId = f.marketingPageId
    GROUP BY
        f.employeebusinessdivision
),
--reg_21: Counts unique visitors per region for the first 21 days from the earliest page interaction date.
reg_21 AS (
    SELECT
        f.employeeregion,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_employeecontact AS e
        ON f.viewingcontactid = e.contactid
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 20) and m.marketingPageId = f.marketingPageId
    GROUP BY
        f.employeeregion
),

site_21 AS (
    SELECT
        w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 20) and m.marketingPageId = f.marketingPageId
    GROUP BY
        w.websitename

),

-- div_21: Counts unique visitors per business division for the first 21 days from the earliest page interaction date.
site_div_21 AS (
    SELECT
        f.employeebusinessdivision, w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    LEFT JOIN site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 20) and m.marketingPageId = f.marketingPageId
    GROUP BY f.employeebusinessdivision, 
        w.websitename
),
--reg_21: Counts unique visitors per region for the first 21 days from the earliest
site_reg_21 AS (
    SELECT
        f.employeeregion,w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_employeecontact AS e
        ON f.viewingcontactid = e.contactid
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 20) and m.marketingPageId = f.marketingPageId
    GROUP BY w.websitename,
        f.employeeregion
),
site_div_reg_21 AS (
    SELECT
        f.employeebusinessdivision,f.employeeregion,w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 20) and m.marketingPageId = f.marketingPageId
    GROUP BY 
        w.websitename,
        f.employeeregion,
        f.employeebusinessdivision
),


-- joins the CTEs to combine the aggregated metrics. Retrieves various metrics for each marketing page, including_ Overall Metrics (div_reg), Current Year Metrics (div_reg_ty), and First 28/21 Days Metrics (div_reg_28, div_reg_21). Includes UV at different levels (overall, by division, by region, by site, etc.) for comprehensive analysis.

--div_reg_14: Similar to div_reg, but only for the first 14 days from the earliest page interaction date.
div_reg_14 AS (
    SELECT
        f.marketingPageId, w.websitename,
        f.employeebusinessdivision,
        f.employeeregion,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor,
        COUNT(DISTINCT marketingPageIdliked) AS likes,
        SUM(views) AS views,
        SUM(visits) AS visits,
        SUM(comments) AS comments
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    LEFT JOIN site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 13) and m.marketingPageId = f.marketingPageId
    GROUP BY
        f.marketingPageId, w.websitename,
        f.employeebusinessdivision,
        f.employeeregion
),
--div_14: Counts unique visitors per business division for the first 14 days from the earliest page interaction date.
div_14 AS (
    SELECT
        f.employeebusinessdivision,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 13) and m.marketingPageId = f.marketingPageId
    GROUP BY
        f.employeebusinessdivision
),
--reg_14: Counts unique visitors per region for the first 14 days from the earliest page interaction date.
reg_14 AS (
    SELECT
        f.employeeregion,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM        
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 13) and m.marketingPageId = f.marketingPageId
    GROUP BY
        f.employeeregion
),

site_14 AS (
    SELECT
        w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 13) and m.marketingPageId = f.marketingPageId
    GROUP BY
        w.websitename

),
-- div_14: Counts unique visitors per business division for the first 14 days from the earliest page interaction date.
site_div_14 AS (
    SELECT
        f.employeebusinessdivision, w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 13) and m.marketingPageId = f.marketingPageId
    GROUP BY w.websitename,
        f.employeebusinessdivision
),
--reg_14: Counts unique visitors per region for the first 14 days from the earliest
site_reg_14 AS (
    SELECT
        f.employeeregion,w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 13) and m.marketingPageId = f.marketingPageId
    GROUP BY w.websitename,
        f.employeeregion
),
site_div_reg_14 AS (
    SELECT
        f.employeebusinessdivision,f.employeeregion,w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 13) and m.marketingPageId = f.marketingPageId
    GROUP BY 
        w.websitename,
        f.employeeregion,   
        f.employeebusinessdivision
),


--div_reg_7: Similar to div_reg, but only for the first 7 days from the earliest page interaction date.
div_reg_7 AS (
    SELECT
        f.marketingPageId, w.websitename,
        f.employeebusinessdivision,
        f.employeeregion,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor,
        COUNT(DISTINCT marketingPageIdliked) AS likes,
        SUM(views) AS views,
        SUM(visits) AS visits,
        SUM(comments) AS comments
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 6) and m.marketingPageId = f.marketingPageId
    GROUP BY
        f.marketingPageId, w.websitename,
        f.employeebusinessdivision,
        f.employeeregion
),
--div_7: Counts unique visitors per business division for the first 7 days from the earliest page interaction date.
div_7 AS (
    SELECT
        f.employeebusinessdivision,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 6) and m.marketingPageId = f.marketingPageId
    GROUP BY
        f.employeebusinessdivision
),
--reg_7: Counts unique visitors per region for the first 7 days from the earliest page interaction date.
reg_7 AS (
    SELECT
        f.employeeregion,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN   
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 6) and m.marketingPageId = f.marketingPageId
    GROUP BY
        f.employeeregion
)
,

site_7 AS (
    SELECT
        w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 6) and m.marketingPageId = f.marketingPageId
    GROUP BY
        w.websitename

),

-- div_7: Counts unique visitors per business division for the first 7 days from the earliest page interaction date.
site_div_7 AS (
    SELECT
        f.employeebusinessdivision, w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 6) and m.marketingPageId = f.marketingPageId
    GROUP BY w.websitename,
        f.employeebusinessdivision
),
--reg_7: Counts unique visitors per region for the first 7 days from the earliest
site_reg_7 AS (
    SELECT
        f.employeeregion,w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    left join site_page_inventory AS w ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 6) and m.marketingPageId = f.marketingPageId
    GROUP BY w.websitename,
        f.employeeregion
),
site_div_reg_7 AS (
    SELECT
        f.employeebusinessdivision,f.employeeregion,w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        final AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d        
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate AS m
        ON m.marketingPageId = f.marketingPageId
    LEFT JOIN
        site_page_inventory AS w
        ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 6) and m.marketingPageId = f.marketingPageId
    GROUP BY w.websitename,
        f.employeebusinessdivision,f.employeeregion
)

--joins the CTEs to combine the aggregated metrics. Retrieves various metrics for each marketing page, including_ Overall Metrics (div_reg), Current Year Metrics (div_reg_ty), and First 28/21/14/7 Days Metrics (div_reg_28, div_reg_21, div_reg_14, div_reg_7). Includes UV at different levels (overall, by division, by region, by site, etc.) for comprehensive analysis.


SELECT
    a.marketingPageId, -- the ID of the marketing page
    a.employeebusinessdivision, -- the business division of the employee
    a.employeeregion, -- the region of the employee
    a.websitename, -- the name of the website
    a.views as div_reg_views, -- total views for the page, business division, and region
    a.visits as div_reg_visits, -- total visits for the page, business division and region
    a.comments as div_reg_comments, -- total comments for the page, business division and region
    a.likes as div_reg_likes, -- total likes for the page, business division and region
    a.uniquevisitor as div_reg_uniquevisitor, --Unique Visitor for the page, business division and region
    b.uniquevisitor as div_uniquevisitor, -- Unique Visitor for the business division
    c.uniquevisitor as reg_uniquevisitor, -- Unique Visitor for the region
    (
        SELECT
            COUNT(DISTINCT viewingcontactid) as uvall
        FROM
            final   
    ) as uniquevisitor, -- Overall Unique Visitor
    site_.uniquevisitor as site_uniquevisitor, -- Unique Visitor for the site
    site_div_.uniquevisitor as site_div_uniquevisitor, -- Unique Visitor for the site and business division
    site_reg_.uniquevisitor as site_reg_uniquevisitor, -- Unique Visitor for the site and region
    site_div_reg_.uniquevisitor as site_div_reg_uniquevisitor, -- Unique Visitor for the site, business division and region
    h.views as div_reg_viewty, -- total views for the page, business division, and region for the current year
    h.visits as div_reg_visitsty, -- total visits for the page, business division and region for the current year
    h.comments as div_reg_commentsty, -- total comments for the page, business division and region for the current year
    h.likes as div_reg_likesty, -- total likes for the page, business division and region for the current year
    h.uniquevisitor as div_reg_uniquevisitorty, -- Unique Visitor for the page, business division and region for the current year
    i.uniquevisitor as div_uniquevisitorty, -- Unique Visitor for the business division for the current year
    j.uniquevisitor as reg_uniquevisitorty, -- Unique Visitor for the region for the current year
    (
        SELECT
            COUNT(DISTINCT viewingcontactid) as uvall
        FROM
            final AS f
        LEFT JOIN
            sharepoint_gold.pbi_db_dim_date AS d
            ON d.date_key = f.visitdatekey
        WHERE
            YEAR(d.date) = YEAR(NOW())
    ) as uniquevisitorty, -- Overall Unique Visitor for the current year

    site_ty.uniquevisitor as site_uniquevisitorTY, -- Unique Visitor for the site for the current year
    site_div_ty.uniquevisitor as site_div_uniquevisitorTY, -- Unique Visitor for the site and business division for the current year
    site_reg_ty.uniquevisitor as site_reg_uniquevisitorTY, -- Unique Visitor for the site and region for the current year
    site_div_reg_ty.uniquevisitor as site_div_reg_uniquevisitorTY, -- Unique Visitor for the site, business division and region for the current year
    


    e.views as div_reg_views28, -- total views for the page, business division, and region for the first 28 days from the earliest page interaction date
    e.visits as div_reg_visits28, -- total visits for the page, business division and region for the first 28 days from the earliest page interaction date
    e.comments as div_reg_comments28, -- total comments for the page, business division and region for the first 28 days from the earliest page interaction date
    e.likes as div_reg_likes28, -- total likes for the page, business division and region for the first 28 days from the earliest page interaction date
    e.uniquevisitor as div_reg_uniquevisitor28, -- Unique Visitor for the page, business division and region for the first 28 days from the earliest page interaction date
    f.uniquevisitor as div_uniquevisitor28, -- Unique Visitor for the business division for the first 28 days from the earliest page interaction date
    g.uniquevisitor as reg_uniquevisitor28, -- Unique Visitor for the region for the first 28 days from the earliest page interaction date
    (
        SELECT
            COUNT(DISTINCT viewingcontactid) as uvall28
        FROM
            final AS f
        LEFT JOIN
            sharepoint_gold.pbi_db_dim_date AS d
            ON d.date_key = f.visitdatekey
        LEFT JOIN
            minpagedate AS m
            ON m.marketingPageId = f.marketingPageId
        WHERE
            d.date <= DATE_ADD(mindate, 27) and m.marketingPageId = f.marketingPageId
    ) as uniquevisitor28, -- Overall Unique Visitor for the first 28 days from the earliest page interaction date
    site_28.uniquevisitor as site_uniquevisitor28, -- Unique Visitor for the site for the first 28 days from the earliest page interaction date
    site_div_28.uniquevisitor as site_div_uniquevisitor28, -- Unique Visitor for the site and business division for the first 28 days from the earliest page interaction date
    site_reg_28.uniquevisitor as site_reg_uniquevisitor28, -- Unique Visitor for the site and region for the first 28 days from the earliest page interaction date
    site_div_reg_28.uniquevisitor as site_div_reg_uniquevisitor28, -- Unique Visitor for the site, business division and region for the first 28 days from the earliest page interaction date

    k.views as div_reg_views21, -- total views for the page, business division, and region for the first 21 days from the earliest page interaction date
    k.visits as div_reg_visits21, -- total visits for the page, business division and region for the first 21 days from the earliest page interaction date
    k.comments as div_reg_comments21, -- total comments for the page, business division and region for the first 21 days from the earliest page interaction date
    k.likes as div_reg_likes21, -- total likes for the page, business division and region for the first 21 days from the earliest page interaction date
    k.uniquevisitor as div_reg_uniquevisitor21, -- Unique Visitor for the page, business division and region for the first 21 days from the earliest page interaction date
    l.uniquevisitor as div_uniquevisitor21, -- Unique Visitor for the business division for the first 21 days from the earliest page interaction date
    m.uniquevisitor as reg_uniquevisitor21, -- Unique Visitor for the region for the first 21 days from the earliest page interaction date
    (
        SELECT
            COUNT(DISTINCT viewingcontactid) as uvall21
        FROM
            final AS f
        LEFT JOIN
            sharepoint_gold.pbi_db_dim_date AS d
            ON d.date_key = f.visitdatekey
        LEFT JOIN
            minpagedate AS m
            ON m.marketingPageId = f.marketingPageId
        WHERE
            d.date <= DATE_ADD(mindate, 20) and m.marketingPageId = f.marketingPageId
    ) as uniquevisitor21, -- Overall Unique Visitor for the first 21 days from the earliest page interaction date
    site_21.uniquevisitor as site_uniquevisitor21, -- Unique Visitor for the site for the first 21 days from the earliest page interaction date
    site_div_21.uniquevisitor as site_div_uniquevisitor21, -- Unique Visitor for the site and business division for the first 21 days from the earliest page interaction date
    site_reg_21.uniquevisitor as site_reg_uniquevisitor21, -- Unique Visitor for the site and region for the first 21 days from the earliest page interaction date
    site_div_reg_21.uniquevisitor as site_div_reg_uniquevisitor21, -- Unique Visitor for the site, business division and region for the first 21 days from the earliest page interaction date
    o.views as div_reg_views14, -- total views for the page, business division, and region for the first 14 days from the earliest page interaction date
    o.visits as div_reg_visits14, -- total visits for the page, business division and region for the first 14 days from the earliest page interaction date
    o.comments as div_reg_comments14, -- total comments for the page, business division and region for the first 14 days from the earliest page interaction date
    o.likes as div_reg_likes14, -- total likes for the page, business division and region for the first 14 days from the earliest page interaction date
    o.uniquevisitor as div_reg_uniquevisitor14, -- Unique Visitor for the page, business division and region for the first 14 days from the earliest page interaction date
    p.uniquevisitor as div_uniquevisitor14, -- Unique Visitor for the business division for the first 14 days from the earliest page interaction date
    q.uniquevisitor as reg_uniquevisitor14, -- Unique Visitor for the region for the first 14 days from the earliest page interaction date
    (
        SELECT
            COUNT(DISTINCT viewingcontactid) as uvall14
        FROM
            final AS f
        LEFT JOIN
            sharepoint_gold.pbi_db_dim_date AS d
            ON d.date_key = f.visitdatekey
        LEFT JOIN
            minpagedate AS m
            ON m.marketingPageId = f.marketingPageId
        WHERE
            d.date <= DATE_ADD(mindate, 13) and m.marketingPageId = f.marketingPageId
    ) as uniquevisitor14, -- Overall Unique Visitor for the first 14 days from the earliest page interaction date
    site_14.uniquevisitor as site_uniquevisitor14, -- Unique Visitor for the site for the first 14 days from the earliest page interaction date
    site_div_14.uniquevisitor as site_div_uniquevisitor14, -- Unique Visitor for the site and business division for the first 14 days from the earliest page interaction date
    site_reg_14.uniquevisitor as site_reg_uniquevisitor14, -- Unique Visitor for the site and region for the first 14 days from the earliest page interaction date
    site_div_reg_14.uniquevisitor as site_div_reg_uniquevisitor14, -- Unique Visitor for the site, business division and region for the first 14 days from the earliest page interaction date
    r.views as div_reg_views7, -- total views for the page, business division, and region for the first 7 days from the earliest page interaction date
    r.visits as div_reg_visits7, -- total visits for the page, business division and region for the first 7 days from the earliest page interaction date
    r.comments as div_reg_comments7, -- total comments for the page, business division and region for the first 7 days from the earliest page interaction date
    r.likes as div_reg_likes7, -- total likes for the page, business division and region for the first 7 days from the earliest page interaction date
    r.uniquevisitor as div_reg_uniquevisitor7, -- Unique Visitor for the page, business division and region for the first 7 days from the earliest page interaction date
    s.uniquevisitor as div_uniquevisitor7, -- Unique Visitor for the business division for the first 7 days from the earliest page interaction date
    t.uniquevisitor as reg_uniquevisitor7, -- Unique Visitor for the region for the first 7 days from the earliest page interaction date
    (
        SELECT
            COUNT(DISTINCT viewingcontactid) as uvall14
        FROM
            final AS f
        LEFT JOIN
            sharepoint_gold.pbi_db_dim_date AS d
            ON d.date_key = f.visitdatekey
        LEFT JOIN
            minpagedate AS m
            ON m.marketingPageId = f.marketingPageId
        WHERE
            d.date <= DATE_ADD(mindate, 6) and m.marketingPageId = f.marketingPageId
    ) as uniquevisitor7, -- Overall Unique Visitor for the first 7 days from the earliest page interaction date
    site_7.uniquevisitor as site_uniquevisitor7, -- Unique Visitor for the site for the first 7 days from the earliest page interaction date
    site_div_7.uniquevisitor as site_div_uniquevisitor7, -- Unique Visitor for the site and business division for the first 7 days from the earliest page interaction date
    site_reg_7.uniquevisitor as site_reg_uniquevisitor7, -- Unique Visitor for the site and region for the first 7 days from the earliest page interaction date
    site_div_reg_7.uniquevisitor as site_div_reg_uniquevisitor7 -- Unique Visitor for the site, business division and region for the first 7 days from the earliest page interaction date


FROM
    div_reg AS a
LEFT JOIN
    div_ AS b
    ON a.employeebusinessdivision = b.employeebusinessdivision
LEFT JOIN
    reg_ AS c
    ON a.employeeregion = c.employeeregion
LEFT JOIN
    div_reg_28 AS e
    ON a.marketingPageId = e.marketingPageId
    AND a.employeebusinessdivision = e.employeebusinessdivision
    AND a.employeeregion = e.employeeregion
LEFT JOIN
    div_28 AS f
    ON a.employeebusinessdivision = f.employeebusinessdivision
LEFT JOIN
    reg_28 AS g
    ON a.employeeregion = g.employeeregion
LEFT JOIN
    div_reg_ty AS h
    ON a.marketingPageId = h.marketingPageId
    AND a.employeebusinessdivision = h.employeebusinessdivision
    AND a.employeeregion = h.employeeregion
LEFT JOIN
    div_ty AS i
    ON a.employeebusinessdivision = i.employeebusinessdivision
LEFT JOIN
    reg_ty AS j
    ON a.employeeregion = j.employeeregion
LEFT JOIN
    div_reg_21 AS k
    ON a.marketingPageId = k.marketingPageId
    AND a.employeebusinessdivision = k.employeebusinessdivision
    AND a.employeeregion = k.employeeregion
LEFT JOIN
    div_21 AS l
    ON a.employeebusinessdivision = l.employeebusinessdivision
LEFT JOIN
    reg_21 AS n
    ON a.employeeregion = n.employeeregion
LEFT JOIN
    div_reg_14 AS o
    ON a.marketingPageId = o.marketingPageId
    AND a.employeebusinessdivision = o.employeebusinessdivision
    AND a.employeeregion = o.employeeregion
LEFT JOIN
    div_14 AS p
    ON a.employeebusinessdivision = p.employeebusinessdivision
LEFT JOIN
    reg_14 AS q
    ON a.employeeregion = q.employeeregion
LEFT JOIN
    div_reg_7 AS r
    ON a.marketingPageId = r.marketingPageId
    AND a.employeebusinessdivision = r.employeebusinessdivision
    AND a.employeeregion = r.employeeregion
LEFT JOIN
    div_7 AS s
    ON a.employeebusinessdivision = s.employeebusinessdivision
LEFT JOIN
    reg_7 AS t
    ON a.employeeregion = t.employeeregion

LEFT JOIN site_ AS site_ ON site_.websitename = a.websitename
LEFT JOIN site_div_ AS site_div_ ON a.employeebusinessdivision = site_div_.employeebusinessdivision AND site_div_.websitename = a.websitename
LEFT JOIN site_reg_ AS site_reg_ ON a.employeeregion = site_reg_.employeeregion AND site_reg_.websitename = a.websitename
LEFT JOIN site_div_reg_ AS site_div_reg_ ON a.employeeregion = site_div_reg_.employeeregion AND a.employeebusinessdivision = site_div_reg_.employeebusinessdivision AND site_div_reg_.websitename = a.websitename


LEFT JOIN site_ty AS site_ty ON site_ty.websitename = a.websitename
LEFT JOIN site_div_ty AS site_div_ty ON a.employeebusinessdivision = site_div_ty.employeebusinessdivision AND site_div_ty.websitename = a.websitename
LEFT JOIN site_reg_ty AS site_reg_ty ON a.employeeregion = site_reg_ty.employeeregion AND site_reg_ty.websitename = a.websitename
LEFT JOIN site_div_reg_ty AS site_div_reg_ty ON a.employeeregion = site_div_reg_ty.employeeregion AND a.employeebusinessdivision = site_div_reg_ty.employeebusinessdivision AND site_div_reg_ty.websitename = a.websitename


LEFT JOIN site_28 AS site_28 ON site_28.websitename = a.websitename
LEFT JOIN site_div_28 AS site_div_28 ON a.employeebusinessdivision = site_div_28.employeebusinessdivision AND site_div_28.websitename = a.websitename
LEFT JOIN site_reg_28 AS site_reg_28 ON a.employeeregion = site_reg_28.employeeregion AND site_reg_28.websitename = a.websitename
LEFT JOIN site_div_reg_28 AS site_div_reg_28 ON a.employeeregion = site_div_reg_28.employeeregion AND a.employeebusinessdivision = site_div_reg_28.employeebusinessdivision AND site_div_reg_28.websitename = a.websitename


LEFT JOIN site_21 AS site_21 ON site_21.websitename = a.websitename
LEFT JOIN site_div_21 AS site_div_21 ON a.employeebusinessdivision = site_div_21.employeebusinessdivision AND site_div_21.websitename = a.websitename
LEFT JOIN site_reg_21 AS site_reg_21 ON a.employeeregion = site_reg_21.employeeregion AND site_reg_21.websitename = a.websitename
LEFT JOIN site_div_reg_21 AS site_div_reg_21 ON a.employeeregion = site_div_reg_21.employeeregion AND a.employeebusinessdivision = site_div_reg_21.employeebusinessdivision AND site_div_reg_21.websitename = a.websitename


LEFT JOIN site_14 AS site_14 ON site_14.websitename = a.websitename
LEFT JOIN site_div_14 AS site_div_14 ON a.employeebusinessdivision = site_div_14.employeebusinessdivision AND site_div_14.websitename = a.websitename
LEFT JOIN site_reg_14 AS site_reg_14 ON a.employeeregion = site_reg_14.employeeregion AND site_reg_14.websitename = a.websitename
LEFT JOIN site_div_reg_14 AS site_div_reg_14 ON a.employeeregion = site_div_reg_14.employeeregion AND a.employeebusinessdivision = site_div_reg_14.employeebusinessdivision AND site_div_reg_14.websitename = a.websitename


LEFT JOIN site_7 AS site_7 ON site_7.websitename = a.websitename
LEFT JOIN site_div_7 AS site_div_7 ON a.employeebusinessdivision = site_div_7.employeebusinessdivision AND site_div_7.websitename = a.websitename
LEFT JOIN site_reg_7 AS site_reg_7 ON a.employeeregion = site_reg_7.employeeregion AND site_reg_7.websitename = a.websitename
LEFT JOIN site_div_reg_7 AS site_div_reg_7 ON a.employeeregion = site_div_reg_7.employeeregion AND a.employeebusinessdivision = site_div_reg_7.employeebusinessdivision AND site_div_reg_7.websitename = a.websitename

