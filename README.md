# 🏏 AthleteGuard: Sports Workload & Injury Risk Predictor
![AthleteGuard Dashboard](dashboard%20ss.png)

**Domain**: Sports Analytics / Medical Intelligence  
**Tech Stack**: Python (Pandas/NumPy), Microsoft SQL Server (T-SQL), Power BI, DAX  

## 📌 The Business Problem
In the high-stakes environment of the Indian Premier League (IPL), player availability is directly correlated with franchise success and return on investment. The grueling two-month tournament compresses high-intensity T20 matches, extensive travel schedules, and demanding net sessions into a short window. Soft-tissue injuries represent the highest cause of match unavailability for elite athletes. Historically, medical teams have relied on subjective feedback and reactive treatment, costing franchises millions of dollars in lost player value when injuries inevitably occur.

## 💡 The AthleteGuard Solution
AthleteGuard was engineered to shift medical strategy from reactive treatment to **proactive risk management**. By modeling historical ball-by-ball match data and tracking the **Acute-to-Chronic Workload Ratio (ACWR)**, this end-to-end analytical Command Center provides the Head Coach and Physiotherapy team with daily, actionable intelligence to predict and prevent injuries before clinical symptoms appear. 

---

## 🛠️ Phase 1: Python (Data Cleaning & Preparation)
The foundation of the project required processing massive amounts of raw, unformatted IPL data to create a reliable foundation for the database.
* **Libraries Used**: `pandas`, `numpy`
* **Execution**: 
  * Ingested historical ball-by-ball and match metadata CSV files spanning 15 years of IPL history.
  * Standardized player IDs, handled missing/null values in runs and extras, and aggregated raw delivery data into daily workload metrics.
  * Exported the cleaned datasets into structured outputs (`Fact_DailyWorkload`, `Dim_Player`, `Dim_Match`, `Fact_BallByBall`) ready for database insertion.

## 🗄️ Phase 2: SQL Server (Database Architecture & ETL)
To ensure the Power BI dashboard remained highly responsive without front-end lag, all heavy transformations and aggregations were pushed upstream to a Microsoft SQL Server database (`AthleteGuard_IPL`).
* **Advanced T-SQL & Window Functions**: Engineered rolling 7-day (Acute Load) and 28-day (Chronic Load) fitness baseline calculations using complex `OVER (PARTITION BY ... ROWS BETWEEN ...)` window functions.
* **Custom Views Created**:
  1. `vw_Medical_Risk_Alerts`: The primary fact table calculating ACWR, assigning "Risk Zones" (Danger, Warning, Safe), and generating explicit medical actions (e.g., "REST / OMIT").
  2. `vw_Venue_Pressure_Index`: Aggregates runs and deliveries to quantify the physical toll of specific away stadiums.
  3. `vw_Player_Performance_vs_Fatigue`: Joins match performance with daily fatigue scoring.
  4. `vw_Bowler_Workload_Tracking`: Isolates active bowlers for targeted strain analysis.
  5. `vw_Daily_Team_Risk_Trends`: Tracks squad-wide health fluctuations over the tournament lifecycle.

## 📊 Phase 3: Power BI (Visualization & UI/UX)
The front-end deliverable is an executive-level 'Dark Mode' Command Center designed for rapid morning triage by the coaching staff.
* **UI/UX Design**: Utilized a "Glass UI" aesthetic with 0% background opacity on charts, layered over a dark navy wallpaper with a custom IPL logo watermark anchored to the bottom z-order.
* **Executive Control Panel**: Implemented a 3-part interactive filtering system featuring a Tournament Year Dropdown, a Player Search dropdown, and a custom "Risk Zone" tile slicer for instant triage.
* **Custom DAX KPIs**: Created dynamic measures for 6 top-level cards including *Medical Action*, *Predicted Injury Alerts*, *Squad Fitness Rate*, and *Maximum Player Strain*.
* **Data Storytelling**: Replaced standard chart titles with direct, analytical questions to guide executive decision-making:
  * *What is the current health status of the squad?* (Donut Chart)
  * *Are immediate workloads dangerously exceeding base fitness?* (Trend Line)
  * *Which players are at the highest risk for soft-tissue injuries?* (Danger Matrix Scatter Plot)
  * *Which away stadiums demand the most physical exertion?* (Venue Bar Chart)
  * *Who requires immediate medical intervention before training?* (Conditional Formatting Triage Matrix)

## 📑 Phase 4: Documentation & Handover
To ensure the project delivered actual business value, a complete professional handover package was authored and included in the repository.
1. **Executive Summary & Insights Report**: Translates the data into actionable business recommendations for non-technical stakeholders (Head Coaches, Directors), detailing the 1.5 ACWR danger threshold and peak fatigue windows.
2. **Technical Documentation (Data Dictionary)**: Maps the system architecture, ETL pipeline, SQL schemas, and DAX logic for future data engineering teams.
3. **End-User Guide (SOP)**: A visual, step-by-step Standard Operating Procedure teaching the medical staff how to incorporate the dashboard into their daily 08:00 AM triage briefings.

---

## 📁 Repository Structure
* `/SQL_Scripts`: Contains the `01_AthleteGuard_Views.sql` script with all upstream transformations.
* `/Dashboard`: The `AthleteGuard.pbix` file and UI screenshots.
* `/Documentation`: The comprehensive Handover PDFs (Executive Summary, Technical Docs, SOP).
* `/Data`: Samples of the cleaned baseline CSV files generated by Python.
