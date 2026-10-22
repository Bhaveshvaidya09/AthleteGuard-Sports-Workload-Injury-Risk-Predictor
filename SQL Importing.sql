-- 1. Create the Database
CREATE DATABASE AthleteGuard_IPL;
GO

USE AthleteGuard_IPL;
GO



-- Drop child tables first to remove foreign key dependencies
DROP TABLE IF EXISTS Fact_DailyWorkload;
DROP TABLE IF EXISTS Fact_BallByBall;

-- Drop parent dimension tables
DROP TABLE IF EXISTS Dim_Match;
DROP TABLE IF EXISTS Dim_Team;
DROP TABLE IF EXISTS Dim_Player;


