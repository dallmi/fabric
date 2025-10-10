-- =====================================================================================
-- Unique Visitor Analysis by Website
-- =====================================================================================
-- Purpose: Calculate unique visitors per website with employee region mapping
--          and date filtering based on minimum page date
-- =====================================================================================

WITH minpagedate AS (
    SELECT
        MIN(d.date) AS mindate,
        m.marketingPageId
    FROM
        sharepoint_gold.pbi_db_interactions_metrics AS m
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = m.visitdatekey
    GROUP BY
        m.marketingPageId
),
site_page_inventory AS (
    SELECT
        DISTINCT marketingPageId,
        websitename,
        CASE
            WHEN e.employeebusinessdivision IS NULL THEN 'Unknown'
            ELSE e.employeebusinessdivision
        END AS employeebusinessdivision,
        CASE
            WHEN e.employeeregion IS NULL THEN 'Unknown'
            ELSE e.employeeregion
        END AS employeeregion
    FROM
        sharepoint_gold.pbi_db_interactions_metrics f
    LEFT JOIN
        sharepoint_gold.pbi_db_employeecontact AS e
        ON f.viewingcontactid = e.contactid
),
final AS (
    SELECT
        f.*,
        w.websitename,
        COUNT(DISTINCT f.viewingcontactid) AS uniquevisitor
    FROM
        sharepoint_gold.pbi_db_interactions_metrics AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        minpagedate e
        ON e.marketingPageId = f.marketingPageId
    LEFT JOIN
        site_page_inventory AS w
        ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date <= DATE_ADD(mindate, 6)
        AND m.marketingPageId = f.marketingPageId
    GROUP BY
        w.websitename
)
SELECT * FROM final;
