﻿--[[
-------------------------------------------------------------------------------
	Project: Van32's CombatMusic, ver @project-version@
	File: core.lua; revision @file-revision@
	Date: @file-date-iso@
	Description: The meat of the addon. Event handling and module registering.
	Author: Vandesdelca32
	
	Copyright ©2010-2012 Vandesdelca32. All rights reserved.
-------------------------------------------------------------------------------
]]

local E, L, C, P = unpack(select(2, ...)) -- E, L, C, P: Engine, Localization, Config, Private


function E:HandleChatCommand(msg)
	return false
end