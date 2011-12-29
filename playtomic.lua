--[[
//  This file is part of the official Playtomic API for Lua games.  
//  Playtomic is a real time analytics platform for casual games 
//  and services that go in casual games.  If you haven't used it 
//  before check it out:
//  http://playtomic.com/
//
//  Created by ben at the above domain on 2/25/11.
//  Copyright 2011 Playtomic LLC. All rights reserved.
//
//  Documentation is available at:
//  http://playtomic.com/api/lua
//
// PLEASE NOTE:
// You may modify this SDK if you wish but be kind to our servers.  Be
// careful about modifying the analytics stuff as it may give you 
// borked reports.
//
// If you make any awesome improvements feel free to let us know!
//
// -------------------------------------------------------------------------
// THIS SOFTWARE IS PROVIDED BY PLAYTOMIC, LLC "AS IS" AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

--[[ Port to Lua for Corona SDK by Angelo @ Yobonja, v1.0 ]]--

--[[ Include ]]--
local CoronaEnvironment = _G --used only in makeDefault()
local _json = require "json"
local crypto = require "crypto"
local mime = require "mime"
local math = math
local string = string
local print = print
local tonumber = tonumber
local tostring = tostring
local setmetatable = setmetatable
local system = system
local io = io
local os = os
local pairs = pairs
local table = table
local network = network

--[[ Setup the invoke tables ]]--
local I, nI = {}, {}

--[[ change some of the json behavior so it returns nil instead of throwing a runtime error when it gets invalid input. ]]--
local function json_decode( result )
	result[1] = _json.decode( result[1] )
end
local json = {
	encode = _json.encode,
	decode = function( input )
		local result = { input }
		if pcall(json_decode, result) then
			return result[1]
		end
	end
}

--[[ Some JavaScript functions ~ this is for convenience since this is a port of the Lua API. ]]--
local Encode = {		
	Base64 = mime.b64,
	MD5 = function(str) return crypto.digest(crypto.md5, str ) end,	
}

local function conditional( A, B, C )
	if A then return B else return C end
end

local function escape (s)
      if s == nil then return "" end
      return (string.gsub(tostring(s), [[([% %!%#%$%%%^%&%(%)%=%:%;%"%'%\%?%<%>%~%[%]%{%}%`%,])]], function (c) return string.format("%%%02X", string.byte(c)) end))
end

local function unescape (s)
      s = string.gsub(s, "%%(%x%x)", function (h)
            return string.char(tonumber(h, 16))
          end)
      return s
end

local function join( object, string )
	return table.concat( object, string )
end

local function push( object, string )
	table.insert( object, string )
end

local invoke = function( func, time, repeating )
	nI[#nI+1] = {func=func, time=time or 1000, elapsed=0, repeating=repeating or false}
end

local function setTimeout(func, time)
	invoke( func, time, false )
end

local function setInterval(func, time)
	invoke( func, time, true )
end

local tP = system.getTimer()
Runtime:addEventListener( "enterFrame",  function ( event )
	local rI = {}
	local dt = event.time - tP
	tP = event.time
	
	if #nI > 0 then
		for i = #nI,1,-1 do
			I[#I+1] = nI[i]
			nI[i] = nil
		end
		nI = {}
	end
	
	for i = 1, #I do
		local o = I[i] 
		if o ~= nil then
			o.elapsed = o.elapsed + dt
			if o.elapsed >= o.time then
				o.func()
				if o.repeating then
					o.elapsed = 0
					rI[#rI+1] = o
				end 
			else
				rI[#rI+1] = o
			end
		end
	end
	I = rI
end )

--[[ Shortcut for a common operation ]]--
local function yn( y )
	if y ~= false and y ~= nil then 
		return "y"
	else return "n" end
end

local Playtomic = {};
Playtomic.__index = Playtomic
setfenv(1, Playtomic)
	local Temp = {};
	local SWFID = 0;
	local GUID = "";
	local Enabled = true;
	local SourceUrl = "";
	local BaseUrl = "";
	local APIUrl = "";
	local APIKey = "";
	local Pings = 0;
	local FailCount = 0;
	local URLStub = "";
	local URLTail = "";
	local SECTIONS = {};
	local ACTIONS = {};
	local Cookies = {};
	local DEBUG = true;
	local function debug (...) if DEBUG then print("Playtomic: ",...) end end

--[[ Logging ]]--	
		local Request = false
		local Plays = 0
		local Pings = 0
		local FirstPing = true
		local Frozen = false
		local FrozenQueue = {}
		local Customs = {}
		local LevelCounters = {}
		local LevelAverages = {}
		local LevelRangeds = {}

		local function LogRequest()
			local this = {}
			this.Data = {};
			this.Ready = false;
	
			this.Queue = function(data)
				push(this.Data, data);

				if(#this.Data > 8) then
					this.Ready = true;
				end
			end

			this.Send = function()
				local url = URLStub .. "tracker/q.aspx?swfid=" .. SWFID .. "&q=" ..  join(this.Data, "~") .. "&url=" .. SourceUrl .. "&" .. math.random() .. "z"
				network.request(url, "GET")
				debug( "Send:",  url )
			end
		
			this.MassQueue = function(frozenqueue)
			
				if(#frozenqueue == 0)then
					Log.Request = this;
					return;
				end
				
				for i=#frozenqueue-1,0,-1 do
					this.Queue(frozenqueue[i]);
					frozenqueue.splice(i, 1);
					
					if(this.Ready)then
						this.Send();
						local request = LogRequest();
						request.MassQueue(frozenqueue);
						return;
					end
				end
			end
			return this
		end

		
		--[[
		 * Adds an event and if ready or a view or not queuing, sends it
		 * @param	s	The event as an ev/xx string
		 * @param	view	If it's a view or not
		 ]]	
		local function Send(data, forcesend)		
			if Frozen then
				push(FrozenQueue,data);
				return false
			end
			
			if not Request then
				Request = LogRequest();
			end

			Request.Queue(data);
			
			if Request.Ready or forcesend then
				Request.Send();
				Request = LogRequest();
			end
		end
		
		--[[
		 * Increases the play time and triggers events being sent
		 ]]
		local Ping
		Ping = function ()
			if not Enabled then
				return false
			end
				
			Pings = Pings + 1;

			if FirstPing then
				Send("t/y/" .. Pings, true);
			else
				Send("t/n/" .. Pings, true);
			end
				
			if FirstPing then
				setInterval(Ping, 30000);
				FirstPing = false;
			end
		end

		--[[
		 * Cleans a piece of text of reserved characters
		 * @param	s	The string to be cleaned
		 ]]
		local function Clean(s)
			if s == nil then return ""; end
			s = string.gsub(tostring(s), [[([%/%~])]], function (c)
				if c == "~" then c = "-"
				elseif c == "/" then c = "\\" end
				return c
			end)

			return escape(s);		
		end		
		
		--[[
		 * Saves a cookie value
		 * @param	key		The key (views, plays)
		 * @param	value	The value
		 ]]
		local function SetCookie(key, value)
			Cookies[ key ] = value				
			local path = system.pathForFile( "playtomic.cookies", system.DocumentsDirectory  ) 
			local fileHandle = io.open( path, "w" ) 
			
			if fileHandle then 	
				fileHandle:write( json.encode( Cookies ) )
				io.close( fileHandle )
			end
		end

		local function LoadCookies()
			local path = system.pathForFile( "playtomic.cookies", system.DocumentsDirectory  )
			local fileHandle = io.open( path, "r" )

			if fileHandle then 
				Cookies = json.decode( fileHandle:read( "*a" ) ) 
				io.close( fileHandle )
			end 
		
			if not Cookies then 
				Cookies = {}
			end
		end

		--[[
		 * Gets a cookie value
		 * @param	key		The key (views, plays)
		 ]]
		local function GetCookie(key)
			return Cookies[ key ]
		end
				
		Log = { }
				
			--[[
			 * Logs a view and initializes the API.  You must do this first before anything else!
			 * @param	swfid		Your game id from the Playtomic dashboard
			 * @param	guid		Your game guid from the Playtomic dashboard
			 * @param	apikey		Your secret API key from the Playtomic dashboard
			 * @param	defaulturl	Should be root.loaderInfo.loaderURL or some other default url value to be used if we can't detect the page
			 ]]
		function Log.View(swfid, guid, apikey, defaulturl, debugMode)
				-- game credentials
				if SWFID > 0 then
					return
				end
	
				SWFID = swfid;
				GUID = guid;
				Enabled = true;
	
				if SWFID == 0 or not SWFID or not GUID then
					debug( "Error: SWFID or GUID missing." )
					Enabled = false;
					local Nothing = function () end
					local blockAccess = {}
					blockAccess.__index = function () return Nothing end
					blockAccess.__newindex = function ()  end
					setmetatable( Log, blockAccess )
					return
				end

				--DEBUG = ( debugMode == true )
				debug("View:",swfid, guid, apikey, defaulturl, debugMode);
						
				-- game & api urls
				SourceUrl = "ansca.corona.playtomic"
				BaseUrl = "ansca.corona.playtomic"

				URLStub = "http://g" .. GUID .. ".api.playtomic.com/";
				URLTail = "swfid=" .. SWFID .. "&js=y";	
				
				-- section & actions
				SECTIONS = {
					["gamevars"] = Encode.MD5("gamevars-" .. apikey),
					["geoip"] = Encode.MD5("geoip-" .. apikey),
					["leaderboards"] = Encode.MD5("leaderboards-" .. apikey),
					["playerlevels"] = Encode.MD5("playerlevels-" .. apikey),
					["data"] = Encode.MD5("data-" .. apikey),
					["parse"] = Encode.MD5("parse-" .. apikey),					
				}

				ACTIONS = {
					["gamevars-load"] = Encode.MD5("gamevars-load-" .. apikey),
					["geoip-lookup"] = Encode.MD5("geoip-lookup-" .. apikey),
					["leaderboards-list"] = Encode.MD5("leaderboards-list-" .. apikey),
					["leaderboards-listfb"] = Encode.MD5("leaderboards-listfb-" .. apikey),
					["leaderboards-save"] = Encode.MD5("leaderboards-save-" .. apikey),
					["leaderboards-savefb"] = Encode.MD5("leaderboards-savefb-" .. apikey),
					["leaderboards-saveandlist"] = Encode.MD5("leaderboards-saveandlist-" .. apikey),
					["leaderboards-saveandlistfb"] = Encode.MD5("leaderboards-saveandlistfb-" .. apikey),
					["leaderboards-createprivateleaderboard"] = Encode.MD5("leaderboards-createprivateleaderboard-" .. apikey),
					["leaderboards-loadprivateleaderboard"] = Encode.MD5("leaderboards-loadprivateleaderboard-" .. apikey),
					["playerlevels-save"] = Encode.MD5("playerlevels-save-" .. apikey),
					["playerlevels-load"] = Encode.MD5("playerlevels-load-" .. apikey),
					["playerlevels-list"] = Encode.MD5("playerlevels-list-" .. apikey),
					["playerlevels-rate"] = Encode.MD5("playerlevels-rate-" .. apikey),
					["data-views"] = Encode.MD5("data-views-" .. apikey),
					["data-plays"] = Encode.MD5("data-plays-" .. apikey),
					["data-playtime"] = Encode.MD5("data-playtime-" .. apikey),
					["data-custommetric"] = Encode.MD5("data-custommetric-" .. apikey),
					["data-levelcountermetric"] = Encode.MD5("data-levelcountermetric-" .. apikey),
					["data-levelrangedmetric"] = Encode.MD5("data-levelrangedmetric-" .. apikey),
					["data-levelaveragemetric"] = Encode.MD5("data-levelaveragemetric-" .. apikey),
					["parse-save"] = Encode.MD5("parse-save-" .. apikey),
					["parse-delete"] = Encode.MD5("parse-delete-" .. apikey),
					["parse-load"] = Encode.MD5("parse-load-" .. apikey),
					["parse-find"] = Encode.MD5("parse-find-" .. apikey),	
				}
				
				-- Log the view (first or repeat visitor)
				LoadCookies();
				local views = GetCookie("views") or 0;
				views = views + 1;
				SetCookie("views", views);
				Send("v/" .. views, true);
	
				-- Start the play timer
				setTimeout(Ping, 60000);
			
		end		
			--[[
			 * Logs a play.  Call this when the user begins an actual game (eg clicks play button)
			 ]]
		function Log.Play()
			debug("Play");	
			LevelCounters = {};
			LevelAverages = {};
			LevelRangeds = {};
			Plays = Plays + 1;
			Send("p/" .. Plays);
		end
				
			--[[
			 * Logs the link results, internal use only.  The correct use is Link.Open(...)
			 * @param	levelid		The player level id
			 ]]
		function Log.Link(name, group, url, unique, total, fail)
			debug("Link:",name, group, url, unique, total, fail)
			if not Enabled then
				return;
			end
				
			Send("l/" .. Clean(name) .. "/" .. Clean(group) .. "/" .. Clean(url) .. "/" .. unique .. "/" .. total .. "/" .. fail);
		end
			
			--[[
			 * Logs a custom metric which can be used to track how many times something happens in your game.
			 * @param	name		The metric name
			 * @param	group		Optional group used in reports
			 * @param	unique		Only count a metric one single time per view
			 ]]		
			function Log.CustomMetric(name, group, unique)
				debug("CustomMetric:",name, group, unique)
				if not Enabled then
					return;
				end
	
				if(group == nil or group == undefined)then
					group = "";
				end
				if unique then
					if Customs[name] ~= nil then
						return;
					end
	
					push(Customs,name);
				end
					
				Send("c/" .. Clean(name) .. "/" .. Clean(group));
			end
				
			--[[
			 * Logs a level counter metric which can be used to track how many times something occurs in levels in your game.
			 * @param	name		The metric name
			 * @param	level		The level number as an integer or name as a string
			 * @param	unique		Only count a metric one single time per play
			 ]]
			function Log.LevelCounterMetric(name, level, unique)
				debug("LevelCounterMetric:", name, level, unique)	
				if unique then		
					local key = name .. "." .. tostring(level);
					if LevelCounter[key] then return end
					LevelCounters[key] = 1;
				end
				Send("lc/" .. Clean(name) .. "/" .. Clean(level));
			end
	
			--[[
			 * Logs a level ranged metric which can be used to track how many times a certain value is achieved in levels in your game.
			 * @param	name		The metric name
			 * @param	level		The level number as an integer or name as a string
			 * @param	value		The value being tracked
			 * @param	unique		Only count a metric one single time per play
			 ]]
			function Log.LevelRangedMetric(name, level, value, unique)
				debug("LevelRangedMetric:",name, level, value, unique)
				if unique then
					local key = name .. "." .. tostring(level);
					if LevelRanged[key] then return end
					LevelRangeds[key] = 1;
				end
				Send("lr/" .. Clean(name) .. "/" .. Clean(level) .. "/" .. value);
			end
			
			--[[
			 * Logs a level average metric which can be used to track the min, max, average and total values for an event.
			 * @param	name		The metric name
			 * @param	level		The level number as an integer or name as a string
			 * @param	value		The value being added
			 * @param	unique		Only count a metric one single time per play
			 ]]
			function Log.LevelAverageMetric(name, level, value, unique)
				debug("LevelAverageMetric:",name, level, value, unique)	
				if unique then
					local key = name .. "." .. tostring(level);
					if Log.LevelAverages[key] then return end
					LevelAverages[key] = 1;
				end
				
				Send("la/" .. Clean(name) .. "/" .. Clean(level) .. "/" .. value);
			end
				
			--[[
			 * Logs a heatmap which allows you to visualize where some event occurs.
			 * @param	metric		The metric you are tracking (eg clicks)
			 * @param	heatmap		The heatmap (it has the screen attached in Playtomic dashboard)
			 * @param	x			The x coordinate
			 * @param	y			The y coordinate
			 ]]
			function Log.Heatmap(metric, heatmap, x, y)
				debug("Heatmap:",metric, heatmap, x, y)
				Send("h/" .. Clean(metric) .. "/" .. Clean(heatmap) .. "/" .. x .. "/" .. y);
			end
			
			--[[
			 * Not yet implemented :(
			 ]]
			function Log.Funnel(name, step, stepnum)
				Send("f/" .. Clean(name) .. "/" .. Clean(step) .. "/" .. num);
			end
			
			--[[
			 * Logs a start of a player level, internal use only.  The correct use is PlayerLevels.LogStart(...);
			 * @param	levelid		The player level id
			 ]]			
			function Log.PlayerLevelStart(levelid)	
				Send("pls/" .. levelid);
			end
			
			--[[
			 * Logs a win on a player level, internal use only.  The correct use is PlayerLevels.LogWin(...);
			 * @param	levelid		The player level id
			 ]]
			function Log.PlayerLevelWin(levelid)
				Send("plw/" .. levelid);
			end
	
			--[[
			 * Logs a quit on a player level, internal use only.  The correct use is PlayerLevels.LogQuit(...);
			 * @param	levelid		The player level id
			 ]]
			function Log.PlayerLevelQuit(levelid)
				Send("plq/" .. levelid);
			end
	
			--[[
			 * Logs a retry on a player level, internal use only.  The correct use is PlayerLevels.LogRetry(...);
			 * @param	levelid		The player level id
			 ]]
			function Log.PlayerLevelRetry(levelid)
				Send("plr/" .. levelid);
			end
			
			--[[
			 * Logs a flag on a player level, internal use only.  The correct use is PlayerLevels.Flag(...);
			 * @param	levelid		The player level id
			 ]]
			function Log.PlayerLevelFlag(levelid)
				Send("plf/" .. levelid);
			end
			
			--[[
			 * Forces the API to send any unsent data now
			 ]]
			function Log.ForceSend()				
				if(Request == nil)then
					Request = LogRequest();
				end
				Request.Send();
				Request = LogRequest();
			end
			
			--[[
			 * Freezes the API so analytics events are queued but not sent
			 ]]		
			function Log.Freeze()
				Frozen = true;
			end
			
			--[[ Unfreezes the API and sends any queued events ]]		
			function Log.UnFreeze()
				Frozen = false;
				if(#FrozenQueue > 0)then
					Request.MassQueue();
				end
			end
			
			function Log.isFrozen()
				return Frozen
			end
		--};
		
	--end 
--end

	--// Responses
	local ERRORS = {
		--// General Errors
		["0"] = "No error",
		["1"] = "General error, this typically means the player is unable to connect to the Playtomic servers",
		["2"] = "Invalid game credentials. Make sure you use your SWFID and GUID from the `API` section in the dashboard.",
		["3"] = "Request timed out.",
		["4"] = "Invalid request.",

		--// GeoIP Errors
		["100"] = "GeoIP API has been disabled. This may occur if your game is faulty or overwhelming the Playtomic servers.",

		----// Leaderboard Errors
		["200"] = "Leaderboard API has been disabled. This may occur if your game is faulty or overwhelming the Playtomic servers.",
		["201"] = "The source URL or name weren't provided when saving a score. Make sure the player specifies a name and the game is initialized before anything else using the code in the `Set your game up` section.",
		["202"] = "Invalid auth key. You should not see this normally, players might if they tamper with your game.",
		["203"] = "No Facebook user id on a score specified as a Facebook submission.",
		["204"] = "Table name wasn't specified for creating a private leaderboard.",
		["205"] = "Permalink structure wasn't specified = http://website.com/game/whatever?leaderboard=",
		["206"] = "Leaderboard id wasn't provided loading a private leaderboard.",
		["207"] = "Invalid leaderboard id was provided for a private leaderboard.",
		["208"] = "Player is banned from submitting scores in your game.",
		["209"] = "Score was not the player's best score.  You can notify the player, highlight their best score via score.SubmittedOrBest, or circumvent this by specifying 'allowduplicates' to be true in your save options.",

		--// GameVars Errors
		["300"] = "GameVars API has been disabled. This may occur if your game is faulty or overwhelming the Playtomic servers.",

		--// LevelSharing Errors
		["400"] = "Level sharing API has been disabled. This may occur if your game is faulty or overwhelming the Playtomic servers.",
		["401"] = "Invalid rating value (must be 1 - 10).",
		["402"] = "Player has already rated that level.",
		["403"] = "The level name wasn't provided when saving a level.",
		["404"] = "Invalid image auth. You should not see this normally, players might if they tamper with your game.",
		["405"] = "Invalid image auth (again). You should not see this normally, players might if they tamper with your game.",
		["406"] = "Cannot submit the same level name twice",
		
		--// Data API Errors
		["500"] = "Data API has been disabled. This may occur if the Data API is not enabled for your game, or your game is faulty or overwhelming the Playtomic servers.",

		--// Playtomic + Parse.com Errors
		["600"] = "You have not configured your Parse.com database.  Sign up at Parse and then enter your API credentials in your Playtomic dashboard.",
		["601"] = "No response was returned from Parse.  If you experience this a lot let us know exactly what you're doing so we can sort out a fix for it.",
		["6021"] = "Parse's servers had an error.",
		["602101"] = "Object not found.  Make sure you include the classname and objectid and that they are correct.",
		["602102"] = "Invalid query.  If you think you're doing it right let us know what you're doing and we'll look into it.",
		["602103"] = "Invalid classname.",
		["602104"] = "Missing objectid.",
		["602105"] = "Invalid key name.",
		["602106"] = "Invalid pointer (not used anymore).",
		["602107"] = "Invalid JSON.",
		["602108"] = "Command unavailable.",
	}

	local function Response(status, errorcode)
		debug("Status: " .. status .. ", Code: " .. errorcode .. ", Message: " .. ERRORS[tostring(errorcode)]);	
		
		return {
			Success = status == 1, 
			ErrorCode = errorcode, 
			ErrorMessage = ERRORS[tostring(errorcode)] 
		}
	end
	

	local function GenerateKey(name, key, arr)
		table.sort(arr);
		push(arr, name .. "=" .. Encode.MD5(join(arr,"&") .. key));
	end


	local function SendAPIRequest(section, action, complete, callback, postdata)
		local url = URLStub .. "v3/api.aspx?" .. URLTail .. "&debug=y&r=" .. math.random() .. "Z";
		local timestamp = tostring(os.time());
		local nonce = Encode.MD5( (os.time() * math.random()) .. GUID);
		
		local pd = {};
		push(pd,"nonce=" .. nonce);
		push(pd,"timestamp=" .. timestamp);
		
		if postdata ~= nil then
			for key, value in pairs(postdata) do
				push(pd, key .. "=" .. escape(postdata[key]));
			end
		end
		
		GenerateKey("section", section, pd);
		GenerateKey("action", action, pd);
		GenerateKey("signature", nonce .. timestamp .. section .. action .. url .. GUID, pd);

		local pda = "data=" .. escape(Encode.Base64(join(pd,"&")));
		
		--debug("url: " .. url);
		local requestListener = function( event )		
			if event.isError then
				complete(callback, postdata, {}, Response(0, 1));
			else
				local data = json.decode(event.response);
			
				if data then --[[ Note: this checks if the object was successfuly parsed. 
							The json module packaged with Corona just throws
							a runtime error when it gets invalid input. So this
							depends on the modification to json at the top of
							this file.]]
					complete(callback, postdata, data.Data, Response(data.Status, data.ErrorCode));
				else
					complete(callback, postdata, {}, Response(0, 1));
					debug( "Invalid json in response:", event.response ) -- do the same thing corona's json was doing, but only in debug mode, and don't throw an error.
				end
			end
		end

		local params = {
                	headers = {["Content-Type"] = "multipart/text"},
                	body = pda,
                }

		debug( url, params.body )
		network.request( url, "POST", requestListener,  params )
	end


--	// level sharing

		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]
		local function SaveComplete(callback, postdata, data, response)
			if callback == nil then
				return;
			end
			
			callback(data.LevelId, response);
		end
		
		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]
		local function LoadComplete(callback, postdata, data, response)
			if callback == nil then
				return;
			end

			callback(data, response);
		end	
		
		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]
		local function ListComplete(callback, postdata, data, response)
			if callback == nil then
				return;
			end

			callback(data.Levels, data.NumLevels, response);
		end
		
		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]
		local function RateComplete(callback, postdata, data, response)
			if callback == nil then
				return;
			end

			callback(response);
		end


		Playtomic.PlayerLevels = {
		
			POPULAR= "popular",
			NEWEST= "newest",
	
			--[[/**
			 * Saves a player level
			 * @param	level			The PlayerLevel to save
			 * @param	thumb			A movieclip or other displayobject (optional)
			 * @param	callback		Your function to receive the response:  function(level:PlayerLevel, response:Response)
			 */ ]]		
			Save = function(level, callback)
			
				local postdata = {};
				postdata.nothumb = true;
				postdata.playerid = level.PlayerId;
				postdata.playersource = level.PlayerSource;
				postdata.playername = level.PlayerName;
				postdata.name = level.Name;
				
				local c = 0;
				
				if level.CustomData then
				
					for key, _ in pairs(level.CustomData) do
					
						postdata["ckey" .. c] = key;
						postdata["cdata" .. c] = level.CustomData[key];
						c = c + 1;
					end
				end
		
				postdata.customfields = c;
				postdata.data = level.Data;
		
				SendAPIRequest(SECTIONS["playerlevels"], ACTIONS["playerlevels-save"], SaveComplete, callback, postdata);
			end,				
			
			--[[/**
			 * Loads a player level
			 * @param	levelid			The playerLevel.LevelId 
			 * @param	callback		Your function to receive the response:  function(response:Response)
			 */]]
			Load= function(levelid, callback)
							
				local postdata = {};
				postdata.levelid = levelid;
		
				SendAPIRequest(SECTIONS["playerlevels"], ACTIONS["playerlevels-load"], LoadComplete, callback, postdata);
			end,
	
			--[[/**
			 * Lists player levels
			 * @param	callback		Your function to receive the response:  function(response:Response)
			 * @param	options			The list options, see http://playtomic.com/api/as3#PlayerLevels
			 */]]
			List= function(callback, options)
			
				if(options == nil) then
					options = {};
				end
				
				local postdata = {};
		
				postdata.mode = options.mode or "popular";
				postdata.page = options.page or 1;
				postdata.perpage = options.perpage or 20;
				postdata.data = yn( postdata.data )

				postdata.thumbs = "n";
				postdata.datemin = options.datemin or "";
				postdata.datemax = options.datemax or "";
				
				local customfilters 
				if options.hasOwnProperty("customfilters") then
					customfilters = options["customfilters"]
				else
					customfilters = {}
				end
			
				local c = 0;
				
				for key, _ in pairs(customfilters) do
				
					postdata["ckey" .. c] = key;
					postdata["cdata" .. c] = level.CustomData[key];
					c = c + 1;
				end
				
				postdata.filters = c;
				
				SendAPIRequest(SECTIONS["playerlevels"], ACTIONS["playerlevels-list"], ListComplete, callback, postdata);
			end,
			
			--[[/**
			 * Rates a player level
			 * @param	levelid			The playerLevel.LevelId 
			 * @param	rating			Integer from 1 to 10
			 * @param	callback		Your function to receive the response:  function(response:Response)
			 */]]
			Rate= function(levelid, rating, callback)
			
				local postdata = {};
				postdata.levelid = levelid;
				postdata.rating = rating;
				
				SendAPIRequest(SECTIONS["playerlevels"], ACTIONS["playerlevels-rate"], RateComplete, callback, postdata);
			end,
	
			--[[/**
			 * Logs a start on a player level
			 * @param	levelid			The playerLevel.LevelId 
			 */]]
			LogStart = function(levelid)
				Playtomic.Log.PlayerLevelStart(levelid);
			end,
		
			--[[/**
			 * Logs a quit on a player level
			 * @param	levelid			The playerLevel.LevelId 
			 */]]	
			LogQuit = function(levelid)
				Playtomic.Log.PlayerLevelQuit(levelid);
			end,
		
			--[[/**
			 * Logs a win on a player level
			 * @param	levelid			The playerLevel.LevelId 
			 */]]
			LogWin = function(levelid)
				Playtomic.Log.PlayerLevelWin(levelid);
			end,
		
			--[[/**
			 * Logs a retry on a player level
			 * @param	levelid			The playerLevel.LevelId 
			 */]]
			LogRetry = function(levelid)
				Playtomic.Log.PlayerLevelRetry(levelid);
			end,
		
			--[[/**
			 * Flags a player level
			 * @param	levelid			The playerLevel.LevelId 
			 */]]	
			Flag = function(levelid)
				Playtomic.Log.PlayerLevelFlag(levelid);
			end,
		}
		
--[[ Leaderboards ]]--		


		
		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]
		local function ListComplete(callback, postdata, data, response) --// also used for saveandlist
			if callback == nil then
				return;
			end
			
			if response.Success == false then
				callback({}, 0, response);
				return
			end

			local scores = {};
			local arr = data.Scores;
			--[[
			for key,value in pairs(arr) do
				print(key,value)
			end
			]]--
			for i = 0, #arr do				
				local score = {};
				score.Name = unescape(arr[i].Name);
				--score.FBUserId = arr[i].FBUserId;
				score.Points = arr[i].Points;
				score.Website = arr[i].Website;
				score.SDate = arr[i].SDate;
				score.RDate = arr[i].RDate;
				score.Rank = arr[i].Rank;
				
				if arr[i]["SubmittedOrBest"] ~= nil then
					score.SubmittedOrBest = arr[i].SubmittedOrBest == "true";
				else
					score.SubmittedOrBest = false;
				end
				
				score.CustomData = {};
				
				for key,value in pairs(arr[i].CustomData) do
					score.CustomData[key] = unescape(arr[i].CustomData[key]);
				end
				scores[i] = score;
			end
	
			callback(scores, data.NumScores, response);
		end
		
		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]
		local function SaveComplete(callback, postdata, data, response)
			if callback == nil then
				return;
			end

			callback(response);
		end
		
		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]
		local function CreatePrivateLeaderboardComplete(callback, postdata, data, response) --// also used for loading
			if response.Success == false then
				callback({}, response);
				return
			end

			local leaderboard = { 
				TableId = data.TableId, 
				Name = data.Name, 
				Permalink = data.Permalink, 
				Bitly = data.Bitly,
				RealName = data.RealName,
			};
			
			callback(leaderboard, response);
		end
	




		Playtomic.Leaderboards = {
			TODAY = "today",
			LAST7DAYS = "last7days",
			LAST30DAYS = "last30days",
			ALLTIME = "alltime",
			NEWEST = "newest",
	
			--[[/**
			 * Lists scores from a table
			 * @param	table		The name of the leaderboard
			 * @param	callback	Callback function to receive the data:  function(scores:Array, numscores:int, response:Response)
			 * @param	options		The leaderboard options, check the documentation at http://playtomic.com/api/as3#Leaderboards
			 */]]		
			List = function(table, callback, options)
				if options == nil then
					options = {}
				end

				local highest, facebook
				if options.highest or options.highest == false then
					highest = options.highest 
				else highest = true end
				
				if options.facebook or options.facebook == false then
					facebook = options.facebook
				else facebook = false end
				
				local postdata = {};
				postdata.highest = yn(highest);
				postdata.facebook = yn(facebook);
				postdata.mode = options.mode or "alltime";
				postdata.page = options.page or 1;
				postdata.perpage = options.perpage or 20;
						
				local customfilters = options.customfilters or {};
				local numcustomfilters = 0;
		
				for key,value in pairs(customfilters)  do
					postdata["ckey" + numcustomfilters] = key;
					postdata["cdata" + numcustomfilters] = customfilters[key];
					numcustomfilters = numcustomfilters + 1;
				end
		
				local global = conditional( options.global or options.global == false, options.global, true )
				postdata.url = conditional( global, "global", SourceUrl );
				postdata.table = table;
				postdata.filters = numcustomfilters;
				
				local action = "leaderboards-list";
				
				if facebook then
					local friendslist = options.friendslist or {}
					
					if #friendslist > 0 then
						postdata.friendslist = join(friendslist,",");
					end
					
					action = action .. "fb";
				end
		
				SendAPIRequest(SECTIONS["leaderboards"], ACTIONS[action], ListComplete, callback, postdata);		
			end,
			
			--[[/**
			 * Saves a user's score
			 * @param	score		The player's score as a PlayerScore
			 * @param	table		The name of the leaderboard
			 * @param	callback	Callback function to receive the data:  function(score:PlayerScore, response:Response)
			 * @param	options		The leaderboard options, check the documentation at http://playtomic.com/api/as3#Leaderboards
			 */]]
			Save = function(score, table, callback, options)
				if options == nil then
					options = {}
				end

				local allowduplicates = conditional( options.allowduplicates or options.allowduplicates == false, options.allowduplicates, false)
				local highest = conditional(options.highest or options.highest == false, options.highest, true)
				
				local postdata = {};
				postdata.allowduplicates = yn(allowduplicates)
				postdata.highest = yn(highest)
				postdata.table = table;
				postdata.name = score.Name;
				postdata.points = tostring(score.Points)
				postdata.auth = Encode.MD5(SourceUrl .. postdata.points);
				postdata.url = SourceUrl;

				if score.FBUserId ~= nil and score.FBUserId ~= "" then
					postdata.fbuserid = score.FBUserId;
					postdata.fb = "y";
				else
					postdata.fbuserid = "";
					postdata.fb = "n";
				end
		
				local c = 0;
		
				if score.CustomData then
					for key,_ in pairs(score.CustomData) do
						postdata["ckey" .. c] = key;
						postdata["cdata" .. c] = score.CustomData[key];
						c = c + 1;
					end
				end
		
				postdata.customfields = c;
				
				SendAPIRequest(SECTIONS["leaderboards"], ACTIONS["leaderboards-save"], SaveComplete, callback, postdata);
			end,
			
			--[[/**
			 * Performs a save and a list in a single request that returns the player's score and page of scores it occured on
			 * @param	score		The player's score as a PlayerScore
			 * @param	table		The name of the leaderboard
			 * @param	callback	Callback function to receive the data:  function(scores:Array, numscores:int, response:Response)
			 * @param	options		The leaderboard options, check the documentation at http://playtomic.com/api/as3#Leaderboards
			 */]]
			SaveAndList = function(score, table, callback, saveoptions, listoptions)
				--// common data
				local postdata = {};
				postdata.table = table;
				
				--// save data
				local allowduplicates = conditional(saveoptions.allowduplicates or saveoptions.allowduplicates == false, saveoptions.allowduplicates, false)
				local highest = conditional(saveoptions.highest or saveoptions.highest == false, saveoptions.highest, true)
				local facebook = conditional(saveoptions.facebook or saveoptions.facebook == false, saveoptions.facebook, false)
				
				if saveoptions == nil then
					saveoptions = {}
				end
					
				postdata.allowduplicates = yn(allowduplicates)
				postdata.highest = yn(highest)
				postdata.facebook = yn(facebook)
				postdata.name = score.Name;
				postdata.points = tostring(score.Points)
				postdata.auth = Encode.MD5(SourceUrl .. postdata.points);
				postdata.url = SourceUrl;
		
				if score.FBUserId ~= nil and score.FBUserId ~= "" then
					postdata.fbuserid = score.FBUserId;
					postdata.fb = "y";
				else
					postdata.fbuserid = "";
					postdata.fb = "n";
				end
		
				local c = 0;
		
				if score.CustomData then
					for key,_ in pairs(score.CustomData) do
						postdata["ckey" .. c] = key;
						postdata["cdata" .. c] = score.CustomData[key];
						c = c + 1;
					end
				end
		
				postdata.numfields = c;
				
				--// list options
				if listoptions == nil then
					listoptions = {}
				end
				
				local global = conditional(listoptions.global or listoptions.global == false, listoptions.global, true)
				
				postdata.global = yn(global)
				postdata.mode = listoptions.mode or "alltime";
				postdata.perpage = listoptions.perpage or 20;
				
				local customfilters = listoptions.customfilters or {};
				local numcustomfilters = 0;

				if customfilters ~= nil then
					for key,_ in pairs(customfilters) do
						postdata["lkey" .. numcustomfilters] = key;
						postdata["ldata" .. numcustomfilters] = customfilters[key];
						numcustomfilters = numcustomfilters + 1;
					end
				end
				
				postdata.numfilters = numcustomfilters;
				
				--// extra wranging for facebook
				local action = "leaderboards-saveandlist";
				
				if facebook then
					local friendslist = options.friendslist or {};
					
					if #friendslist > 0 then
						postdata.friendslist = join(friendslist,",");
					end
					
					action = action .. "fb";
				end
				
				SendAPIRequest(SECTIONS["leaderboards"], ACTIONS[action], ListComplete, callback, postdata);
			end,
			
			--[[/**
			 * Creates a private leaderboard for the user
			 * @param	table		The name of the leaderboard
			 * @param	permalink	The stem of the permalink, eg http://mywebsite.com/game.html?leaderboard=
			 * @param	callback	Callback function to receive the data:  function(leaderboard:Leaderboard, response:Response)
			 * @param	highest		The board's mode (true for highest, false for lowest)
			 */]]
			CreatePrivateLeaderboard = function(table, permalink, callback, highest)
				local postdata = {};
				postdata.table = table;
				postdata.highest = yn(highest);
				postdata.permalink = permalink;
				
				SendAPIRequest(SECTIONS["leaderboards"], ACTIONS["leaderboards-createprivateleaderboard"], CreatePrivateLeaderboardComplete, callback, postdata);
			end,
		
			--[[/**
			 * Loads a private leaderboard
			 * @param	tableid		The id of the leaderboard
			 * @param	callback	Callback function to receive the data:  function(leaderboard:Leaderboard, response:Response)
			 */]]
			LoadPrivateLeaderboard = function(tableid, callback)
				local postdata = {};
				postdata.tableid = tableid;
				
				SendAPIRequest(SECTIONS["leaderboards"], ACTIONS["leaderboards-loadprivateleaderboard"], CreatePrivateLeaderboardComplete, callback, postdata);
			end,
		};


	--// data api
		
		--[[/**
		 * Passes a general request on
		 * @param	action		The action on the server
		 * @param	type		The type of data being requested
		 * @param	callback	The user's callback function
		 * @param	options		Object with day, month, year properties or null for all time
		 */]]
		local function General(action, type, callback, options)
			if options == nil then
				options = {};
			end
			
			local postdata = {};
			postdata.type = type;
			postdata.day = conditional(options.day, options.day, 0);
			postdata.month = conditional(options.month, options.month, 0);
			postdata.year = conditional(options.year, options.year, 0);
			
			SendAPIRequest(SECTIONS["data"], action, GeneralComplete, callback, postdata);
		end
		
		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]
		local function GeneralComplete(callback, postdata, data, response)
			if callback == nil then
				return;
			end
			
			if response.Success == false then
				callback({},0,response);
				return;
			end

			local result = {
				Name = postdata.type, 
				Day = postdata.day, 
				Month = postdata.month, 
				Year = postdata.year, 
				Value = data.Value
			};
			
			callback(result, response);
		end
		
		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]	
		local function CustomMetricComplete(callback, postdata, data, response)
			if callback == nil then
				return;
			end

			if response.Success == false then
				callback({},0,response);
				return;
			end

			local result = {
				Name = "custommetric", 
				Day = postdata.day, 
				Month = postdata.month, 
				Year = postdata.year, 
				Value = data.Value,
			};
			
			callback(result, response);
		end
				
		--[[/**
		 * Passes a level metric request on
		 * @param	action		The action on the server
		 * @param	metric		The metric
		 * @param	level		The level number or name as a string
		 * @param	complete	The complete handler
		 * @param	callback	The user's callback function
		 * @param	options		Object with day, month, year properties or null for all time
		 */]]
		local function LevelMetric(action, metric, level, complete, callback, options)
			if options == nil then
				options = {};
			end
			
			local postdata = {};	
			postdata.metric = metric;
			postdata.level = level;
			postdata.day = conditional(options.day, options.day, 0);
			postdata.month = conditional(options.month, options.month, 0);
			postdata.year = conditional(options.year, options.year, 0);
			
			SendAPIRequest(SECTIONS["data"], action, complete, callback, postdata);
		end
		
		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]
		local function LevelCounterMetricComplete(callback, postdata, data, response)
			if callback == nil then
				return;
			end

			if response.Success == false then
				callback({},0,response);
				return;
			end

			local result = {
				Name = "levelcountermetric", 
				Metric = metric, 
				Level = level, 
				Day = day, 
				Month = month, 
				Year = year, 
				Value = data.Value
			};
			
			callback(result, response);
		end

		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]		
		local function LevelRangedMetricComplete(callback, postdata, data, response)
			if callback == nil then
				return;
			end
			
			if response.Success == false then
				callback({},0,response);
				return;
			end

			local result = {
				Name = "levelrangedmetric", 
				Metric = metric, 
				Level = level, 
				Day = day, 
				Month = month, 
				Year = year, 
				Data = data.Values
			};
			
			callback(result, response);
		end
		
		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]
		local function LevelAverageMetricComplete(callback, postdata, data, response)
			if callback == nil then
				return;
			end
			
			if response.Success == false then
				callback({},0,response);
				return;
			end
	
			local result = {
				Name = "levelaveragemetric", 
				Metric = metric, 
				Level = level, 
				Day = day, 
				Month = month, 
				Year = year, 
				Min = data.Min, 
				Max = data.Max, 
				Average = data.Average, 
				Total = data.Total
			};
				
			callback(data, response);
		end

		Playtomic.Data = {
			--[[/**
			 * Loads the views your game logged on a day or all time
			 * @param	callback	Your function to receive the data:  callback(data:Object, response:Response);
			 * @param	options		Object with day, month, year properties or null for all time
			 */]]
			Views = function(callback, options)		
				General(ACTIONS["data-views"], "views", callback, options);
			end,
	
			--[[/**
			 * Loads the plays your game logged on a day or all time
			 * @param	callback	Your function to receive the data:  callback(data:Object, response:Response);
			 * @param	options		Object with day, month, year properties or null for all time
			 */]]
			Plays = function(callback, options)		
				General(ACTIONS["data-plays"], "plays", callback, options);
			end,
	
			--[[/**
			 * Loads the playtime your game logged on a day or all time
			 * @param	callback	Your function to receive the data:  callback(data:Object, response:Response);
			 * @param	options		Object with day, month, year properties or null for all time
			 */]]			
			PlayTime = function(callback, options)	
				General(ACTIONS["data-playtime"], "playtime", callback, options);
			end,
			
			--[[/**
			 * Loads a custom metric's data for a date or all time
			 * @param	metric		The name of your metric
			 * @param	callback	Your function to receive the data:  callback(data:Object, response:Response);
			 * @param	options		Object with day, month, year properties or null for all time
			 */]]
			CustomMetric = function(metric, callback, options)
				if options == nil then
					options = {};
				end

				local postdata = {};		
				postdata.day = conditional(options.day, options.day, 0);
				postdata.month = conditional(options.month, options.month, 0);
				postdata.year = conditional(options.year, options.year, 0);
				
				SendAPIRequest(SECTIONS["data"], ACTIONS["data-custommetric"], CustomMetricComplete, callback, postdata);
			end,
			
			--[[/**
			 * Loads a level counter metric's data for a level on a date or all time
			 * @param	metric		The name of your metric
			 * @param	level		The level number (integer) or name (string)
			 * @param	callback	Your function to receive the data:  callback(data:Object, response:Response);
			 * @param	options		Object with day, month, year properties or null for all time
			 */]]
			LevelCounterMetric = function(metric, level, callback, options)
				LevelMetric(ACTIONS["data-levelcountermetric"], metric, level, LevelCounterMetricComplete, callback, options);
			end,
		
			--[[/**
			 * Loads a level ranged metric's data for a level on a date or all time
			 * @param	metric		The name of your metric
			 * @param	level		The level number (integer) or name (string)
			 * @param	callback	Your function to receive the data:  callback(data:Object, response:Response);
			 * @param	options		Object with day, month, year properties or null for all time
			 */]]		
			LevelRangedMetric = function(metric, level, callback, options)
				LevelMetric(ACTIONS["data-levelrangedmetric"], metric, level, LevelRangedMetricComplete, callback, options);
			end,

			--[[/**
			 * Loads a level average metric's data for a level on a date or all time
			 * @param	metric		The name of your metric
			 * @param	level		The level number (integer) or name (string)
			 * @param	callback	Your function to receive the data:  callback(data:Object, response:Response);
			 * @param	options		Object with day, month, year properties or null for all time
			 */]]			
			LevelAverageMetric = function(metric, level, callback, options)
				LevelMetric(ACTIONS["data-levelaveragemetric"], metric, level, LevelAverageMetricComplete, callback, options);
			end,
		};
	
	--// geoip

		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	status		The request status returned from the esrver (1 for success)
		 * @param	errorcode	The errorcode returned from the server (0 for none)
		 */]]
		local function LookupComplete(callback, postdata, data, response)
			if callback == nil then
				return;
			end
			
			if response.Success == false then
				callback({},0,response);
				return;
			end
				
			callback(data, response);
		end

		Playtomic.GeoIP = {
			--[[/**
			 * Performs a country lookup on the player IP address
			 * @param	callback	Your function to receive the data:  callback(data:Object, response:Response);
			 * @param	view	If it's a view or not
			 */]]			
			Lookup = function(callback)		
				SendAPIRequest(SECTIONS["geoip"], ACTIONS["geoip-lookup"], LookupComplete, callback, nil);
			end
		};


	--// gamevars

		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	status		The request status returned from the esrver (1 for success)
		 * @param	errorcode	The errorcode returned from the server (0 for none)
		 */]]		
		local function LoadComplete(callback, postdata, data, response)
		
			if callback == nil then
				return;
			end
			
			if response.Success == false then
				callback(nil, response);
				return;
			end

			callback(data, response);
		end

		Playtomic.GameVars = {
			--[[/**
			 * Loads your GameVars 
			 * @param	callback	Your function to receive the data:  callback(gamevars:Object, response:Response);
			 */]]		
			Load = function(callback)		
				SendAPIRequest(SECTIONS["gamevars"], ACTIONS["gamevars-load"], LoadComplete, callback, nil);
			end
		};
		


