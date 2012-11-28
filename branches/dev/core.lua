--[[
	Project: Van32sCombatMusic
	File: core, revision @file-revision@
	Date: @file-date-iso@
	Purpose: The heart of CombatMusic.
	Credits: Code written by Vandesdelca32
	
    Copyright ©2010-2012 Vandesdelca32
]]

local E, L = unpack(select(2, ...))

-- Handle CombatMusic Loading
function  E:Handle_Load()
	if not self.Loaded then return end
	self.Loaded = true
	self:PrintMessage(L.Chat_LoadMessage)
end