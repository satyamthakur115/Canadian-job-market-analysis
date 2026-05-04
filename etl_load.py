"""
Canadian Job Market Analysis — ETL Pipeline
Author : Satyam Thakur
Date   : 2024

Loads the raw CSV dataset into MySQL, cleans the data,
and normalizes the skills column into a proper bridge table.

Run: python etl_load.py
Prereq: mysql running locally + schema.sql already executed
"""

import csv
import re
import mysql.connector
from datetime import datetime

DB = {
    "host":     "localhost",
    "user":     "root",
    "password": "your_password",   # <-- change this
    "database": "canada_jobs_db"
}

CSV_PATH = "data/ca_data_analyst_jobs_2024.csv"


def connect():
    return mysql.connector.connect(**DB)


def clean_salary(val):
    """Handle blanks and bad values - about 18% of postings skip salary."""
    if not val or val.strip() == '':
        return None
    try:
        return int(float(str(val).replace(',', '').strip()))
    except ValueError:
        return None


def clean_date(val):
    if not val:
        return None
    try:
        return datetime.strptime(val.strip(), "%Y-%m-%d").date()
    except ValueError:
        return None


def load_postings(cursor, rows):
    print(f"  Loading {len(rows)} job postings...")
    inserted = 0
    skipped  = 0

    for row in rows:
        salary = clean_salary(row.get("salary_cad"))
        pdate  = clean_date(row.get("posted_date"))

        if not row.get("job_id") or not row.get("title"):
            skipped += 1
            continue

        try:
            cursor.execute("""
                INSERT IGNORE INTO job_postings
                    (job_id, title, company_size, industry, city, province,
                     work_type, experience_level, salary_cad, degree_req,
                     posted_date, source)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                row["job_id"], row["title"].strip(),
                row.get("company_size"), row.get("industry"),
                row.get("city"), row.get("province"),
                row.get("work_type"), row.get("experience_level"),
                salary, row.get("degree_req"), pdate,
                row.get("source")
            ))
            inserted += 1
        except mysql.connector.Error as e:
            skipped += 1
            # not stopping on individual row errors
            print(f"    Warning: skipped {row['job_id']} — {e}")

    print(f"  ✅ Inserted {inserted} | Skipped {skipped}")
    return inserted


def get_skill_map(cursor):
    """Return dict of skill_name -> skill_id from dim_skills."""
    cursor.execute("SELECT skill_id, skill_name FROM dim_skills")
    return {row[1].lower(): row[0] for row in cursor.fetchall()}


def load_skills(cursor, rows):
    """
    Parse the skills_required column and populate job_skills bridge table.
    Skills are stored as "SQL; Python; Power BI" in the CSV.
    """
    print("  Parsing and loading skill associations...")
    skill_map  = get_skill_map(cursor)
    inserted   = 0
    unmatched  = set()

    for row in rows:
        raw = row.get("skills_required", "")
        if not raw:
            continue

        # split on ; or , - dataset uses semicolons but being defensive
        skills_in_row = [s.strip() for s in re.split(r"[;,]", raw) if s.strip()]

        for skill_name in skills_in_row:
            skill_id = skill_map.get(skill_name.lower())
            if skill_id is None:
                unmatched.add(skill_name)
                continue
            try:
                cursor.execute("""
                    INSERT IGNORE INTO job_skills (job_id, skill_id)
                    VALUES (%s, %s)
                """, (row["job_id"], skill_id))
                inserted += 1
            except mysql.connector.Error:
                pass

    if unmatched:
        print(f"  ⚠️  Unmatched skills (not in dim_skills): {sorted(unmatched)}")

    print(f"  ✅ Inserted {inserted} skill associations")


def main():
    print("=" * 50)
    print("  Canadian Job Market Analysis — ETL Load")
    print(f"  {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 50)

    # Read CSV
    print(f"\n📥 Reading {CSV_PATH}...")
    with open(CSV_PATH, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows   = list(reader)
    print(f"  ✅ Read {len(rows)} rows")

    # Basic sanity check
    expected_cols = {"job_id", "title", "city", "salary_cad", "skills_required"}
    missing = expected_cols - set(rows[0].keys())
    if missing:
        raise ValueError(f"CSV missing expected columns: {missing}")

    # Load into DB
    print("\n📤 Loading into MySQL...")
    conn   = connect()
    cursor = conn.cursor()

    load_postings(cursor, rows)
    conn.commit()

    load_skills(cursor, rows)
    conn.commit()

    # Quick summary check
    cursor.execute("SELECT COUNT(*) FROM job_postings")
    n_jobs = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM job_skills")
    n_skills = cursor.fetchone()[0]
    cursor.execute("SELECT ROUND(AVG(salary_cad)) FROM job_postings WHERE salary_cad IS NOT NULL")
    avg_sal = cursor.fetchone()[0]

    print(f"\n📊 Load Summary")
    print(f"   job_postings rows : {n_jobs:,}")
    print(f"   job_skills rows   : {n_skills:,}")
    print(f"   Avg salary (disclosed): CAD ${avg_sal:,}")

    cursor.close()
    conn.close()
    print("\n✅ ETL complete — run analysis_queries.sql for insights")


if __name__ == "__main__":
    main()