--[[ Parse ]]--

	--[[/**
	 * Creates a Parse.com database object
	 */]]
	Playtomic.PFObject = function()
		this = {}
		this.ObjectId = "";
		this.ClassName = "";
		this.Data = {};
		this.UpdatedAt = nil;
		this.CreatedAt = nil;
		this.Password = "";
		return this
	end

	--[[/**
	 * Creates a Parse.com database query object
	 */]]
	Playtomic.PFQuery = function()
		this = {}
		this.ClassName = "";
		this.WhereData = {};
		this.Order = "";
		this.Limit = 10;
		return this
	end

-------------------
-------------------

		--[[/**
		 * Converts the server's MM/dd/yyyy hh:mm:ss into a Flash Date
		 * @param	date		The date from the XML
		 */]]	
		local function DateParse(date)
			local dp = {}
			date:gsub( "[% %/%:]-([0-9]+)", function( part ) dp[#dp+1] = tonumber(part) end)	
			return os.time{ year=dp[3], month=dp[1], day=dp[2], hour=dp[4], minute=dp[5], sec=dp[6] }--flag make sure minute is correct, and make sure a timestamp is the correct output.
		end

		DateParse("12/13/2011 09:10:00")


		local function ObjectPostData(pobject)
			local postdata = {};
			postdata.classname = pobject.ClassName;
			postdata.id = conditional(pobject.ObjectId == nil, "", pobject.ObjectId);
			postdata.password = conditional(pobject.Password == nil, "", pobject.Password);

			for key,_ in pairs(pobject.Data) do
				postdata["data" .. key] = pobject.Data[key];
			end

			return postdata;
		end
		
		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]
		local function SaveComplete(callback, postdata, data, response)
			if callback == nil then
				return;
			end

			local po = Playtomic.PFObject();
			po.ClassName = postdata.classname;
			po.ObjectId = data.id;
			po.Password = postdata.password;
			
			for key,_ in pairs(postdata) do
				if key:find("data") == 0 then --flag     make sure these string operations are correct
					po.Data[key:sub(4)] = postdata[key]; --flag
				end
			end
			
			if response.Success then
				po.ObjectId = data.id;
			end
			
			callback(po, response);
		end
		
		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]
		local function LoadComplete(callback, postdata, data, response)
			if callback == nil then
				return;
			end
			
			if response.Success == false then
				callback({},0,response);
				return;
			end
			
			local po = Playtomic.PFObject();
			po.ClassName = data.classname;
			po.ObjectId = data.id;
			po.Password = data.password;
			po.CreatedAt = DateParse(data.created);
			po.UpdatedAt = DateParse(data.updated);
			
			for key,_ in pairs(data.fields) do
				po.Data[key] = data.fields[key];
			end
							
			callback(po, response);
		end
		
		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]
		local function DeleteComplete(callback, postdata, data, response)
			if callback == nil then
				return;
			end
			
			if response.Success == false then
				callback({},0,response);
				return;
			end
				
			callback(data, response);
		end
		
		--[[/**
		 * Processes the response received from the server, returns the data and response to the user's callback
		 * @param	callback	The user's callback function
		 * @param	postdata	The data that was posted
		 * @param	data		The XML returned from the server
		 * @param	response	The response from the server
		 */]]
		local function FindComplete(callback, postdata, data, response)
			if callback == nil then
				return;
			end
			
			if response.Success == false then
				callback({}, response);
				return;
			end
			
			local results = {};
			
			for i = 0, #data do
				local ptemp = data[i];
				
				local po = Playtomic.PFObject();
				po.ClassName = ptemp.classname;
				po.ObjectId = ptemp.id;
				po.Password = ptemp.password;
				po.CreatedAt = DateParse(ptemp.created);
				po.UpdatedAt = DateParse(ptemp.updated);
				
				for key,_ in pairs(ptemp.fields) do
					po.Data[key] = ptemp.fields[key];
				end
								
				push(results,po);
			end
				
			callback(results, response);
		end
		

