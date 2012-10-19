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
local AddOn = LibStub:GetLibrary("AceAddon-3.0"):NewAddon(AddOnName, "AceEvent-3.0")
AddOn.DF = {}; AddOn.DF["private"] = {} -- Defaults

-- Add LibVan32-1.0
LibStub:GetLibrary("LibVan32-1.0"):Embed(AddOn, AddOnName)

--@alpha@
AddOn._DebugMode = true
--@end-alpha@

local L = LibStub:GetLibrary("AceLocale-3.0"):GetLocale(AddOnName)

Engine[1] = AddOn
Engine[2] = L
Engine[3] = AddOn.DF
Engine[4] = AddOn.DF["private"]

-- table.copy
local table = table
function table.copy(t, deep, seen)
    seen = seen or {}
    if t == nil then return nil end
    if seen[t] then return seen[t] end

    local nt = {}
    for k, v in pairs(t) do
        if deep and type(v) == 'table' then
            nt[k] = table.copy(v, deep, seen)
        else
            nt[k] = v
        end
    end
    setmetatable(nt, table.copy(getmetatable(t), deep, seen))
    seen[t] = nt
    return nt
end

-- OnInitialize: Handles all of the addon's loading processes.
function AddOn:OnInitialize()
	-- Check the settings
	if not CombatMusic_SavedDB then
		CombatMusic_SavedDB = {}
	end
	if not CombatMusic_PrivateDB then
		CombatMusic_PrivateDB = {}
	end
	
	-- Import the tables
	self.private = table.copy(CombatMusic_PrivateDB, true)
	self.config = table.copy(CombatMusic_SavedDB, true)
	
	-- Slash commands
	SLASH_COMBATMUSIC1 = "/combatmusic"
	SLASH_COMBATMUSIC2 = "/cm"
	
	SlashCmdList["COMBATMUSIC"] = function(msg)
		self:HandleChatCommand(msg)
	end
end

function AddOn:OnEnable()
	self:PrintMessage(L.Enabled)
	self.loaded = true
	
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function AddOn:OnDisable()
	self:UnregisterAllEvents()
end

_G[AddOnName] = Engine