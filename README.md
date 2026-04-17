# 🔍 LAPD Crime Data Warehouse & Business Intelligence Solution

![SQL Server](https://img.shields.io/badge/SQL%20Server-2022-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![SSIS](https://img.shields.io/badge/SSIS-ETL%20Pipeline-0078D4?style=for-the-badge&logo=microsoft&logoColor=white)
![SSAS](https://img.shields.io/badge/SSAS-Multidimensional%20Cube-0078D4?style=for-the-badge&logo=microsoft&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Reports-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Python](https://img.shields.io/badge/Python-ETL%20Support-3776AB?style=for-the-badge&logo=python&logoColor=white)

> An end-to-end Data Warehousing and Business Intelligence solution built on **LAPD Crime Incident data**, covering dimensional modelling, ETL pipeline design, OLAP cube construction, and interactive reporting.

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Architecture](#-architecture)
- [Assignment 1 — Data Warehouse & ETL](#-assignment-1--data-warehouse--etl)
- [Assignment 2 — BI & Reporting](#-assignment-2--bi--reporting)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Setup & Installation](#-setup--installation)
- [Key Design Decisions](#-key-design-decisions)

---

## 📌 Project Overview

This project was developed as part of **IT3021 — Data Warehousing and Business Intelligence**. It implements a complete DW/BI pipeline over the **Los Angeles Police Department (LAPD) Crime Incidents** dataset, enabling analytical reporting across time, geography, crime type, victim demographics, and more.

**Dataset:** LAPD Crime Incident Records (~50,000 rows)  
**Database:** Microsoft SQL Server 2022  
**Schema Design:** Star Schema with SCD Type 2 support

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     SOURCE DATA (CSV)                        │
│              LAPD Crime Incidents Dataset                    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  ETL LAYER (SSIS + Python)                   │
│   InitialLoad.dtsx  │  AccumulatingFactUpdate.dtsx          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│            DATA WAREHOUSE — CrimeAnalysisDW                  │
│                                                              │
│   FACT_CRIME_INCIDENT  ◄──── 8 Dimension Tables              │
│   (50,000 rows)              DIM_DATE (role-playing)         │
│                              DIM_TIME                        │
│                              DIM_AREA (SCD Type 2)           │
│                              DIM_CRIME                       │
│                              DIM_PREMISE                     │
│                              DIM_WEAPON                      │
│                              DIM_STATUS                      │
│                              DIM_VICTIM (SCD Type 2)         │
└────────────────────────┬────────────────────────────────────┘
                         │
              ┌──────────┴───────────┐
              ▼                      ▼
┌─────────────────────┐   ┌──────────────────────────────────┐
│   SSAS CUBE         │   │   POWER BI REPORTS               │
│   CrimeCubeProject  │   │   Published to Power BI Service  │
│   (Multidimensional)│   │   4 Interactive Dashboards       │
└─────────────────────┘   └──────────────────────────────────┘
```

---

## 📦 Assignment 1 — Data Warehouse & ETL

### Star Schema Design

| Table | Type | Description |
|---|---|---|
| `FACT_CRIME_INCIDENT` | Fact | Core fact table with 50k rows and accumulating snapshot columns |
| `DIM_DATE` | Dimension | Role-playing dimension for Date Occurred & Date Reported |
| `DIM_TIME` | Dimension | Time of day breakdown |
| `DIM_AREA` | SCD Type 2 | LAPD area/division with historical tracking |
| `DIM_CRIME` | Dimension | Crime code and description |
| `DIM_PREMISE` | Dimension | Premise type (street, vehicle, residence, etc.) |
| `DIM_WEAPON` | Dimension | Weapon type used |
| `DIM_STATUS` | Dimension | Case investigation status |
| `DIM_VICTIM` | SCD Type 2 | Victim demographic info with historical tracking |

### Fact Table Measures

| Measure | Description |
|---|---|
| `IncidentCount` | Count of crime incidents |
| `DaysToReport` | Days between occurrence and report |
| `VictimAge` | Age of victim at time of incident |
| `Lat / Lon` | Geographic coordinates |
| `txn_process_time_hours` | Persisted computed accumulating column |

### ETL Packages (SSIS)

- **`InitialLoad.dtsx`** — Full initial load from CSV source into staging and all dimension/fact tables
- **`AccumulatingFactUpdate.dtsx`** — Updates accumulating snapshot columns on the fact table

> **Note:** Due to SSIS Unicode compatibility issues with OLE DB Destinations on flat files, the ETL uses `BULK INSERT` via Execute SQL Tasks and Python (`pyodbc` + `pandas`) as a reliable fallback for staging loads.

---

## 📊 Assignment 2 — BI & Reporting

### Step 1 — Documentation
ER diagram and schema documentation for the data warehouse design.

### Step 2 — SSAS Multidimensional Cube (`CrimeCubeProject`)

- Data Source: `CrimeAnalysisDW.ds`
- Measures: `IncidentCount`, `DaysToReport`, `VictimAge`, `TxnProcessTimeHours`
- Hierarchies:
  - `DIM_DATE` → Calendar Hierarchy: Year → QuarterName → MonthName → DayName
  - `DIM_AREA` → Location Hierarchy

### Step 3 — Excel OLAP Operations
OLAP analysis using Excel connected to the SSAS cube — slice, dice, drill-down, pivot operations on crime incident data.

### Step 4 — Power BI Reports
Four interactive reports published to **Power BI Service**:

| Report | Focus Area |
|---|---|
| Report 1 | Crime Trends Over Time |
| Report 2 | Geographic Crime Distribution |
| Report 3 | Victim Demographics Analysis |
| Report 4 | Crime Type & Weapon Analysis |

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| SQL Server 2022 | Database engine & data warehouse hosting |
| SSMS | Database management & query execution |
| Visual Studio 2022 | SSIS & SSAS project development |
| SSIS | ETL pipeline design and execution |
| SSAS | Multidimensional OLAP cube |
| Power BI Desktop | Report development |
| Power BI Service | Report publishing & sharing |
| Python (pyodbc, pandas) | ETL support & staging data loads |
| Microsoft Excel | OLAP operations & pivot analysis |

---

## 📁 Project Structure

```
CrimeAnalysisDW/
│
├── Assignment1/
│   ├── SSIS/
│   │   ├── InitialLoad.dtsx
│   │   └── AccumulatingFactUpdate.dtsx
│   ├── SQL/
│   │   ├── create_tables.sql
│   │   ├── dim_population.sql
│   │   └── fact_load.sql
│   ├── Python/
│   │   └── staging_load.py
│   └── Documentation/
│       └── Assignment1_Report.docx
│
├── Assignment2/
│   ├── SSAS/
│   │   └── CrimeCubeProject/
│   ├── PowerBI/
│   │   └── CrimeReports.pbix
│   ├── Excel/
│   │   └── OLAP_Analysis.xlsx
│   └── Documentation/
│       └── Assignment2_Report.docx
│
└── README.md
```

---

## ⚙️ Setup & Installation

### Prerequisites

- SQL Server 2022 (Developer Edition)
- Visual Studio 2022 with SSIS & SSAS extensions
- Power BI Desktop
- Python 3.x with `pyodbc` and `pandas`
- Microsoft Analysis Services client libraries (MSOLAP, AMO, ADOMD)

### Steps

1. **Restore / Create the Database**
   ```sql
   CREATE DATABASE CrimeAnalysisDW;
   ```

2. **Run SQL scripts** in `Assignment1/SQL/` to create all dimension and fact tables.

3. **Load Data via SSIS**
   - Open the SSIS solution in Visual Studio 2022
   - Update the connection string to point to your SQL Server instance
   - Run `InitialLoad.dtsx` first, then `AccumulatingFactUpdate.dtsx`

4. **Python Fallback (if SSIS staging fails)**
   ```bash
   pip install pyodbc pandas
   python Assignment1/Python/staging_load.py
   ```

5. **Deploy SSAS Cube**
   - Open `CrimeCubeProject` in Visual Studio 2022
   - Update the deployment target server
   - Build and deploy the project

6. **Open Power BI Reports**
   - Open `CrimeReports.pbix` in Power BI Desktop
   - Update the data source connection to your SQL Server instance
   - Refresh data and publish to Power BI Service

---

## 🔑 Key Design Decisions

- **SCD Type 2** implemented on `DIM_AREA` and `DIM_VICTIM` for historical tracking
- **Role-playing dimension** — `DIM_DATE` serves dual roles as both Date Occurred and Date Reported via aliased views
- **Accumulating snapshot** — `txn_process_time_hours` is a PERSISTED computed column on the fact table
- **Default unknown rows** (SK=1) inserted into all dimensions before fact load to handle referential integrity safely
- **BULK INSERT over SSIS OLE DB Destination** to avoid Unicode type conversion failures on flat file sources
- **DIM_DATE pre-populated back to 2010** to cover the full historical range of the LAPD dataset

---

## 👤 Author

**Yahya Ayyash**  
IT3021 — Data Warehousing and Business Intelligence  
*Built with SQL Server, SSIS, SSAS, Power BI & Python*
