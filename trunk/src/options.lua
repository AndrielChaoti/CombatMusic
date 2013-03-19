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

-- GLOBALS: CombatMusicDB, InCombatLockdown, ReloadUI

--Import Engine, Locale, Defaults, CanonicalTitle
local AddOnName = ...
local E, L, DF = unpack(select(2, ...))
local DEFAULT_WIDTH = 785
local DEFAULT_HEIGHT = 500
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
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
	ACD:Open(AddOnName)
end



----------------
--	Options Table
----------------

E.Options.args = {
	Enabled = {
		name = L["Enabled"],
		desc = L["Desc_Enabled"],
		type = "toggle",
		confirm = true,
		confirmText = L["Confirm_Reload"],
		get = function(info) return E:GetSetting("Enabled") end,
		set = function(info, val) CombatMusicDB.Enabled = val; if val then E:Enable(); else E:Disable(); end; ReloadUI(); end,
	},
	LoginMessage = {
		name = L["LoginMessage"],
		type = "toggle",
		get = function(info) return E:GetSetting("LoginMessage") end,
		set = function(info, val) CombatMusicDB.LoginMessage = val end,
		order = 110,
	},
	RestoreDefaults = {
		name = L["RestoreDefaults"],
		desc = L["Desc_RestoreDefaults"],
		type = "execute",
		confirm = true,
		confirmText = L["Confirm_RestoreDefaults"],
		func = function() CombatMusicDB = DF; ACR:NotifyChange(AddOnName); end,
		order = 120,
	},
	--@alpha@
	DebugMode = {
		name = "Debug Mode",
		type = "toggle",
		set = function(info,val) E._DebugMode = val end,
		get = function(info) return E._DebugMode end,
	},
	--@end-alpha@
	General = {
		name = "General",
		type = "group",
		get = function(info) return E:GetSetting("General", info[#info]) end,
		set = function(info, val) CombatMusicDB.General[info[#info]] = val end,
		args = {
			UseMaster = {
				name = L["UseMaster"],
				desc = L["Desc_UseMaster"],
				type = "toggle",
			},
			Volume = {
				name = L["Volume"],
				--desc = L["Desc_Volume"],
				type = "range",
				width = "double",
				min = 0.01,
				max = 1,
				step = 0.001,
				bigStep = 0.01,
				isPercent = true,
				order = 200,
			},
			SongList = {
				name = L["NumSongs"],
				--desc = L["Desc_NumSongs"],
				type = "group",
				inline = true,
				order = 400,
				args = {} -- This will be filled in by our :RegisterSongType 
			}
		}
	}
}