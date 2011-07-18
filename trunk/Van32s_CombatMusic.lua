--[[
------------------------------------------------------------------------
	Project: Van32sCombatMusic
	File: Reusable Functions, revision @file-revision@
	Date: @project-date-iso@
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

CombatMusic = {}
--@alpha@ 
CombatMusic_DebugMode = true
--@end-alpha@

--[===[@non-alpha@ 
CombatMusic_DebugMode = false
--@end-non-alpha@]===]

local currentSVVersion = "2"

function CombatMusic.ns(var)
	return tostring(var) or "nil"
end


-- Your standard print message function
function CombatMusic.PrintMessage(message, isError, DEBUG)
	-- The typical args check

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
	if DEBUG then
		if ChatFrame4:IsVisible() then
			ChatFrame4:AddMessage(outMessage)
			return
		end
	end
	print(outMessage)
end

-- Check that settings are loaded properly, and are up to date
function CombatMusic.CheckSettingsLoaded()
	CombatMusic.PrintMessage(CombatMusic_Colors.var .. "CheckSettingsLoaded()", false, true)
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
	CombatMusic.PrintMessage(CombatMusic_Colors.var .. "SetDefaults(" .. CombatMusic.ns(outOfDate) .. ")", false, true)
	-- Are settings there, but out of date? Try to update them.
	if outOfDate and CombatMusic_SavedDB.SVVersion == "1" then
		--[[Settings Version 1:
			CombatMusic_SavedDB = {
				["SVVersion"] = "1",
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
		]]
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
		CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.UpdateSettings)
	else
		-- Load the default settings for CombatMusic
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
		CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.LoadDefaults)
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
	-- The addon was loaded:
	if event == "ADDON_LOADED" and arg1 == addonName then
		-- The addon was loaded.
		CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.AddonLoaded)
		CombatMusic.PrintMessage(CombatMusic_Messages.DebugMessages.DebugLoaded, false, true)
		-- Do a settings Check
		CombatMusic.CheckSettingsLoaded()
		return
	-- The player leveled up:
	elseif event == "PLAYER_LEVEL_UP" then
		CombatMusic.LevelUp()
		return
	-- Entering combat
	elseif event == "PLAYER_REGEN_DISABLED" then
		CombatMusic.enterCombat()
		return
	-- Leaving Combat
	elseif event == "PLAYER_REGEN_ENABLED" then
		CombatMusic.leaveCombat()
		return
	-- Died
	elseif event == "PLAYER_DEAD" then
		CombatMusic.GameOver()
		return
	-- Target Changed
	elseif event == "PLAYER_TARGET_CHANGED" then
		CombatMusic.TargetChanged("player")
		return
	-- Other unit's target changed
	elseif event == "UNIT_TARGET" then
		if arg1 == "focus" then
			CombatMusic.TargetChanged(arg1)
			return
		end
	-- Leaving the world/Reloading the UI
	elseif event == "PLAYER_LEAVING_WORLD" then
		CombatMusic.leaveCombat(1)
		return
	-- Addon Chat message
	elseif event == "CHAT_MSG_ADDON" then
		-- They may have decided to comment this section out,
		-- it is optional after all.
		if CombatMusic.CheckComm then
			CombatMusic.CheckComm(...)
		end
	end
end

-- PrintHelp()
function CombatMusic.PrintHelp()
	CombatMusic.PrintMessage(CombatMusic_Colors.var .. "PrintHelp()", false, true)
	CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.CurrentVerHelp)
	for k, v in pairs(CombatMusic_Messages.SlashHelp) do
		CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.HelpLine, k, v))
	end
end

