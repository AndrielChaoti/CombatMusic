--[[
------------------------------------------------------------------------
	Project: Van32sCombatMusic
	File: Reusable Functions, revision @file-revision@
	Date: @file-date-iso@
	Purpose: The reusable, essential functions that any addon needs.
	Credits: Code written by Vandesdelca32

    Copyright (C) 2011  Vandesdelca32

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
------------------------------------------------------------------------
]]


local addonName, _ = ...

local CombatMusic = LibStub:GetLibrary("LibVan32-1.0")

--@alpha@ 
CombatMusic:EnableDebugMode()
--@end-alpha@

--[===[@non-alpha@ 
CombatMusic:DisableDebugMode()
--@end-non-alpha@]===]

local currentSVVersion = "2"
local L = CM_STRINGS


--debugNils: Returns literal "nil" or the tostring of all of the arguments passed to it.
local function debugNils(...)
	local tmp = {}
	for i = 1, select("#", ...) do
		tmp[i] = tostring(select(i, ...)) or "nil"
	end
	return table.concat(tmp, ", ")
end


-- cmPrint: A call into my library PrintMessage method
local function cmPrint(message, isError, isDebug)
	CombatMusic:PrintMessage("CombatMusic", message, isError, isDebug)
end

-------------------------]]

-- CM_CheckSettingsLoaded: Check to make sure the settings loaded properly
local function CM_CheckSettingsLoaded()
	cmPrint("CheckSettingsLoaded()", false, true)
	
	-- Set a couple of flags
	local main, list, char = true, true, true
	
	-- Check the settings table
	if not CombatMusic_SavedDB then
		CM_SetDefaults(nil, "global")
		main = nil
	elseif CombatMusic_SavedDB.SVVersion ~= currentSVVersion then 
		CM_SetDefaults(true, "global")
		main = nil
	end
	
	-- Check the BossList
	if not CombatMusic_BossList then
		CombatMusic_BossList = {}
		cmPrint(L.OTHER.BossListReset)
		list = nil
	end
	
	-- Check the per-character
	if not CombatMusic_SavedDBPerChar then
		CM_SetDefaults(nil, "perchar")
		char = nil
	elseif CombatMusic_SavedDBPerChar ~= currentSVVersion then
		CM_SetDefaults(true, "perchar")
		char = nil
	end
	
	-- Check the flags, and let the user know:
	if main and char then	
		cmPrint(L.OTHER.SettingsLoaded)
	end
	if list then
		cmPrint(L.OTHER.BossListLoaded)
	end
end


-- CM_SetDefaults: Load the default settings
local function CM_SetDefaults(outOfDate, restoreMode)
	cmPrint("SetDefaults($V" .. debugNils(outOfDate) .. "$C)", false, true)
	-- For an old settings reference, see 'settingsHistory.lua'
	
	if restoreMode = "global" then
		-- Try to restore the user's settings, or set defaults for missing ones:
		if outOfDate and CombatMusic_SavedDB.SVVersion == "1" then
			local tempDB = {
				["SVVersion"] = currentSVVersion,
				["Enabled"] = CombatMusic_SavedDB.Enabled or true,
				["Music"] = {
					["Enabled"] = true,
					["numSongs"] = CombatMusic_SavedDB.numSongs or {["Battles"] = -1, ["Bosses"] = -1},
					["Volume"] = CombatMusic_SavedDB.MusicVolume or 0.85,
					["FadeOut"] = CombatMusic_SavedDB.FadeTime or 5,
				}, 
				["GameOver"] = {
					["Enabled"] = CombatMusic_SavedDB.PlayWhen.GameOver or true,
					["Cooldown"] = CombatMusic_SavedDB.timeOuts.GameOver or 30,
				},
				["Victory"] = {
					["Enabled"] = CombatMusic_SavedDB.PlayWhen.CombatFanfare or true,
					["Cooldown"] = CombatMusic_SavedDB.timeOuts.Fanfare or 30,
				},
				["LevelUp"] = {
					["Enabled"] = CombatMusic_SavedDB.PlayWhen.LevelUp or true, 
					["NewFanfare"] = false,
				},
				["AllowComm"] = true,
			}

			CombatMusic_SavedDB = tempDB
			cmPrint(L.OTHER.SettingsUpdate)
		else
			-- Load the default settings
			CombatMusic_SavedDB = {
				["SVVersion"] = currentSVVersion,
				["Enabled"] = true,
				["Music"] = {
					["Enabled"] = true,
					["numSongs"] = {
						["Battles"] = -1,
						["Bosses"] = -1,
					},
					["Volume"] = 0.85,
					["FadeOut"] = 5,
				},
				["GameOver"] = {
					["Enabled"] = true,
					["Cooldown"] = 30,
				},
				["Victory"] = {
					["Enabled"] = true,
					["Cooldown"] = 30,
				},
				["LevelUp"] = {
					["Enabled"] = true,
					["NewFanfare"] = false,
				},
				["AllowComm"] = true,
			}
			cmPrint(L.OTHER.SettingsReset)
		end
	elseif restoreMode = "perchar" then
		CombatMusic_SavedDBPerChar = {
			["SVVersion"] = currentSVVersion,
			["PreferFocusTarget"] = false
		}
	else
		return
	end
