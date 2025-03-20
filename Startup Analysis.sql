CREATE DATABASE startup_funding;

USE startup_funding;

CREATE TABLE startup_data (
    S_No INT,
    Startup_Name VARCHAR(100),
    Incorporation_Date DATE,
    Location VARCHAR(50),
    Industry_Vertical VARCHAR(50),
    Sub_Vertical VARCHAR(100),
    Investors_Name VARCHAR(100),
    Investment_Type VARCHAR(50),
    Total_Funding_USD DECIMAL(15,2)
);

-- 1. What is the total funding amount across all startups?

SELECT 
    SUM(Total_Funding_USD) AS Total_Funding
FROM
    startup_data;


-- 2. Which cities have attracted the most funding?

SELECT 
    Location,
    SUM(Total_Funding_USD) AS Total_Funding,
    COUNT(*) AS Number_of_Startups
FROM
    startup_data
GROUP BY Location
ORDER BY Total_Funding DESC;


-- 3. What are the top 5 industry verticals by funding amount?

SELECT 
    Industry_Vertical, SUM(Total_Funding_USD) AS Total_Funding
FROM
    startup_data
GROUP BY Industry_Vertical
ORDER BY Total_Funding DESC
LIMIT 5;


-- 4. Which investment type is most common?

SELECT 
    Investment_Type, COUNT(*) AS Frequency
FROM
    startup_data
GROUP BY Investment_Type
ORDER BY Frequency DESC;


-- 5. What is the average funding amount by investment type?

SELECT 
    Investment_Type, AVG(Total_Funding_USD) AS Avg_Funding
FROM
    startup_data
GROUP BY Investment_Type
ORDER BY Avg_Funding DESC;


-- 6. Which investors have made the most investments?

SELECT 
    Investors_Name, COUNT(*) AS Investment_Count
FROM
    startup_data
GROUP BY Investors_Name
ORDER BY Investment_Count DESC
LIMIT 10;


-- 7. What is the monthly trend of investments?

SELECT 
    MONTH(Incorporation_Date) AS Month,
    COUNT(*) AS Deal_Count,
    SUM(Total_Funding_USD) AS Total_Funding
FROM
    startup_data
GROUP BY Month
ORDER BY Month;


-- 8. Which startups received the highest funding?

SELECT 
    Startup_Name, SUM(Total_Funding_USD) AS Total_Funding
FROM
    startup_data
GROUP BY Startup_Name
ORDER BY Total_Funding DESC
LIMIT 10;


-- 9. What is the distribution of funding amounts?

SELECT 
    CASE
        WHEN Total_Funding_USD < 1000000 THEN 'Less than 1M'
        WHEN Total_Funding_USD < 10000000 THEN '1M-10M'
        WHEN Total_Funding_USD < 100000000 THEN '10M-100M'
        ELSE 'More than 100M'
    END AS Funding_Range,
    COUNT(*) AS Count
FROM
    startup_data
GROUP BY Funding_Range;


-- 10. Which sub-verticals are most popular in each industry?

SELECT 
    Industry_Vertical, Sub_Vertical, COUNT(*) AS Count
FROM
    startup_data
GROUP BY Industry_Vertical , Sub_Vertical
ORDER BY Industry_Vertical , Count DESC;


-- 11. What is the year-over-year growth in funding?

SELECT 
    YEAR(Incorporation_Date) AS Year,
    SUM(Total_Funding_USD) AS Total_Funding,
    COUNT(*) AS Deal_Count
FROM
    startup_data
GROUP BY Year
ORDER BY Year;


-- 12. Which cities have the most diverse industry verticals?

SELECT 
    Location,
    COUNT(DISTINCT Industry_Vertical) AS Industry_Diversity
FROM
    startup_data
GROUP BY Location
ORDER BY Industry_Diversity DESC;


-- 13. What is the average funding by city and industry?

SELECT 
    Location,
    Industry_Vertical,
    AVG(Total_Funding_USD) AS Avg_Funding
FROM
    startup_data
GROUP BY Location , Industry_Vertical
ORDER BY Avg_Funding DESC;


-- 14. Which startups received multiple rounds of funding?

SELECT 
    Startup_Name, COUNT(*) AS Funding_Rounds
