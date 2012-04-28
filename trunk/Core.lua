--[[
------------------------------------------------------------------------
	Project: Van32sCombatMusic
	File: Reusable Functions, revision @file-revision@
	Date: @file-date-iso@
	Purpose: The reusable, essential functions that any addon needs.
	Credits: Code written by Vandesdelca32

    Copyright (C) 2010-2012 Vandesdelca32

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

LibStub:GetLibrary("LibVan32-1.0"):Embed(CombatMusic, "CombatMusic")

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

-----------------------]]

-- CM_CheckSettingsLoaded: Check to make sure the settings loaded properly
local function CM_CheckSettingsLoaded()
	CombatMusic:PrintMessage("CheckSettingsLoaded()", false, true)

	-- Set a couple of flags
	local main, list, char = true, true, true
	
	-- Check the settings table
	if not CombatMusic_SavedDB then
		CombatMusic.SetDefaults( "global", nil)
		CombatMusic:PrintMessage(L.OTHER.GlobalConfigReset)
		main = nil
	elseif CombatMusic_SavedDB.SVVersion ~= currentSVVersion then 
		CombatMusic.SetDefaults( "global", true)
		main = nil
	end
	
	-- Check the BossList
	if not CombatMusic_BossList then
		CombatMusic_BossList = {}
		CombatMusic:PrintMessage(L.OTHER.BossListReset)
		list = nil
	end
	
	-- Check the per-character
	if not CombatMusic_SavedDBPerChar then
		CombatMusic.SetDefaults( "perchar", nil)
		char = nil
	elseif CombatMusic_SavedDBPerChar.SVVersion ~= currentSVVersion then
		CombatMusic.SetDefaults( "perchar", true)
		char = nil
	end
	
	-- Set the CVars that CombatMusic needs on...
	SetCVar("Sound_EnableAllSound", "1")
	SetCVar("Sound_EnableMusic", "1")
	-- If you don't like the ingame music, set the music slider to 0!
	
	-- Check the flags, and let the user know:
	if main and char then	
		CombatMusic:PrintMessage(L.OTHER.GlobalConfigLoaded)
	end
	if list then
		CombatMusic:PrintMessage(L.OTHER.BossListLoaded)
	end
end


-- CombatMusic.SetDefaults: Load the default settings
function CombatMusic.SetDefaults(restoreMode, outOfDate)
	CombatMusic:PrintMessage("SetDefaults(" .. debugNils(restoreMode, outOfDate) .. ")", false, true)
	-- For an old settings reference, see 'settingsHistory.lua'
	
	if restoreMode == "global" then
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
			CombatMusic:PrintMessage(L.OTHER.GlobalConfigUpdate)
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
			CombatMusic_SavedDBPerChar = {
				["SVVersion"] = currentSVVersion,
				["PreferFocusTarget"] = false,
				["CheckBossTargets"] = false
			}
			CombatMusic:PrintMessage(L.OTHER.GlobalConfigReset)
		end
	elseif restoreMode == "perchar" then
		CombatMusic_SavedDBPerChar = {
			["SVVersion"] = currentSVVersion,
			["PreferFocusTarget"] = false,
			["CheckBossTargets"] = false
		}
	elseif restoreMode == "fullreset" then
		CombatMusic.SetDefaults("global")
		CombatMusic.SetDefaults("perchar")
	else
		return
	end
end


-- CM_CheckBossList: Adds an NPC to the BossList
local function CM_CheckBossList(self, dialogNo, data, data2)
	CombatMusic:PrintMessage("CheckBossList()", false, true)
	if dialogNo == 1 then
		local UnitName = self.editBox:GetText()
		self:Hide()
		local text
		if not CombatMusic_BossList[UnitName] then
			text = L.OTHER.BossListDialog2
		else
			text = CombatMusic:ParseColorCodedString(format(L.OTHER.BossListDialog2_Existing, UnitName, CombatMusic_BossList[UnitName]))
		end
		local dlg2 = StaticPopup_Show("COMBATMUSIC_BOSSLISTADD2", text)
		if dlg2 then
			dlg2.data = {
				Name = UnitName
			}
		end
	elseif dialogNo == 2 then
		local SongPath = self.editBox:GetText()
		CombatMusic_BossList[data.Name] = SongPath
		CombatMusic:PrintMessage(format(L.OTHER.BossListAdd, data.Name, SongPath))
		self:Hide()
	end
