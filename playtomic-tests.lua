--[[
	This is a demonstration of a subset of what the full Playtomic API can do. 
	Feel free to dig into the playtomic.lua file to see for yourself.
	
	Note: We are using a conveniently made wrapper created by Angelo @Yobonja Games.
	This wrapper is activated using the makeDefault() call in main.lua, which overwrites CoronaSDK's analytics() function
	If you choose otherwise, don't call makeDefault.
	
]]--

local TEST = {}
		
	-- BASIC METRICS
	-- tried and tested in Blast Monkeys, a top iOS+Android Game -> https://market.android.com/details?id=com.yobonja.blastmonkeysfree&hl=en	
	-- tried and tested in Ghost vs Monsters sample. To see implementation -> https://github.com/chongf/Ghost-vs-Monsters-Playtomic

		-- CUSTOM METRICS
		TEST.CustomMetric = function()
			local eventData = {
				type = "custom",
				eventGroup = "MainMenu"
			}

			analytics.logEvent("SomeEventHappened",eventData);
			analytics.forceSend();		
		end
	
		-- HEATMAP
		TEST.HeatMap = function()
			local eventData = {
				type = "heatmap",
				mapName = "level1",
				x = math.random(100),
				y = math.random(100),
			}

			analytics.logEvent("deathposition",eventData); -- eg: we track positions where players get killed
			analytics.forceSend();	
		end
		
		-- LEVEL METRICS
			-- LEVEL COUNTER METRIC
			TEST.LevelCounterMetric = function()
				eventData = {
					type = "counter",
					levelName = "level1",

				}

				analytics.logEvent("Win",eventData); -- eg: we log wins on level1
				analytics.forceSend();		
			end

			-- LEVEL AVERAGE METRIC
			TEST.LevelAverageMetric = function()
				eventData = {
					type = "average",
					levelName = "level1",
					value = math.random(10000) + 1000, -- randomized for fun

				}

				analytics.logEvent("AverageTime",eventData); -- eg: we track average time to complete level1
				analytics.forceSend();	
			end

			-- LEVEL RANGED METRIC
			TEST.LevelRangedMetric = function()
				eventData = {
					type = "ranged",
					levelName = "level1",
					value = math.random(100), -- randomized for fun

				}

				analytics.logEvent("CoinsCollected",eventData); -- eg: we track coins collected in level1
				analytics.forceSend();	
			end

			-- GEO IP
			TEST.GeoIP = function()
				analytics.GeoIP.Lookup(TEST.GeoIP_Callback);
			end

			TEST.GeoIP_Callback = function(country,response)
				if response.Success then
					print("Player is from " .. country.Name .. " (" .. country.Code .. ")")
				else
					print("Error calling GeoIP")
				end
			end

			-- LINK TRACKING
				-- Playtomic opens the link for you
				TEST.LinkTrackingOpen = function()
					analytics.Link.Open("http://google.com/", "Website", "MyLinks");
				end

				-- You open the link yourself
				TEST.LinkTrackingTrack = function()
					analytics.Link.Open("http://google.com/", "Website", "MyLinks");
				end
				
											
	-- DATA METRICS	( NOTE: you need to enable Data API in the Playtomic Dashboard. Settings-> Game Details -> Data API)
		-- LOAD VIEWS
		TEST.DataMetricsLoadViews = function()
			-- trivial, hence delayed
		end

		-- LOAD PLAYS
		TEST.DataMetricsLoadPlays = function()
			-- trivial, hence delayed	
		end

		-- LOAD VIEWS
		TEST.DataMetricsLoadPlayTime = function()
			-- trivial, hence delayed	
		end

		-- LOAD CUSTOM METRIC. This loads all the metrics from Playtomic's servers to your app/game
		TEST.DataMetricsLoadCustomMetric = function()
			-- eg: we're loading the custom metrics as shown TEST.CustomMetric
			analytics.Data.CustomMetric("SomeEventHappened",TEST.DataMetricsLoadCustomMetric_Callback)
		end
			-- CALLBACK FOR LOAD CUSTOM METRIC
			TEST.DataMetricsLoadCustomMetric_Callback = function(data,response)
				if response.Success then
					print(data.Name .. " has value of " .. data.Value)
				else
					print("Error loading Custom Metric")
				end
			end

		-- LOAD LEVEL COUNTER METRIC
		TEST.DataMetricsLoadLevelCounterMetric = function()
			analytics.Data.LevelCounterMetric("Win",TEST.DataMetricsLoadCounterMetric_Callback)
		end
			-- CALLBACK FOR LOAD COUNTER METRIC
			TEST.DataMetricsLoadCounterMetric_Callback = function(data,response)
				if response.Success then
					print(data.Name .. " has value of " .. data.Value .. " on level " .. data.Level)
				else
					print("Error loading Level Counter Metric")
				end
			end
				
		-- LOAD LEVEL AVERAGE METRIC
		TEST.DataMetricsLoadLevelAverageMetric = function()
			-- same process for the above
		end

		-- LOAD LEVEL RANGED METRIC
		TEST.DataMetricsLoadLevelRangedMetric = function()
			-- same process for the above
		end
							
	--[[ GAME VARS		
		to set this up, you need to add a GameVar in your Playtomic dashboard (under Settings->Gamevars)
		in our case, we added 5 different variables, called Variable1, Variable2, Variable3, Variable4, ArbitraryVariableName and assigned them different values
		the LoadGameVars function attempts to retrieve that value from Playtomic's database, and insert it into the CoronaSDK game
	]]--
	TEST.LoadGameVars = function()
		analytics.GameVars.Load(TEST.GameVarsLoaded)
	end
	
	TEST.GameVarsLoaded = function(vars,response)
		    if (response.Success) then
				-- print all GameVars
				print("Variable1: " .. vars.Variable1)
				print("Variable2: " .. vars.Variable2)
				print("Variable3: " .. vars.Variable3)
				print("Variable4: " .. vars.Variable4)
				print("ArbitraryVariableName: " .. vars.ArbitraryVariableName)				
		    else	    
		        print('error loading GameVars')
		    end
	end
	
	-- LEVEL SHARING
	TEST.SavePlayerLevel = function()
	 	local level = {};

		--[[ 
		level.Name must be a different level name each time, or else it defeats the purpose of players sharing newly created levels.
		Here we just concatenate some random digits behind the level name, in the spirit of randomizing
		If a same level name is submitted twice --> Error Code 406
		]]--		
	    level.Name = "some_level_" .. math.random(100,100000); 
	
	
		level.PlayerName="playerName";	
		level.PlayerSource="coronaSDK";	-- anything that refers to Corona
		level.PlayerId="playerId";			
	    level.Data = "some_level_string"; -- the entire level data (max 3 mb)

		analytics.PlayerLevels.Save(level,TEST.SaveComplete);		
	end

	TEST.SaveComplete = function(level, response)
	    -- do something
		print('completed')
	end
	
	-- LEADERBOARDS
	TEST.SubmitScoreSimple = function()
	    local simple_score = {};
	    simple_score.Name = "playerName"; -- name of player submitting the score
	    simple_score.Points = 200000;

	    --submit to the highest-is-best table "highscores"
	    analytics.Leaderboards.Save(simple_score, "highscores"); 

	    --submit to the lowest-is-best table "besttimes"
	    --analytics.Leaderboards.Save(simple_score, "besttimes", null, {highest: false}); 
	end

	TEST.SubmitScoreAdvanced = function()		    
	    local advanced_score = {};
	    advanced_score.Name = "playerName"; -- name of player submitting the score
	    advanced_score.Points = 100000;

		-- define the required tables
	    advanced_score.CustomData = {}
	
		-- add data
	    advanced_score.CustomData.Character = "Character"; -- eg: Warrior/Mage, etc
	    advanced_score.CustomData.Level = "Some-Level-Data";

	    analytics.Leaderboards.Save(advanced_score, "highscores", TEST.SubmitComplete);
	end

	TEST.SubmitComplete = function(response)
	    -- do something based on response
	end

	TEST.ShowScores = function()
	    analytics.Leaderboards.List("highscores", TEST.ListComplete);
	end

	TEST.ListComplete = function(scores, numscores, response)
	    if(response.Success) then
	        debug(scores.length .. " scores returned out of " .. numscores);
		
			for i = 1, scores.length do
	            local score = scores[i];
	            debug(" - " .. score.Name .. " got " .. score.Points .. " on " .. score.SDate);
            
	            -- including custom data?  score.CustomPlaytomic.Data.Property
	        end
	    else
	        -- score listing failed because of response.ErrorCode
	    end
	end

return TEST