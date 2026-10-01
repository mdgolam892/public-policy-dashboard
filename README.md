# PMAY-G / PMUY — Public Policy Analytics Dashboard

### Python · SQL · MySQL · Power BI · ETL

An end-to-end public policy analytics project built using PMAY-G and PMUY government scheme data. The project covers the complete data workflow from raw CSV files through Python-based loading, SQL transformation and analytics tables, and finally an interactive Power BI dashboard.

The analysis focuses on fund release, houses sanctioned, physical progress, PMUY connections, year-over-year trends, and state-level performance.
![Executive Overview](dashboard/Screenshots/Page1-Executive%20Overview.png)
---

## 🎯 Project Objective

The goal of this project was to transform multiple government scheme datasets into a structured analytics solution that could answer questions around:

- **Fund utilization:** How have funds been released across states and years?
- **Housing progress:** How has the number of houses sanctioned changed over time?
- **Physical progress:** What does the available physical progress data show across states?
- **PMUY connections:** How have connections changed over time?
- **State-level performance:** Which states show stronger or weaker performance across the available indicators?
- **Data quality:** How should missing years, cumulative figures, and incomplete source data be handled without hiding or inventing information?

---

## 🔄 Data Pipeline Architecture

The project follows an end-to-end ETL architecture:

    Raw CSVs
       ↓
    Python — Load Raw Data
       ↓
    MySQL Staging Tables
       ↓
    SQL ETL & Transformation
       ↓
    MySQL Analytics Tables
       ↓
    Power BI
       ↓
    Interactive Dashboard & Insights

Python is used primarily for loading the raw files, while SQL handles the transformation and analytics logic.

---

## 🛠️ What I Built

### 1. Python Data Loading

Created a Python-based loading process to ingest the four raw CSV files into MySQL staging tables.

The process loads:

- Fund release data
- Houses sanctioned data
- Physical progress data
- PMUY connection data

### 2. SQL ETL Pipeline

Built a sequence of SQL transformation scripts to clean, reshape, standardize, and combine the source datasets.

The pipeline includes:

- State-level lookup table creation
- Wide-to-long transformations
- Data cleaning and type handling
- Year-over-year calculations
- Window functions
- Deduplication logic
- NULL and zero handling
- Joining multiple datasets into analytics-ready tables

### 3. Analytics Layer

Created final analytics tables designed specifically for Power BI reporting, including:

- `state_level_summary`
- `pmay_g_yearly_kpis`
- `national_ujjwala_refill_note`

### 4. Power BI Dashboard

Connected Power BI to the MySQL analytics layer and built an interactive dashboard for exploring the available policy and scheme data at national and state levels.

The dashboard covers:

- Fund release trends
- Houses sanctioned
- Physical progress
- PMUY connections
- Year-over-year changes
- State-level comparisons
- National contextual information

---

## 📊 Dashboard Pages

The Power BI dashboard is organized into five pages, moving from an executive-level overview to regional analysis, budget and outcome comparison, contextual PMUY information, and finally strategic recommendations.

### 1️⃣ Executive Overview

The main overview page provides a high-level view of PMAY-G and PMUY performance, bringing key indicators and overall trends together in one place.

![Executive Overview](dashboard/Screenshots/Page1-Executive%20Overview.png)

**Key elements:**
- **Executive KPIs:** High-level indicators for quickly understanding the overall program position.
- **Trend Analysis:** Visualizes changes in key indicators across the available time periods.
- **State-Level View:** Provides a geographic and tabular view of performance across states.
- **Performance Summary:** Brings the most important indicators together for quick review.

**Why it matters:** Provides a starting point for decision-makers to understand the overall picture before moving into deeper state and program-level analysis.

---

### 2️⃣ Regional & State Drilldown

This page focuses on comparing performance across states and allowing deeper exploration of regional differences.

![Regional & State Drilldown](dashboard/Screenshots/Page2-Regional%20%26%20State%20Drilldown.png)

**Key elements:**
- **State-Level Comparison:** Compares indicators across individual states.
- **Regional View:** Helps identify differences in performance between regions.
- **Interactive Drilldown:** Allows users to move from a broader view into individual state-level details.
- **Comparative Visuals:** Combines charts and tables to make differences easier to identify.

**Why it matters:** Helps identify states with stronger or weaker performance and provides a more detailed view of where policy outcomes differ geographically.

---

### 3️⃣ Budget vs Outcomes — 2019–20 Year Lens

This page focuses on comparing financial activity with program outcomes for the overlapping 2019–20 period.

![Budget vs Outcomes](dashboard/Screenshots/Page3-Budget%20vs%20Outcomes%20%282019-20%20Year%20Lens%29.png)

