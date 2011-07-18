--[[
------------------------------------------------------------------------
	Project: Van32s_CombatMusic
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

local addonName, CM = ...

--@alpha@ 
CM.DebugMode = true
--@end-alpha@

--[===[@non-alpha@ 
CM.DebugMode = false
--@end-non-alpha@]===]

local currentSVVersion = "2"

function CM.ns(var)
	return tostring(var) or "nil"
end


-- Your standard print message function
function CM.PrintMessage(message, isError, DEBUG)
	-- The typical args check

	if message == "" then message = nil end
	assert(message, "Usage. PrintMessage(message[, isError[, DEBUG]])")

	outMessage = CM.Colours.title .. CM.AddonTitle .. CM.Colours.close .. ": "

	if DEBUG and CM.DebugMode then
		--DCF:Clear()
		outMessage = outMessage .. CM.L.Header.Debug
	elseif DEBUG and not DebugMode then
		return
	end

	if isError then
		outMessage = outMessage .. CM.L.Header.Error
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
function CM.CheckSettingsLoaded()
	CM.PrintMessage(CM.Colours.var .. "CheckSettingsLoaded()", false, true)
	local x1 = 1
	local x2 = 1
	
	if not CM_SavedDB then
		CM.SetDefaults()
		x1 = nil
	elseif CM_SavedDB.SVVersion ~= currentSVVersion then
		CM.SetDefaults(1)
		x1 = nil
	end
	
	if not CM_BossList then
		CM_BossList = {}
		CM.PrintMessage(CM.L.Other.SongListDefaults)
		x2 = nil
	end
	
	-- Spamcheck, if they're not 1 then don't spam
	if x1 then
		CM.PrintMessage(CM.L.Other.VarsLoaded)
	end
	if x2 then
		CM.PrintMessage(CM.L.Other.SongListLoaded)
	end
end

-- Sets the CM settings to default values
function CM.SetDefaults(outOfDate)
	CM.PrintMessage(CM.Colours.var .. "SetDefaults(" .. CM.ns(outOfDate) .. ")", false, true)
	-- Are settings there, but out of date? Try to update them.
	if outOfDate and CM_SavedDB.SVVersion == "1" then
		--[[Settings Version 1:
			CM_SavedDB = {
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
			["Enabled"] = CM_SavedDB.Enabled or true,
			["Music"] = {
				["Enabled"] = true,
				["numSongs"] = CM_SavedDB.numSongs or {["Battles"] = -1, ["Bosses"] = -1},
				["Volume"] = CM_SavedDB.MusicVolume or 0.85,
				["FadeOut"] = CM_SavedDB.FadeTime or 5,
			}, 
			["GameOver"] = {
				["Enabled"] = CM_SavedDB.PlayWhen.GameOver or true,
				["Cooldown"] = CM_SavedDB.timeOuts.GameOver or 30,
			},
			["Victory"] = {
				["Enabled"] = CM_SavedDB.PlayWhen.CombatFanfare or true,
				["Cooldown"] = CM_SavedDB.timeOuts.Fanfare or 30,
			},
			["LevelUp"] = {
				["Enabled"] = CM_SavedDB.PlayWhen.LevelUp or true, 
				["NewFanfare"] = false,
			},
			["AllowComm"] = true,
		}

		CM_SavedDB = tempDB
		CM.PrintMessage(CM.L.Other.UpdateSettings)
	else
		-- Load the default settings for CM
		CM_SavedDB = {
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
		CM.PrintMessage(CM.L.Other.LoadDefaults)
		CM_BossList = {}
		CM.PrintMessage(CM.L.Other.SongListDefaults)
	end
end



-- Event Handling function
function CM_OnEvent(self, event, ...)
	-- Debug Messages
	--CM.PrintMessage(format("Event. %s", event or "nil"), false, true)
	--CM.PrintMessage(..., false, true)
	local arg1 = ...
	if event == "ADDON_LOADED" and arg1 == addonName then
		-- The addon was loaded.
		CM.PrintMessage(CM.L.Other.AddonLoaded)
		CM.PrintMessage(CM.L.Debug.DebugLoaded, false, true)
		-- Do a settings Check
		CM.CheckSettingsLoaded()
		return
	elseif event == "PLAYER_LEVEL_UP" then
		CM.LevelUp()
		return
	elseif event == "PLAYER_REGEN_DISABLED" then
		CM.enterCombat()
		return
	elseif event == "PLAYER_REGEN_ENABLED" then
		CM.leaveCombat()
		return
	elseif event == "PLAYER_DEAD" then
		CM.GameOver()
		return
	elseif event == "PLAYER_TARGET_CHANGED" then
		CM.TargetChanged("player")
		return
	elseif event == "UNIT_TARGET" then
		if arg1 == "focus" then
			CM.TargetChanged(arg1)
			return
		end
	elseif event == "PLAYER_LEAVING_WORLD" then
		CM.leaveCombat(1)
		return
	elseif event == "CHAT_MSG_ADDON" then
		-- They may have decided to comment this section out,
		-- it is optional after all.
		if CM.CheckComm then
			CM.CheckComm(...)
		end
	end
end

-- PrintHelp()
function CM.PrintHelp()
	CM.PrintMessage(CM.Colours.var .. "PrintHelp()", false, true)
	CM.PrintMessage(CM.L.Other.CurrentVerHelp)
	for k, v in pairs(CM.L.SlashHelp) do
		CM.PrintMessage(format(CM.L.Other.HelpLine, k, v))
	end
end

-- Slash command function
function CM.SlashCommandHandler(args)
	CM.PrintMessage(CM.Colours.var .. "SlashCommandHandler(" .. CM.ns(args) .. ")", false, true)
	local command, arg = args:match("^(%S*)%s*(.-)$");

	-- /cm help
	-----------
	if command == "" or command == CM.SlashArgs.Help then
		-- Show /command help
		CM.PrintHelp()

	--/cm on
	--------
	elseif command == CM.SlashArgs.Enable then
		-- Enable CM
		CM_SavedDB.Enabled = true
		CM.PrintMessage(CM.L.Other.Enabled)

	--/cm off
	---------	
	elseif command == CM.SlashArgs.Disable then
		-- Disable CM
		CM.leaveCombat(true)
		CM_SavedDB.Enabled = false
		CM.PrintMessage(CM.L.Other.Disabled)

	--/cm reset
	-----------
	elseif command == CM.SlashArgs.Reset then
		-- Reload defaults for CM
		StaticPopup_Show("CM_RESET")

	--/cm battles
	------------
	elseif command == CM.SlashArgs.BattleCount then
		--Command to set number of battle songs
		if (not tonumber(arg)) and arg ~= "off" then
			--Show current setting if arg not provided.
			CM.PrintMessage(format(CM.L.Other.BattleCount, CM_SavedDB.Music.numSongs.Battles))
		else
			-- Set the number of battles, if arg > 0
			if arg == "off" then
				CM.PrintMessage(CM.L.Other.BattlesOff)
				CM_SavedDB.Music.numSongs.Battles = -1
			elseif tonumber(arg) <= 0 then
				CM.PrintMessage(CM.L.Errors.BiggerThan0, true)
			else
				CM_SavedDB.Music.numSongs.Battles = tonumber(arg)
				CM.PrintMessage(format(CM.L.Other.NewBattles, arg))
			end
		end

	--/cm bosses
	------------
	elseif command == CM.SlashArgs.BossCount then
		-- Command to set the number of boss songs
		if (not tonumber(arg)) and arg ~= "off" then
			--Show current setting if arg not provided.
			CM.PrintMessage(format(CM.L.Other.BossCount, CM_SavedDB.Music.numSongs.Bosses))
		else
			-- Set the number of boss batles, if arg > 0
			if arg == "off" then
				CM_SavedDB.Music.numSongs.Bosses = -1
				CM.PrintMessage(CM.L.Other.BossesOff)
			elseif tonumber(arg) <= 0 then
				CM.PrintMessage(CM.L.Errors.BiggerThan0, true)
			else
				CM_SavedDB.Music.numSongs.Bosses = tonumber(arg)
				CM.PrintMessage(format(CM.L.Other.NewBosses, arg))
			end
		end

	--/cm volume
	------------
	elseif command == CM.SlashArgs.MusicVol then
		--Command to change the in-combat music volume
		if not tonumber(arg) then
			--Show current setting if arg not provided.
			CM.PrintMessage(format(CM.L.Other.CurMusicVol, CM_SavedDB.Music.Volume))
		else
			--Change the setting if arg is in the accepted range.
			if tonumber(arg) < 0 or tonumber(arg) > 1 then
				CM.PrintMessage(CM.L.Errors.Volume, true)
			else
				CM_SavedDB.Music.Volume = tostring(arg)
				CM.PrintMessage(format(CM.L.Other.SetMusicVol, arg))
			end
		end
	
	--/cm fade
	----------
	elseif command == CM.SlashArgs.FadeTime then
		-- Command to change fadeout timer
		if (not tonumber(arg)) and arg ~= "off" then
			CM.PrintMessage(format(CM.L.Other.CurrentFade, CM_SavedDB.Music.FadeOut))
		else
			if arg == "off" then
				CM_SavedDB.Music.FadeOut = 0
				CM.PrintMessage(CM.L.Other.FadingDisable)
			elseif tonumber(arg) <= 0 then
				CM.PrintMessage(CM.L.Errors.BiggerThan0, true)
			else
				CM_SavedDB.Music.FadeOut = tonumber(arg)
				CM.PrintMessage(format(CM.L.Other.FadingSet, arg))
			end
		end
	
	--/cm bosslist
	--------------
	elseif command == CM.SlashArgs.BossList then
		if arg == "add" then
			local dlg = StaticPopup_Show("COMBATMUIC_BOSSLISTADD")
			if dlg then
				dlg.data = {
					CurTarget = UnitName("target")
					--CurSong = CM.Info.CurrentSong
				}
			end
		elseif arg == "remove" then
			local dlg = StaticPopup_Show("CM_BOSSLISTREMOVE")
		else
			CM.PrintMessage(CM.L.Other.UseDump)
			CM.DumpBossList()
		end
		
	--/cm comm
	----------
	elseif command == CM.SlashArgs.Comm then
		if arg == "off" then	
			CM_SavedDB.AllowComm = false
			CM.PrintMessage(CM.L.Other.AddonCommOff)
		elseif arg == "on" then
			CM_SavedDB.AllowComm = true
			CM.PrintMessage(CM.L.Other.AddonCommOn)
		else
			CM.PrintMessage(CM.L.Errors.OnOrOff, true)
		end
	
	--/cm debug
	-----------
	elseif command == CM.SlashArgs.Debug then
		-- Debug mode slash command
		if arg == "off" then
			CM.DebugMode = false
			CM.PrintMessage(CM.L.Debug.DebugOff)
		elseif arg == "on" then
			CM.DebugMode = true
			CM.PrintMessage(CM.L.Debug.DebugOn)
		else
			CM.PrintMessage(CM.L.Errors.OnOrOff, true)
		end
		
	-- Unknown
	else
		CM.PrintMessage(format(CM.L.Errors.InvalidArg, args), true)
	end
end

local function CM_CheckBossList(self, dialogNo, data, data2)
	CM.PrintMessage(CM.Colours.var .. "CheckBossList()", false, true)
	if dialogNo == 1 then
		local UnitName = self.editBox:GetText()
		self:Hide()
		local dlg2 = StaticPopup_Show("CM_BOSSLISTADD2")
		if dlg2 then
			dlg2.data = {
				Name = UnitName
			}
		end
	elseif dialogNo == 2 then
		local SongPath = self.editBox:GetText()
		CM_BossList[data.Name] = SongPath
		CM.PrintMessage(format(CM.L.Other.BossListAdded, data.Name, SongPath))
		self:Hide()
	end
end

-- Remove bosslist entry
local function CM_RemoveBossList(self)
	CM.PrintMessage(CM.Colours.var .. "RemoveBossList()", false, true)
	local unit = self.editBox:GetText()
	-- Check the bosslist
	if CM_BossList[unit] then
		CM_BossList[unit] = nil
		CM.PrintMessage(format(CM.L.Other.BosslistRemoved, unit))
		self:Hide()
	else
		CM.PrintMessage(CM.L.Errors.NotOnList, true)
	end
end

-- BossList dumper
function CM.DumpBossList()
	CM.PrintMessage(CM.Colours.var .. "DumpBossList()", false, true)
	for k,v in pairs(CM_BossList) do
		CM.PrintMessage(format(CM.L.Other.BossListDump, k,v))
	end
end

function CM_OnLoad(self)

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
	SLASH_CM_MAIN1 = "/combatMusic"
	SLASH_CM_MAIN2 = "/combat"
	SLASH_CM_MAIN3 = "/cm"

	SlashCmdList["CM_MAIN"] = function(args)
		CM.SlashCommandHandler(args)
	end

	-- Static Popup for reset
	StaticPopupDialogs["CM_RESET"] = {
		text = CM.L.Other.ResetDialog,
		button1 = OKAY,
		button2 = CANCEL,
		OnAccept = function()
			CM.SetDefaults()
			ReloadUI()
		end,
		whileDead = true,
		timeout = 0,
		hideOnEscape = true,
		showAlert = true,
	}
	
	-- Popups for BossList add
	StaticPopupDialogs["COMBATMUIC_BOSSLISTADD"] = {
		text = CM.L.Other.BossListAdd1,
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
	
	StaticPopupDialogs["CM_BOSSLISTADD2"] = {
		text= CM.L.Other.BossListAdd2,
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
	
	StaticPopupDialogs["CM_BOSSLISTREMOVE"] = {
		text = CM.L.Other.BossListRemove,
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