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
)



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


