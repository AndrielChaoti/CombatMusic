--[[
	Project: CombatMusic
	Friendly Name: CombatMusic
	Author: Vandesdelca32

	File: core.lua
	Purpose: Core functions to build on

	Version: @file-revision@


	This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	See http://creativecommons.org/licenses/by-sa/3.0/deed.en_CA for more info.
]]

--GLOBALS: CombatMusicDB, CombatMusicBossList, SetCVar, GetCVar
--GLOBALS: PlayMusic, StopMusic, UnitName

local E, L, DF, T = unpack(select(2, ...))

local tconcat, error = table.concat, error
local tostringall, strfind = tostringall, strfind
local select, type, random = select, type, random


-- Helps with printing function arguments and names in debug messages
-- to make tracing code progress easier.
local function printFuncName(func, ...)
	local argList = tconcat({tostringall(...)}, "§r,§6 ")
	return E:PrintDebug("§a" .. func .. "§f(§6" .. (argList or "") .. "§f)")
end

E.printFuncName = printFuncName



--------------
--	Useful Code
--------------
-- Various functions to make adding new features a lot easier.

--- Gets a setting or it's equivalent in the defaults table if it can't be found
-- @arg ... a list of table keys
-- @return A value representing the setting requested.
function E:GetSetting(...)
	printFuncName("GetSetting", ...)
	local t = CombatMusicDB -- Start by setting t to the top-level settings table
	local dt = DF -- And the top-level defaults table.
	for i = 1, select("#", ...) do
		local key = select(i, ...)
		if t[key] == nil then -- If the key doesn't exist in the table,
			t[key] = dt[key] -- use the default value instead (modified to accept false key values!)
		end
		t = t[key] -- Set t to the value at key in the current table

		if dt[key] == nil then -- Check if this is actually a valid setting
			error("no such setting: " .. tconcat({tostringall(...)}, ", "), 2)
		end
		dt = dt[key] -- and dt to the value at key in the defaults table, so we can parse multiple table levels.
		
		if type(t) ~= "table" then -- If the new value of t isn't a table, return it now (terminating the function early)
			return t
		end
		-- Otherwise, t is the new table and we move on to the next key
		
		-- We repeat the above until we've processed every key or encountered a non-table value.
	end
	return t
end

--- Get the addon's version string
-- @arg short Set to true to return a shorter version string. (Ex. r411)
-- @return A string reperesenting the addon's current version (Ex. "release_v4.6.3.411")
function E:GetVersion(short)
	printFuncName("GetVersion", short)

	local v, rev = self._major, self._revision
	if v:find("^@") then
		v = "DEV_VERSION"
		self._DebugMode = true
	end

	if rev:find("^@") then
		rev = "???"
		self._DebugMode = true
	end

	if short then
		-- Try to discern what release stage:
		if strfind(v, "release") then 
			return "r" .. rev
		elseif strfind(v, "beta") then
			return "b" .. rev
		else
			return "a" .. rev
		end
	end
	return v .. "." .. rev
end

--- Check and make sure the SavedVariables database exists
-- and is up to date.
function E:CheckSettingsDB()
	printFuncName("CheckSettingsDB")

	-- Make sure they have a bosslist
	if type(CombatMusicBossList) ~= "table" then
		CombatMusicBossList = {}
	end

	-- They don't have a settings database
	if not CombatMusicDB then
		self:PrintErr(L["ChatErr_SettingsNotFound"])
		CombatMusicDB = DF
		return false

	-- Or their settings are outdated
	elseif self:GetSetting("_VER") ~= DF._VER then
		self:PrintErr(L["ChatErr_SettingsOutOfDate"])
		CombatMusicDB = DF
		return false
	end
	return true
end


------------
--	Core code
------------
-- Code that needs to be built into the engine

--- The list of registered song types
E.RegisteredSongs = {}

--- Registers a new songtype to be saved in the "numsongs" table
--@arg name The name of the songtype to register
--@arg defaultState the default state to set the registered songtype
--@return true if the songtype registration succeeded.
function E:RegisterNewSongType(name, defaultState)
	if not name or self.RegisteredSongs[name] then error("invalid songtype") end

	-- Create our song's settings table.
	DF.General.SongList[name] = {
		Enable = defaultState,
		Count = 1,
	}

	-- And add the type to the settings table
	self.RegisteredSongs[name] = true
	return true
end


--- Plays a random music file from the folder 'songPath'
--@arg songPath The folder path rooted at "Interface\\Music" of the songs to pick from
--@return 1 if music played successfully, otherwise nil
--@usage MyModule.Success = E:PlayMusicFile("songPath")
function E:PlayMusicFile(songPath)
	printFuncName("PlayMusicFile", songPath)
	if not songPath then return end
	-- Quickly plot out the paths we use
	local fullPath = "Interface\\Music\\" .. songPath

	-- songPath needs to exist...
	if not self:GetSetting("General","SongList",songPath) then return end
	-- Are we using this song type?
	if not self:GetSetting("General", "SongList", songPath, "Enable") then return end
	-- How many songs are we using of this songType?
	local max = self:GetSetting("General", "SongList", songPath, "Count")

	-- Some more sanity checking...!
	if not max then return end
	if max > 0 then
		local rand = random(1, max)
		self:PrintDebug("  ==§bSong: " .. fullPath .. "\\song" .. rand .. ".mp3")
		return PlayMusic(fullPath .. "\\song" .. rand .. ".mp3")
	end
end


--- Check to see if 'unit''s name is on the custom song list
--@arg unit the unit token to check
--@return True if the unit is on the custom song list, otherwise false.
function E:CheckBossList(unit)
	printFuncName("CheckBossList", unit)
	if not unit then return end
	
	local name = UnitName(unit)
	if CombatMusicBossList[name] then
		-- The unit is on the bosslist, play that specific song.
		self.PlayingMusic = PlayMusic(CombatMusicBossList[name])
		return true
	end
	return false
end


--- Sets or restores the volume levels provided in the settings
--@arg restore Set to true to restore the out of combat levels instead.
function E:SetVolumeLevel(restore)
	printFuncName("SetVolumeLevel", restore)
	if not restore then
		-- Set the in combat music levels
		SetCVar("Sound_MusicVolume", self:GetSetting("General", "Volume"))
		SetCVar("Sound_EnableMusic", "1")
	else
		-- Set the out of combat ones.
		SetCVar("Sound_MusicVolume", self.lastMusicVolume)
		-- We don't -restore- EnableMusic, because it's always supposed to be on.
	end
end

--- Saves the user's current volume settings.
function E:SaveLastVolumeState()
	printFuncName("SaveLastVolumeState")
	self.lastMusicVolume = GetCVar("Sound_MusicVolume")
end