end


-- CM_CheckBossList: Adds an NPC to the BossList
local function CM_CheckBossList(self, dialogNo, data, data2)
	cmPrint("CheckBossList()", false, true)
	if dialogNo == 1 then
		local UnitName = self.editBox:GetText()
		self:Hide()
		local dlg2 = StaticPopup_Show("COMBATMUSIC_BossListADD2")
		if dlg2 then
			dlg2.data = {
				Name = UnitName
			}
		end
	elseif dialogNo == 2 then
		local SongPath = self.editBox:GetText()
		CombatMusic_BossList[data.Name] = SongPath
		cmPrint(format(L.OTHER.BossListAdd, data.Name, SongPath))
		self:Hide()
	end
end


-- CM_RemoveBossList: Removes an NPC from the BossList
local function CM_RemoveBossList(self)
	cmPrint("RemoveBossList()", false, true)
	local unit = self.editBox:GetText()
	-- Check the BossList
	if CombatMusic_BossList[unit] then
		CombatMusic_BossList[unit] = nil
		cmPrint(format(L.OTHER.BossListRemoved, unit))
		self:Hide()
	else
		cmPrint(format(L.ERRORS.BossListNotFound, unit), true)
	end
end


-- CM_DumpBossList: Prints all of the BossList entries
local function CM_DumpBossList()
	for k, v in pairs(CombatMusic_BossList) do
		cmPrint(format("$V%s$C will play \"$V%s$C\"", k, v))
	end
end


-- CM_PrintHelp: Prints the Help text
local function CM_PrintHelp()
	cmPrint(L.OTHER.HelpHead)
	for k, v in pairs(L.HELP) do
		cmPrint(format("$V%s%C - %s", k, v))
	end
end


