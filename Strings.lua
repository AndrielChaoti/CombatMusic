--[[
------------------------------------------------------------------------
	Project: Van32sCombatMusic
	File: English Localization, revision @file-revision@
	Date: @file-date-iso@
	Purpose: The English string localization for CombatMusic.
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

local addonName, _ = ...

local verString = function()
	local str = "version $V" .. (GetAddOnMetadata(addonName, "VERSION") or "??")
	str = str .. " r".. (tonumber('@project-revision@') or "DEV")
	return str
end

CM_STRINGS = {
	ERRORS = {
		BiggerThan0 = "That needs to be a number bigger than $V0$C.",
		Between0And1 = "That has to be bigger than $V0$C and no bigger than $V1$C.",
		OnOrOff = "That can only be \"$Von$C\" or \"$Voff$C\"",
		InvalidCommand = "I don't recognize that command. use $V/cm help$C for a list of commands!",
		BossListNotFound = "Couldn't find $V%s$C on the BossList.",
		InvalidArgumentCD = "That can only be \"$Vgameover$C\" or \"$Vvictory$C\"",
		InvalidArgumentE = "That can only be \"$Vgameover$C\", \"$Vvictory$C\", or \"$Vding$C\"",
	},
	OTHER = {
		-- Settings messages
		SettingsLoaded = "Configuration loaded successfully.",
		BossListLoaded = "BossList loaded successfully.",
		BossListReset = "BossList not found; setting default...",
		SettingsReset = "Configuration not found; setting default...",
		SettingsUpdate = "Configuration updated!",
		SettingChange = "$V%s$C has been set to $V%s$C.",
		SettingShow = "$V%s$C is currently set to $V%s$C.",
		BossListAdd = "$V%s$C was added to the BossList with \"$V%s$C\"",
		BossListRemoved = "$V%s$C was removed from the BossList.",
		-- Dialogs
		ResetDialog = "$EWARNING!$C\nResetting CombatMusic will destroy all of your custom settings and your BossList!\nAre you sure you want to do this?\n\nThis can't be undone! $V(Clicking " .. YES .. " will reload your UI.)$C",
		BossListDialog1 = "Enter the name of the NPC you want to add to the BossList",
		BossListDialog2 = "Enter the path to the song you want CombatMusic to play every time you are in combat with this NPC",
		BossListDialogRemove = "Enter the name of the NPC you want to remove from the BossList",
		-- Misc
		Enable = "CombatMusic is $V%s$C",
		HelpHead = "CombatMusic $V" .. verString() .. "$C - Command Help:",
		Loaded = "CombatMusic $V" .. verString() .. "$C loaded successfuly. Use $V/cm help$C for command help.",
		DebugLoaded = "The addon has been loaded in debug mode.\nThis mode prints extra information to your chat window to help figure out where things aren't working. Use $V/cm debug off$C to turn it off.",
		CommString = verString() ..",%s,%s",
		-- Constants
		On = "enabled",
		Off = "disabled",
		-- Settings names
		Battles = "Battle songs",
		Bosses = "Boss songs", 
		Volume = "In-combat volume",
		Fade = "Combat FadeOut time",
		CDGameOver = "Game over cooldown",
		CDVictory = "Victory cooldown",
		ExtrasGameOver = "Game over",
		ExtrasVictory = "Victory",
		ExtrasDing = "Level Up",
		NewDing = "Seperate level up fanfare",
		UseFocus = "Prefer focus",
		Debug = "Debug mode",
		Comm = "Addon comm", 
		NewDing = "Alternate Level up fanfare",
	},
	HELP = {
		["on|off"] = "Enables, or disables CombatMusic.",
		["reset"] = "Resets CombatMusic to the default settings.",
		["battles {#|off}"] = "Sets the number of battle songs.",
		["bosses {#|off}"] = "Sets the number of boss songs.",
		["cds [gameover|victory] {#|off}"] = "Sets the duration of the cooldown.",
		["extras [gameover|victory|ding] [on|off]"] = "Enables or disables specific features.",
		["useding [on|off]"] = "Enables or disables the seperate level up fanfare.",
		["usefocus [on|off]"] = "Sets whether or not you prefer your focus target for boss checks.",
		["volume {#|off}"] = "Sets the in-combat music volume.",
		["fade {#|off}"] = "Sets how long the music will fade out for after combat.",
		["BossList {add|remove}"] = "View, add or remove entries from the BossList.",
		["comm [on|off]"] = "Enable or disable the addon's communications.",
		["debug [on|off]"] = "Enable or disable debug mode. We don't reccomend this, it's very spammy.",
	},
}

--[[
CombatMusic_Messages = {
	-- Message headers.. These get added onto a message to specify it's type.
	["DebugHeader"] = "<Debug> ",
	["ErrorHeader"] = CombatMusic_Colors.err .. "[ERROR]" .. CombatMusic_Colors.close .. " ",
	
	-- Error Messages
	["ErrorMessages"] = {
		["InvalidArg"] = CombatMusic_Colors.var .. "\"%s\"" .. CombatMusic_Colors.close .. " is an invalid argument.",
		--["NonEmpty"] = "Please enter something into the text field. The value can not be empty.",
		["NotImplemented"] = "The feature you are trying to use has not been implemented yet.",
		["Volume"] = "Music volume can only be set between the values of " .. CombatMusic_Colors.var .. "0" .. CombatMusic_Colors.close .. " and " .. CombatMusic_Colors.var .. "1" .. CombatMusic_Colors.close .. ".",
		["BiggerThan0"] = "The value you entered must be bigger than " .. CombatMusic_Colors.var .. "0" .. CombatMusic_Colors.close .. ".",
		["OnOrOff"] = "Please use " .. CombatMusic_Colors.var .. "on" .. CombatMusic_Colors.close .. " or " .. CombatMusic_Colors.var .. "off" .. CombatMusic_Colors.close .. ".",
		["NotOnList"] = "That unit wasn't found on the BossList!",
		--["AddRemoveDisplay"] = "Please use ".. CombatMusic_Colors.var .. "add" .. CombatMusic_Colors.close .. ", ".. CombatMusic_Colors.var .. "remove" .. CombatMusic_Colors.close .. ", or ".. CombatMusic_Colors.var .. "display" .. CombatMusic_Colors.close .. ".",
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
		["/cm battles [value\124off]"] = "Sets the number of \"Battles\" songs to \"value\". If value is not provided; shows the current value.",
		["/cm bosses [value\124off]"] = "Sets the number of \"Bosses\" songs to \"value\". If value is not provided; shows the current value.",
		["/cm fade [value\124off]"] = "Sets the fade timer for playing music. If value is not provided; shows the current value.",
		["/cm BossList [add\124\124remove]"] = "Allows you to add/remove entries on the BossList table. Without an argument, will print the contents to the chat frame.",
		["/cm comm [on\124off]"] = "Allows you to enable/disable responding to settings requests from other players.",
		["/cm debug [on\124off]"] = "Sets Debug mode on or off. When enabled, it will print debug messages to your chat frame.",
		["/cm reset"] = "Shows the prompt to reset your ".. CombatMusic_AddonTitle .." setings. This cannot be undone!",		
	},
	-- Other Messages
	["OtherMessages"] = {
		["AddonLoaded"] = "CombatMusic version " .. CombatMusic_Colors.var .. CombatMusic_VerStr .. " r" .. CombatMusic_Rev .. CombatMusic_Colors.close .. " successfully loaded! " .. CombatMusic_Colors.var .. "/combatmusic" .. CombatMusic_Colors.close .. " shows command help.",
		["VarsLoaded"] = "Configuration Loaded.",
		["SongListLoaded"] = "Song list loaded.",
		["LoadDefaults"] = "Configuration not set. Loading defaults...",
		["SongListDefaults"] = "Song List not found. Loading defaults...",
		["UpdateSettings"] = "Settings updated to new format. Some settings may have been lost.",
		["ResetDialog"] = CombatMusic_Colors.err .."WARNING!\n".. CombatMusic_Colors.close .. "Resetting ".. CombatMusic_AddonTitle .. " will erase all of your settings and custom bosses!\nThis cannot be undone!\n\nAre you sure you want to reset ".. CombatMusic_AddonTitle .."?\n".. CombatMusic_Colors.var .."(An interface reload is required.)" .. CombatMusic_Colors.close,
		["Enabled"] = CombatMusic_AddonTitle .. " has been " .. CombatMusic_Colors.var .. "enabled" .. CombatMusic_Colors.close .. ".",
		["Disabled"] = CombatMusic_AddonTitle .. " has been " .. CombatMusic_Colors.var .. "disabled" .. CombatMusic_Colors.close .. ".",
		["BattleCount"] = "Current number of battle songs is set to " .. CombatMusic_Colors.var .. "%s" .. CombatMusic_Colors.close .. ".",
		["BossCount"] = "Current number of boss songs is set to " .. CombatMusic_Colors.var .. "%s" .. CombatMusic_Colors.close .. ".",
		["NewBattles"] = "New battle count set to " .. CombatMusic_Colors.var .. "%s" .. CombatMusic_Colors.close .. ".",
		["NewBosses"] = "New boss count set to " .. CombatMusic_Colors.var .. "%s" .. CombatMusic_Colors.close .. ".",
		["CurMusicVol"] = "Current music volume is set to " .. CombatMusic_Colors.var .. "%s" .. CombatMusic_Colors.close .. ".",
		["SetMusicVol"] = "In combat music volume set to " .. CombatMusic_Colors.var .. "%s" .. CombatMusic_Colors.close .. ".",
		["CurrentVerHelp"] = "Version: " .. CombatMusic_Colors.var .. CombatMusic_VerStr .. " r" .. CombatMusic_Rev .. CombatMusic_Colors.close .. " - Help:",
		["FadingSet"] = "Song fadeout set to " .. CombatMusic_Colors.var .. "%s seconds" .. CombatMusic_Colors.close .. ".",
		["CurrentFade"] = "Song fadeout is set to " .. CombatMusic_Colors.var .. "%s seconds" .. CombatMusic_Colors.close .. ".",
		["FadingDisable"] = "Song fadeout disabled.",
		["BattlesOff"] = "Battle music disabled.",
		["BossesOff"] = "Boss music disabled.",
		["BossListAdd1"] = "Enter the name of the NPC you want to add to the BossList.",
		["BossListAdd2"] = "Enter the path to the song you want to play when CombatMusic finds this target.",
		["BossListRemove"] = "Enter the name of the NPC you no longer want on the BossList.",
		["BossListAdded"] = "Successfully added " .. CombatMusic_Colors.var .. "%s" ..  CombatMusic_Colors.close .. " to the BossList with the song at " .. CombatMusic_Colors.var .. "%s" ..  CombatMusic_Colors.close .. "!",
		["BossListRemoved"] = "Successfully removed " .. CombatMusic_Colors.var .. "%s" ..  CombatMusic_Colors.close .. " from the BossList!",
		["UseDump"] = "Printing " .. CombatMusic_Colors.var .. "BossList" .. CombatMusic_Colors.close .. ".",
		["AddonCommOff"] = "Addon communications for " .. CombatMusic_Colors.var .. "disabled" .. CombatMusic_Colors.close .. ". No longer replying to settings requests!",
		["AddonCommOn"] = "Addon communications for " .. CombatMusic_Colors.var .. "enabled" .. CombatMusic_Colors.close .. ". Thanks for showing your support!",
		["BossListDump"] = CombatMusic_Colors.var .. "%s" .. CombatMusic_Colors.close .. " will play "..  CombatMusic_Colors.var .. "\"%s\"" .. CombatMusic_Colors.close,
		["HelpLine"] = CombatMusic_Colors.var .. "%s " .. CombatMusic_Colors.close .. "- %s",
	},
}
]]

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
	["FadeTime"] = "fade",
	["BossList"] = "BossList",
	["Comm"] = "comm",
}
	