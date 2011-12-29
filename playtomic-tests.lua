--[[
	This is a demonstration of a subset of what the full Playtomic API can do. 
	Feel free to dig into the playtomic.lua file to see for yourself.
	
	Note: We are using a conveniently made wrapper created by Angelo @Yobonja Games.
	This was done using the makeDefault() call in main.lua, which overwrites CoronaSDK's analytics() function
	If you choose otherwise, don't call makeDefault.
	
]]--

local TEST = {}
	
	-- CUSTOM METRICS, LEVEL METRICS, AND HEATMAPS
	-- tried and tested in Ghost vs Monsters sample
	
	-- DATA METRICS
	
	
	--[[ GAME VARS		
		to set this up, you need to add a GameVar in your Playtomic dashboard
		in our case, we added a GameVar called "CloudSpeed", and set it to an arbitrary integer, 2.
		the LoadGameVars function attempts to retrieve that value from Playtomic's database, and insert it into the CoronaSDK game
	]]--
	TEST.LoadGameVars = function()
		analytics.GameVars.Load(TEST.GameVarsLoaded)
	end
	
	TEST.GameVarsLoaded = function(vars,response)
		    if (response.Success) then	    
				-- print all GameVars
				for k,v in vars do
					print (k,v)
				end
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