-- CM_SlashHandler: Handles the console commands
local function CM_SlashHandler(args)
	cmPrint("SlashHandler($V" .. debugNils(args) .. "$C)", false, true)
	--We don't want to throw errors because of case-sensitive commands
	--so make the arguments string all lowercase to match!
	args = args:lower()

	-- Split it up into the arguments.
	local command, arg1, arg2 = args:split(" ", 3);

	-- /cm {?/help}
	---------------
	if not command or command == "" or command == "?" or command == "help" then
		CM_PrintHelp()
	
	-- /cm on
	---------
	elseif command == "on" then
		-- Turn on CombatMusic
		CombatMusic_SavedDB.Enabled = true
		cmPrint(format(L.OTHER.Enable, L.OTHER.On))
		
	-- /cm off
	----------
	elseif command == "off" then
		-- Turn off CombatMusic
		CombatMusic.leaveCombat(true)
		CombatMusic_SavedDB.Enabled = false
		cmPrint(format(L.OTHER.Enable, L.OTHER.Off))
	
	-- /cm reset
	------------
	elseif command == "reset" then
		-- Ask the user if they want to reset thier settings
		StaticPopup_Show("COMBATMUSIC_RESET")
		
	-- /cm battles {#|off}
	----------------------
	elseif command == "battles" then
		-- If it's passed with no argument, then show
		if not tonumber(arg1) and arg1 ~= "off" then
			cmPrint(format(L.OTHER.SettingShow, L.OTHER.Battles, CombatMusic_SavedDB.Music.numSongs.Battles))
		else
			if arg1 == "off" then
				cmPrint(format(L.OTHER.SettingChange, L.OTHER.Battles, L.OTHER.Off))
				CombatMusic_SavedDB.Music.numSongs.Battles = -1
			elseif tonumber(arg1) <= 0 then
				cmPrint(L.ERRORS.BiggerThan0, true)
			else
				cmPrint(format(L.OTHER.SettingChange, L.OTHER.Battles, tonumber(arg1)))
				CombatMusic_SavedDB.Music.numSongs.Battles = tonumber(arg1)
			end
		end

	-- /cm bosses {#|off}
	---------------------
	elseif command == "bosses" then
		-- If it's passed with no argument, then show
		if not tonumber(arg1) and arg1 ~= "off" then
			cmPrint(format(L.OTHER.SettingShow, L.OTHER.Bosses, CombatMusic_SavedDB.Music.numSongs.Bosses))
		else
			if arg1 == "off" then
				cmPrint(format(L.OTHER.SettingChange, L.OTHER.Bosses, L.OTHER.Off))
				CombatMusic_SavedDB.Music.numSongs.Bosses = -1
			elseif tonumber(arg1) <= 0 then
				cmPrint(L.ERRORS.BiggerThan0, true)
			else
				cmPrint(format(L.OTHER.SettingChange, L.OTHER.Bosses, tonumber(arg1)))
				CombatMusic_SavedDB.Music.numSongs.Bosses = tonumber(arg1)
			end
		end
	
	-- /cm [cooldowns|cds] [gameover|victory] {#|off}
	-------------------------------------------------
	elseif command == "cooldowns" or command == "cds" then
		-- /cm cooldowns gameover [on|off]
		if arg1 == "gameover" or arg1 == "go" then
			if not tonumber(arg2) and arg2 ~= "off" then
				cmPrint(format(L.OTHER.SettingShow, L.OTHER.CDGameOver, CombatMusic_SavedDB.GameOver.Cooldown))
			else
				if arg2 == "off" then
					cmPrint(format(L.OTHER.SettingChange, L.OTHER.CDGameOver, L.OTHER.Off))
					CombatMusic_SavedDB.GameOver.Cooldown = 0
				elseif tonumber(arg2) <= 0 then
					cmPrint(L.ERRORS.BiggerThan0, true)
				else
					cmPrint(format(L.OTHER.SettingChange, L.OTHER.CDGameOver, tonumber(arg2)))
					CombatMusic_SavedDB.GameOver.Cooldown = tonumber(arg2)
				end
			end
		-- cm cooldowns victory [on|off]
		elseif arg1 == "victory" or arg1 == "vic" then
			if not tonumber(arg2) and arg2 ~= "off" then
				cmPrint(format(L.OTHER.SettingShow, L.OTHER.CDVictory, CombatMusic_SavedDB.Victory.Cooldown))
			else
				if arg2 == "off" then
					cmPrint(format(L.OTHER.SettingChange, L.OTHER.CDVictory, L.OTHER.Off))
					CombatMusic_SavedDB.Victory.Cooldown = 0
				elseif tonumber(arg2) <= 0 then
					cmPrint(L.ERRORS.BiggerThan0, true)
				else
					cmPrint(format(L.OTHER.SettingChange, L.OTHER.CDVictory, tonumber(arg2)))
					CombatMusic_SavedDB.Victory.Cooldown = tonumber(arg2)
				end
			end
		else
			cmPrint(L.ERRORS.InvalidArgumentCD, true)
		end
	
	-- /cm extras [gameover|victory|ding] {on|off}
	----------------------------------------------
	elseif command == "extras" then
		-- /cm extras gameover [on|off]
		if arg1 == "gameover" or arg1 == "go" then
			if arg2 == "on" then
				cmPrint(format(L.OTHER.SettingChange, L.OTHER.ExtrasGameOver, L.OTHER.On))
				CombatMusic_SavedDB.GameOver.Enabled = true
			elseif arg2 == "off" then
				cmPrint(format(L.OTHER.SettingChange, L.OTHER.ExtrasGameOver, L.OTHER.Off))
				CombatMusic_SavedDB.GameOver.Enabled = false
			else
				cmPrint(L.ERRORS.OnOrOff, true)
			end
		-- /cm extras victory [on|off]
		elseif arg1 == "victory" or arg1 == "vic" then
			if arg2 == "on" then
				cmPrint(format(L.OTHER.SettingChange, L.OTHER.ExtrasVictory, L.OTHER.On))
				CombatMusic_SavedDB.Victory.Enabled = true
			elseif arg2 == "off" then
				cmPrint(format(L.OTHER.SettingChange, L.OTHER.ExtrasVictory, L.OTHER.Off))
				CombatMusic_SavedDB.Victory.Enabled = false
			else
				cmPrint(L.ERRORS.OnOrOff, true)
			end
		-- /cm extras ding [on|off]
		elseif arg1 == "ding" then
			if arg2 == "on" then
				cmPrint(format(L.OTHER.SettingChange, L.OTHER.ExtrasDing, L.OTHER.On))
				CombatMusic_SavedDB.LevelUp.Enabled = true
			elseif arg2 == "off" then
				cmPrint(format(L.OTHER.SettingChange, L.OTHER.ExtrasDing, L.OTHER.Off))
				CombatMusic_SavedDB.LevelUp.Enabled = false
			else
				cmPrint(L.ERRORS.OnOrOff, true)
			end
		else
			cmPrint(L.ERRORS.InvalidArgumentE, true)
		end
	
	-- /cm useding [on|off]
	--------------------------
	elseif command == "useding" then
		if arg1 == "on" then
			cmPrint(format(L.OTHER.SettingChange, L.OTHER.NewDing, L.OTHER.On))
			CombatMusic_SavedDB.LevelUp.NewFanfare = true
		elseif arg1 == "off" then
			cmPrint(format(L.OTHER.SettingChange, L.OTHER.NewDing, L.Other.Off))
			CombatMusic_SavedDB.LevelUp.NewFanfare = false
		else
			cmPrint(L.ERRORS.OnOrOff, true)
		end
	
	
	-- /cm usefocus [on|off]
	------------------------
	elseif command == "usefocus" then
		if arg1 == "on" then
			cmPrint(format(L.OTHER.SettingChange, L.OTHER.UseFocus, L.OTHER.On))
			CombatMusic_SavedDBPerChar.PreferFocusTarget = true
		elseif arg1 == "off" then
			cmPrint(format(L.OTHER.SettingChange, L.OTHER.UseFocus, L.OTHER.Off))
			CombatMusic_SavedDBPerChar.PreferFocusTarget = false
		else
			cmPrint(L.ERRORS.OnOrOff, true)
		end
	
	-- /cm volume {#}
	-----------------
	elseif command == "volume" then
		-- Change the in-combat volume settings:
		if not tonumber(arg1) then
			-- Output the current setting
			cmPrint(format(L.OTHER.SettingShow, L.OTHER.Volume, CombatMusic_SavedDB.Music.Volume))
		else
			if tonumber(arg1) <= 0 or tonumber(arg1) > 1 then
				cmPrint(L.ERRORS.Between0And1, true)
			else
				cmPrint(format(L.OTHER.SettingChange, L.OTHER.Volume, tonumber(arg1)))
				CombatMusic_SavedDB.Music.Volume = tonumber(arg1)
			end
		end
	
	-- /cm fade {#|off}
	-------------------
	elseif command == "fade" then
		-- If it's passed with an invalid argument, show the value instead
		if not tonumber(arg1) and arg1 ~= "off" then
			cmPrint(format(L.OTHER.SettingShow, L.OTHER.Fade, CombatMusic_SavedDB.Music.FadeOut))
		else
			if arg1 == "off" then
				cmPrint(format(L.OTHER.SettingsChange, L.OTHER.Fade, L.OTHER.Off))
				CombatMusic_SavedDB.Music.FadeOut = 0
			elseif arg1 <= 0 then
				cmPrint(L.ERRORS.BiggerThan0, true)
			else
				CombatMusic_SavedDB.Music.FadeOut = tonumber(arg1)
				cmPrint(format(L.OTHER.SettingsChange, L.OTHER.Fade, arg1))
			end
		end
		
	-- /cm BossList {add|remove}
	----------------------------
	elseif command == "bosslist" then
		if arg1 == "add" then
			local dlg = StaticPopup_Show("COMBATMUSIC_BOSSLISTADD")
			if dlg then
				dlg.data = { CurTarget = UnitName('target') }
			end
		elseif arg1 == "remove" then
			local dlg = StaticPopup_Show("COMBATMUSIC_BOSSLISTREMOVE")
		else
			DumpBossList()
		end

	-- /cm debug [on|off]
	---------------------
	elseif command == "debug" then
		if arg == "on" then
			cmPrint(format(L.OTHERS.SettingChange, L.OTHER.Debug, L.OTHER.On))
			CombatMusic:EnableDebugMode()
		elseif arg == "off" then
			cmPrint(format(L.OTHER.SettingChange, L.OTHER.Debug, L.OTHER.Off))
			CombatMusic:DisableDebugMode()
		else
			cmPrint(L.ERRORS.OnOrOff, true)
		end
		
	-- /cm comm [on|off]
	--------------------
	elseif command == "comm" then
		if arg == "on" then
			cmPrint(foramt(L.OTHER.SettingChange, L.OTHER.Comm, L.OTHER.On))
			CombatMusic_SavedDB.AllowComm = true
		elseif arg == "off" then
			cmPrint(foramt(L.OTHER.SettingChange, L.OTHER.Comm, L.OTHER.Off))
			CombatMusic_SavedDB.AllowComm = false
		end
	else
		cmPrint(L.ERRORS.InvalidCommand, true)	
	end
end


-- CombatMusic_OnEvent: Handles events fired by the WoW client
function CombatMusic_OnEvent(self, event, ...)
	local arg1, arg2 = ...
	-- PLAYER_ENTERING_WORLD: Finishing the loading sequence
	if event == "PLAYER_ENTERING_WORLD" and not CombatMusic.Info.Loaded then
		cmPrint(L.OTHER.Loaded)
		cmPrint(L.OTHER.DebugLoaded, false, true)
		CombatMusic:SetTimer(2, function()
				CheckSettingsLoaded()
				CombatMusic["Info"]["Loaded"] = true
			end
		)
		return
	
	-- PLAYER_LEVEL_UP: Plays the Ding song
	elseif event == "PLAYER_LEVEL_UP" then
		CombatMusic.LevelUp()
		return
		
	-- PLAYER_REGEN_DISABLED: Entering Combat
	elseif event == "PLAYER_REGEN_DISABLED" then
		CombatMusic.enterCombat()
		return
		
	-- PLAYER_REGEN_ENABLED: Leaving Combat
	elseif event == "PLAYER_REGEN_ENABLED" then
		CombatMusic.leaveCombat()
		return
	
	-- PLAYER_DEAD: <==
	elseif event == "PLAYER_DEAD" then
		CombatMusic.GameOver()
		return
	
	-- PLAYER_TARGET_CHANGED: <==
	elseif event == "PLAYER_TARGET_CHANGED" then
		CombatMusic.TargetChanged("player")
		return
		
	-- UNIT_TARGET: FocusTarget changed
	elseif event == "UNIT_TARGET" and arg1 = "focus" then
		CombatMusic.TargetChanged("focus")
		return
	
	-- PLAYER_LEAVING_WORLD: Used to stop the music for loading screens
	elseif event == "PLAYER_LEAVING_WORLD" then
		CombatMusic.leaveCombat(true)
		return
	
	-- CHAT_MSG_ADDON: Settings Suvey Comm
	elseif event == "CHAT_MSG_ADDON" then
		CombatMusic.CheckComm()
		return
	end
end


-- CombatMusic_OnLoad: OnLoad handler for the addon
function CombatMusic_OnLoad(self)

	-- Trigger events
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("PLAYER_LEAVING_WORLD")

	-- Slash Command listings
	SLASH_COMBATMUSIC_MAIN1 = "/combatmusic"
	SLASH_COMBATMUSIC_MAIN2 = "/combat"
	SLASH_COMBATMUSIC_MAIN3 = "/cm"

	RegisterAddonMessagePrefix("CM3")
	
	SlashCmdList["COMBATMUSIC_MAIN"] = function(args)
		CM_SlashHandler(args)
	end

	-- Static Popup for reset
	StaticPopupDialogs["COMBATMUSIC_RESET"] = {
		text = L.OTHER.ResetDialog,
		button1 = YES,
		button2 = NO,
		OnAccept = function()
			CM_SetDefaults()
			ReloadUI()
		end,
		whileDead = true,
		timeout = 0,
		hideOnEscape = true,
		showAlert = true,
	}
	
	-- Popups for BossList add
	StaticPopupDialogs["COMBATMUIC_BOSSLISTADD"] = {
		text = L.OTHER.BossListDialog1,
		button1 = OKAY,
		button2 = CANCEL,
		hasEditBox = true,
		maxLetters = 128, 
		editBoxWidth = 250,
		OnShow = function(self)
			self.editBox:SetText(UnitName('target') or "")
		end,
		OnAccept = function(self)
			if not self.button1:IsEnabled() then
				return
			end
			CM_CheckBossList(self, 1)
		end,
		EditBoxOnEnterPressed = function(self)
			if not self:GetParent().button1:IsEnabled() then
				return
			end
			CM_CheckBossList(self:GetParent(), 1)
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		EditBoxOnTextChanged = function(self)
			if self:GetText() == "" or self:GetText() == nil then
				self:GetParent().button1:Disable()
			else
				self:GetParent().button1:Enable()
			end
		end,
		whileDead = true,
		hideOnEscape = true,
		timeout = 0,
	}
	
	StaticPopupDialogs["COMBATMUSIC_BOSSLISTADD2"] = {
		text= L.OTHER.BossListDialog2,
		button1 = OKAY,
		button2 = CANCEL,
		hasEditBox = true,
		editBoxWidth = 350,
		OnShow = function(self, data)
			self.editBox:SetText("Interface\\Music\\")
		end,
		OnAccept = function(self, data)
			if not self.button1:IsEnabled() then
				return
			end
			CM_CheckBossList(self, 2, data)
		end,
		EditBoxOnEnterPressed = function(self, data)
			if not self:GetParent().button1:IsEnabled() then
				return
			end
			CM_CheckBossList(self:GetParent(), 2, data)
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		EditBoxOnTextChanged = function(self)
			local text = self:GetText()
			local ext = strmatch(text, ".+(%.mp3)")
			if ext == ".mp3" then
				self:GetParent().button1:Enable()
			else
				self:GetParent().button1:Disable()
			end
		end,
		whileDead = true,
		hideOnEscape = true,
		timeout = 0,
	}
	
	-- Popup for BossList remove
	StaticPopupDialogs["COMBATMUSIC_BOSSLISTREMOVE"] = {
		text = L.OTHER.BossListDialogRemove,
		button1 = OKAY,
		button2 = CANCEL,
		hasEditBox = true,
		maxLetters = 128, 
		editBoxWidth = 250,
		OnShow = function(self)

			self.editBox:SetText(UnitName('target') or "")
		end,
		OnAccept = function(self)
		if not self:GetParent().button1:IsEnabled() then
				return
			end
			CM_RemoveBossList(self)
		end,
		EditBoxOnEnterPressed = function(self)
			if not self:GetParent().button1:IsEnabled() then
				return
			end
			CM_RemoveBossList(self:GetParent())
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		EditBoxOnTextChanged = function(self)
			if self:GetText() == "" or self:GetText() == nil then
				self:GetParent().button1:Disable()
			else
				self:GetParent().button1:Enable()
			end
		end,
		whileDead = true,
		hideOnEscape = true,
		timeout = 0,
	}
end