**Key elements:**
- **Budget / Fund Release Analysis:** Examines the financial side of the program.
- **Outcome Comparison:** Places financial information alongside relevant program outcomes.
- **State-Level Analysis:** Allows differences between states to be explored.
- **2019–20 Focus:** Uses the overlapping year available across the relevant source datasets.

**Why it matters:** Helps move the analysis beyond individual KPIs by looking at financial activity alongside measurable outcomes.

---

### 4️⃣ Ujjwala National Context

This page provides contextual analysis around PMUY and the national-level information available in the source data.

![Ujjwala National Context](dashboard/Screenshots/Page4-Ujjwala%20National%20Context.png)

**Key elements:**
- **PMUY Trend:** Presents the available Ujjwala connection data over time.
- **National Context:** Provides supporting information where state-level refill or adoption data is not available.
- **Trend Visualization:** Makes changes in PMUY indicators easier to interpret.
- **Contextual Callout:** Separates supporting national information from directly queryable state-level metrics.

**Why it matters:** Provides the broader context needed to interpret PMUY performance while clearly distinguishing between available data and data limitations.

---

### 5️⃣ Strategic Insights

The final page turns the analysis into practical observations and recommendations, moving from **"what happened?"** to **"what does it mean?"**

![Strategic Insights](dashboard/Screenshots/Page5-Strategic%20Insights.png)

**Key elements:**
- **Key Findings:** Highlights important observations identified during the analysis.
- **Cross-Program Insights:** Brings together findings from the different dashboard sections.
- **Strategic Recommendations:** Connects the analytical findings with potential areas for action.
- **Executive Summary:** Provides a concise final view of the most important takeaways.

**Why it matters:** The purpose of analytics is not only to present numbers, but also to help decision-makers understand what those numbers could mean and where further action or investigation may be required.

---

## 📌 Key Data Considerations

An important part of this project was handling limitations in the source data transparently rather than hiding or filling gaps.

### 1. Different Year Ranges

The four source files do not have fully overlapping year ranges.

To handle this, the project uses two different analytical views:

- `pmay_g_yearly_kpis` for the overlapping 2019–20 period
- `state_level_summary` for the broader cross-sectional state-level analysis

### 2. 2018–19 Houses Sanctioned Data Gap

The raw houses-sanctioned dataset contains zero values for all states for 2018–19.

This is explicitly flagged using:

`is_known_data_gap`

The values are not artificially imputed or presented as genuine observations.

### 3. PMUY Connections Are Cumulative

The PMUY connection figures are cumulative rather than representing only new connections during each year.

The analysis therefore distinguishes between:

- `cumulative_connections`
- `new_connections_this_year`

### 4. State-Level Ujjwala Refill Data

State-level Ujjwala refill/adoption data was not available in the source data.

A cited national statistic is therefore stored separately in:

`national_ujjwala_refill_note`

It is presented as contextual information on the dashboard rather than as a queryable state-level metric.

---

## 🔍 SQL Transformation Pipeline

The SQL scripts are executed in sequence:

| Script | Purpose |
|---|---|
| `01_dim_states.sql` | Creates the state name lookup table |
| `02_clean_fund_release.sql` | Unpivots fund release data from wide to long format |
| `03_clean_houses_sanctioned.sql` | Transforms houses sanctioned data and flags the known data gap |
| `04_clean_physical_progress.sql` | Cleans the available physical progress snapshot |
| `05_clean_pmuy_connections.sql` | Transforms PMUY connection data and calculates YoY growth |
| `06_analytics_layer.sql` | Joins the cleaned datasets into final analytics tables |

---

## 🔧 BigQuery to MySQL Implementation

The original architecture was designed around BigQuery. Due to a cloud billing/access issue during development, the implementation was reproduced locally using MySQL while preserving the same overall ETL architecture and analytical logic.

The main SQL differences include:

| Concept | BigQuery | MySQL |
|---|---|---|
| Unpivoting wide columns | Native `UNPIVOT(...)` | `UNION ALL` of one SELECT per year |
| Safe casting | `SAFE_CAST(x AS FLOAT64)` | `CASE` with validation before casting |
| Safe division | `SAFE_DIVIDE(a, b)` | `CASE WHEN b IS NULL OR b = 0 THEN NULL ELSE a/b END` |
| Table replacement | `CREATE OR REPLACE TABLE` | `DROP TABLE IF EXISTS` + `CREATE TABLE` |
| Deduplication | `QUALIFY ROW_NUMBER()...` | Subquery with `ROW_NUMBER()` and outer filtering |
| Window functions | Supported | Supported in MySQL 8.0+ |
| Table reference | `project.dataset.table` | `database.table` |
| Python client | `google-cloud-bigquery` | `mysql-connector-python` + `sqlalchemy` |

