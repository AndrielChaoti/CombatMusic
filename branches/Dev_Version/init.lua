--[[
-------------------------------------------------------------------------------
	Project: Van32's CombatMusic, ver @project-version@
	File: init.lua; revision @file-revision@
	Date: @file-date-iso@
	Description: The functions used to initialize CombatMusic
	Author: Vandesdelca32
	
	Copyright ©2010-2012 Vandesdelca32. All rights reserved.
-------------------------------------------------------------------------------
]]

local AddOnName, Engine = ...
-- Import AceAddon-3.0
local AddOn = LibStub:GetLibrary("AceAddon-3.0"):NewAddon(AddOnName)
AddOn.DF = {}; AddOn.DF["private"] = {} -- Defaults

-- Add LibVan32-1.0
LibStub:GetLibrary("LibVan32-1.0"):Embed(AddOn, AddOnName)

local L = LibStub:GetLibrary("AceLocale-3.0"):GetLocale(AddOnName)

Engine[1] = AddOn
Engine[2] = L
Engine[3] = AddOn.DF
Engine[4] = AddOn.DF["private"]

function AddOn:OnInitialize()
	-- Check the settings
	if not CombatMusic_SavedDB then
		CombatMusic_SavedDB = {}
	end
	if not CombatMusic_PrivateDB then
		CombatMusic_PrivateDB = {}
	end
	
	-- Import the tables
	self.private = table.copy(CombatMusic_PrivateDB)
	self.config = table.copy(CombatMusic_SavedDB)
	
	-- Slash commands
	SLASH_COMBATMUSIC1 = "/combatmusic"
	SLASH_COMBATMUSIC2 = "/cm"
	
	SlashCmdList["COMBATMUSIC"] = function(msg)
		self:HandleChatCommand(msg)
	end
end

function AddOn:OnEnable()
	self:PrintMessage(L.Enabled)
end