--[[ API calls ]]--
		Playtomic.Parse = {
							
			--[[/**
			 * Creates or updates an object in your Parse.com database
			 * @param	pobject		A ParseObject, if it has an objectId it will update otherwise save
			 * @param	callback	Callback function to receive the data:  function(pobject:ParseObject, response:Response)
			 */]]
			Save = function(pobject, callback)
				SendAPIRequest(SECTIONS["parse"], ACTIONS["parse-save"], SaveComplete, callback, ObjectPostData(pobject));
			end,
		
			--[[/**
			 * Deletes an object in your Parse.com database
			 * @param	pobject		A ParseObject that must include the ObjectId
			 * @param	callback	Callback function to receive the data:  function(response:Response)
			 */]]	
			Delete = function(pobject, callback)
				SendAPIRequest(SECTIONS["parse"], ACTIONS["parse-delete"], DeleteComplete, callback, ObjectPostData(pobject));
			end,
		
			--[[/**
			 * Loads a specific object from your Parse.com database
			 * @param	pobject		A ParseObject that must include the ObjectId and className
			 * @param	callback	Callback function to receive the data:  function(pobject:ParseObject, response:Response)
			 */]]
			Load = function(pobjectid, classname, callback)
				local postdata = {};
				postdata.id = pobjectid;
				postdata.classname = classname;
				
				SendAPIRequest(SECTIONS["parse"], ACTIONS["parse-load"], LoadComplete, callback, postdata);
			end,
		
			--[[/**
			 * Finds objects matching the criteria in your ParseQuery
			 * @param	pquery		A ParseQuery object
			 * @param	callback	Callback function to receive the data:  function(objects:Array, response:Response)
			 */]]
			Find = function(pquery, callback)
				local postdata = {};
				postdata.classname = pquery.ClassName;
				postdata.limit = pquery.Limit;
				postdata.order = conditional(pquery.Order ~= nil and pquery.Order ~= "", pquery.Order, "created_at");
				
				for key,_ in pairs(pquery.WhereData) do
					postdata["data" .. key] = pquery.WhereData[key];
				end
					
				SendAPIRequest(SECTIONS["parse"], ACTIONS["parse-find"], FindComplete, callback, postdata);
			end,
		};

