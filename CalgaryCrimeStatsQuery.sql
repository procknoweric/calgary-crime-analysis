-- ============================================================
-- Calgary Crime & Community Analysis 2018-2024
-- Description: Data cleaning and view creation scripts for
-- Calgary crime dashboard project. Connects crime statistics,
-- civic census population, community metadata, and 311 service
-- requests to enable community-level crime analysis.
-- Source: Calgary Open Data Portal (data.calgary.ca)
-- All raw staging tables left untouched and views built on top
-- ============================================================
 
USE CalgaryCrimeStats;
GO
 
-- ============================================================
-- DATABASE OVERVIEW
-- Raw staging tables loaded via SSMS Import Flat File:
--   stg_CrimeRaw            - Wide format crime data 2018-2024
--                             One row per community/category
--                             84 month columns (_2018_JAN etc.)
--   stg_CivicRaw            - 2019 civic census by community
--                             22 rows per community (dwelling types)
--   stg_CommunityPointsRaw  - Community metadata and coordinates
--                             One row per community
--   stg_311newraw           - 311 service requests 2012-2026
--                             Capped at 1M rows due to Excel limit
-- ============================================================
 
-- ============================================================
-- VIEW 1: vw_CrimeLong
-- Unpivots the wide crime table (one column per month) into
-- long format (one row per community/category/year/month)
-- SUBSTRING(MonthYear, 2, 4) skips the leading underscore
-- added by SSMS on import e.g. _2018_JAN becomes 2018
-- NULL rows excluded as they represent months with no crime
-- Result: 99,826 rows covering 2018-2024
-- ============================================================
CREATE VIEW vw_CrimeLong AS
SELECT
    CommunityName,
    Category,
    CAST(SUBSTRING(MonthYear, 2, 4) AS INT) AS Year,
    RIGHT(MonthYear, 3) AS Month,
    CAST(CrimeCount AS INT) AS CrimeCount
FROM stg_CrimeRaw
UNPIVOT (
    CrimeCount FOR MonthYear IN (
        [_2018_JAN],[_2018_FEB],[_2018_MAR],[_2018_APR],[_2018_MAY],[_2018_JUN],
        [_2018_JUL],[_2018_AUG],[_2018_SEP],[_2018_OCT],[_2018_NOV],[_2018_DEC],
        [_2019_JAN],[_2019_FEB],[_2019_MAR],[_2019_APR],[_2019_MAY],[_2019_JUN],
        [_2019_JUL],[_2019_AUG],[_2019_SEP],[_2019_OCT],[_2019_NOV],[_2019_DEC],
        [_2020_JAN],[_2020_FEB],[_2020_MAR],[_2020_APR],[_2020_MAY],[_2020_JUN],
        [_2020_JUL],[_2020_AUG],[_2020_SEP],[_2020_OCT],[_2020_NOV],[_2020_DEC],
        [_2021_JAN],[_2021_FEB],[_2021_MAR],[_2021_APR],[_2021_MAY],[_2021_JUN],
        [_2021_JUL],[_2021_AUG],[_2021_SEP],[_2021_OCT],[_2021_NOV],[_2021_DEC],
        [_2022_JAN],[_2022_FEB],[_2022_MAR],[_2022_APR],[_2022_MAY],[_2022_JUN],
        [_2022_JUL],[_2022_AUG],[_2022_SEP],[_2022_OCT],[_2022_NOV],[_2022_DEC],
        [_2023_JAN],[_2023_FEB],[_2023_MAR],[_2023_APR],[_2023_MAY],[_2023_JUN],
        [_2023_JUL],[_2023_AUG],[_2023_SEP],[_2023_OCT],[_2023_NOV],[_2023_DEC],
        [_2024_JAN],[_2024_FEB],[_2024_MAR],[_2024_APR],[_2024_MAY],[_2024_JUN],
        [_2024_JUL],[_2024_AUG],[_2024_SEP],[_2024_OCT],[_2024_NOV],[_2024_DEC]
    )
) AS Unpivoted
WHERE CrimeCount IS NOT NULL;
GO
 