end


-- CM_RemoveBossList: Removes an NPC from the BossList
local function CM_RemoveBossList(self)
	CombatMusic:PrintMessage("RemoveBossList()", false, true)
	local unit = self.editBox:GetText()
	-- Check the BossList
	if CombatMusic_BossList[unit] then
		CombatMusic_BossList[unit] = nil
		CombatMusic:PrintMessage(format(L.OTHER.BossListRemoved, unit))
		self:Hide()
	else
		CombatMusic:PrintMessage(format(L.ERRORS.BossListNotFound, unit), true)
	end
end


-- CM_DumpBossList: Prints all of the BossList entries
local function CM_DumpBossList()
	for k, v in pairs(CombatMusic_BossList) do
		CombatMusic:PrintMessage(format("§b%s§r will play \"§b%s§r\"", k, v))
	end
end


-- CM_PrintHelp: Prints the Help text
local function CM_PrintHelp()
	CombatMusic:PrintMessage(L.OTHER.HelpHead)
	for k, v in pairs(L.HELP) do
		CombatMusic:PrintMessage(format("§b%s§r - %s", k, v))
	end
end


-- SendVersion: Tell everyone in our group what version we're using
function CombatMusic.SendVersion()
	CombatMusic:PrintDebug("SendVersion()")
	
	-- Is this a raid group?
	local gType
	if GetNumRaidMembers() > 0 then gType = "RAID";
	elseif GetNumPartyMembers() > 0 then gType = "PARTY";
	else return;
	end
	
	-- Don't SEND the version check if the revision can't be determined.
	if strfind(L.OTHER.VerString, "???") then return gType end
	
	-- Check and set the cooldown appropriately
	if not CombatMusic.VCooldown or GetTime() >= (CombatMusic.VCooldown + 30) then
		CombatMusic.VCooldown = GetTime()
		SendAddonMessage("CM3", L.OTHER.VerString, gType)
		return gType
	end
end


-- CheckOutOfDate: Parse the version sent by other players to see if ours is out of date.
function CombatMusic:CheckOutOfDate(version)
	self:PrintDebug("CheckOutOfDate(" .. debugNils(version) .. ")")
	-- Don't run if already out of date
	if self.OutOfDate then return end
	
	-- Define a couple of patterns and some extra info
	local pattern = "V:([rba])(%d+)"
	local sChannel, sRevision = strmatch(L.OTHER.VerString, pattern)
	local rChannel, rRevision = strmatch(version, pattern)
	
	sRevision, rRevision = tonumber(sRevision), tonumber(rRevision)
	
	-- if ANY of these variables are nil, then NO check
	if (not sChannel and not sRevision) and (not rChannel and not rRevision) then return end
	
	-- Don't check if on or recieved alpha channel:
	if sChannel == "a" or rChannel == "a" then return end

	-- Compare channels and versions
	if sChannel == rChannel then
		if sRevision < rRevision then
			-- My revision is less than theirs, the addon was updated!
			self.OutOfDate = true
			self:PrintMessage(L.OTHER.OutOfDate)
		end
	end	
end


-- CheckVersion: Prepare to send version strings to the group
function CombatMusic:CheckVersions()
	self:PrintDebug("CheckVersions()")
	-- If it's out of date, no need to send version strings to everyone else
	if self.OutOfDate then return end
	
	-- If on a check cooldown, don't start the timer.	
	if self.VCooldown and GetTime() < (self.VCooldown + 30) then return end
	
	-- Reset our 4s timer.
	if self.VTimer then
		self.VTimer = self:KillTimer(self.VTimer)
	end
	self.VTimer = self:SetTimer(4, self.SendVersion)
end


