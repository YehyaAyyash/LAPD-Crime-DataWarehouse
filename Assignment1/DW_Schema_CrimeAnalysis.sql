-- ============================================================
-- CRIME ANALYSIS DATA WAREHOUSE - SQL SERVER SCHEMA
-- Dataset: LAPD Crime Incident Data (Los Angeles)
-- ============================================================

USE master;
GO

IF DB_ID('CrimeAnalysisDW') IS NOT NULL
    DROP DATABASE CrimeAnalysisDW;
GO

CREATE DATABASE CrimeAnalysisDW;
GO

USE CrimeAnalysisDW;
GO

-- ============================================================
-- DIMENSION TABLES
-- ============================================================

-- ------------------------------------------------------------
-- DIM_DATE  (Common Dimension)
-- ------------------------------------------------------------
CREATE TABLE DIM_DATE (
    DateKey         INT           NOT NULL PRIMARY KEY,  -- surrogate key e.g. 20200115
    FullDate        DATE          NOT NULL,
    DayOfWeek       TINYINT       NOT NULL,   -- 1=Sun, 7=Sat
    DayName         VARCHAR(10)   NOT NULL,
    DayOfMonth      TINYINT       NOT NULL,
    DayOfYear       SMALLINT      NOT NULL,
    WeekOfYear      TINYINT       NOT NULL,
    MonthNum        TINYINT       NOT NULL,
    MonthName       VARCHAR(10)   NOT NULL,
    Quarter         TINYINT       NOT NULL,
    QuarterName     CHAR(2)       NOT NULL,   -- Q1..Q4
    Year            SMALLINT      NOT NULL,
    IsWeekend       BIT           NOT NULL,
    IsHoliday       BIT           NOT NULL    DEFAULT 0
);
GO

-- Populate DIM_DATE for 2018-2026
DECLARE @StartDate DATE = '2018-01-01';
DECLARE @EndDate   DATE = '2026-12-31';
DECLARE @CurrDate  DATE = @StartDate;

WHILE @CurrDate <= @EndDate
BEGIN
    INSERT INTO DIM_DATE VALUES (
        CAST(FORMAT(@CurrDate,'yyyyMMdd') AS INT),
        @CurrDate,
        DATEPART(WEEKDAY, @CurrDate),
        DATENAME(WEEKDAY, @CurrDate),
        DAY(@CurrDate),
        DATEPART(DAYOFYEAR, @CurrDate),
        DATEPART(WEEK, @CurrDate),
        MONTH(@CurrDate),
        DATENAME(MONTH, @CurrDate),
        DATEPART(QUARTER, @CurrDate),
        'Q' + CAST(DATEPART(QUARTER,@CurrDate) AS CHAR(1)),
        YEAR(@CurrDate),
        CASE WHEN DATEPART(WEEKDAY,@CurrDate) IN (1,7) THEN 1 ELSE 0 END,
        0
    );
    SET @CurrDate = DATEADD(DAY, 1, @CurrDate);
END;
GO

-- ------------------------------------------------------------
-- DIM_TIME  (Time of Day Dimension)
-- ------------------------------------------------------------
CREATE TABLE DIM_TIME (
    TimeKey         INT         NOT NULL PRIMARY KEY,  -- HHMM integer e.g. 1430
    Hour            TINYINT     NOT NULL,
    Minute          TINYINT     NOT NULL,
    TimeLabel       CHAR(5)     NOT NULL,   -- "14:30"
    TimePeriod      VARCHAR(15) NOT NULL,   -- Morning/Afternoon/Evening/Night
    IsRushHour      BIT         NOT NULL    DEFAULT 0
);
GO

DECLARE @h TINYINT = 0;
DECLARE @m TINYINT = 0;

WHILE @h < 24
BEGIN
    SET @m = 0;
    WHILE @m < 60
    BEGIN
        INSERT INTO DIM_TIME VALUES (
            @h * 100 + @m,
            @h,
            @m,
            RIGHT('0' + CAST(@h AS VARCHAR),2) + ':' + RIGHT('0' + CAST(@m AS VARCHAR),2),
            CASE
                WHEN @h BETWEEN 5  AND 11 THEN 'Morning'
                WHEN @h BETWEEN 12 AND 16 THEN 'Afternoon'
                WHEN @h BETWEEN 17 AND 20 THEN 'Evening'
                ELSE 'Night'
            END,
            CASE WHEN (@h BETWEEN 7 AND 9) OR (@h BETWEEN 16 AND 18) THEN 1 ELSE 0 END
        );
        SET @m = @m + 1;
    END;
    SET @h = @h + 1;
