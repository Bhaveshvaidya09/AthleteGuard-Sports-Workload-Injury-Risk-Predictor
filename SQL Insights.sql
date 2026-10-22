USE AthleteGuard_IPL;
GO

PRINT '======================================================================';
PRINT 'ATHLETEGUARD 2.0 - EXECUTIVE BUSINESS INSIGHTS & AD-HOC ANALYSIS';
PRINT '======================================================================';

-- ==============================================================================
-- INSIGHT 1: THE "REST OR RISK" DILEMMA (PLAYER ROTATION)
-- Business Question: Which of our top-performing players are currently in the 
-- red zone (ACWR > 1.5) and need to be rested immediately to prevent injury?
-- ==============================================================================
SELECT TOP 10
    PlayerName,
    Match_Runs_Scored,
    Match_Balls_Bowled,
    ACWR,
    CASE 
        WHEN ACWR > 2.0 THEN 'URGENT: Rest Immediately'
        WHEN ACWR > 1.5 THEN 'WARNING: Sub/Rotate Next Match'
        ELSE 'Cleared to Play'
    END AS Medical_Recommendation
FROM vw_Player_Performance_vs_Fatigue
WHERE ACWR > 1.5 
  AND (Match_Runs_Scored > 30 OR Match_Balls_Bowled > 12)
ORDER BY ACWR DESC;

-- ==============================================================================
-- INSIGHT 2: HIGH-RISK FAST BOWLER IDENTIFICATION
-- Business Question: Which bowlers have accumulated the most extreme fatigue over 
-- a rolling 7-day period, making them highly susceptible to stress fractures?
-- ==============================================================================
SELECT TOP 10
    Date,
    PlayerName,
    Bowling_Exertion_Score,
    Acute_7Day_Load,
    Predicted_Injury_Prob,
    'Extreme Bowler Fatigue' AS Alert_Status
FROM vw_Bowler_Workload_Tracking
WHERE Predicted_Injury_Prob > 0.6
ORDER BY Acute_7Day_Load DESC;

-- ==============================================================================
-- INSIGHT 3: VENUE ROTATION STRATEGY (ENVIRONMENTAL LOAD)
-- Business Question: Which stadiums are the most physically exhausting for 
-- players based on the average number of deliveries bowled per match?
-- ==============================================================================
SELECT TOP 5
    venue,
    Total_Matches_Hosted,
    Total_Deliveries_Bowled,
    (Total_Deliveries_Bowled / Total_Matches_Hosted) AS Avg_Deliveries_Per_Match
FROM vw_Venue_Pressure_Index
WHERE Total_Matches_Hosted > 5
ORDER BY Avg_Deliveries_Per_Match DESC;

-- ==============================================================================
-- INSIGHT 4: LEAGUE-WIDE HEALTH BAROMETER
-- Business Question: Historically, which days in the tournament had the highest 
-- number of players simultaneously pushed into the injury danger zone?
-- ==============================================================================
SELECT TOP 10
    Date,
    Total_Active_Players,
    Players_In_Danger_Zone,
    Average_League_ACWR,
    Max_Injury_Probability,
    ROUND((CAST(Players_In_Danger_Zone AS FLOAT) / Total_Active_Players) * 100, 2) AS Pct_Players_In_Danger
FROM vw_Daily_Team_Risk_Trends
WHERE Total_Active_Players > 0
ORDER BY Players_In_Danger_Zone DESC;

-- ==============================================================================
-- INSIGHT 5: THE "OVER-BOWLED" MATCH SCENARIO
-- Business Question: Have any bowlers been forced to bowl a full quota (24 balls) 
-- in a single match while already carrying a highly dangerous workload?
-- ==============================================================================
SELECT 
    Date,
    PlayerName,
    Match_Balls_Bowled,
    Daily_Load_Score,
    ACWR
FROM vw_Player_Performance_vs_Fatigue
WHERE Match_Balls_Bowled >= 24 
  AND ACWR > 1.8
ORDER BY Date DESC;

-- ==============================================================================
-- INSIGHT 6: THE "CARRYING THE TEAM" RISK FOR BATTERS
-- Business Question: Which batters are scoring heavily and carrying their team's 
-- offense, but are currently sitting at a dangerous workload level?
-- ==============================================================================
SELECT TOP 10
    Date,
    PlayerName,
    Match_Runs_Scored,
    ACWR,
    Injury_Flag,
    'High Value Batter at Risk' AS Alert_Type
FROM vw_Player_Performance_vs_Fatigue
WHERE Match_Runs_Scored >= 50 
  AND ACWR >= 1.4
ORDER BY Match_Runs_Scored DESC;

-- ==============================================================================
-- INSIGHT 7: SUDDEN LOAD SPIKES (ACUTE EXERTION ALERT)
-- Business Question: Which players experienced the most drastic and sudden 
-- physiological spikes in their workload over a short 3-day rolling period?
-- ==============================================================================
SELECT TOP 10
    Date,
    PlayerName,
    Daily_Load_Score,
    Rolling_3Day_Load,
    ACWR,
    Daily_Risk_Rank
FROM vw_Medical_Risk_Alerts
ORDER BY Rolling_3Day_Load DESC;

-- ==============================================================================
-- INSIGHT 8: VENUE EXTRAS PRESSURE (BOWLING DISCIPLINE)
-- Business Question: Which venues induce the most bowling fatigue strictly through 
-- extra deliveries (wides/no-balls), forcing bowlers to bowl more than necessary?
-- ==============================================================================
SELECT TOP 5
    venue,
    Total_Matches_Hosted,
    Total_Extras,
    (Total_Extras / Total_Matches_Hosted) AS Avg_Extras_Per_Match,
    'High Extras - Bowler Drain' AS Venue_Characteristic
FROM vw_Venue_Pressure_Index
WHERE Total_Matches_Hosted > 5
ORDER BY Avg_Extras_Per_Match DESC;

-- ==============================================================================
-- INSIGHT 9: PLAYING THROUGH THE PAIN
-- Business Question: Are there instances where a player's workload triggered a 
-- simulated injury event, but they continued to bat or bowl heavily that day?
-- ==============================================================================
SELECT 
    Date,
    PlayerName,
    Match_Runs_Scored,
    Match_Balls_Bowled,
    ACWR,
    Injury_Flag
FROM vw_Player_Performance_vs_Fatigue
WHERE Injury_Flag = 1 
  AND (Match_Runs_Scored > 20 OR Match_Balls_Bowled > 12)
ORDER BY ACWR DESC;

-- ==============================================================================
-- INSIGHT 10: TOURNAMENT FATIGUE BASELINE
-- Business Question: What is the overall baseline average ACWR across the entire 
-- dataset, and what is the maximum injury probability ever reached?
-- ==============================================================================
SELECT 
    ROUND(AVG(Average_League_ACWR), 3) AS Global_Baseline_ACWR,
    MAX(Max_Injury_Probability) AS Absolute_Max_Injury_Prob,
    SUM(Actual_Injuries_Simulated) AS Total_Injuries_Flagged,
    MAX(Players_In_Danger_Zone) AS Max_Players_In_Danger_On_Single_Day
FROM vw_Daily_Team_Risk_Trends;

GO