# Calgary Crime & Community Analysis 2018–2024
An end-to-end data analysis project examining crime patterns across Calgary communities, the relationship between neighbourhood service complaints and crime rates, and how crime types and volumes have shifted over a seven-year period.

## Project Context
Crime in Calgary is not evenly distributed. A small number of communities account for a disproportionate share of reported incidents, and neighbourhoods with higher volumes of 311 service complaints tend to show consistently elevated crime rates which I found to be a pattern consistent with broken windows theory. This project uses publicly available Calgary Open Data to quantify where crime is concentrated, what types dominate, and whether targeted city service investment correlates with safer outcomes.

The analysis was built entirely from publicly available data and is intended to demonstrate end-to-end analytics skills across SQL Server, data modeling, Power BI, and DAX.

## Key Findings
- Total crime in Calgary declined 9.11% from 2023 to 2024, continuing a gradual downward trend since 2018
- Disorder is the single largest crime category, accounting for the majority of all reported incidents across every year in the dataset
- Crime follows a consistent seasonal pattern, peaking in July and August and dropping sharply in February which is consistent with Calgary's climate and homelessness patterns
- A strong positive correlation exists between community-level 311 service request volume and total crime count, supporting the case for proactive neighbourhood maintenance as a crime reduction strategy
- Beltline is the highest crime community in Calgary by total incidents, followed by Downtown Commercial Core and Forest Lawn
- Crime is concentrated in a small number of communities and the top 5 account for a disproportionate share of citywide totals

## Data Sources
| Dataset | Source | Coverage |
|---|---|---|
| Community Crime Statistics | Calgary Open Data Portal | 2018–2024 |
| Community Points | Calgary Open Data Portal | Current |
| Civic Census by Community | Calgary Open Data Portal | 2019 |
| 311 Service Requests | Calgary Open Data Portal | 2018–2024 |

## Technical Stack
- **Database:** SQL Server (local instance via SSMS 22)
- **ETL:** SQL-based unpivoting, cleaning, and view creation
- **Visualization:** Power BI Desktop
- **Languages:** T-SQL, DAX, Power Query (M)

## Repository Structure
```
calgary-crime-analysis/
├── sql/
│   └── CalgaryCrimeStatsQuery.sql    # All views: unpivot, clean, join, aggregate
├── powerbi/
│   └── CalgaryCrimeStats.pbix   # Power BI dashboard file
├── Calgary-Crime-Dashboard-Screenshot.png          # Dashboard preview
└── README.md
```

## Dashboard
The Power BI dashboard is built for decision-making, not just display. It covers four analytical themes:

1. Crime Hotspots by Community: bubble map showing total crime volume by neighbourhood, colour coded by city sector
2. Relationship Between 311 Requests and Crime: scatter plot with trend line showing community-level correlation between service complaints and crime rates
3. Crime Mix by Year: stacked bar showing how the composition of crime types has shifted 2018–2024. Select a community on the map to filter to that neighbourhood's specific breakdown
4. Top 5 Communities by Crime: ranked bar chart with conditional formatting highlighting communities where crime is trending upward

Key metrics are surfaced in headline KPI cards showing total crimes, the dominant crime category, and year-over-year change vs the prior year.


![Dashboard Preview] <img width="1294" height="726" alt="Calgary-Crime-Dashboard-Screenshot" src="https://github.com/user-attachments/assets/d5719a57-8430-4486-87f3-27709234dc2e" />


## Methodology Notes
- Crime data was delivered in wide format with one column per month and unpivoted in SQL to long format before analysis
- Population figures sourced from the 2019 Calgary Civic Census, the most recent community-level data available. Newer communities developed after 2019 may show understated crime rates per capita
- 311 service request data is capped at approximately 1 million rows due to Excel import limitations. The full dataset contains approximately 7 million rows. Community-level totals may be understated but the relative correlation pattern holds
- Communities with fewer than 500 residents excluded from per-capita crime rate calculations to prevent misleading outliers
- Residual Sub Areas and undeveloped communities excluded from community reference data
- SCARBORO/SUNALTA WEST name spacing inconsistency resolved via REPLACE() in SQL join logic

## Author
Eric Procknow
Calgary, AB
(https://www.linkedin.com/in/ericprocknow/)