FROM
    startup_data
GROUP BY Startup_Name
HAVING Funding_Rounds > 1
ORDER BY Funding_Rounds DESC;


-- 15. What is the correlation between location and investment type?

SELECT 
    Location, Investment_Type, COUNT(*) AS Frequency
FROM
    startup_data
GROUP BY Location , Investment_Type
ORDER BY Location , Frequency DESC;


-- 16. Analyze funding trends with moving averages over 3-month periods?

WITH MonthlyFunding AS (
    SELECT 
        DATE_FORMAT(Incorporation_Date, '%Y-%m') as Month,
        SUM(Total_Funding_USD) as Monthly_Funding
    FROM startup_data
    GROUP BY DATE_FORMAT(Incorporation_Date, '%Y-%m')
)
SELECT 
    Month,
    Monthly_Funding,
    AVG(Monthly_Funding) OVER (
        ORDER BY Month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as Three_Month_Moving_Avg
FROM MonthlyFunding
ORDER BY Month;


-- 17. Identify startups that received above-average funding within their industry?

WITH IndustryAvg AS (
    SELECT 
        Industry_Vertical,
        AVG(Total_Funding_USD) as Avg_Industry_Funding
    FROM startup_data
    GROUP BY Industry_Vertical
)
SELECT 
    s.Startup_Name,
    s.Industry_Vertical,
    s.Total_Funding_USD,
    ia.Avg_Industry_Funding,
    ((s.Total_Funding_USD - ia.Avg_Industry_Funding) / ia.Avg_Industry_Funding * 100) as Percentage_Above_Avg
FROM startup_data s
JOIN IndustryAvg ia ON s.Industry_Vertical = ia.Industry_Vertical
WHERE s.Total_Funding_USD > ia.Avg_Industry_Funding
ORDER BY Percentage_Above_Avg DESC;


-- 18. Calculate the funding concentration by location and industry?

WITH FundingRanked AS (
    SELECT 
        Location,
        Industry_Vertical,
        SUM(Total_Funding_USD) as Total_Funding,
        ROW_NUMBER() OVER (ORDER BY SUM(Total_Funding_USD) DESC) as `Rank`
    FROM startup_data
    GROUP BY Location, Industry_Vertical
)
SELECT 
    Location,
    Industry_Vertical,
    Total_Funding,
    Grand_Total,
    ROUND((Total_Funding / Grand_Total * 100), 2) as Funding_Percentage,
    ROUND(SUM(Total_Funding / Grand_Total * 100) OVER (ORDER BY Total_Funding DESC), 2) as Cumulative_Percentage
FROM (
    SELECT 
        Location,
        Industry_Vertical,
        Total_Funding,
        SUM(Total_Funding) OVER () as Grand_Total,
        `Rank`
    FROM FundingRanked
) as RankedFunding
WHERE `Rank` <= 10;


-- 19. Analyze sequential investments in startups (startups receiving multiple rounds)?

WITH RankedInvestments AS (
    SELECT 
        Startup_Name,
        Incorporation_Date,
        Total_Funding_USD,
        Investment_Type,
        ROW_NUMBER() OVER (PARTITION BY Startup_Name ORDER BY Incorporation_Date) as Investment_Sequence
    FROM startup_data
)
SELECT 
    r1.Startup_Name,
    r1.Investment_Type as First_Round,
    r2.Investment_Type as Second_Round,
    r1.Total_Funding_USD as First_Amount,
    r2.Total_Funding_USD as Second_Amount,
    DATEDIFF(r2.Incorporation_Date, r1.Incorporation_Date) as Days_Between_Rounds
FROM RankedInvestments r1
JOIN RankedInvestments r2 
    ON r1.Startup_Name = r2.Startup_Name 
    AND r1.Investment_Sequence = 1 
    AND r2.Investment_Sequence = 2
ORDER BY Days_Between_Rounds;


-- 20. Identify investment patterns by investor type?

SELECT 
    CASE 
        WHEN Investors_Name REGEXP 'Capital|Ventures|Partners' THEN 'VC Firm'
        WHEN Investors_Name REGEXP 'Angel|Individual' THEN 'Angel Investor'
        WHEN Investors_Name REGEXP 'Bank|Financial|Finance' THEN 'Financial Institution'
        ELSE 'Others'
    END as Investor_Type,
    COUNT(*) as Investment_Count,
    AVG(Total_Funding_USD) as Avg_Investment,
    SUM(Total_Funding_USD) as Total_Investment
FROM startup_data
GROUP BY Investor_Type
ORDER BY Investment_Count DESC;


-- 21. Analyze seasonal patterns in startup funding?

WITH SeasonalAnalysis AS (
    SELECT 
        CASE 
            WHEN MONTH(Incorporation_Date) IN (12,1,2) THEN 'Winter'
            WHEN MONTH(Incorporation_Date) IN (3,4,5) THEN 'Spring'
            WHEN MONTH(Incorporation_Date) IN (6,7,8) THEN 'Summer'
            ELSE 'Fall'
        END as Season,
        Industry_Vertical,
        Total_Funding_USD
    FROM startup_data
)
SELECT 
    Season,
    Industry_Vertical,
    COUNT(*) as Deal_Count,
    AVG(Total_Funding_USD) as Avg_Funding,
    SUM(Total_Funding_USD) as Total_Funding
FROM SeasonalAnalysis
GROUP BY Season, Industry_Vertical
HAVING Deal_Count > 5
ORDER BY Season, Total_Funding DESC;


-- 22. Calculate the funding velocity and growth rate?

WITH MonthlyMetrics AS (
    SELECT 
        DATE_FORMAT(Incorporation_Date, '%Y-%m') as Month,
        COUNT(*) as Deals,
        SUM(Total_Funding_USD) as Monthly_Funding,
        LAG(SUM(Total_Funding_USD)) OVER (ORDER BY DATE_FORMAT(Incorporation_Date, '%Y-%m')) as Prev_Month_Funding
    FROM startup_data
    GROUP BY DATE_FORMAT(Incorporation_Date, '%Y-%m')
)
SELECT 
    Month,
    Deals,
    Monthly_Funding,
    ROUND(((Monthly_Funding - Prev_Month_Funding) / Prev_Month_Funding * 100), 2) as MoM_Growth_Rate,
    Monthly_Funding/Deals as Avg_Deal_Size
FROM MonthlyMetrics
WHERE Prev_Month_Funding IS NOT NULL
ORDER BY Month;


-- 23. Analyze co-investment patterns?

WITH InvestorPairs AS (
    SELECT 
        a.Investors_Name as Investor1,
        b.Investors_Name as Investor2,
        COUNT(*) as Co_Investments
    FROM startup_data a
    JOIN startup_data b 
        ON a.Startup_Name = b.Startup_Name 
        AND a.Investors_Name < b.Investors_Name
    GROUP BY a.Investors_Name, b.Investors_Name
    HAVING Co_Investments > 1
)
SELECT 
    Investor1,
    Investor2,
    Co_Investments,
    DENSE_RANK() OVER (ORDER BY Co_Investments DESC) as Partnership_Rank
FROM InvestorPairs
ORDER BY Co_Investments DESC
LIMIT 10;


-- 24. Analyze funding success by location and create a location attractiveness index?

WITH LocationMetrics AS (
    SELECT 
        Location,
        COUNT(*) as Total_Startups,
        AVG(Total_Funding_USD) as Avg_Funding,
        COUNT(DISTINCT Industry_Vertical) as Industry_Diversity,
        COUNT(DISTINCT Investors_Name) as Unique_Investors
    FROM startup_data
    GROUP BY Location
    HAVING Total_Startups >= 5
)
SELECT 
    Location,
    Total_Startups,
    ROUND(Avg_Funding, 2) as Avg_Funding,
    Industry_Diversity,
    Unique_Investors,
    ROUND((
        (Avg_Funding / MAX(Avg_Funding) OVER ()) * 0.4 +
        (Industry_Diversity / MAX(Industry_Diversity) OVER ()) * 0.3 +
        (Unique_Investors / MAX(Unique_Investors) OVER ()) * 0.3
    ) * 100, 2) as Location_Attractiveness_Score
FROM LocationMetrics
ORDER BY Location_Attractiveness_Score DESC;























--




