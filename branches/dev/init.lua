--[[
	Project: Van32sCombatMusic
	File: init, revision @file-revision@
	Date: @file-date-iso@
	Purpose: Basic initialization
	Credits: Code written by Vandesdelca32
	
    Copyright ©2010-2012 Vandesdelca32
]]

local addonName, Engine = ...

-- Initialize the addon:
Engine[1] = {}
LibStub:GetLibrary("LibVan32-1.0"):Embed(Engine[1], addonName)
Engine[2] = LibStub:GetLibrary("AceLocale-3.0"):GetLocale(addonName)


_G[addonName] = Engine
