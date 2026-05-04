"""
Canadian Job Market Analysis — Key Findings
Author : Satyam Thakur
Date   : 2024

Runs the main analysis queries and prints a clean summary report.
Useful for quickly checking insights without opening MySQL Workbench.

Also exports a summary CSV that can be used as Tableau/Power BI input.

Run: python analysis.py
"""

import csv
import os
import mysql.connector
import pandas as pd
from datetime import datetime

DB = {
    "host":     "localhost",
    "user":     "root",
    "password": "your_password",   # <-- change this
    "database": "canada_jobs_db"
}

OUTPUT_DIR = "outputs"


def connect():
    return mysql.connector.connect(**DB)


def run_query(conn, sql, params=None):
    return pd.read_sql(sql, conn, params=params)


def section(title):
    print(f"\n{'='*55}")
    print(f"  {title}")
    print(f"{'='*55}")


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    conn = connect()

    print("\n🇨🇦  Canadian Data Analyst Job Market — Analysis Report")
    print(f"   Generated: {datetime.now().strftime('%B %d, %Y')}")

    # ── 1. Posting volume by city ────────────────────────────
    section("Top Cities by Job Posting Volume")
    df_cities = run_query(conn, """
        SELECT city, province,
               COUNT(*) AS postings,
               ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM job_postings),1) AS pct
        FROM job_postings
        GROUP BY city, province
        ORDER BY postings DESC
        LIMIT 10
    """)
    print(df_cities.to_string(index=False))

    # ── 2. Salary benchmarks by city ───────────────────────
    section("Average Salary by City (CAD, disclosed postings only)")
    df_salary_city = run_query(conn, """
        SELECT city, COUNT(*) AS n,
               ROUND(AVG(salary_cad)) AS avg_salary,
               MIN(salary_cad) AS min_sal,
               MAX(salary_cad) AS max_sal
        FROM job_postings
        WHERE salary_cad IS NOT NULL
        GROUP BY city
        HAVING n >= 10
        ORDER BY avg_salary DESC
    """)
    print(df_salary_city.to_string(index=False))

    # ── 3. Most in-demand skills ────────────────────────────
    section("Top 15 Most In-Demand Skills")
    df_skills = run_query(conn, """
        SELECT ds.skill_name, ds.category,
               COUNT(js.job_id) AS mentions,
               ROUND(COUNT(js.job_id)*100.0/(SELECT COUNT(*) FROM job_postings),1) AS pct_jobs
        FROM job_skills js
        JOIN dim_skills ds ON js.skill_id = ds.skill_id
        GROUP BY ds.skill_name, ds.category
        ORDER BY mentions DESC
        LIMIT 15
    """)
    print(df_skills.to_string(index=False))

    # ── 4. Salary by experience level ──────────────────────
    section("Salary Range by Experience Level")
    df_exp = run_query(conn, """
        SELECT experience_level,
               COUNT(*) AS postings,
               ROUND(AVG(salary_cad)) AS avg_salary,
               MIN(salary_cad) AS min_sal,
               MAX(salary_cad) AS max_sal
        FROM job_postings
        WHERE salary_cad IS NOT NULL
        GROUP BY experience_level
        ORDER BY avg_salary
    """)
    print(df_exp.to_string(index=False))

    # ── 5. Work type breakdown ──────────────────────────────
    section("Work Arrangement Distribution")
    df_work = run_query(conn, """
        SELECT work_type,
               COUNT(*) AS postings,
               ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM job_postings),1) AS pct,
               ROUND(AVG(salary_cad)) AS avg_salary
        FROM job_postings
        WHERE salary_cad IS NOT NULL
        GROUP BY work_type
        ORDER BY postings DESC
    """)
    print(df_work.to_string(index=False))

    # ── 6. Skills that pay more ─────────────────────────────
    section("Skills with Highest Salary Premium (vs overall avg)")
    df_skill_sal = run_query(conn, """
        SELECT ds.skill_name,
               COUNT(DISTINCT js.job_id) AS jobs,
               ROUND(AVG(jp.salary_cad)) AS avg_with_skill,
               ROUND(AVG(jp.salary_cad)) - (
                   SELECT ROUND(AVG(salary_cad))
                   FROM job_postings WHERE salary_cad IS NOT NULL
               ) AS premium_cad
        FROM job_skills js
        JOIN dim_skills ds   ON js.skill_id = ds.skill_id
        JOIN job_postings jp ON js.job_id   = jp.job_id
        WHERE jp.salary_cad IS NOT NULL
        GROUP BY ds.skill_name
        HAVING jobs > 30
        ORDER BY premium_cad DESC
        LIMIT 10
    """)
    print(df_skill_sal.to_string(index=False))

    # ── 7. Industry salary comparison ──────────────────────
    section("Average Salary by Industry")
    df_ind = run_query(conn, """
        SELECT industry,
               COUNT(*) AS postings,
               ROUND(AVG(salary_cad)) AS avg_salary
        FROM job_postings
        WHERE salary_cad IS NOT NULL
        GROUP BY industry
        ORDER BY avg_salary DESC
    """)
    print(df_ind.to_string(index=False))

    # ── Export summary for Tableau ──────────────────────────
    print(f"\n📁 Exporting summary CSVs to /{OUTPUT_DIR}/...")

    dfs_to_export = {
        "city_summary.csv":        df_cities,
        "salary_by_city.csv":      df_salary_city,
        "top_skills.csv":          df_skills,
        "salary_by_experience.csv":df_exp,
        "work_arrangement.csv":    df_work,
        "skill_salary_premium.csv":df_skill_sal,
        "industry_salary.csv":     df_ind,
    }

    for fname, df in dfs_to_export.items():
        path = os.path.join(OUTPUT_DIR, fname)
        df.to_csv(path, index=False)
        print(f"  ✅ {fname}")

    conn.close()
    print("\n✅ Analysis complete!")
    print("   Load the CSVs in outputs/ into Tableau or Power BI for dashboards.")


if __name__ == "__main__":
    main()