-- Slash command function
function CombatMusic.SlashCommandHandler(args)
	CombatMusic.PrintMessage(CombatMusic_Colors.var .. "SlashCommandHandler(" .. CombatMusic.ns(args) .. ")", false, true)
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
			CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.BattleCount, CombatMusic_SavedDB.Music.numSongs.Battles))
		else
			-- Set the number of battles, if arg > 0
			if arg == "off" then
				CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.BattlesOff)
				CombatMusic_SavedDB.Music.numSongs.Battles = -1
			elseif tonumber(arg) <= 0 then
				CombatMusic.PrintMessage(CombatMusic_Messages.ErrorMessages.BiggerThan0, true)
			else
				CombatMusic_SavedDB.Music.numSongs.Battles = tonumber(arg)
				CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.NewBattles, arg))
			end
		end

	--/cm bosses
	------------
	elseif command == CombatMusic_SlashArgs.BossCount then
		-- Command to set the number of boss songs
		if (not tonumber(arg)) and arg ~= "off" then
			--Show current setting if arg not provided.
			CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.BossCount, CombatMusic_SavedDB.Music.numSongs.Bosses))
		else
			-- Set the number of boss batles, if arg > 0
			if arg == "off" then
				CombatMusic_SavedDB.Music.numSongs.Bosses = -1
				CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.BossesOff)
			elseif tonumber(arg) <= 0 then
				CombatMusic.PrintMessage(CombatMusic_Messages.ErrorMessages.BiggerThan0, true)
			else
				CombatMusic_SavedDB.Music.numSongs.Bosses = tonumber(arg)
				CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.NewBosses, arg))
			end
		end

	--/cm volume
	------------
	elseif command == CombatMusic_SlashArgs.MusicVol then
		--Command to change the in-combat music volume
		if not tonumber(arg) then
			--Show current setting if arg not provided.
			CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.CurMusicVol, CombatMusic_SavedDB.Music.Volume))
		else
			--Change the setting if arg is in the accepted range.
			if tonumber(arg) < 0 or tonumber(arg) > 1 then
				CombatMusic.PrintMessage(CombatMusic_Messages.ErrorMessages.Volume, true)
			else
				CombatMusic_SavedDB.Music.Volume = tostring(arg)
				CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.SetMusicVol, arg))
			end
		end
	
	--/cm fade
	----------
	elseif command == CombatMusic_SlashArgs.FadeTime then
		-- Command to change fadeout timer
		if (not tonumber(arg)) and arg ~= "off" then
			CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.CurrentFade, CombatMusic_SavedDB.Music.FadeOut))
		else
			if arg == "off" then
				CombatMusic_SavedDB.Music.FadeOut = 0
				CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.FadingDisable)
			elseif tonumber(arg) <= 0 then
				CombatMusic.PrintMessage(CombatMusic_Messages.ErrorMessages.BiggerThan0, true)
			else
				CombatMusic_SavedDB.Music.FadeOut = tonumber(arg)
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
		elseif arg == "remove" then
			local dlg = StaticPopup_Show("COMBATMUSIC_BOSSLISTREMOVE")
		else
			CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.UseDump)
			CombatMusic.DumpBossList()
		end
		
	--/cm comm
	----------
	elseif command == CombatMusic_SlashArgs.Comm then
		if arg == "off" then	
			CombatMusic_SavedDB.AllowComm = false
			CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.AddonCommOff)
		elseif arg == "on" then
			CombatMusic_SavedDB.AllowComm = true
			CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.AddonCommOn)
		else
			CombatMusic.PrintMessage(CombatMusic_Messages.ErrorMessages.OnOrOff, true)
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
	CombatMusic.PrintMessage(CombatMusic_Colors.var .. "CheckBossList()", false, true)
	if dialogNo == 1 then
		local UnitName = self.editBox:GetText()
		self:Hide()
		local dlg2 = StaticPopup_Show("COMBATMUSIC_BOSSLISTADD2")
		if dlg2 then
			dlg2.data = {
				Name = UnitName
			}
		end
	elseif dialogNo == 2 then
		local SongPath = self.editBox:GetText()
		CombatMusic_BossList[data.Name] = SongPath
		CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.BossListAdded, data.Name, SongPath))
		self:Hide()
	end
end

-- Remove bosslist entry
local function CombatMusic_RemoveBossList(self)
	CombatMusic.PrintMessage(CombatMusic_Colors.var .. "RemoveBossList()", false, true)
	local unit = self.editBox:GetText()
	-- Check the bosslist
	if CombatMusic_BossList[unit] then
		CombatMusic_BossList[unit] = nil
		CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.BosslistRemoved, unit))
		self:Hide()
	else
		CombatMusic.PrintMessage(CombatMusic_Messages.ErrorMessages.NotOnList, true)
	end
end

-- BossList dumper
function CombatMusic.DumpBossList()
	CombatMusic.PrintMessage(CombatMusic_Colors.var .. "DumpBossList()", false, true)
	for k,v in pairs(CombatMusic_BossList) do
		CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.BossListDump, k,v))
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
	self:RegisterEvent("PLAYER_LEAVING_WORLD")

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
			if not self.button1:IsEnabled() then
				return
			end
			CombatMusic_CheckBossList(self, 1)
		end,
		EditBoxOnEnterPressed = function(self)
			if not self:GetParent().button1:IsEnabled() then
				return
			end
			CombatMusic_CheckBossList(self:GetParent(), 1)
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
		text= CombatMusic_Messages.OtherMessages.BossListAdd2,
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
			CombatMusic_CheckBossList(self, 2, data)
		end,
		EditBoxOnEnterPressed = function(self, data)
			if not self:GetParent().button1:IsEnabled() then
				return
			end
			CombatMusic_CheckBossList(self:GetParent(), 2, data)
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
	
	StaticPopupDialogs["COMBATMUSIC_BOSSLISTREMOVE"] = {
		text = CombatMusic_Messages.OtherMessages.BossListRemove,
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
			CombatMusic_RemoveBossList(self)
		end,
		EditBoxOnEnterPressed = function(self)
			if not self:GetParent().button1:IsEnabled() then
				return
			end
			CombatMusic_RemoveBossList(self:GetParent())
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