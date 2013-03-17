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

	L["Enabled"] = true
	L["LoginMessage"] = "Login Message"
	L["Desc_Enabled"] = "Enable/Disable the addon or module."
end
