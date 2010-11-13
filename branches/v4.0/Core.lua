--[[
------------------------------------------------------------------------
	Project: Van32sCombatMusic
	File: Main Functions revision @file-revision@
	Date: @project-date-iso@
	Purpose: Major core functions of any addon.
	Credits: Code written by Vandesdelca32

	Copyright (c) 2010 Vandesdelca32

		This file is part of Van32sCombatMusic.

 Van32sCombatMusic is free software: you can redistribute it and/or 
modify it under the terms of the GNU General Public License as published 
by the Free Software Foundation, either version 3 of the License, or (at 
your option) any later version. 

 Van32sCombatMusic is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
Public License for more details. 

 You should have received a copy of the GNU General Public License along 
with Van32sCombatMusic. If not, see <http://www.gnu.org/licenses/>. 

------------------------------------------------------------------------
]]
local addonName, CM = ...

-- Initialize the Addon

local CombatMusic = LibStub("AceAddon-3.0"):NewAddon(CM.TITLE, "AceTimer-3.0", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(CM.TITLE, false)

------------------
-- Print functions
------------------
--local MessagePrefix = CM.COLORS.TITLE .. CM.TITLE .. CM.COLORS.END .. ": "
-- PrintMessage - Print a normal message
function CombatMusic.PrintMessage(message)
	CombatMusic:Print(message)
end

--PrintError - Print an Error message
function CombatMusic.PrintError(message)
	CombatMusic:Print(L["ERROR"] .. message)
end

-- PrintDebug - Print a debug message
function CombatMusic.PrintDebug(message)
	if not CM.DEBUG then return end
	CombatMusic:Print(L["DEBUG"] .. message)
end
------------------
------------------

-- CheckSavedVars - Checks the SavedVariables for the proper version, and if they loaded correctly
function CombatMusic.CheckSavedVars()
	local DBPass = CombatMusic.CheckDB()
	local BossPass = CombatMusic.CheckBossList()
	if DBPass then
		CombatMusic.PrintMessage(L["Configuration Loaded"])
	end
	if BossPass then
		CombatMusic.PrintMessage(L["Bosslist Loaded"])
	end

end

-- CheckDB - Check the main saved data for consistency
function CombatMusic.CheckDB()
	if not CombatMusic_SavedDB then
		CombatMusic.SetDBDefaults()
		CombatMusic.PrintError(L["Errors"]["No Settings"])
		return nil
	elseif CombatMusic_SavedDB.Version ~= CM.SV_COMPATIBLE then
		CombatMusic.SetDBDefaults(1)
		CombatMusic.PrintError(L["Errors"]["Out of Date Settings"])
		return nil
	end
	return true
end

-- CheckBossList - Check if the Boss List exists.
function CombatMusic.CheckBossList()
	if not CombatMusic_BossList then
		CombatMusic_BossList = {}
		CombatMusic.PrintError(L["Errors"]["No Boss List"])
		return nil
	end
	return true
end

-- SetDBDefaults - Load Default settings
function CombatMusic.SetDBDefaults(tryToUpdate, oldVer)
	CombatMusic_SavedDB = {
		Version = CM.SV_COMPATIBLE,
		Enabled = true,
		Features = {
			CombatFanfare = {
				AlwaysPlay = false,
				Enabled = true,
				Cooldown = 30,
			},
			CombatMusic = {
				Enabled = true,
				MusicFade = {
					Enabled = true,
					FadeTime = 5,
				},
				SongCount = {
					Battles = 0,
					Bosses = 0,
					Fanfares = 0,
					GameOvers = 0,
				},
			},
			GameOver = {
				Enabled = true,
				Cooldown = 30,
			},
			LevelUp = {
				Enabled = true,
			},
		},
	}
end


-------------
-- Ace3 stuff
-------------
 
-- OnInitialize - Called when the addon is first loaded
function CombatMusic:OnInitialize()
	-- Register Slash commands
	CombatMusic:RegisterChatCommand("combatmusic", "OnConsoleCommand")
	CombatMusic:RegisterChatCommand("cm", "OnConsoleCommand")
	-- Check SavedVariables
	CombatMusic.CheckSavedVars()
	CombatMusic.PrintDebug("OnInitialize")
end

-- OnEnable - Called when the addon is enabled.
function CombatMusic:OnEnable()
	-- Add Enable code here
	CombatMusic.PrintDebug("OnEnable")
end


-- OnDisable - Called when the addon is disabled
function CombatMusic:OnDisable()
	CombatMusic.PrintDebug("OnDisable")
-- Add Disable code here:
end


-- OnConsoleCommand - Called when the user uses a slash command
function CombatMusic:OnConsoleCommand(args)
	CombatMusic.PrintDebug("OnConsoleCommand(" .. args .. ")")
-- Slash command code
end
