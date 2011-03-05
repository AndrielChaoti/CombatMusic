--[[
------------------------------------------------------------------------
	Project: Van32sCombatMusic
	File: Reusable Functions, revision @file-revision@
	Date: @project-date-iso@
	Purpose: The reusable, essential functions that any addon needs.
	Credits: Code written by Vandesdelca32

	Copyright (c) 2010 Vandesdelca32

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

------------------------------------------------------------------------
]]

local addonName, _ = ...

CombatMusic = {}
--@alpha@ 
CombatMusic_DebugMode = true
--@end-alpha@

--[===[@non-alpha@ 
CombatMusic_DebugMode = false
--@end-non-alpha@]===]

local currentSVVersion = "1"

-- Your standard print message function
function CombatMusic.PrintMessage(message, isError, DEBUG)
	-- The typical args check
	local DCF = DEFAULT_CHAT_FRAME
	assert(DCF, "Cannot find DEFAULT_CHAT_FRAME.")

	if message == "" then message = nil end
	assert(message, "Usage. PrintMessage(message[, isError[, DEBUG]])")

	outMessage = CombatMusic_Colors.title .. CombatMusic_AddonTitle .. CombatMusic_Colors.close .. ": "

	if DEBUG and CombatMusic_DebugMode then
		--DCF:Clear()
		outMessage = outMessage .. CombatMusic_Messages.DebugHeader
	elseif DEBUG and not DebugMode then
		return
	end

	if isError then
		outMessage = outMessage .. CombatMusic_Messages.ErrorHeader
	end

	outMessage = outMessage .. message

	DCF:AddMessage(outMessage)
end

-- Check that settings are loaded properly, and are up to date
function CombatMusic.CheckSettingsLoaded()
	local x1 = 1
	local x2 = 1
	
	if not CombatMusic_SavedDB then
		CombatMusic.SetDefaults()
		x1 = nil
	elseif CombatMusic_SavedDB.SVVersion ~= currentSVVersion then
		CombatMusic.SetDefaults(1)
		x1 = nil
	end
	
	if not CombatMusic_BossList then
		CombatMusic_BossList = {}
		CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.SongListDefaults)
		x2 = nil
	end
	
	-- Spamcheck, if they're not 1 then don't spam
	if x1 then
		CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.VarsLoaded)
	end
	if x2 then
		CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.SongListLoaded)
	end
end

-- Sets the CombatMusic settings to default values
function CombatMusic.SetDefaults(outOfDate)

	-- Load the default settings for CombatMusic
	CombatMusic_SavedDB = {
		["SVVersion"] = currentSVVersion,
		["Enabled"] = true, 
		["PlayWhen"] = {
			["LevelUp"] = true,
			["CombatFanfare"] = true,
			["GameOver"] = true,
		},
		["numSongs"] = {
			["Battles"] = -1,
			["Bosses"] = -1,
		},
		["MusicVolume"] = 0.85,
		["timeOuts"] = {
			["Fanfare"] = 30,
			["GameOver"] = 30,
		},
		["FadeTime"] = 5,
	}
	CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.LoadDefaults)
	if not outOfDate then
		CombatMusic_BossList = {}
		CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.SongListDefaults)
	end
end



-- Event Handling function
function CombatMusic_OnEvent(self, event, ...)
	-- Debug Messages
	--CombatMusic.PrintMessage(format("Event. %s", event or "nil"), false, true)
	--CombatMusic.PrintMessage(..., false, true)
	local arg1 = ...
	if event == "ADDON_LOADED" and arg1 == addonName then
		-- The addon was loaded.
		CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.AddonLoaded)
		CombatMusic.PrintMessage(CombatMusic_Messages.DebugMessages.DebugLoaded, false, true)
		-- Do a settings Check
		CombatMusic.CheckSettingsLoaded()
		return
	elseif event == "PLAYER_LEVEL_UP" then
		CombatMusic.LevelUp()
		return
	elseif event == "PLAYER_REGEN_DISABLED" then
		CombatMusic.enterCombat()
		return
	elseif event == "PLAYER_REGEN_ENABLED" then
		CombatMusic.leaveCombat()
		return
	elseif event == "PLAYER_DEAD" then
		CombatMusic.GameOver()
		return
	elseif event == "PLAYER_TARGET_CHANGED" then
		CombatMusic.TargetChanged("player")
		return
	elseif event == "UNIT_TARGET" then
		if arg1 == "focus" then
			CombatMusic.TargetChanged(arg1)
			return
		end
	elseif event == "CHAT_MSG_ADDON" then
		CombatMusic.CheckComm(...)
	end