END;
GO

-- ------------------------------------------------------------
-- DIM_AREA  (SCD Type 2 - Slowly Changing Dimension)
-- Tracks changes in Area name/region classification over time
-- ------------------------------------------------------------
CREATE TABLE DIM_AREA (
    AreaSK              INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,  -- surrogate key
    AreaCode            INT           NOT NULL,                             -- natural key
    AreaName            VARCHAR(50)   NOT NULL,
    Region              VARCHAR(30)   NOT NULL,   -- e.g. North, South, East, West, Central
    Division            VARCHAR(30)   NOT NULL,   -- e.g. Patrol Division
    -- SCD Type 2 columns
    EffectiveDate       DATE          NOT NULL,
    ExpiryDate          DATE          NULL,        -- NULL means current record
    IsCurrent           BIT           NOT NULL    DEFAULT 1,
    RowCreatedDate      DATETIME      NOT NULL    DEFAULT GETDATE(),
    RowUpdatedDate      DATETIME      NOT NULL    DEFAULT GETDATE()
);
GO

-- Seed DIM_AREA from AreaCodeDescription lookup
-- (In ETL, this is loaded from AreaCodeDescription.csv)
INSERT INTO DIM_AREA (AreaCode, AreaName, Region, Division, EffectiveDate, ExpiryDate, IsCurrent)
VALUES
    (1,  'Central',      'Central',  'Central Bureau',  '2018-01-01', NULL, 1),
    (2,  'Rampart',      'Central',  'Central Bureau',  '2018-01-01', NULL, 1),
    (3,  'Southwest',    'South',    'South Bureau',    '2018-01-01', NULL, 1),
    (4,  'Hollenbeck',   'East',     'East Bureau',     '2018-01-01', NULL, 1),
    (5,  'Harbor',       'South',    'South Bureau',    '2018-01-01', NULL, 1),
    (6,  'Hollywood',    'Central',  'Central Bureau',  '2018-01-01', NULL, 1),
    (7,  'Wilshire',     'Central',  'Central Bureau',  '2018-01-01', NULL, 1),
    (8,  'West LA',      'West',     'West Bureau',     '2018-01-01', NULL, 1),
    (9,  'Van Nuys',     'Valley',   'Valley Bureau',   '2018-01-01', NULL, 1),
    (10, 'West Valley',  'Valley',   'Valley Bureau',   '2018-01-01', NULL, 1),
    (11, 'Northeast',    'East',     'East Bureau',     '2018-01-01', NULL, 1),
    (12, '77th Street',  'South',    'South Bureau',    '2018-01-01', NULL, 1),
    (13, 'Newton',       'South',    'South Bureau',    '2018-01-01', NULL, 1),
    (14, 'Pacific',      'West',     'West Bureau',     '2018-01-01', NULL, 1),
    (15, 'N Hollywood',  'Valley',   'Valley Bureau',   '2018-01-01', NULL, 1),
    (16, 'Foothill',     'Valley',   'Valley Bureau',   '2018-01-01', NULL, 1),
    (17, 'Devonshire',   'Valley',   'Valley Bureau',   '2018-01-01', NULL, 1),
    (18, 'Southeast',    'South',    'South Bureau',    '2018-01-01', NULL, 1),
    (19, 'Mission',      'Valley',   'Valley Bureau',   '2018-01-01', NULL, 1),
    (20, 'Olympic',      'West',     'West Bureau',     '2018-01-01', NULL, 1),
    (21, 'Topanga',      'Valley',   'Valley Bureau',   '2018-01-01', NULL, 1),
    (22, 'Unknown',      'Unknown',  'Unknown',         '2018-01-01', NULL, 1);
GO

-- ------------------------------------------------------------
-- DIM_CRIME  (Crime Type Dimension - SCD Type 1)
-- ------------------------------------------------------------
CREATE TABLE DIM_CRIME (
    CrimeSK             INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    CrimeCode           INT           NOT NULL,
    CrimeDescription    VARCHAR(150)  NOT NULL,
    CrimeCategory       VARCHAR(50)   NOT NULL,   -- Violent / Property / Other
    CrimeSeverity       VARCHAR(20)   NOT NULL,   -- Part 1 / Part 2
    IsViolent           BIT           NOT NULL    DEFAULT 0,
    IsPropertyCrime     BIT           NOT NULL    DEFAULT 0
);
GO

