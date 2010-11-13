--[[
------------------------------------------------------------------------
	Project: Van32sCombatMusic
	File: enUS revision @file-revision@
	Date: @project-date-iso@
	Purpose: enUS string localizations
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

local L = LibStub("AceLocale-3.0"):NewLocale(CM.TITLE, "enUS", true)

if L then
	L["ERROR"] = CM.COLORS.ERROR .. "[ERROR]" .. CM.COLORS.END
	L["DEBUG"] = CM.COLORS.DEBUG .. "<DEBUG>" .. CM.COLORS.END
	L["Addon Loaded"] = CM.TITLE .. " version " .. CM.VERSION .. " loaded successfuly!"
	L["Show Once Help"] = "Type /cm help for a list of slash commands!"
	L["Configuration Loaded"] = "Core settings loaded."
	L["BossList Loaded"] = "Custom songlist loaded."
	L["Errors"] = {
		["No Boss List"] = "Couldn't find a custom songlist, resetting the songlist instead.",
		["No Settings"] = "Couldn't find the settings, resetting to default",
		["Out of Date Settings"] = "Settings are out of date, restoring defaults.",
	}
end
