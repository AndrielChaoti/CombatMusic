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

-- GLOBALS: SlashCmdList, SLASH_COMBATMUSIC1, SLASH_COMBATMUSIC2
-- GLOBALS: GetCVarBool, SetCVar

local AddOnName, Engine = ...
local canonicalTitle = "CombatMusic"

local format, tconcat, tostringall = format, table.concat, tostringall


-----------------------
--	Library Registration
-----------------------
local AddOn = LibStub("AceAddon-3.0"):NewAddon(AddOnName, "AceEvent-3.0", "AceTimer-3.0")
LibStub("LibVan32-1.0"):Embed(AddOn, canonicalTitle)

AddOn._major = "@project-version@"
AddOn._revision = "@project-revision@"



-------------------
--	Default Settings
-------------------
AddOn.DF = {
	_VER = 1,
	Enabled = true,
	LoginMessage = true,
	General = {
		Volume = 0.85,
		UseMaster = true,
		["Fix5.3Bug"] = true,
		SongList = {}
	},
	Modules = {},
}



-----------------
--	AddOn Building
-----------------
AddOn.Options = {
	type = "group",
	name = canonicalTitle,
	args = {},
}

local Locale = LibStub("AceLocale-3.0"):GetLocale(AddOnName)

--Build the actual engine.
Engine[1] = AddOn
Engine[2] = Locale
Engine[3] = AddOn.DF

--Importing the AddOn:
--local E, L, DF = unpack(select(2, ...))

-- External imports:
--local E, L, DF = unpack(CombatMusic)

-- And expose it
_G[AddOnName] = Engine




--------------
--	Debug stuff
--------------
-- Helps with printing function arguments and names in debug messages
-- to make tracing code progress easier.
function AddOn.printFuncName(func, ...)
	local argList = tconcat({tostringall(...)}, "§r,§6 ")
	return AddOn:PrintDebug("§a" .. func .. "§f(§6" .. (argList or "") .. "§f)")
end




-----------------
--	Initialization
-----------------
--- Initialies CombatMusic
function AddOn:OnInitialize()
	-- Create the slash command
	SLASH_COMBATMUSIC1 = "/combatmusic"
	SLASH_COMBATMUSIC2 = "/cm"

	-- Build the bosslist buttons:	
	self.Options.args.General.args.BossList.args.ListGroup.args = self:GetBosslistButtons()

	SlashCmdList["COMBATMUSIC"] = function(...)
		self:ToggleOptions()
	end
	-- if the addon is disabled, DON'T LOAD IT
	if not self:GetSetting("Enabled") then
		self:SetEnabledState(false)
		for _, module in self:IterateModules() do
			module:SetEnabledState(false)
		end
	end
end

function AddOn:OnEnable()
	-- Check the settings, and make sure they're all there.
	self:CheckSettingsDB()
	local ver = self:GetVersion()
	if self:GetSetting("LoginMessage") then
		self:PrintMessage(format(Locale["AddonLoaded"], canonicalTitle, ver))
	end

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

function AddOn:OnDisable()
	-- Disable all of the modules on addon disable
	for name, module in self:IterateModules() do
		module:Disable()
	end
end