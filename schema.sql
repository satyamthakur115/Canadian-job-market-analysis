-- ================================================================
-- Canadian Data Analyst Job Market Analysis (2023-2025)
-- Author : Satyam Thakur
-- Dataset: 1,200 job postings scraped/collected from LinkedIn,
--          Indeed, Job Bank Canada, and Glassdoor
-- Purpose: Understand hiring trends, salary benchmarks, and
--          in-demand skills for data analyst roles in Canada
-- ================================================================

DROP TABLE IF EXISTS job_skills;
DROP TABLE IF EXISTS job_postings;
DROP TABLE IF EXISTS dim_skills;
DROP TABLE IF EXISTS dim_cities;

-- ── City reference table ──────────────────────────────────────
CREATE TABLE dim_cities (
    city_id      SMALLINT    PRIMARY KEY AUTO_INCREMENT,
    city         VARCHAR(60) NOT NULL,
    province     VARCHAR(60) NOT NULL,
    region       VARCHAR(30) NOT NULL,   -- East / West / Central / Atlantic
    is_major_hub BOOLEAN     DEFAULT FALSE
);

INSERT INTO dim_cities (city, province, region, is_major_hub) VALUES
('Toronto',    'Ontario',           'East',     TRUE),
('Vancouver',  'British Columbia',  'West',     TRUE),
('Calgary',    'Alberta',           'Prairies', TRUE),
('Ottawa',     'Ontario',           'East',     TRUE),
('Montreal',   'Quebec',            'East',     TRUE),
('Edmonton',   'Alberta',           'Prairies', FALSE),
('Waterloo',   'Ontario',           'East',     FALSE),
('Mississauga','Ontario',           'East',     FALSE),
('Halifax',    'Nova Scotia',       'Atlantic', FALSE),
('Winnipeg',   'Manitoba',          'Prairies', FALSE),
('Saskatoon',  'Saskatchewan',      'Prairies', FALSE),
('Regina',     'Saskatchewan',      'Prairies', FALSE),
('Victoria',   'British Columbia',  'West',     FALSE);

-- ── Skills reference table ───────────────────────────────────
CREATE TABLE dim_skills (
    skill_id    SMALLINT    PRIMARY KEY AUTO_INCREMENT,
    skill_name  VARCHAR(50) NOT NULL UNIQUE,
    category    VARCHAR(40) NOT NULL   -- Query / Visualization / Programming / Cloud / Tools
);

INSERT INTO dim_skills (skill_name, category) VALUES
('SQL',         'Query'),
('SQL Server',  'Query'),
('Excel',       'Tools'),
('Power Query', 'Tools'),
('DAX',         'Tools'),
('Jira',        'Tools'),
('Power BI',    'Visualization'),
('Tableau',     'Visualization'),
('Looker',      'Visualization'),
('Python',      'Programming'),
('R',           'Programming'),
('Git',         'Programming'),
('Azure',       'Cloud'),
('Spark',       'Cloud'),
('Databricks',  'Cloud'),
('Snowflake',   'Cloud');

-- ── Main job postings table ───────────────────────────────────
CREATE TABLE job_postings (
    job_id           VARCHAR(10)   PRIMARY KEY,
    title            VARCHAR(100)  NOT NULL,
    company_size     VARCHAR(20),
    industry         VARCHAR(60),
    city             VARCHAR(60),
    province         VARCHAR(60),
    work_type        VARCHAR(15),  -- Hybrid / Remote / On-site
    experience_level VARCHAR(30),
    salary_cad       INT,          -- NULL means salary not posted (~18% of listings)
    degree_req       VARCHAR(30),
    posted_date      DATE,
    source           VARCHAR(30)
);

CREATE INDEX idx_jp_city     ON job_postings(city);
CREATE INDEX idx_jp_province ON job_postings(province);
CREATE INDEX idx_jp_title    ON job_postings(title);
CREATE INDEX idx_jp_salary   ON job_postings(salary_cad);
CREATE INDEX idx_jp_date     ON job_postings(posted_date);

-- ── Job-Skills bridge table (normalized from CSV) ─────────────
-- Each row = one skill required for one job posting
CREATE TABLE job_skills (
    id       INT       PRIMARY KEY AUTO_INCREMENT,
    job_id   VARCHAR(10) NOT NULL,
    skill_id SMALLINT    NOT NULL,
    FOREIGN KEY (job_id)   REFERENCES job_postings(job_id),
    FOREIGN KEY (skill_id) REFERENCES dim_skills(skill_id),
    UNIQUE KEY uq_job_skill (job_id, skill_id)
);

CREATE INDEX idx_js_skill ON job_skills(skill_id);
CREATE INDEX idx_js_job   ON job_skills(job_id);
