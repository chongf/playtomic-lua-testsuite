local playtomic = require("playtomic")
local playtomicTestSuite = require("playtomic-tests")
local button = require("button")

playtomic.makeDefault()
analytics.init(5751,"5a80457160d84193","6f1474a2afce4583a612c2c8c1c8ce")


-- attach events to buttons

-- BASIC
button.createButton("Basic: CustomMetric",40,150,250,20,playtomicTestSuite.CustomMetric)
button.createButton("Basic: LevelCounterMetric",40,180,250,20,playtomicTestSuite.LevelCounterMetric)
button.createButton("Basic: LevelAverageMetric",40,210,250,20,playtomicTestSuite.LevelAverageMetric)
button.createButton("Basic: LevelRangedMetric",40,240,250,20,playtomicTestSuite.LevelRangedMetric)
button.createButton("Basic: HeatMap",40,270,250,20,playtomicTestSuite.HeatMap)

-- ADVANCED
	-- DATA METRIC ( NOTE: you need to enable Data API in the Playtomic Dashboard. Settings-> Game Details -> Data API)
	button.createButton("Data API: CustomMetric",40,300,250,20,playtomicTestSuite.DataMetricsLoadCustomMetric)
	button.createButton("Data API: LevelCounterMetric",40,330,250,20,playtomicTestSuite.DataMetricsLoadLevelCounterMetric)	
	-- more to come
		
	-- GAMEVARS
	button.createButton("Load Game Vars",40,30,250,20,playtomicTestSuite.LoadGameVars)

	-- LEVEL SHARING
	button.createButton("Save Player Level",40,120,250,20,playtomicTestSuite.SavePlayerLevel)
	
	-- LEADERBOARDS
	button.createButton("Submit Scores (Simple)",40,60,250,20,playtomicTestSuite.SubmitScoreSimple)
	button.createButton("Submit Scores (Advanced)",40,90,250,20,playtomicTestSuite.SubmitScoreAdvanced)



-- tests
--playtomicTestSuite.LoadGameVars()
--playtomicTestSuite.SubmitScoreSimple()
--playtomicTestSuite.SubmitScoreAdvanced()
--playtomicTestSuite.ShowScores()
--playtomicTestSuite.SavePlayerLevel()