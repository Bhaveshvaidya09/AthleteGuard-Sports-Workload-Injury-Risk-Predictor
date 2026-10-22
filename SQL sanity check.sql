USE AthleteGuard_IPL;
GO

PRINT '======================================================================';
PRINT 'PHASE 1: PERFORMANCE OPTIMIZATION (INDEXING)';
PRINT '======================================================================';

-- 1. Fact_BallByBall Indexes (Speeds up joining balls to matches and players)
CREATE NONCLUSTERED INDEX IX_FactBBB_MatchID ON Fact_BallByBall(match_id);
CREATE NONCLUSTERED INDEX IX_FactBBB_Striker ON Fact_BallByBall(striker_id);
CREATE NONCLUSTERED INDEX IX_FactBBB_Bowler ON Fact_BallByBall(bowler_id);

-- 2. Fact_DailyWorkload Indexes (Speeds up time-series and risk filtering)
CREATE NONCLUSTERED INDEX IX_FactWorkload_PlayerDate ON Fact_DailyWorkload(PlayerID, Date);
CREATE NONCLUSTERED INDEX IX_FactWorkload_ACWR ON Fact_DailyWorkload(ACWR);
CREATE NONCLUSTERED INDEX IX_FactWorkload_InjuryProb ON Fact_DailyWorkload(Predicted_Injury_Prob DESC);

-- 3. Dimension Indexes (Speeds up dashboard slicers and filters)
CREATE NONCLUSTERED INDEX IX_DimMatch_Date ON Dim_Match(start_date, season);

PRINT 'Indexes created successfully. Query retrieval is optimized.';
GO

PRINT '======================================================================';
PRINT 'PHASE 2: DATA QUALITY & INTEGRITY AUDIT';
PRINT '======================================================================';

-- DQ 1: Orphan Record Check (Are there workloads for players that don't exist?)
SELECT 'Orphan Workloads' as Audit_Test, COUNT(*) as Failed_Rows
FROM Fact_DailyWorkload
WHERE PlayerID NOT IN (SELECT PlayerID FROM Dim_Player);

-- DQ 2: Duplicate Record Check (Does a player have two workload scores on the exact same day?)
SELECT 'Duplicate Daily Workloads' as Audit_Test, COUNT(*) as Failed_Rows
FROM (
    SELECT PlayerID, Date, COUNT(*) as Record_Count
    FROM Fact_DailyWorkload
    GROUP BY PlayerID, Date
    HAVING COUNT(*) > 1
) AS Duplicates;

-- DQ 3: Negative Value Check (Are there impossible negative values in the workload data?)
SELECT 'Negative Exertion Scores' as Audit_Test, COUNT(*) as Failed_Rows
FROM Fact_DailyWorkload
WHERE Daily_Load_Score < 0 OR ACWR < 0;

-- DQ 4: Missing Date Check (Are any matches missing a schedule date?)
SELECT 'Matches Missing Dates' as Audit_Test, COUNT(*) as Failed_Rows
FROM Dim_Match
WHERE start_date IS NULL;

GO

PRINT '======================================================================';
PRINT 'PHASE 3: BUSINESS LOGIC & SANITY CHECKS';
PRINT '======================================================================';

-- Sanity Check 1: ACWR Boundary Test 
-- (ACWR rarely exceeds 3.0. If we have values > 5.0, the math might be broken)
SELECT TOP 5 
    'Extreme ACWR Warning' as Alert_Type, 
    p.PlayerName, 
    f.Date, 
    f.ACWR
FROM Fact_DailyWorkload f
JOIN Dim_Player p ON f.PlayerID = p.PlayerID
WHERE f.ACWR > 3.0
ORDER BY f.ACWR DESC;

-- Sanity Check 2: The "Code Red" Medical Alert Review
-- (Ensures our medical view is correctly trapping high-risk predictions)
SELECT TOP 5 
    'High Risk Player Confirmed' as Alert_Type,
    Date, 
    PlayerName, 
    ACWR, 
    Predicted_Injury_Prob
FROM vw_Medical_Risk_Alerts
ORDER BY Predicted_Injury_Prob DESC;

-- Sanity Check 3: Venue Pressure Aggregation Test
-- (Ensures stadiums are properly rolling up total deliveries)
SELECT TOP 5 
    'Venue Pressure Test' as Alert_Type,
    venue, 
    Total_Matches_Hosted, 
    Total_Deliveries_Bowled
FROM vw_Venue_Pressure_Index
ORDER BY Total_Deliveries_Bowled DESC;

-- Sanity Check 4: Incomplete Match Detection
-- (Are there matches recorded that have less than 120 balls bowled?)
SELECT 
    'Incomplete Match Warning' as Alert_Type,
    m.match_id, 
    m.start_date, 
    COUNT(b.ball) as Balls_Bowled
FROM Dim_Match m
JOIN Fact_BallByBall b ON m.match_id = b.match_id
GROUP BY m.match_id, m.start_date
HAVING COUNT(b.ball) < 120;
GO

USE AthleteGuard_IPL;