-- ============================================================
-- VIEW 2: vw_CensusClean
-- Filters 2019 civic census to one row per community
-- Raw table has 22 rows per community (one per dwelling type)
-- Filtering to CENSUS_YEAR = 2019 gives total population
-- Zero population communities excluded (undeveloped areas)
-- Population used as 2019 baseline for crime rate calculation
-- Note: newer communities (post-2019) will have understated rates
-- Result: 4,733 communities with valid population
-- ============================================================
CREATE VIEW vw_CensusClean AS
SELECT
    COMM_CODE,
    RESIDENT_CNT AS Population
FROM stg_CivicRaw
WHERE CENSUS_YEAR = 2019
AND RESIDENT_CNT > 0;
GO
 
-- ============================================================
-- VIEW 3: vw_CommunityClean
-- Clean community reference table with sector, class,
-- era of development, and lat/long for Power BI map visual
-- Residual Sub Areas excluded as they are non-residential
-- Community names uppercased to match crime data join key
-- Result: 270 residential and commercial communities
-- ============================================================
CREATE VIEW vw_CommunityClean AS
SELECT
    COMM_CODE,
    UPPER(NAME) AS CommunityName,
    SECTOR,
    CLASS,
    COMM_STRUCTURE,
    longitude,
    latitude
FROM stg_CommunityPointsRaw
WHERE CLASS != 'Residual Sub Area';
GO
 
-- ============================================================
-- VIEW 4: vw_CrimeFinal
-- Master view joining crime, community, and population data
-- Crime joined to community on CommunityName (uppercased)
-- REPLACE handles SCARBORO/ SUNALTA WEST spacing mismatch
-- between crime data and community points dataset
-- Community joined to population on COMM_CODE
-- CrimeRatePer1000 uses 2019 population as baseline
-- NULLIF prevents divide by zero on unpopulated communities
-- COMM_CODE included to enable join with vw_311Clean in Power BI
-- LEFT JOINs preserve all crime records even without a match
-- Result: 99,826 rows
-- ============================================================
CREATE VIEW vw_CrimeFinal AS
SELECT
    c.COMM_CODE,
    c.CommunityName,
    c.SECTOR,
    c.CLASS,
    c.COMM_STRUCTURE,
    c.latitude,
    c.longitude,
    cr.Category,
    cr.Year,
    cr.Month,
    cr.CrimeCount,
    p.Population,
    ROUND(CAST(cr.CrimeCount AS FLOAT) / NULLIF(p.Population, 0) * 1000, 2) AS CrimeRatePer1000
FROM vw_CrimeLong cr
LEFT JOIN vw_CommunityClean c 
    ON UPPER(REPLACE(cr.CommunityName, '/ ', '/')) = UPPER(c.CommunityName)
LEFT JOIN vw_CensusClean p 
    ON c.COMM_CODE = p.COMM_CODE;
GO
 
-- ============================================================
-- VIEW 5: vw_311Clean
-- Aggregates 311 service requests to community/service/month
-- Filters to 2018-2024 to align with crime data window
-- Extracts year and month from datetime requested_date column
-- Grouped to reduce 1M raw rows to manageable aggregate
-- Note: raw data capped at 1M rows due to Excel import limit
-- Full dataset is ~7M rows — rates may be understated
-- Joins to vw_CrimeFinal in Power BI on COMM_CODE
-- Result: 368,300 aggregated rows
-- ============================================================
CREATE VIEW vw_311Clean AS
SELECT
    comm_code,
    comm_name,
    service_name,
    YEAR(CAST(requested_date AS DATETIME)) AS Year,
    MONTH(CAST(requested_date AS DATETIME)) AS MonthNumber,
    COUNT(*) AS RequestCount
FROM stg_311newraw
WHERE YEAR(CAST(requested_date AS DATETIME)) BETWEEN 2018 AND 2024
GROUP BY
    comm_code,
    comm_name,
    service_name,
    YEAR(CAST(requested_date AS DATETIME)),
    MONTH(CAST(requested_date AS DATETIME));
GO
 