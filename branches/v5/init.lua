--[[
-------------------------------------------------------------------------------
	Project: Van32's CombatMusic
	Author: Vandesdelca32
	Date: @file-date-iso@
	
	File: Initialization, r@file-revision@
	Purpose: To initialize the addon, it's namespace and important variables.
	
	
	    This file is part of CombatMusic.

    CombatMusic is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    CombatMusic is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with CombatMusic.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------
]]

local addonName, CM_Engine = ...

-- This is called when a string can't be found in localization
local function notFound(t, i)
	return "§c" .. i
end

-- Attempt to find a localization.
local function GetLocalization()
	local locale == GetLocale()
	-- Check to see if our locale exists, otherwise
	-- default to english.
	if not CombatMusic_Locale[locale] then
		return setmetatable(CombatMusic_Locale.enUS, {__index = notFound})
	end
	return setmetatable(CombatMusic_Locale[locale], {__index = notFound})

end

-- CombatMusic's default settings.
local settingsDefaults = {
	SV_Version = "3",
	Core_Enabled = true,
	Comm_Enabled = true,
	ChatFrame = "DEFAULT_CHAT_FRAME",
	Music = {
		FadeOut = {
			Boss_Enabled = true,
			Combat_Enabled = true,
			duration = 5,
		},
		Volume = 1,
		PreferFocus = true,
		CheckBoss = true,
		SongCounts = {
			Battles = -1,
			Bosses = -1,
		},
	},
	Fanfare = {
		Enabled = true,
		Cooldown = 30,
	},
	GameOver = {
		Enabled = true,
		Cooldown = 30,
	},
	LevelUp = {
		Enabled = true,
		Use_Ding = true,
	},
	BossList = {},
}


CM_Engine[1] = {}						--The core code goes here
CM_Engine[2] = GetLocalization()		--The localization info goes here
CM_Engine[3] = {}						--The player's settings
CM_Engine[4] = settingsDefaults			--The default settings, Easier to have one place where they are defined.


-- Populate a global table with everything we need.
_G[addonName] = CM_Engine
