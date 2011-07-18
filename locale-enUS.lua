--[[
------------------------------------------------------------------------
	Project: Van32sCM
	File: English Localization, revision @file-revision@
	Date: @project-date-iso@
	Purpose: The English string localization for CM.
	Credits: Code written by Vandesdelca32
	
    Copyright (C) 2011  Vandesdelca32

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

------------------------------------------------------------------------
]]

local addonName, CM = ...
CM = {}

CM.AddonTitle = "CombatMusic"
CM.VerStr = GetAddOnMetadata(addonName, "Version")
CM.Rev = tonumber("@project-revision@") or "DEV"

-- This shouldn't ever need to be localized, it's color strings.
CM.Colours = {
		var = string.format("|cff%02X%02X%02X", 255, 75, 0),
		title = string.format("|cff%02X%02X%02X", 175, 150, 255),
		err = string.format("|cff%02X%02X%02X", 230, 10, 10),
		close = "|r",
}

-- All localizable strings are HERE.
CM.L = {
	Header = {
		Debug = "<DEBUG> ",
		Error = CM.Colours.err .. "[ERROR]".. CM.Colours.close .. " "
	},
	Errors = {
		InvalidArg = CM.Colours.var .. "\"%s\"" .. CM.Colours.close .. " is an invalid argument!",
		NotImplemented = "I'm lazy and I haven't finished that yet!",
		Volume = "That's gotta be between " .. CM.Colours.var .. "0" .. CM.Colours.close .. " and " .. CM.Colours.var .. "1" .. CM.Colours.close .. ".",
		BiggerThan0 = "That's gotta be bigger than "  .. CM.Colours.var .. "0" .. CM.Colours.close .. ".",
		OnOrOff = "That's gotta be " .. CM.Colours.var .. "on" .. CM.Colours.close .. " or " .. CM.Colours.var .. "off" .. CM.Colours.close .. ".",
		NotOnList = "That one wasn't found on the BossList!"
	},
	-- Debug mode messages:
	Debug = {
		DebugLoaded = "Loaded in Debug Mode! Use " .. CM.Colours.var .. "/cm debug off" .. CM.Colours.close .. " to turn it off.",
		DebugOn = "Debug mode is " .. CM.Colours.var .. "on" .. CM.Colours.close .. ". Spammy output AWAY!",
		DebugOff = "DebugMode is " .. CM.Colours.var .. "off" .. CM.Colours.close .. "."
	},
	Other = {
		AddonLoaded = CM.AddonTitle .. "loaded! You're running version " .. CM.Colours.var .. CM.VerStr .. " r" .. CM.Rev .. CM.Colours.close .. ". Use " .. CM.Colours.var .. "/cm" .. CM.Colours.close .. " for help!",
		VarsLoaded = "Settings loaded...",
		SongListLoaded = "BossList loaded...",
		LoadDefaults = "Couldn't find your settings, loading the default ones...",
		SongListDefaults = "Couldn't find your BossList! Loading a blank one...",
		UpdateSettings = "Found out you were using outdated settings. Gone ahead and updated that for you.",
		ResetDialog = CM.Colours.err .."WARNING!\n".. CM.Colours.close .. "Resetting ".. CM.AddonTitle .. " will erase your settings and BossList!!\nThis cannot be undone!\n\nAre you sure you want to reset ".. CM.AddonTitle .."?\n".. CM.Colours.var .."(An interface reload is required.)" .. CM.Colours.close,
		Enabled = "Enabled.",
		Disabled = "Disabled. Why? :(",
		BattleCount = "You've got " .. CM.Colours.var .. "%s" .. CM.Colours.close .. " battle songs set.",
		BossCount = "You've got " .. CM.Colours.var .. "%s" .. CM.Colours.close .. " boss songs set.",
		NewBattles = "You've set the number of battle songs to " .. CM.Colours.var .. "%s" .. CM.Colours.close .. ".",
		NewBosses = "You've set the number of boss songs to " .. CM.Colours.var .. "%s" .. CM.Colours.close .. ".",
		CurMusicVol = "You've got the in-combat music volume set to " .. CM.Colours.var .. "%s" .. CM.Colours.close .. ".",
		SetMusicVol = "You've set the in-combat music volume to " .. CM.Colours.var .. "%s" .. CM.Colours.close .. ".",
		CurrentFade = "You've got songs set to fade out over " .. CM.Colours.var .. "%s" .. CM.Colours.close .. " seconds.",
		FadingSet = "You've set songs to fade out over " .. CM.Colours.var .. "%s" .. CM.Colours.close .. " seconds.",
		FadingDisable = "Fading turned off.",
		BattlesOff = "Battle music turned off.",
		BossesOff = "Boss music turned off.",
		BossListAdd1 = "Enter the name of the NPC you want to add to the BossList.",
		BossListAdd2 = "Enter the path to the song you want to play when " .. CM.AddonTitle .. " finds this target.",
		BossListRemove = "Enter the name of the NPC you no longer want on the BossList.",
		BossListAdded = "Added " .. CM.Colours.var .. "%s" .. CM.Colours.close .. " to the BossList! They'll play "  .. CM.Colours.var .. "%s" .. CM.Colours.close .. " now!",
		BossListRemoved = "Took "  .. CM.Colours.var .. "%s" .. CM.Colours.close .. " off the BossList. They'll play a randomly chosen song now.",
		UseDump = "Your BossList:",
		BossListDump = CM.Colours.var .. "%s" .. CM.Colours.close .. " will play "..  CM.Colours.var .. "\"%s\"" .. CM.Colours.close,
		AddonCommOff = "Addon communications for " .. CM.Colours.var .. "disabled" .. CM.Colours.close .. ". No longer replying to settings requests!",
		AddonCommOn  = "Addon communications for " .. CM.Colours.var .. "enabled" .. CM.Colours.close .. ". Thanks for showing your support!",
		CurrentVerHelp = "Version: " .. CM.Colours.var .. CM.VerStr .. " r" .. CM.Rev .. CM.Colours.close .. " - Help:",
		HelpLine = CM.Colours.var .. "%s " .. CM.Colours.close .. "- %s",
	},
	SlashHelp = {
		["/cm help"] = "Shows this text.",
		["/cm on"] = "Enables CM.",
		["/cm off"] = "Disables CM.",
		["/cm volume [value]"] = "Set the in-combat music volume to \"value\". If value is not provided; shows the current value.",
		["/cm battles [value\124off]"] = "Sets the number of \"Battles\" songs to \"value\". If value is not provided; shows the current value.",
		["/cm bosses [value\124off]"] = "Sets the number of \"Bosses\" songs to \"value\". If value is not provided; shows the current value.",
		["/cm fade [value\124off]"] = "Sets the fade timer for playing music. If value is not provided; shows the current value.",
		["/cm bosslist [add\124\124remove]"] = "Allows you to add/remove entries on the BossList table. Without an argument, will print the contents to the chat frame.",
		["/cm comm [on\124off]"] = "Allows you to enable/disable responding to settings requests from other players.",
		["/cm debug [on\124off]"] = "Sets Debug mode on or off. When enabled, it will print debug messages to your chat frame.",
		["/cm reset"] = "Shows the prompt to reset your ".. CM.AddonTitle .." setings. This cannot be undone!",		
--[[
	-- Message headers.. These get added onto a message to specify it's type.
	["DebugHeader"] = "<Debug> ",
	["ErrorHeader"] = CM.Colours.err .. "[ERROR]" .. CM.Colours.close .. " ",
	
	-- Error Messages
	["ErrorMessages"] = {
		["InvalidArg"] = CM.Colours.var .. "\"%s\"" .. CM.Colours.close .. " is an invalid argument.",
		--["NonEmpty"] = "Please enter something into the text field. The value can not be empty.",
		["NotImplemented"] = "The feature you are trying to use has not been implemented yet.",
		["Volume"] = "Music volume can only be set between the values of " .. CM.Colours.var .. "0" .. CM.Colours.close .. " and " .. CM.Colours.var .. "1" .. CM.Colours.close .. ".",
		["BiggerThan0"] = "The value you entered must be bigger than " .. CM.Colours.var .. "0" .. CM.Colours.close .. ".",
		["OnOrOff"] = "Please use " .. CM.Colours.var .. "on" .. CM.Colours.close .. " or " .. CM.Colours.var .. "off" .. CM.Colours.close .. ".",
		["NotOnList"] = "That unit wasn't found on the BossList!",
		--["AddRemoveDisplay"] = "Please use ".. CM.Colours.var .. "add" .. CM.Colours.close .. ", ".. CM.Colours.var .. "remove" .. CM.Colours.close .. ", or ".. CM.Colours.var .. "display" .. CM.Colours.close .. ".",
	},
	
	-- Debug Messages, These are most likely going to be hardcoded into the acutal files...
	["DebugMessages"] = {
		["DebugLoaded"] = "Addon loaded in debug mode. Type ".. CM.Colours.var .. "/cm debug off" .. CM.Colours.close .." to disable.",
		["DebugOn"] = "Debug mode has been " .. CM.Colours.var .. "enabled" .. CM.Colours.close .. ". Type " .. CM.Colours.var .. "/cm debug off" .. CM.Colours.close .. " to disable.",
		["DebugOff"] = "Debug mode has been " .. CM.Colours.var .. "disabled" .. CM.Colours.close .. ".",
		},
	-- Slash command help list.
	["SlashHelp"] = {
		["/cm help"] = "Shows this text.",
		["/cm on"] = "Enables CM.",
		["/cm off"] = "Disables CM.",
		["/cm volume [value]"] = "Set the in-combat music volume to \"value\". If value is not provided; shows the current value.",
		["/cm battles [value\124off]"] = "Sets the number of \"Battles\" songs to \"value\". If value is not provided; shows the current value.",
		["/cm bosses [value\124off]"] = "Sets the number of \"Bosses\" songs to \"value\". If value is not provided; shows the current value.",
		["/cm fade [value\124off]"] = "Sets the fade timer for playing music. If value is not provided; shows the current value.",
		["/cm bosslist [add\124\124remove]"] = "Allows you to add/remove entries on the BossList table. Without an argument, will print the contents to the chat frame.",
		["/cm comm [on\124off]"] = "Allows you to enable/disable responding to settings requests from other players.",
		["/cm debug [on\124off]"] = "Sets Debug mode on or off. When enabled, it will print debug messages to your chat frame.",
		["/cm reset"] = "Shows the prompt to reset your ".. CM.AddonTitle .." setings. This cannot be undone!",		
	},
	-- Other Messages
	["OtherMessages"] = {
		x["AddonLoaded"] = CM.AddonTitle .. " version " .. CM.Colours.var .. CM.VerStr .. " r" .. CM.Rev .. CM.Colours.close .. " successfully loaded! " .. CM.Colours.var .. "/CM" .. CM.Colours.close .. " shows command help.",
		x["VarsLoaded"] = "Configuration Loaded.",
		x["SongListLoaded"] = "Song list loaded.",
		x["LoadDefaults"] = "Configuration not set. Loading defaults...",
		x["SongListDefaults"] = "Song List not found. Loading defaults...",
		x["UpdateSettings"] = "Settings updated to new format. Some settings may have been lost.",
		x["ResetDialog"] = CM.Colours.err .."WARNING!\n".. CM.Colours.close .. "Resetting ".. CM.AddonTitle .. " will erase all of your settings and custom bosses!\nThis cannot be undone!\n\nAre you sure you want to reset ".. CM.AddonTitle .."?\n".. CM.Colours.var .."(An interface reload is required.)" .. CM.Colours.close,
		x["Enabled"] = CM.AddonTitle .. " has been " .. CM.Colours.var .. "enabled" .. CM.Colours.close .. ".",
		x["Disabled"] = CM.AddonTitle .. " has been " .. CM.Colours.var .. "disabled" .. CM.Colours.close .. ".",
		x["BattleCount"] = "Current number of battle songs is set to " .. CM.Colours.var .. "%s" .. CM.Colours.close .. ".",
		x["BossCount"] = "Current number of boss songs is set to " .. CM.Colours.var .. "%s" .. CM.Colours.close .. ".",
		x["NewBattles"] = "New battle count set to " .. CM.Colours.var .. "%s" .. CM.Colours.close .. ".",
		x["NewBosses"] = "New boss count set to " .. CM.Colours.var .. "%s" .. CM.Colours.close .. ".",
		x["CurMusicVol"] = "Current music volume is set to " .. CM.Colours.var .. "%s" .. CM.Colours.close .. ".",
		x["SetMusicVol"] = "In combat music volume set to " .. CM.Colours.var .. "%s" .. CM.Colours.close .. ".",
		x["CurrentVerHelp"] = "Version: " .. CM.Colours.var .. CM.VerStr .. " r" .. CM.Rev .. CM.Colours.close .. " - Help:",
		x["FadingSet"] = "Song fadeout set to " .. CM.Colours.var .. "%s seconds" .. CM.Colours.close .. ".",
		x["CurrentFade"] = "Song fadeout is set to " .. CM.Colours.var .. "%s seconds" .. CM.Colours.close .. ".",
		x["FadingDisable"] = "Song fadeout disabled.",
		x["BattlesOff"] = "Battle music disabled.",
		x["BossesOff"] = "Boss music disabled.",
		x["BossListAdd1"] = "Enter the name of the NPC you want to add to the BossList.",
		x["BossListAdd2"] = "Enter the path to the song you want to play when CM finds this target.",
		x["BossListRemove"] = "Enter the name of the NPC you no longer want on the BossList.",
		x["BossListAdded"] = "Successfully added " .. CM.Colours.var .. "%s" ..  CM.Colours.close .. " to the BossList with the song at " .. CM.Colours.var .. "%s" ..  CM.Colours.close .. "!",
		x["BosslistRemoved"] = "Successfully removed " .. CM.Colours.var .. "%s" ..  CM.Colours.close .. " from the BossList!",
		x["UseDump"] = "Printing " .. CM.Colours.var .. "Bosslist" .. CM.Colours.close .. ".",
		x["AddonCommOff"] = "Addon communications for " .. CM.Colours.var .. "disabled" .. CM.Colours.close .. ". No longer replying to settings requests!",
		x["AddonCommOn"] = "Addon communications for " .. CM.Colours.var .. "enabled" .. CM.Colours.close .. ". Thanks for showing your support!",
		x["BossListDump"] = CM.Colours.var .. "%s" .. CM.Colours.close .. " will play "..  CM.Colours.var .. "\"%s\"" .. CM.Colours.close,
		x["HelpLine"] = CM.Colours.var .. "%s " .. CM.Colours.close .. "- %s",
	},
}
]]
-- DO NOT LOCALIZE KEYS OR STRINGS!
CM.SlashArgs = {
	["Help"]    = "help",
	["Enable"]  = "on",
	["Disable"] = "off",
	--["Config"]  = "config",
	["Debug"] = "debug",
	["BattleCount"] = "battles",
	["BossCount"] = "bosses",
	["Reset"] = "reset",
	["MusicVol"] = "volume",
	["FadeTime"] = "fade",
	["BossList"] = "bosslist",
	["Comm"] = "comm",
}
	