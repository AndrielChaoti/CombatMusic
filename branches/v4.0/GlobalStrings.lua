--[[
------------------------------------------------------------------------
	Project: Van32sCombatMusic
	File: GlobalStrings revision @file-revision@
	Date: @project-date-iso@
	Purpose: Global Strings, non-localized.
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

CM["TITLE"] = "CombatMusic"

local CSTR = "|cff%02X%02X%02X" -- Color code string
CM["COLORS"] = {
	END = "|r",
	ERROR = format(CSTR, 230, 10, 10),
	GREEN = format(CSTR, 10, 230, 10),
	DEBUG = format(CSTR, 165, 205, 160), 
	ORANG = format(CSTR, 255, 75, 0),
	TITLE = format(CSTR, 175, 150, 255),
}
CM["VERSION"] = GetAddOnMetadata(addonName, "Version") .. "r" .. (tostring("@project-revision@") or "DEV")
CM["SV_COMPATIBLE"] = "2"

CM["DEBUG"] = false
--@alpha@
CM["DEBUG"] = true
--@end-alpha@