end

-- PrintHelp()
function CombatMusic.PrintHelp()
	CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.CurrentVerHelp)
	for k, v in pairs(CombatMusic_Messages.SlashHelp) do
		CombatMusic.PrintMessage(format(CombatMusic_Colors.var .. "%s " .. CombatMusic_Colors.close .. "- %s", k, v))
	end
end

-- Slash command function
function CombatMusic.SlashCommandHandler(args)
	local command, arg = args:match("^(%S*)%s*(.-)$");

	-- /cm help
	-----------
	if command == "" or command == CombatMusic_SlashArgs.Help then
		-- Show /command help
		CombatMusic.PrintHelp()

	--/cm on
	--------
	elseif command == CombatMusic_SlashArgs.Enable then
		-- Enable CombatMusic
		CombatMusic_SavedDB.Enabled = true
		CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.Enabled)

	--/cm off
	---------	
	elseif command == CombatMusic_SlashArgs.Disable then
		-- Disable CombatMusic
		CombatMusic.leaveCombat(true)
		CombatMusic_SavedDB.Enabled = false
		CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.Disabled)

	--/cm reset
	-----------
	elseif command == CombatMusic_SlashArgs.Reset then
		-- Reload defaults for CombatMusic
		StaticPopup_Show("COMBATMUSIC_RESET")

	--/cm battles
	------------
	elseif command == CombatMusic_SlashArgs.BattleCount then
		--Command to set number of battle songs
		if (not tonumber(arg)) and arg ~= "off" then
			--Show current setting if arg not provided.
			CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.BattleCount, CombatMusic_SavedDB.numSongs.Battles))
		else
			-- Set the number of battles, if arg > 0
			if arg == "off" then
				CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.BattlesOff)
				CombatMusic_SavedDB.numSongs.Battles = -1
			elseif tonumber(arg) <= 0 then
				CombatMusic.PrintMessage(CombatMusic_Messages.ErrorMessages.BiggerThan0, true)
			else
				CombatMusic_SavedDB.numSongs.Battles = tonumber(arg)
				CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.NewBattles, arg))
			end
		end

	--/cm bosses
	------------
	elseif command == CombatMusic_SlashArgs.BossCount then
		-- Command to set the number of boss songs
		if (not tonumber(arg)) and arg ~= "off" then
			--Show current setting if arg not provided.
			CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.BossCount, CombatMusic_SavedDB.numSongs.Bosses))
		else
			-- Set the number of boss batles, if arg > 0
			if arg == "off" then
				CombatMusic_SavedDB.numSongs.Bosses = -1
				CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.BossesOff)
			elseif tonumber(arg) <= 0 then
				CombatMusic.PrintMessage(CombatMusic_Messages.ErrorMessages.BiggerThan0, true)
			else
				CombatMusic_SavedDB.numSongs.Bosses = tonumber(arg)
				CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.NewBosses, arg))
			end
		end

	--/cm volume
	------------
	elseif command == CombatMusic_SlashArgs.MusicVol then
		--Command to change the in-combat music volume
		if not tonumber(arg) then
			--Show current setting if arg not provided.
			CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.CurMusicVol, CombatMusic_SavedDB.MusicVolume))
		else
			--Change the setting if arg is in the accepted range.
			if tonumber(arg) < 0 or tonumber(arg) > 1 then
				CombatMusic.PrintMessage(CombatMusic_Messages.ErrorMessages.Volume, true)
			else
				CombatMusic_SavedDB.MusicVolume = tostring(arg)
				CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.SetMusicVol, arg))
			end
		end
	
	--/cm fade
	----------
	elseif command == CombatMusic_SlashArgs.FadeTime then
		-- Command to change fadeout timer
		if (not tonumber(arg)) and arg ~= "off" then
			CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.CurrentFade, CombatMusic_SavedDB.FadeTime))
		else
			if arg == "off" then
				CombatMusic_SavedDB.FadeTime = 0
				CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.FadingDisable)
			elseif tonumber(arg) <= 0 then
				CombatMusic.PrintMessage(CombatMusic_Messages.ErrorMessages.BiggerThan0, true)
			else
				CombatMusic_SavedDB.FadeTime = tonumber(arg)
				CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.FadingSet, arg))
			end
		end
	
	--/cm bosslist
	--------------
	elseif command == CombatMusic_SlashArgs.BossList then
		if arg == "add" then
			local dlg = StaticPopup_Show("COMBATMUIC_BOSSLISTADD")
			if dlg then
				dlg.data = {
					CurTarget = UnitName("target")
					--CurSong = CombatMusic.Info.CurrentSong
				}
			end
		elseif arg == "delete" then
			CombatMusic.PrintMessage(CombatMusic_Messages.ErrorMessages.NotImplemented, true)
		end
	
	--/cm debug
	-----------
	elseif command == CombatMusic_SlashArgs.Debug then
		-- Debug mode slash command
		if arg == "off" then
			CombatMusic_DebugMode = false
			CombatMusic.PrintMessage(CombatMusic_Messages.DebugMessages.DebugOff)
		elseif arg == "on" then
			CombatMusic_DebugMode = true
			CombatMusic.PrintMessage(CombatMusic_Messages.DebugMessages.DebugOn)
		else
			CombatMusic.PrintMessage(CombatMusic_Messages.ErrorMessages.OnOrOff, true)
		end
		
	-- Unknown
	else
		CombatMusic.PrintMessage(format(CombatMusic_Messages.ErrorMessages.InvalidArg, args), true)
	end