-- CM_SlashHandler: Handles the console commands
local function CM_SlashHandler(args)
	--CombatMusic:PrintMessage("SlashHandler(" .. debugNils(args) .. ")", false, true)
	--We don't want to throw errors because of case-sensitive commands
	--so make the arguments string all lowercase to match!
	args = args:lower()

	-- Split it up into the arguments.
	local command, arg1, arg2 = strsplit(" ", args, 3);
	CombatMusic:PrintMessage("Args = " .. debugNils(command, arg1, arg2), false, true)

	-- /cm {?/help}
	---------------
	if not command or command == "" or command == "?" or command == "help" then
		CM_PrintHelp()
	
	-- /cm on
	---------
	elseif command == "on" then
		-- Turn on CombatMusic
		CombatMusic_SavedDB.Enabled = true
		CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.Addon, L.OTHER.Enable))
		
	-- /cm off
	----------
	elseif command == "off" then
		-- Turn off CombatMusic
		CombatMusic.leaveCombat(true)
		CombatMusic_SavedDB.Enabled = false
		CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.Addon, L.OTHER.Disable))
	
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
			-- Check to see if the user has the setting turned off, that way we can show them a different message
			if CombatMusic_SavedDB.Music.numSongs.Battles ~= -1 then
				CombatMusic:PrintMessage(format(L.OTHER.PrintSetting, L.OTHER.Battles, CombatMusic_SavedDB.Music.numSongs.Battles))
			else
				CombatMusic:PrintMessage(format(L.OTHER.ShowState, L.OTHER.UsingBattles, L.OTHER.Off))
			end
		else
			if arg1 == "off" then
				-- Turn off this feature
				CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.UsingBattles, L.OTHER.Off))
				CombatMusic_SavedDB.Music.numSongs.Battles = -1
			elseif tonumber(arg1) <= 0 then
				-- Print an error
				CombatMusic:PrintMessage(L.ERRORS.BiggerThan0, true)
			else
				-- Set it to what the user passed
				CombatMusic:PrintMessage(format(L.OTHER.ChangeSetting, L.OTHER.Battles, tonumber(arg1)))
				CombatMusic_SavedDB.Music.numSongs.Battles = tonumber(arg1)
			end
		end

	-- /cm bosses {#|off}
	---------------------
	elseif command == "bosses" then
		-- If it's passed with no argument, then show
		if not tonumber(arg1) and arg1 ~= "off" then
			-- Check to see if the user has the setting turned off, that way we can show them a different message
			if CombatMusic_SavedDB.Music.numSongs.Bosses ~= -1 then
				CombatMusic:PrintMessage(format(L.OTHER.PrintSetting, L.OTHER.Bosses, CombatMusic_SavedDB.Music.numSongs.Bosses))
			else
				CombatMusic:PrintMessage(format(L.OTHER.ShowState, L.OTHER.UsingBosses, L.OTHER.Off))
			end
		else
			if arg1 == "off" then
				-- Turn off this feature
				CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.UsingBosses, L.OTHER.Off))
				CombatMusic_SavedDB.Music.numSongs.Bosses = -1
			elseif tonumber(arg1) <= 0 then
				-- Print an error
				CombatMusic:PrintMessage(L.ERRORS.BiggerThan0, true)
			else
				-- Set it to what the user passed
				CombatMusic:PrintMessage(format(L.OTHER.ChangeSetting, L.OTHER.Bosses, tonumber(arg1)))
				CombatMusic_SavedDB.Music.numSongs.Bosses = tonumber(arg1)
			end
		end
	
	-- /cm [cooldowns|cds] [gameover|victory] {#|off}
	-------------------------------------------------
	elseif command == "cooldowns" or command == "cds" then
		-- /cm cooldowns gameover {#|off}
		if arg1 == "gameover" or arg1 == "go" then
			-- If it's passed with no argument, then show
			if not tonumber(arg2) and arg2 ~= "off" then
				-- Check to see if the user has the setting turned off, that way we can show them a different message
				if CombatMusic_SavedDB.GameOver.Cooldown ~= 0 then
					CombatMusic:PrintMessage(format(L.OTHER.PrintSetting, L.OTHER.CDGameOver, CombatMusic_SavedDB.GameOver.Cooldown))
				else
					CombatMusic:PrintMessage(format(L.OTHER.ShowState, L.OTHER.CDGameOver, L.OTHER.Off))
				end
			else
				if arg2 == "off" then
					-- Turn off this feature
					CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.CDGameOver, L.OTHER.Off))
					CombatMusic_SavedDB.GameOver.Cooldown = 0
				elseif tonumber(arg2) <= 0 then
					-- Print an error
					CombatMusic:PrintMessage(L.ERRORS.BiggerThan0, true)
				else
					-- Set it to what the user passed
					CombatMusic:PrintMessage(format(L.OTHER.ChangeSetting, L.OTHER.CDGameOver, tonumber(arg2)))
					CombatMusic_SavedDB.GameOver.Cooldown = tonumber(arg2)
				end
			end
		-- cm cooldowns victory {#|off}
		elseif arg1 == "victory" or arg1 == "vic" then
			-- If it's passed with no argument, then show
			if not tonumber(arg2) and arg2 ~= "off" then
				-- Check to see if the user has the setting turned off, that way we can show them a different message
				if CombatMusic_SavedDB.Victory.Cooldown ~= -1 then
					CombatMusic:PrintMessage(format(L.OTHER.PrintSetting, L.OTHER.CDVictory, CombatMusic_SavedDB.Victory.Cooldown))
				else
					CombatMusic:PrintMessage(format(L.OTHER.ShowState, L.OTHER.CDVictory, L.OTHER.Off))
				end
			else
				if arg2 == "off" then
					-- Turn off this feature
					CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.CDVictory, L.OTHER.Off))
					CombatMusic_SavedDB.Victory.Cooldown = -1
				elseif tonumber(arg2) <= 0 then
					-- Print an error
					CombatMusic:PrintMessage(L.ERRORS.BiggerThan0, true)
				else
					-- Set it to what the user passed
					CombatMusic:PrintMessage(format(L.OTHER.ChangeSetting, L.OTHER.CDVictory, tonumber(arg2)))
					CombatMusic_SavedDB.Victory.Cooldown = tonumber(arg2)
				end
			end
		else
			-- Eeeoooops, wrong argument #1
			CombatMusic:PrintMessage(L.ERRORS.InvalidArgumentCD, true)
		end
	
	-- /cm extras [gameover|victory|ding] [on|off]
	----------------------------------------------
	elseif command == "extras" then
		-- /cm extras gameover [on|off]
		if arg1 == "gameover" or arg1 == "go" then
			if arg2 == "on" then
				-- Turning it on
				CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.ExtrasGameOver, L.OTHER.On))
				CombatMusic_SavedDB.GameOver.Enabled = true
			elseif arg2 == "off" then
				-- Turning it off
				CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.ExtrasGameOver, L.OTHER.Off))
				CombatMusic_SavedDB.GameOver.Enabled = false
			else
				CombatMusic:PrintMessage(L.ERRORS.OnOrOff, true)
			end
			
		-- /cm extras victory [on|off]
		elseif arg1 == "victory" or arg1 == "vic" then
			if arg2 == "on" then
				-- Turning it on
				CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.ExtrasVictory, L.OTHER.On))
				CombatMusic_SavedDB.Victory.Enabled = true
			elseif arg2 == "off" then
				-- Turning it off
				CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.ExtrasVictory, L.OTHER.Off))
				CombatMusic_SavedDB.Victory.Enabled = false
			else
				CombatMusic:PrintMessage(L.ERRORS.OnOrOff, true)
			end
		-- /cm extras ding [on|off]
		elseif arg1 == "ding" then
			if arg2 == "on" then
				-- Turning it on
				CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.ExtrasDing, L.OTHER.On))
				CombatMusic_SavedDB.LevelUp.Enabled = true
			elseif arg2 == "off" then
				-- Turning it off
				CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.ExtrasDing, L.OTHER.Off))
				CombatMusic_SavedDB.LevelUp.Enabled = false
			else
				CombatMusic:PrintMessage(L.ERRORS.OnOrOff, true)
			end
		else
			-- Oops, Arg #1 error
			CombatMusic:PrintMessage(L.ERRORS.InvalidArgumentE, true)
		end
	
	-- /cm useding [on|off]
	--------------------------
	elseif command == "useding" then
		if arg1 == "on" then
			-- Turning it on
			CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.NewDing, L.OTHER.On))
			CombatMusic_SavedDB.LevelUp.NewFanfare = true
		elseif arg1 == "off" then
			-- Turning it off
			CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.NewDing, L.OTHER.Off))
			CombatMusic_SavedDB.LevelUp.NewFanfare = false
		else
			CombatMusic:PrintMessage(L.ERRORS.OnOrOff, true)
		end
	
	
	-- /cm usefocus [on|off]
	------------------------
	elseif command == "usefocus" then
		if arg1 == "on" then
			-- Turning it on
			CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.UseFocus, L.OTHER.On))
			CombatMusic_SavedDBPerChar.PreferFocusTarget = true
		elseif arg1 == "off" then
			-- Turning it off
			CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.UseFocus, L.OTHER.Off))
			CombatMusic_SavedDBPerChar.PreferFocusTarget = false
		else
			CombatMusic:PrintMessage(L.ERRORS.OnOrOff, true)
		end
		
	-- /cm usebosstargets [on|off]
	elseif command == "usebosstargets" or command == "useboss" then
			if arg1 == "on" then
			-- Turning it on
			CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.UseBossTargets, L.OTHER.On))
			CombatMusic_SavedDBPerChar.CheckBossTargets = true
		elseif arg1 == "off" then
			-- Turning it off
			CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.UseBossTargets, L.OTHER.Off))
			CombatMusic_SavedDBPerChar.CheckBossTargets = false
		else
			CombatMusic:PrintMessage(L.ERRORS.OnOrOff, true)
		end
	
	-- /cm volume [#]
	-----------------
	elseif command == "volume" then
		-- Change the in-combat volume settings:
		if not tonumber(arg1) then
			-- Output the current setting
			CombatMusic:PrintMessage(format(L.OTHER.PrintSetting, L.OTHER.Volume, CombatMusic_SavedDB.Music.Volume))
		else
			if tonumber(arg1) <= 0 or tonumber(arg1) > 1 then
				CombatMusic:PrintMessage(L.ERRORS.Between0And1, true)
			else
				CombatMusic:PrintMessage(format(L.OTHER.ChangeSetting, L.OTHER.Volume, tonumber(arg1)))
				CombatMusic_SavedDB.Music.Volume = tonumber(arg1)
			end
		end
	
	-- /cm fade {#|off}
	-------------------
	elseif command == "fade" then
		-- If it's passed with no argument, then show
		if not tonumber(arg1) and arg1 ~= "off" then
			-- Check to see if the user has the setting turned off, that way we can show them a different message
			if CombatMusic_SavedDB.Music.FadeOut ~= 0 then
				CombatMusic:PrintMessage(format(L.OTHER.PrintSetting, L.OTHER.Fade, CombatMusic_SavedDB.Music.FadeOut))
			else
				CombatMusic:PrintMessage(format(L.OTHER.ShowState, L.OTHER.Fade, L.OTHER.Off))
			end
		else
			if arg1 == "off" then
				-- Turn off this feature
				CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.Fade, L.OTHER.Off))
				CombatMusic_SavedDB.Music.FadeOut = 0
			elseif tonumber(arg1) <= 0 then
				-- Print an error
				CombatMusic:PrintMessage(L.ERRORS.BiggerThan0, true)
			else
				-- Set it to what the user passed
				CombatMusic:PrintMessage(format(L.OTHER.ChangeSetting, L.OTHER.Fade, tonumber(arg1)))
				CombatMusic_SavedDB.Music.FadeOut = tonumber(arg1)
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
			CM_DumpBossList()
		end

	-- /cm debug [on|off]
	---------------------
	elseif command == "debug" then
		if arg1 == "on" then
			-- Turning it on
			CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.Debug, L.OTHER.On))
			CombatMusic._DebugMode = true
		elseif arg1 == "off" then
			-- Turning it off
			CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.Debug, L.OTHER.Off))
			CombatMusic._DebugMode = false
		else
			CombatMusic:PrintMessage(L.ERRORS.OnOrOff, true)
		end
		
	-- /cm comm [on|off]
	--------------------
	elseif command == "comm" then
		if arg1 == "on" then
			-- Turning it on
			CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.Comm, L.OTHER.On))
			CombatMusic_SavedDB.AllowComm = true
		elseif arg1 == "off" then
			-- Turning it off
			CombatMusic:PrintMessage(format(L.OTHER.ToggleState, L.OTHER.Comm, L.OTHER.Off))
			CombatMusic_SavedDB.AllowComm = false
		else
			CombatMusic:PrintMessage(L.ERRORS.OnOrOff, true)
		end
	else
		-- Whoops, someone made a booboo if we got here.
		CombatMusic:PrintMessage(L.ERRORS.InvalidCommand, true)	
	end
