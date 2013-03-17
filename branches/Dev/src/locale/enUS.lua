--[[
	Project: CombatMusic
	Friendly Name: CombatMusic
	Author: Vandesdelca32

	File: enUS.lua
	Purpose: enUS locale

	Version: @file-revision@


	This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	See http://creativecommons.org/licenses/by-sa/3.0/deed.en_CA for more info.
]]

local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)

if L then
	L["AddonLoaded"] = "%s §6%s§r loaded successfully. Type §6/combatmusic§r to access options"
	L["ConfigLoadError"] = "Your configuration couldn't be loaded. Is this the first time you're running the addon? Using defaults."
	L["ConfigOutOfDate"] = "Your configuration is outdated, loading the default config."
	L["Can't do that in combat."] = true
	
	
	-----------
	--	Settings
	-----------
	
	L["Enabled"] = true
	L["Volume"] = "Music Volume"
	L["PreferFocus"] = "Check 'focustarget' first"
	L["LoginMessage"] = "Login Message"
	L["CheckBoss"] = "Check 'bossx' units"
	L["NumSongs"] = "Song Counts"
	L["FadeTimer"] = "Song Fadeout"
	L["SongTypeBattles"] = "Battles"
	L["SongTypeBosses"] = "Bosses"
	L["Count"] = true
	L["CombatEngine"] = "Combat"
	L["UseMaster"] = "Use Master Channel"
	L["BossOnly"] = "Boss fight only"
	L["FanfareEnable"] = "Play Fanfare on..."
	L["GameOverEnable"] = "Play Game Over on..."
	L["RestoreDefaults"] = "Restore Defaults"
	L["UseDing"] = "Use 'DING' instead of 'Victory' for levelling up"
	L["MiscFeatures"] = "Miscellaneous features"

	L["Desc_RestoreDefaults"] = "Restore all settings to their defaults."
	L["Confirm_RestoreDefaults"] = "Are you sure you want to reset all of your settings and Boss Lists?"
	L["Confirm_Reload"] = "You need to reload your UI for this change to take effect."
	L["Desc_FadeTimer"] = "The time in seconds that the music will spend fading out. 0 to disable."
	L["Desc_UseMaster"] = "Use the master audio channel to play fanfares."
	L["Desc_Count"] = "Number of songs."
	L["Desc_PreferFocus"] = "Check your focus' target first in unit checking."
	L["Desc_CheckBoss"] = "Check 'bossx' unitIDs, as well as target and focustarget."
	L["Desc_Enabled"] = "Enable/Disable the addon or module."
	L["Desc_FanfareEnable"] = "Play fanfares on the following event:"
	L["Desc_GameOverEnable"] = "Play GameOver when you die."
	L["Desc_UseDing"] = "Use 'DING.mp3' instead of 'Victory.mp3' when you level up."
end
