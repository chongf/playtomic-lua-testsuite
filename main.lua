local playtomic = require("playtomic")
local playtomicTestSuite = require("playtomic-tests")
local button = require("button")

playtomic.makeDefault()
analytics.init(5751,"5a80457160d84193","6f1474a2afce4583a612c2c8c1c8ce")


-- attach events to buttons
button.createButton("Load Game Vars",40,50,250,50,playtomicTestSuite.LoadGameVars)
button.createButton("Submit Scores (Simple)",40,120,250,50,playtomicTestSuite.SubmitScoreSimple)
button.createButton("Submit Scores (Advanced)",40,190,250,50,playtomicTestSuite.SubmitScoreAdvanced)
button.createButton("Save Player Level",40,260,250,50,playtomicTestSuite.SavePlayerLevel)


-- tests
--playtomicTestSuite.LoadGameVars()
--playtomicTestSuite.SubmitScoreSimple()
--playtomicTestSuite.SubmitScoreAdvanced()
--playtomicTestSuite.ShowScores()
--playtomicTestSuite.SavePlayerLevel()