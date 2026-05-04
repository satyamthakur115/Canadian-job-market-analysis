# Canadian Data Analyst Job Market Analysis (2023–2025)

[![SQL](https://img.shields.io/badge/SQL-4479A1?style=flat-square&logo=mysql&logoColor=white)]()
[![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white)]()
[![Pandas](https://img.shields.io/badge/Pandas-150458?style=flat-square&logo=pandas&logoColor=white)]()
[![Tableau](https://img.shields.io/badge/Tableau-E97627?style=flat-square&logo=tableau&logoColor=white)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Personal project** — I moved to Canada in 2024 and started job hunting. I couldn't find a clear answer to basic questions like *"which Canadian city has the most DA jobs?"* or *"does knowing Azure actually pay more?"* — so I built this analysis myself using 1,200 job postings collected from LinkedIn, Indeed, Job Bank Canada, and Glassdoor between Oct 2023 and Mar 2025.

---

## 🔍 What I Was Trying to Answer

1. Which cities have the most data analyst openings in Canada?
2. What does a realistic salary look like — by city, experience, and industry?
3. Which skills appear most often in job postings? Which ones pay more?
4. Is hybrid/remote work still common, or are companies pulling people back?
5. Are there entry-level friendly cities for someone new to the Canadian market?

---

## 📁 Project Structure

```
canadian-job-market-analysis/
│
├── data/
│   └── ca_data_analyst_jobs_2024.csv   # 1,200 job postings (anonymized)
│
├── sql/
│   ├── schema.sql                      # DB schema with dim tables + indexes
│   └── analysis_queries.sql            # 12 analysis queries with comments
│
├── python/
│   ├── etl_load.py                     # Loads CSV → MySQL, normalizes skills
│   └── analysis.py                     # Runs queries, prints report, exports CSVs
│
└── outputs/                            # Generated CSVs for Tableau/Power BI
    ├── city_summary.csv
    ├── salary_by_city.csv
    ├── top_skills.csv
    └── ...
```

---

## 📊 Key Findings

### 1. 🏙️ Where the Jobs Are

Toronto dominates with **26.8% of all postings** — not surprising, but what caught my attention was how well Calgary is doing. Alberta has been growing fast for tech hiring and it shows.

| City | Province | Postings | Share |
|------|----------|----------|-------|
| Toronto | Ontario | 322 | 26.8% |
| Vancouver | British Columbia | 200 | 16.7% |
| Calgary | Alberta | 133 | 11.1% |
| Ottawa | Ontario | 114 | 9.5% |
| Montreal | Quebec | 104 | 8.7% |
| Edmonton | Alberta | 93 | 7.8% |

> 💡 **Takeaway:** Ontario + BC alone account for ~55% of postings. But if you're open to Alberta (no provincial income tax), the competition is lower and salaries are comparable.

---

### 2. 💰 Salary Reality Check

**Overall average: CAD $79,742** (based on 1,017 postings that disclosed salary — about 82% of listings).

Worth noting: ~18% of postings don't list salary at all. In my experience those are usually contract roles or companies that want to negotiate down.

| City | Avg Salary (CAD) |
|------|-----------------|
| Toronto | $83,957 |
| Mississauga | $82,234 |
| Vancouver | $81,000 |
| Calgary | $80,730 |
| Ottawa | $79,096 |
| Edmonton | $78,145 |

Toronto pays most but also has the highest cost of living. Calgary is close behind with no provincial income tax — **take-home pay is actually competitive**.

---

### 3. 🛠️ Most In-Demand Skills

Looked at every job posting and counted which skills appeared in the requirements.

| Skill | % of Postings | Category |
|-------|--------------|----------|
| **SQL** | **90.7%** | Query |
| Excel | 76.9% | Tools |
| Python | 61.0% | Programming |
| Power BI | 53.8% | Visualization |
| Tableau | 47.7% | Visualization |
| SQL Server | 40.9% | Query |
| Azure | 25.2% | Cloud |
| Jira | 24.5% | Tools |
| Git | 23.9% | Programming |
| Power Query | 20.2% | Tools |

**SQL is non-negotiable.** 9 out of 10 postings list it. Everything else is secondary. If I had to rank where to spend learning time: SQL → Python → Power BI → Azure.

---

### 4. 🏠 Remote vs Hybrid vs On-site

Post-2023, the Canadian market has settled into a pretty clear pattern:

| Work Type | Postings | Share |
|-----------|----------|-------|
| **Hybrid** | 605 | **50.4%** |
| Remote | 355 | 29.6% |
| On-site | 240 | 20.0% |

Hybrid has clearly won. Full remote is still available (especially in tech and consulting) but on-site-only roles are mostly government and healthcare.

---

### 5. 📈 Salary by Industry

| Industry | Avg Salary (CAD) |
|----------|-----------------|
| Technology | $80,838 |
| Government | $80,763 |
| Healthcare | $79,573 |
| Financial Services | $78,883 |
| Consulting | $78,471 |
| Manufacturing | $75,450 |

Government surprised me — stable sector with decent pay and almost always hybrid. Worth targeting if you prefer work-life balance over ceiling.

---

## 🛠️ How to Run This Yourself

### 1. Clone the repo
```bash
git clone https://github.com/satyamthakur115/canadian-job-market-analysis.git
cd canadian-job-market-analysis
```

### 2. Set up the database
```bash
mysql -u root -p -e "CREATE DATABASE canada_jobs_db;"
mysql -u root -p canada_jobs_db < sql/schema.sql
```

### 3. Install Python dependencies
```bash
pip install pandas mysql-connector-python
```

### 4. Load the data
```bash
# Edit DB password in python/etl_load.py first
python python/etl_load.py
```

### 5. Run the analysis
```bash
python python/analysis.py
# Prints full report + saves CSVs to outputs/
```

### 6. Explore with SQL
Open `sql/analysis_queries.sql` in MySQL Workbench or DBeaver and run any query.

---

## 📋 Dataset Notes

- **1,200 postings** collected Oct 2023 – Mar 2025
- Sources: LinkedIn (38%), Indeed (30%), Job Bank Canada (12%), Glassdoor (11%), Company websites (9%)
- ~18% of postings had no salary listed — excluded from salary analysis, kept for skill/volume analysis
- Skills were normalized from free-text into a bridge table (see `etl_load.py`)
- Company names were removed to keep the dataset clean and shareable

---

## 🔧 Tech Stack

| Layer | Technology |
|-------|-----------|
| Database | MySQL (normalized star-adjacent schema) |
| ETL | Python 3.10+, Pandas |
| Analysis | SQL (CTEs, window functions, conditional aggregates) |
| Visualization | Tableau, Excel |
| Version Control | Git / GitHub |

---

## 👤 Author

**Satyam Thakur** — Data Analyst based in Saskatoon, SK  
📧 satyamthakur115@gmail.com | [LinkedIn](https://www.linkedin.com/in/satyam-thakur-94a4231b9) | [GitHub](https://github.com/satyamthakur115)

*Open to Data Analyst, BI Analyst, and Database roles across Canada 🇨🇦*
