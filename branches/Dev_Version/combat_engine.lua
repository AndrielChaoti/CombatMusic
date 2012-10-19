--[[
-------------------------------------------------------------------------------
	Project: Van32's CombatMusic, ver @project-version@
	File: combat_engine.lua; revision @file-revision@
	Date: @file-date-iso@
	Description: Module to handle the entire combat engine. (req'd)
	Author: Vandesdelca32
	
	Copyright ©2010-2012 Vandesdelca32. All rights reserved.
-------------------------------------------------------------------------------
]]

local E, L, C, P = unpack(select(2, ...)) -- E, L, C, P: Engine, Localization, Config, Private

function E:PLAYER_REGEN_ENABLED()
	self:PrintDebug("PLAYER_REGEN_ENABLED")
	StopMusic()
	return true
end

function E:PLAYER_REGEN_DISABLED()
	self:PrintDebug("PLAYER_REGEN_DISABLED")
	SetCVar("Sound_MusicVolume", "1")
	PlayMusic("Interface\Music\Battles\Battle1.mp3")
end