This implementation demonstrates the ability to adapt SQL transformation logic between different database platforms while maintaining the overall data pipeline design.

---

## 📈 Analytics Tables

### `state_level_summary`

Provides the broader state-level analytical view by combining the available indicators from the source datasets.

### `pmay_g_yearly_kpis`

Provides yearly PMAY-G KPI analysis for the overlapping period where the required source data is available.

### `national_ujjwala_refill_note`

Stores the national-level Ujjwala refill statistic used as contextual information on the dashboard.

---

## 🗄️ Data Sources

The project uses four raw CSV datasets covering:

- PMAY-G fund release
- PMAY-G houses sanctioned
- PMAY-G physical progress
- PMUY connections

The source data has different year ranges and structures, which are handled during the ETL process.

---

## 🚀 How to Run

### 1. Install MySQL

Install MySQL Community Server and MySQL Workbench.

During installation, configure a root password and keep it available for the data-loading step.

### 2. Install Python dependencies

    pip install mysql-connector-python pandas sqlalchemy

### 3. Check the MySQL version

The ETL pipeline uses window functions such as `LAG()` and `ROW_NUMBER()`, so MySQL 8.0+ is required.

    SELECT VERSION();

### 4. Load the raw CSV files

From the project root, run:

    python etl/load_raw_to_mysql.py --user root --password YOUR_PASSWORD --database pmay_analytics

This creates the `pmay_analytics` database if required and loads the raw CSV files from the `data/` directory into the staging tables.

### 5. Run the SQL ETL scripts

Open the SQL files from the `etl/` directory in MySQL Workbench and execute them in this order:

    etl/01_dim_states.sql
    etl/02_clean_fund_release.sql
    etl/03_clean_houses_sanctioned.sql
    etl/04_clean_physical_progress.sql
    etl/05_clean_pmuy_connections.sql
    etl/06_analytics_layer.sql

### 6. Verify the analytics tables

    USE pmay_analytics;

    SHOW TABLES;

    SELECT * FROM state_level_summary LIMIT 10;

    SELECT * FROM national_ujjwala_refill_note;

### 7. Connect Power BI to MySQL

Open `dashboard/public_policy_dashboard.pbix` in Power BI Desktop.

If the data connection needs to be configured manually:

    Get Data → MySQL Database

Use:

    Server: localhost:3306
    Database: pmay_analytics

Then select:

    state_level_summary
    national_ujjwala_refill_note
    pmay_g_yearly_kpis

Load the tables into Power BI and explore the dashboard.
---

## 📁 Project Structure

    public-policy-dashboard/
    │
    ├── dashboard/
    │   ├── Screenshots/
    │   │   ├── Page1-Executive Overview
    │   │   ├── Page2-Regional & State Drilldown
    │   │   ├── Page3-Budget vs Outcomes (2019-20 Year Lens)
    │   │   ├── Page4-Ujjwala National Context
    │   │   └── Page5-Strategic Insights
    │   │
    │   └── public_policy_dashboard.pbix
    │
    ├── data/
    │
    ├── etl/
    │   ├── 01_dim_states.sql
    │   ├── 02_clean_fund_release.sql
    │   ├── 03_clean_houses_sanctioned.sql
    │   ├── 04_clean_physical_progress.sql
    │   ├── 05_clean_pmuy_connections.sql
    │   ├── 06_analytics_layer.sql
    │   └── load_raw_to_mysql.py
    │
    └── README.md

---

## 🧰 Tech Stack

| Area | Technology |
|---|---|
| Data Loading | Python |
| Data Processing | Pandas |
| Database | MySQL 8.0+ |
| SQL Transformation | MySQL SQL |
| ETL | Python + SQL |
| Analytics Layer | MySQL |
| Visualization | Power BI |
| Data Sources | CSV |
| SQL Techniques | CTEs, Window Functions, CASE, UNION ALL, Joins |

---

## 💡 Key Takeaways

This project demonstrates an end-to-end approach to data analytics:

- Loading raw data from multiple CSV sources
- Designing a structured staging layer
- Transforming raw data using SQL
- Handling different source structures and year ranges
- Building an analytics-ready data layer
- Performing data-quality checks and explicitly documenting data limitations
- Connecting database tables to Power BI
- Creating a business-facing analytics dashboard

It also demonstrates the ability to translate data transformation logic between different SQL platforms while keeping the overall ETL architecture consistent.

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

## 📫 Contact

**MD GOLAM MOHIUDDIN**

📧 [mdgolammohiuddin892@gmail.com](mailto:mdgolammohiuddin892@gmail.com)  
🔗 [LinkedIn](https://www.linkedin.com/in/md-golam-mohiuddin-980b18150/)  
💻 [GitHub](https://github.com/mdgolam892)
