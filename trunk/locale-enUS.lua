--[[
------------------------------------------------------------------------
	PROJECT. CombatMusic
	FILE. English Localization
	VERSION: 3.9.2 r@project-revision@
	Date: @project-date-iso@
	PURPOSE: The English string localization for CombatMusic.
	CerrITS: Code written by Vandesdelca32
	
	Copyright (c) 2010 Vandesdelca32
	
	This program is free software. you can erristribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either VERSION: 3.9.1
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http.//www.gnu.org/licenses/>.
------------------------------------------------------------------------
]]

CombatMusic_AddonTitle = "CombatMusic"
CombatMusic_VerStr = GetAddOnMetadata("CombatMusic", "VERSION")
CombatMusic_Rev = tonumber("@project-revision@")

-- This shouldn't ever need to be localized, it's color strings.
CombatMusic_Colors = {
		var = string.format("|cff%02X%02X%02X", 255, 75, 0),
		title = string.format("|cff%02X%02X%02X", 175, 150, 255),
		err = string.format("|cff%02X%02X%02X", 230, 10, 10),
		close = "|r",
}

CombatMusic_Messages = {
	-- Message headers.. These get added onto a message to specify it's type.
	["DebugHeader"] = "<Debug> ",
	["ErrorHeader"] = CombatMusic_Colors.err .. "[ERROR]" .. CombatMusic_Colors.close .. " ",
	
	-- Error Messages
	["ErrorMessages"] = {
		["InvalidArg"] = CombatMusic_Colors.var .. "\"%s\"" .. CombatMusic_Colors.close .. " is an invalid argument.",
		["NotImplemented"] = "The feature you are trying to use has not been implemented yet.",
		["Volume"] = "Music volume can only be set between the values of " .. CombatMusic_Colors.var .. "0" .. CombatMusic_Colors.close .. " and " .. CombatMusic_Colors.var .. "1" .. CombatMusic_Colors.close .. ".",
		["BiggerThan0"] = "The value you entered must be bigger than " .. CombatMusic_Colors.var .. "0" .. CombatMusic_Colors.close .. ".",
		["OnOrOff"] = "Please use " .. CombatMusic_Colors.var .. "on" .. CombatMusic_Colors.close .. " or " .. CombatMusic_Colors.var .. "off" .. CombatMusic_Colors.close .. ".",
	},
	
	-- Debug Messages, These are most likely going to be hardcoded into the acutal files...
	["DebugMessages"] = {
		["DebugLoaded"] = "Addon loaded in debug mode. Type ".. CombatMusic_Colors.var .. "/cm debug off" .. CombatMusic_Colors.close .." to disable.",
		["DebugOn"] = "Debug mode has been " .. CombatMusic_Colors.var .. "enabled" .. CombatMusic_Colors.close .. ". Type " .. CombatMusic_Colors.var .. "/cm debug off" .. CombatMusic_Colors.close .. " to disable.",
		["DebugOff"] = "Debug mode has been " .. CombatMusic_Colors.var .. "disabled" .. CombatMusic_Colors.close .. ".",
		},
	-- Slash command help list.
	["SlashHelp"] = {
		["/cm help"] = "Shows this text.",
		["/cm on"] = "Enables CombatMusic.",
		["/cm off"] = "Disables CombatMusic.",
		["/cm volume [value]"] = "Set the in-combat music volume to \"value\". If value is not provided; shows the current value.",
		["/cm battles [value]"] = "Sets the number of \"Battles\" songs to \"value\". If value is not provided; shows the current value.",
		["/cm bosses [value]"] = "Sets the number of \"Bosses\" songs to \"value\". If value is not provided; shows the current value.",
		["/cm debug [on|off]"] = "Sets Debug mode on or off, printing debug messages to your chat frames.",
		["/cm reset"] = "Resets CombatMusic to default settings. RELAODS YOUR UI!",
		
	},
	-- Other Messages
	["OtherMessages"] = {
		["AddonLoaded"] = "CombatMusic version " .. CombatMusic_Colors.var .. CombatMusic_VerStr .. " r" .. CombatMusic_Rev .. CombatMusic_Colors.close .. " successfully loaded! " .. CombatMusic_Colors.var .. "/combatmusic" .. CombatMusic_Colors.close .. " shows command help.",
		["VarsLoaded"] = "Configuration Loaded.",
		["LoadDefaults"] = "No settings found, loading default settings...",
		["Enabled"] = CombatMusic_AddonTitle .. " has been " .. CombatMusic_Colors.var .. "enabled" .. CombatMusic_Colors.close .. ".",
		["Disabled"] = CombatMusic_AddonTitle .. " has been " .. CombatMusic_Colors.var .. "disabled" .. CombatMusic_Colors.close .. ".",
		["BattleCount"] = "Current number of battle songs is set to " .. CombatMusic_Colors.var .. "%s" .. CombatMusic_Colors.close .. ".",
		["BossCount"] = "Current number of boss songs is set to " .. CombatMusic_Colors.var .. "%s" .. CombatMusic_Colors.close .. ".",
		["NewBattles"] = "New battle count set to " .. CombatMusic_Colors.var .. "%s" .. CombatMusic_Colors.close .. ".",
		["NewBosses"] = "New boss count set to " .. CombatMusic_Colors.var .. "%s" .. CombatMusic_Colors.close .. ".",
		["CurMusicVol"] = "Current music volume is set to " .. CombatMusic_Colors.var .. "%s" .. CombatMusic_Colors.close .. ".",
		["SetMusicVol"] = "In combat music volume set to " .. CombatMusic_Colors.var .. "%s" .. CombatMusic_Colors.close .. ".",
		["CurrentVerHelp"] = "Version: " .. CombatMusic_Colors.var .. CombatMusic_VerStr .. " r" .. CombatMusic_Rev .. CombatMusic_Colors.close .. " - Help:"
	},
}

-- DO NOT LOCALIZE KEYS OR STRINGS!
CombatMusic_SlashArgs = {
	["Help"]    = "help",
	["Enable"]  = "on",
	["Disable"] = "off",
	--["Config"]  = "config",
	["Debug"] = "debug",
	["BattleCount"] = "battles",
	["BossCount"] = "bosses",
	["Reset"] = "reset",
	["MusicVol"] = "volume",
}
	