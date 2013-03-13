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
	L["Test"] = "Test"
	L["ChatErr_SettingsNotFound"] = "Your configuration couldn't be loaded, perhaps this is your first run? Loading default config."
	L["ChatErr_SettingsOutOfDate"] = "Your configuration is outdated, loading the default config."
end