-- ------------------------------------------------------------
-- DIM_PREMISE  (Location/Premise Type Dimension)
-- ------------------------------------------------------------
CREATE TABLE DIM_PREMISE (
    PremiseSK           INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    PremiseCode         INT           NOT NULL,
    PremiseDescription  VARCHAR(100)  NOT NULL,
    PremiseCategory     VARCHAR(50)   NOT NULL    -- Residential/Commercial/Public/Vehicle/Other
);
GO

-- ------------------------------------------------------------
-- DIM_WEAPON  (Weapon Type Dimension)
-- ------------------------------------------------------------
CREATE TABLE DIM_WEAPON (
    WeaponSK            INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    WeaponCode          INT           NOT NULL,
    WeaponDescription   VARCHAR(100)  NOT NULL,
    WeaponCategory      VARCHAR(50)   NOT NULL    -- Firearm/Knife/Physical/Other/Unknown
);
GO

-- ------------------------------------------------------------
-- DIM_STATUS  (Case Status Dimension)
-- ------------------------------------------------------------
CREATE TABLE DIM_STATUS (
    StatusSK            INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    StatusCode          CHAR(5)       NOT NULL,
    StatusDescription   VARCHAR(50)   NOT NULL,
    StatusCategory      VARCHAR(30)   NOT NULL    -- Arrest/Investigation/Juvenile
);
GO

INSERT INTO DIM_STATUS (StatusCode, StatusDescription, StatusCategory) VALUES
    ('AA',  'Adult Arrest',        'Arrest'),
    ('IC',  'Invest Cont',         'Investigation'),
    ('AO',  'Adult Other',         'Other'),
    ('JA',  'Juv Arrest',          'Arrest'),
    ('JO',  'Juv Other',           'Other'),
    ('CC',  'UNK',                 'Unknown'),
    ('13',  'Juv Other',           'Juvenile'),
    ('14',  'Other',               'Other');
GO

-- ------------------------------------------------------------
-- DIM_VICTIM  (Victim Demographic Dimension - SCD Type 2)
-- Tracks changes: e.g. age bucket or descent correction over time
-- ------------------------------------------------------------
CREATE TABLE DIM_VICTIM (
    VictimSK            INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    VictimNK            BIGINT        NOT NULL,              -- natural key = DR_NO
    VictimAge           TINYINT       NOT NULL,
    AgeGroup            VARCHAR(20)   NOT NULL,              -- Derived: Child/Teen/Adult/Senior
    VictimGender        CHAR(1)       NOT NULL,              -- M / F / X
    GenderDescription   VARCHAR(15)   NOT NULL,
    VictimDescent       CHAR(2)       NULL,
    DescentDescription  VARCHAR(50)   NULL,
    -- SCD Type 2 tracking
    EffectiveDate       DATE          NOT NULL,
    ExpiryDate          DATE          NULL,
    IsCurrent           BIT           NOT NULL    DEFAULT 1
);
GO

-- ------------------------------------------------------------
-- FACT TABLE: FACT_CRIME_INCIDENT
-- Grain: One row per crime incident (DR_NO)
-- ------------------------------------------------------------
CREATE TABLE FACT_CRIME_INCIDENT (
    FactSK                  BIGINT      NOT NULL IDENTITY(1,1) PRIMARY KEY,
    -- Natural key
    DR_NO                   BIGINT      NOT NULL UNIQUE,
    -- Foreign Keys (Surrogate Keys to Dimensions)
    DateOccurredKey         INT         NOT NULL REFERENCES DIM_DATE(DateKey),
    DateReportedKey         INT         NOT NULL REFERENCES DIM_DATE(DateKey),
    TimeOccurredKey         INT         NOT NULL REFERENCES DIM_TIME(TimeKey),
    AreaSK                  INT         NOT NULL REFERENCES DIM_AREA(AreaSK),
    CrimeSK                 INT         NOT NULL REFERENCES DIM_CRIME(CrimeSK),
    PremiseSK               INT         NOT NULL REFERENCES DIM_PREMISE(PremiseSK),
    WeaponSK                INT         NOT NULL REFERENCES DIM_WEAPON(WeaponSK),
    StatusSK                INT         NOT NULL REFERENCES DIM_STATUS(StatusSK),
    VictimSK                INT         NOT NULL REFERENCES DIM_VICTIM(VictimSK),
    -- Degenerate dimensions
    ReportDistrictNo        INT         NULL,
    Part_1_2                TINYINT     NULL,
    -- Measures / Additive Facts
    IncidentCount           TINYINT     NOT NULL DEFAULT 1,
    DaysToReport            SMALLINT    NOT NULL DEFAULT 0,   -- DateReported - DateOccurred
    VictimAge               TINYINT     NULL,
    Latitude                DECIMAL(9,6) NULL,
    Longitude               DECIMAL(9,6) NULL,
    -- Accumulating Fact Columns (Task 6)
    accm_txn_create_time    DATETIME    NOT NULL DEFAULT GETDATE(),
    accm_txn_complete_time  DATETIME    NULL,
    txn_process_time_hours  AS (
        CASE
            WHEN accm_txn_complete_time IS NOT NULL
            THEN DATEDIFF(HOUR, accm_txn_create_time, accm_txn_complete_time)
            ELSE NULL
        END
    ) PERSISTED
);
GO

