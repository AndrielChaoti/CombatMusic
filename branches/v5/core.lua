--[[
-------------------------------------------------------------------------------
	Project: Van32's CombatMusic
	Author: Vandesdelca32
	Date: @file-date-iso@
	
	File: Core, r@file-revision@
	Purpose: The inner guts of the addon.
	
	
	    This file is part of CombatMusic.

    CombatMusic is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    CombatMusic is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with CombatMusic.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------
]]

-- Engine, Localization, Settings, Defaults...
local addonName = ...
local E, L, DB, DF = unpack(select(2, ...))

LibStub:GetLibrary("LibVan32-1.0"):Embed(E, "CombatMusic")

-- Start in debug mode
--@debug@
	E._DebugMode = true
--@end-debug@


function E.OnEvent(self, event, ...)
	local arg1, arg2, arg3, arg4 = ...
	
	if event == "ADDON_LOADED" and arg1 == addonName then
		DB = CombatMusic_SavedDB
	elseif event == "PLAYER_ENTERING_WORLD" and not E.LoadFinished then
		E.LoadFinished = true

-- The event initializer.
function E.Init(self)
	-- Trigger events
	
	-- The loading steps are finished here
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	-- Level up
	self:RegisterEvent("PLAYER_LEVEL_UP")
	-- Enter Combat
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	-- Leave Combat
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	-- Died
	self:RegisterEvent("PLAYER_DEAD")
	-- Invisible addon messages
	self:RegisterEvent("CHAT_MSG_ADDON")
	-- Player's target changed
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	-- Someone else's target changed
	self:RegisterEvent("UNIT_TARGET")
	-- A 'boss' frame was created or removed
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	-- Unload (Loading screen show)
	self:RegisterEvent("PLAYER_LEAVING_WORLD")
	-- There's a new party member, or someone left (for update)
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	
	-- Slash command
	SLASH_COMBATMUSIC1 = "/combatmusic"
	SLASH_COMBATMUSIC2 = "/cmusic"
	SLASH_COMBATMUSIC3 = "/cm"
	
	SlashCmdList["COMBATMUSIC"] = function(args, editBox)
		E:OnChatCommand(args)
	end
	
	-- Static Popups
end

-- Create an event listener
E.ELFrame = CreateFrame("Frame")
E.ELFrame:SetScript("OnEvent", E.HandleEvent)

-- Initialize it
E.Init(E.ELFrame)
