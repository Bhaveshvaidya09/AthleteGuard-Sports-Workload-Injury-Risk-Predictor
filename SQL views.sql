USE AthleteGuard_IPL;
GO

-- ==============================================================================
-- VIEW 1: vw_Medical_Risk_Alerts (Restored original columns + New Dashboard Metrics)
-- ==============================================================================
CREATE OR ALTER VIEW vw_Medical_Risk_Alerts AS
SELECT 
    f.Date,
    p.PlayerName,
    f.Daily_Load_Score,
    f.ACWR,
    f.Predicted_Injury_Prob,
    f.Injury_Flag,
    
    -- Original columns kept so Power BI does not crash:
    AVG(f.Daily_Load_Score) OVER (PARTITION BY f.PlayerID ORDER BY f.Date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as Rolling_3Day_Load,
    RANK() OVER (PARTITION BY f.Date ORDER BY f.Predicted_Injury_Prob DESC) as Daily_Risk_Rank,
    
    -- NEW calculated columns for the Power BI Dashboard:
    CASE WHEN f.ACWR >= 1.5 THEN 'Danger Zone' WHEN f.ACWR >= 1.2 THEN 'Warning Zone' ELSE 'Safe Zone' END AS Risk_Zone,
    CASE WHEN f.ACWR >= 1.5 THEN 'REST / OMIT' WHEN f.ACWR >= 1.2 THEN 'RESTRICT OVERS' ELSE 'SAFE TO PLAY' END AS medical_action,
    SUM(f.Daily_Load_Score) OVER (PARTITION BY f.PlayerID ORDER BY f.Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS Acute_Load_7Day,
    AVG(f.Daily_Load_Score) OVER (PARTITION BY f.PlayerID ORDER BY f.Date ROWS BETWEEN 27 PRECEDING AND CURRENT ROW) AS Chronic_Load_28Day
FROM Fact_DailyWorkload f
JOIN Dim_Player p ON f.PlayerID = p.PlayerID;
GO

-- ==============================================================================
-- VIEW 2: vw_Player_Performance_vs_Fatigue (Restored)
-- ==============================================================================
CREATE OR ALTER VIEW vw_Player_Performance_vs_Fatigue AS
WITH MatchPerformance AS (
    SELECT m.start_date, b.striker_id as PlayerID, SUM(b.runs_off_bat) as RunsScored, 0 as BallsBowled
    FROM Fact_BallByBall b JOIN Dim_Match m ON b.match_id = m.match_id GROUP BY m.start_date, b.striker_id
    UNION ALL
    SELECT m.start_date, b.bowler_id as PlayerID, 0 as RunsScored, COUNT(b.ball) as BallsBowled
    FROM Fact_BallByBall b JOIN Dim_Match m ON b.match_id = m.match_id GROUP BY m.start_date, b.bowler_id
),
AggregatedPerformance AS (
    SELECT start_date, PlayerID, SUM(RunsScored) as TotalRuns, SUM(BallsBowled) as TotalBallsBowled
    FROM MatchPerformance GROUP BY start_date, PlayerID
)
SELECT 
    f.Date, p.PlayerName, COALESCE(ap.TotalRuns, 0) as Match_Runs_Scored, COALESCE(ap.TotalBallsBowled, 0) as Match_Balls_Bowled,
    f.Daily_Load_Score, f.ACWR, f.Injury_Flag
FROM Fact_DailyWorkload f
JOIN Dim_Player p ON f.PlayerID = p.PlayerID
LEFT JOIN AggregatedPerformance ap ON f.PlayerID = ap.PlayerID AND f.Date = ap.start_date;
GO

-- ==============================================================================
-- VIEW 3: vw_Daily_Team_Risk_Trends (Restored)
-- ==============================================================================
CREATE OR ALTER VIEW vw_Daily_Team_Risk_Trends AS
SELECT 
    f.Date,
    COUNT(DISTINCT f.PlayerID) as Total_Active_Players,
    SUM(CASE WHEN f.ACWR > 1.5 THEN 1 ELSE 0 END) as Players_In_Danger_Zone,
    ROUND(AVG(f.ACWR), 2) as Average_League_ACWR,
    SUM(f.Injury_Flag) as Actual_Injuries_Simulated,
    MAX(f.Predicted_Injury_Prob) as Max_Injury_Probability
FROM Fact_DailyWorkload f
GROUP BY f.Date;
GO

-- ==============================================================================
-- VIEW 4: vw_Venue_Pressure_Index (Restored original columns + New Dashboard Metric)
-- ==============================================================================
CREATE OR ALTER VIEW vw_Venue_Pressure_Index AS
SELECT 
    m.venue,
    m.season, -- Restored to prevent missing column error
    COUNT(DISTINCT m.match_id) as Total_Matches_Hosted,
    SUM(b.runs_off_bat) as Total_Runs_Scored,
    SUM(b.extras) as Total_Extras, -- Restored to prevent missing column error
    COUNT(b.ball) as Total_Deliveries_Bowled,
    
    -- NEW calculated metric for the Venue Bar Chart:
    (COUNT(b.ball) * 1.5 + SUM(b.runs_off_bat) * 0.5) / NULLIF(COUNT(DISTINCT m.match_id), 0) AS Average_Exertion
FROM Fact_BallByBall b
JOIN Dim_Match m ON b.match_id = m.match_id
GROUP BY m.venue, m.season;
GO

-- ==============================================================================
-- VIEW 5: vw_Bowler_Workload_Tracking (Restored)
-- ==============================================================================
CREATE OR ALTER VIEW vw_Bowler_Workload_Tracking AS
WITH ActiveBowlers AS (
    SELECT DISTINCT m.start_date, b.bowler_id
    FROM Fact_BallByBall b JOIN Dim_Match m ON b.match_id = m.match_id
)
SELECT 
    f.Date,
    p.PlayerName,
    f.Daily_Load_Score as Bowling_Exertion_Score,
    f.ACWR,
    f.Predicted_Injury_Prob,
    SUM(f.Daily_Load_Score) OVER (PARTITION BY p.PlayerID ORDER BY f.Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as Acute_7Day_Load
FROM Fact_DailyWorkload f
JOIN Dim_Player p ON f.PlayerID = p.PlayerID
JOIN ActiveBowlers ab ON f.PlayerID = ab.bowler_id AND f.Date = ab.start_date;
GO