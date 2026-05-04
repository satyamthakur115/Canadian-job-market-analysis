-- ================================================================
-- Canadian Data Analyst Job Market — Analysis Queries
-- Author : Satyam Thakur
-- Note   : Run schema.sql first, then load_data.py to populate
-- ================================================================


-- ── Q1: Which cities have the most data analyst openings?
-- Toronto dominates but Calgary is punching above its weight
SELECT
    jp.city,
    jp.province,
    COUNT(*)                                       AS total_postings,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_all_jobs
FROM job_postings jp
GROUP BY jp.city, jp.province
ORDER BY total_postings DESC;


-- ── Q2: Average salary by city (only where salary was disclosed)
-- ~18% of postings don't include salary - I've flagged those separately
SELECT
    city,
    province,
    COUNT(*)                          AS postings_with_salary,
    ROUND(AVG(salary_cad))            AS avg_salary,
    MIN(salary_cad)                   AS min_salary,
    MAX(salary_cad)                   AS max_salary,
    ROUND(AVG(salary_cad) / 12)       AS approx_monthly
FROM job_postings
WHERE salary_cad IS NOT NULL
GROUP BY city, province
ORDER BY avg_salary DESC;


-- ── Q3: Most in-demand skills across all postings
-- SQL is #1 by a wide margin - confirms what every DA job guide says
SELECT
    ds.skill_name,
    ds.category,
    COUNT(js.job_id)                               AS times_mentioned,
    ROUND(COUNT(js.job_id) * 100.0
          / (SELECT COUNT(*) FROM job_postings), 1) AS pct_of_postings
FROM job_skills js
JOIN dim_skills ds ON js.skill_id = ds.skill_id
GROUP BY ds.skill_name, ds.category
ORDER BY times_mentioned DESC;


-- ── Q4: Skill demand by category
-- Useful for knowing where to focus learning time
SELECT
    ds.category,
    COUNT(js.job_id)  AS total_mentions,
    COUNT(DISTINCT ds.skill_name) AS unique_skills_in_category
FROM job_skills js
JOIN dim_skills ds ON js.skill_id = ds.skill_id
GROUP BY ds.category
ORDER BY total_mentions DESC;


-- ── Q5: Salary by experience level
-- Entry-level range is tight; senior roles have huge variance
SELECT
    experience_level,
    COUNT(*)                AS postings,
    COUNT(salary_cad)       AS with_salary,
    ROUND(AVG(salary_cad))  AS avg_salary,
    MIN(salary_cad)         AS min_salary,
    MAX(salary_cad)         AS max_salary,
    ROUND(STDDEV(salary_cad)) AS salary_stddev
FROM job_postings
WHERE salary_cad IS NOT NULL
GROUP BY experience_level
ORDER BY avg_salary;


-- ── Q6: Remote vs Hybrid vs On-site breakdown
-- Hybrid has clearly won post-pandemic in Canadian market
SELECT
    work_type,
    COUNT(*)                                           AS postings,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct,
    ROUND(AVG(salary_cad))                             AS avg_salary
FROM job_postings
WHERE salary_cad IS NOT NULL
GROUP BY work_type
ORDER BY postings DESC;


-- ── Q7: Which industries pay the most?
-- Tech + Finance lead, Government is stable but lower ceiling
SELECT
    industry,
    COUNT(*)               AS total_postings,
    ROUND(AVG(salary_cad)) AS avg_salary,
    MAX(salary_cad)        AS top_salary
FROM job_postings
WHERE salary_cad IS NOT NULL
GROUP BY industry
ORDER BY avg_salary DESC;


-- ── Q8: Month-over-month job posting volume trend
-- Looking for whether hiring picked up or slowed during 2024
WITH monthly AS (
    SELECT
        DATE_FORMAT(posted_date, '%Y-%m') AS month,
        COUNT(*)                           AS postings
    FROM job_postings
    GROUP BY DATE_FORMAT(posted_date, '%Y-%m')
)
SELECT
    month,
    postings,
    LAG(postings) OVER (ORDER BY month)   AS prev_month,
    postings - LAG(postings) OVER (ORDER BY month) AS mom_change,
    ROUND((postings - LAG(postings) OVER (ORDER BY month))
          / NULLIF(LAG(postings) OVER (ORDER BY month), 0) * 100, 1) AS mom_pct
FROM monthly
ORDER BY month;


-- ── Q9: Skills that command higher salaries
-- Do Python/Azure skills actually translate to more $$?
SELECT
    ds.skill_name,
    COUNT(DISTINCT js.job_id)      AS jobs_requiring_skill,
    ROUND(AVG(jp.salary_cad))      AS avg_salary_with_skill,
    (SELECT ROUND(AVG(salary_cad))
     FROM job_postings
     WHERE salary_cad IS NOT NULL) AS overall_avg_salary,
    ROUND(AVG(jp.salary_cad)) -
    (SELECT ROUND(AVG(salary_cad))
     FROM job_postings
     WHERE salary_cad IS NOT NULL) AS salary_premium
FROM job_skills js
JOIN dim_skills    ds ON js.skill_id  = ds.skill_id
JOIN job_postings  jp ON js.job_id    = jp.job_id
WHERE jp.salary_cad IS NOT NULL
GROUP BY ds.skill_name
HAVING COUNT(DISTINCT js.job_id) > 30   -- only skills with enough data
ORDER BY salary_premium DESC;


-- ── Q10: Entry-level friendly cities
-- For someone new to Canada - where should they look?
SELECT
    city,
    province,
    COUNT(*) AS entry_level_postings,
    ROUND(AVG(salary_cad)) AS avg_entry_salary,
    SUM(CASE WHEN work_type IN ('Hybrid','Remote') THEN 1 ELSE 0 END) AS flexible_roles
FROM job_postings
WHERE experience_level = 'Entry Level (0-2 yrs)'
  AND salary_cad IS NOT NULL
GROUP BY city, province
HAVING COUNT(*) >= 5
ORDER BY entry_level_postings DESC;


-- ── Q11: Company size vs salary - do big companies pay more?
-- Spoiler: yes, but mid-size tech firms are competitive
SELECT
    company_size,
    COUNT(*)               AS total_postings,
    ROUND(AVG(salary_cad)) AS avg_salary,
    MAX(salary_cad)        AS max_salary
FROM job_postings
WHERE salary_cad IS NOT NULL
GROUP BY company_size
ORDER BY avg_salary DESC;


-- ── Q12: Top skill combinations (co-occurrence)
-- What skills appear together most often? Good for resume targeting
SELECT
    a.skill_name  AS skill_1,
    b.skill_name  AS skill_2,
    COUNT(*)      AS co_occurrences
FROM job_skills ja
JOIN job_skills jb ON ja.job_id = jb.job_id AND ja.skill_id < jb.skill_id
JOIN dim_skills a  ON ja.skill_id = a.skill_id
JOIN dim_skills b  ON jb.skill_id = b.skill_id
GROUP BY a.skill_name, b.skill_name
ORDER BY co_occurrences DESC
LIMIT 20;