end


-- CombatMusic_OnEvent: Handles events fired by the WoW client
function CombatMusic_OnEvent(self, event, ...)
	local arg1, arg2 = ...
	-- PLAYER_ENTERING_WORLD: Finishing the loading sequence
	if event == "PLAYER_ENTERING_WORLD" and not CombatMusic.Info.Loaded then
		--@alpha@ 
		CombatMusic._DebugMode = true
		--@end-alpha@
		CombatMusic:PrintMessage(L.OTHER.Loaded)
		CombatMusic:PrintMessage(L.OTHER.DebugLoaded, false, true)
		CombatMusic:SetTimer(2, function()
				CM_CheckSettingsLoaded()
				CombatMusic["Info"]["Loaded"] = true
			end
		)
		return
	
	-- PLAYER_LEVEL_UP: Plays the Ding song
	elseif event == "PLAYER_LEVEL_UP" then
		return CombatMusic.LevelUp()
		
	-- PLAYER_REGEN_DISABLED: Entering Combat
	elseif event == "PLAYER_REGEN_DISABLED" then
		return CombatMusic.enterCombat()
		
	-- PLAYER_REGEN_ENABLED: Leaving Combat
	elseif event == "PLAYER_REGEN_ENABLED" then
		return CombatMusic.leaveCombat()
	
	-- PLAYER_DEAD: <==
	elseif event == "PLAYER_DEAD" then
		return CombatMusic.GameOver()
	
	-- PLAYER_TARGET_CHANGED: <==
	elseif event == "PLAYER_TARGET_CHANGED" then
		return CombatMusic.TargetChanged("player")
		
	-- UNIT_TARGET: FocusTarget changed
	elseif event == "UNIT_TARGET" and arg1 == "focus" then
		return CombatMusic.TargetChanged("focus")

	-- INSTANCE_ENCOUNTER_ENGAGE_UNIT: Fired when boss frames are hidden/shown
	elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
		return CombatMusic.TargetChanged("boss1")

	-- PLAYER_LEAVING_WORLD: Used to stop the music for loading screens
	elseif event == "PLAYER_LEAVING_WORLD" then
		return CombatMusic.leaveCombat(true)
	
	-- PARTY_MEMBERS_CHANGED: Used to check the version with group members.
	elseif event == "PARTY_MEMBERS_CHANGED" then
		return CombatMusic:CheckVersions()
	
	-- CHAT_MSG_ADDON: Settings Suvey Comm
	elseif event == "CHAT_MSG_ADDON" then
		return CombatMusic:CheckComm(...)
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
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	self:RegisterEvent("PLAYER_LEAVING_WORLD")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	
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
		text = CombatMusic:ParseColorCodedString(L.OTHER.ResetDialog),
		button1 = YES,
		button2 = NO,
		OnAccept = function()
			CombatMusic.SetDefaults("global")
			ReloadUI()
		end,
		whileDead = true,
		timeout = 0,
		hideOnEscape = true,
		showAlert = true,
	}
	
	-- Popups for BossList add
	StaticPopupDialogs["COMBATMUSIC_BOSSLISTADD"] = {
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
		text = "%s",
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
		if not self.button1:IsEnabled() then
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