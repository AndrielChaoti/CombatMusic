--[[
	Project: CombatMusic
	Friendly Name: CombatMusic
	Author: Vandesdelca32

	File: init.lua
	Purpose: Addon engine init

	Version: @file-revision@


	This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	See http://creativecommons.org/licenses/by-sa/3.0/deed.en_CA for more info.
]]

-- GLOBALS: SlashCmdList, SLASH_COMBATMUSIC1, SLASH_COMBATMUSIC2, GetCVarBool, SetCVar

local addonName, engine = ...
local canonicalTitle = "CombatMusic"

local E = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0", "AceTimer-3.0")
LibStub("LibVan32-1.0"):Embed(E, canonicalTitle)

-- Set the addon's version number
E._major = "@project-version@"
E._revision = "@project-revision@"

-- Mark our defaults table and it's 'version'
local df = {
	_VER = 0.31,
	General = {
		Volume = 0.85,
		PreferFocus = true,
		CheckBoss = false,
		SongList = {},
	},
	Modules = {},
}

-- Build the engine namespace
engine[1] = E
engine[2] = LibStub("AceLocale-3.0"):GetLocale(addonName)
engine[3] = df
engine[4] = canonicalTitle
 
---Initilization handler, run before OnEnable, but after ADDON_LOADED
function E:OnInitialize()
	--[[
	-- CombatMusic Slash Command
	SLASH_COMBATMUSIC1 = "/combatmusic"
	SLASH_COMBATMUSIC2 = "/cm"


	SlashCmdList["COMBATMUSIC"] = function(...) self:DoChatCommand(...) end
	]]
end

--- Handler for addon enable.
function E:OnEnable()	
	-- Check the settings, and make sure they're all there.
	E:CheckSettingsDB()
	self:PrintMessage(E:GetVersion() .. " LOADED")

	-- This forces the user's Music volume to 0 if they have music off
	-- so that they won't notice that it was turned on.
	if not GetCVarBool("Sound_EnableMusic") then
		SetCVar("Sound_MusicVolume", "0")
	end
	SetCVar("Sound_EnableMusic", "1")

	-- Disable any modules that are marked to not load
	for name, module in self:IterateModules() do
		if not self:GetSetting("Modules", name) then
			module:Disable()
		end
	end
end

--- Handler for addon disable.
function E:OnDisable()
	-- Disable all of the modules on addon disable
	for name, module in self:IterateModules() do
		module:Disable()
	end
end


-- Put the entire addon in the global namespace.
_G[addonName] = engine