-- ============================================================
-- INDEXES for query performance
-- ============================================================
CREATE INDEX IX_FACT_DateOccurred ON FACT_CRIME_INCIDENT(DateOccurredKey);
CREATE INDEX IX_FACT_Area         ON FACT_CRIME_INCIDENT(AreaSK);
CREATE INDEX IX_FACT_Crime        ON FACT_CRIME_INCIDENT(CrimeSK);
CREATE INDEX IX_FACT_Status       ON FACT_CRIME_INCIDENT(StatusSK);
CREATE INDEX IX_FACT_DR_NO        ON FACT_CRIME_INCIDENT(DR_NO);
GO

-- ============================================================
-- STAGING TABLES (used by SSIS ETL)
-- ============================================================
CREATE TABLE STG_CrimeIncidents (
    DR_NO           BIGINT,
    Date_Reported   VARCHAR(20),
    Date_Occurred   VARCHAR(20),
    Time_Occurred   VARCHAR(4),
    Area_Code       INT,
    Crime_Code      INT,
    Premise_Code    INT,
    Weapon_Code     INT,
    Status_Code     VARCHAR(10),
    Rpt_District_No INT,
    Part_1_2        TINYINT,
    Latitude        DECIMAL(9,6),
    Longitude       DECIMAL(9,6)
);
GO

CREATE TABLE STG_VictimData (
    DR_NO                   BIGINT,
    Victim_Age              TINYINT,
    Victim_Gender           CHAR(1),
    Victim_OriginalCountry  VARCHAR(5)
);
GO

CREATE TABLE STG_AccumulatingUpdate (
    txn_id                  BIGINT,
    accm_txn_complete_time  DATETIME
);
GO

-- ============================================================
-- HELPER: SCD Type 2 UPDATE PROCEDURE for DIM_AREA
-- ============================================================
CREATE PROCEDURE usp_SCD2_UpdateArea
    @AreaCode   INT,
    @NewName    VARCHAR(50),
    @NewRegion  VARCHAR(30),
    @NewDiv     VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);

    -- Expire the current row
    UPDATE DIM_AREA
    SET    ExpiryDate = DATEADD(DAY,-1,@Today),
           IsCurrent  = 0,
           RowUpdatedDate = GETDATE()
    WHERE  AreaCode = @AreaCode
      AND  IsCurrent = 1;

    -- Insert new current row
    INSERT INTO DIM_AREA (AreaCode, AreaName, Region, Division, EffectiveDate, ExpiryDate, IsCurrent)
    VALUES (@AreaCode, @NewName, @NewRegion, @NewDiv, @Today, NULL, 1);
END;
GO

-- ============================================================
-- ACCUMULATING FACT UPDATE PROCEDURE (Task 6 - Step 4 & 5)
-- ============================================================
CREATE PROCEDURE usp_UpdateAccumulatingFact
    @txn_id                 BIGINT,
    @accm_txn_complete_time DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE FACT_CRIME_INCIDENT
    SET    accm_txn_complete_time = @accm_txn_complete_time
    WHERE  DR_NO = @txn_id;
    -- txn_process_time_hours is a PERSISTED computed column - auto-updates
END;
GO

PRINT 'CrimeAnalysisDW schema created successfully.';
GO
