--[[
  Project: CombatMusic
  Friendly Name: CombatMusic
  Author: Vandesdelca32

  File: options.lua
  Purpose: All of the options that come with the standard kit.

  Version: @file-revision@


  This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
  See http://creativecommons.org/licenses/by-sa/3.0/deed.en_CA for more info.
  ]]

-- GLOBALS: CombatMusicDB, InCombatLockdown

--Import Engine, Locale, Defaults, CanonicalTitle
local AddOnName = ...
local E, L, DF, CT = unpack(select(2, ...))
local DEFAULT_WIDTH = 890;
local DEFAULT_HEIGHT = 651;
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
AC:RegisterOptionsTable(AddOnName, E.Options)
ACD:SetDefaultSize(AddOnName, DEFAULT_WIDTH, DEFAULT_HEIGHT)


local tinsert, unpack, ipairs = table.insert, unpack, ipairs
local printFuncName = E.printFuncName

function E:ToggleOptions()
	printFuncName("ToggleOptions")
	if InCombatLockdown() then
		self:PrintErr(L["Can't do that in combat."])
		return
	end
	if E.ShowingOptions then
		ACD:Close(AddOnName)
		E.ShowingOptions = false
	else
		ACD:Open(AddOnName)
		E.ShowingOptions = true
	end
end


-------------------
--	Default Settings
-------------------
E.DF = {
	_VER = 0.4,
	Enabled = true,
	LoginMessage = true,
	General = {
		PreferFocus = false,
		CheckBoss = true,
		Volume = 0.85,
		NumSongs = {}
	},
	Modules = {},
}


----------------
--	Options Table
----------------

E.Options.args = {
	Enabled = {
		name = L["Enabled"],
		desc = L["Desc_Enabled"],
		type = "toggle",
		get = function(info) return E:GetSetting("Enabled") end,
		set = function(info, val) CombatMusicDB.Enabled = val end,
	},
	LoginMessage = {
		name = L["LoginMessage"],
		type = "toggle",
		get = function(info) return E:GetSetting("LoginMessage") end,
		set = function(info, val) CombatMusicDB.LoginMessage = val end,
	},
	General = {
		name = "General",
		type = "Group",
		get = function(info) return E:GetSetting("General", info[#info]) end,
		set = function(info, val) CombatMusicDB.General[info[#info]] = val end,
		args = {
			PreferFocs = {
				name = L["PreferFocs"],
				desc = L["Desc_PreferFocs"],
				type = "toggle",
			},
			CheckBoss = {
				name = L["CheckBoss"],
				desc = L["Desc_CheckBoss"],
				type = "toggle",
			},
			Volume = {
				name = L["Volume"],
				desc = L["Desc_Volume"],
				type = "range",
				min = 0.01,
				max = 1,
				step = 0.001,
				bigStep = 0.01,
				isPercent = true,
			},
			NumSongs = {
				name = L["NumSongs"],
				desc = L["Desc_NumSongs"],
				type = "group",
				inline = true,
				args = {} -- This will be filled in by our :RegisterSongType 
			},
		},
	}
}