--[[ Simple wrapper for Playtomic that is compatible with Corona Analytics. ]]--
function init( swfid, guid, apikey, debug )
	Log.View( swfid, guid, apikey, "", debug )
end

function logEvent( event, eventData )
	ed = eventData or { }
	eventType = ed.type or "custom"
	if event == "Play" then
		Log.Play()
	elseif eventType == "custom" then
		Log.CustomMetric(event, ed.eventGroup, ed.unique )
	elseif eventType == "counter" then		
		Log.LevelCounterMetric(event, ed.levelName, ed.unique )
	elseif eventType == "average" then
		Log.LevelAverageMetric(event, ed.levelName, ed.value, ed.unique )
	elseif eventType == "ranged" then
		Log.LevelRangedMetric(event, ed.levelName, ed.value, ed.unique )
	elseif eventType == "heatmap" then
		Log.Heatmap(event, ed.mapName, ed.x , ed.y )
	end
end

function forceSend()
	Log.ForceSend()
end

function freeze()
	Log.Freeze()
end

function unFreeze()
	Log.UnFreeze()
end

function isFrozen()
	return Log.isFrozen()
end

--[[ Call this function to overwrite Corona Analytics ]]--
function makeDefault() 
	CoronaEnvironment.analytics = Playtomic
end

return Playtomic