end

local function CombatMusic_CheckBossList(self, dialogNo, data, data2)
	if dialogNo == 1 then
		local UnitName = self.editBox:GetText()
		if UnitName then
			local dlg2 = StaticPopup_Show("COMBATMUSIC_BOSSLISTADD2")
			if dlg2 then
				dlg2.data = {
					Name = self.editBox:GetText()
				}
			end
		else
			CombatMusic.PrintMessage(CombatMusic_Messages.ErrorMessages.NonEmpty)
			StaticPopup_Show("COMBATMUSIC_BOSSLISTADD")
		end
	elseif dialogNo == 2 then
		local SongPath = self.editBox:GetText()
		if SongPath then
			CombatMusic_BossList[data.Name] = SongPath
			CombatMusic_PrintMessage(format(CombatMusic_Messages.OtherMessages.BossListAdded, data.Name, SongPath))
		else
			CombatMusic_PrintMessage(CombatMusic_Messages.ErrorMessages.NonEmpty)
		end
	end
end
	

function CombatMusic_OnLoad(self)

	-- AddonEvents
	self:RegisterEvent("ADDON_LOADED")
	-- Trigger events
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("CHAT_MSG_ADDON")
	--self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_TARGET")

	-- Slash Command listings
	SLASH_COMBATMUSIC_MAIN1 = "/combatmusic"
	SLASH_COMBATMUSIC_MAIN2 = "/combat"
	SLASH_COMBATMUSIC_MAIN3 = "/cm"

	SlashCmdList["COMBATMUSIC_MAIN"] = function(args)
	CombatMusic.SlashCommandHandler(args)
	end

	-- Static Popup for reset
	StaticPopupDialogs["COMBATMUSIC_RESET"] = {
		text = CombatMusic_Messages.OtherMessages.ResetDialog,
		button1 = OKAY,
		button2 = CANCEL,
		OnAccept = function()
			CombatMusic.SetDefaults()
			ReloadUI()
		end,
		whileDead = true,
		timeout = 0,
		hideOnEscape = true,
		showAlert = true,
	}
	
	-- Popups for BossList add
	StaticPopupDialogs["COMBATMUIC_BOSSLISTADD"] = {
		text = CombatMusic_Messages.OtherMessages.BossListAdd1,
		button1 = OKAY,
		button2 = CANCEL,
		hasEditBox = true,
		maxLetters = 128, 
		editBoxWidth = 250,
		OnShow = function(self)
			self.editBox:SetText(UnitName('target') or "")
		end,
		OnAccept = function(self)
			CombatMusic_CheckBossList(self, 1)
		end,
		EditBoxOnEnterPressed = function(self)
			CombatMusic_CheckBossList(self, 1)
		end,
		
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		whileDead = true,
		hideOnEscape = true,
		timeout = 0,
	}
	
	StaticPopupDialogs["COMBATMUSIC_BOSSLISTADD2"] = {
		text= CombatMusic_Messages.OtherMessages.BossListAdd2,
		button1 = OKAY,
		button2 = CANCEL,
		hasEditBox = true,
		whileDead = true,
		hideOnEscape = true,
		timeout = 0,
		OnShow = function(self, data)
			self.editBox:SetText("Inteface\\Music\\")
		end,
		OnAccept = function(self, data)
			CombatMusic_CheckBossList(self, 2, data)
		end,
		EditBoxOnEnterPressed = function(self, data)
			CombatMusic_CheckBossList(self, 2, data)
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
	}
end