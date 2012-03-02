--[[
------------------------------------------------------------------------
	Project: Van32sCombatMusic
	File: Main Operations, revision @file-revision@
	Date: @file-date-iso@
	Purpose: The main operations of CombatMusic.
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


CombatMusic["Info"]= {}
local L = CM_STRINGS

--debugNils: Returns literal "nil" or the tostring of all of the arguments passed to it.
local function debugNils(...)
	local tmp = {}
	for i = 1, select("#", ...) do
		tmp[i] = tostring(select(i, ...)) or "nil"
	end
	return table.concat(tmp, ", ")
end

-- This file contains the addon itself, this is how everything works
do
	local oldPM = PlayMusic
	PlayMusic = function(...)
		CombatMusic:PrintDebug("PlayMusic($V" .. debugNils(...) .. "$C)")
		return oldPM(...)
	end
end


-- EnterCombat: We just dropped into combat
function CombatMusic.enterCombat()
	CombatMusic:PrintDebug("$GenterCombat()", false)
	
	--Check that CombatMusic is turned on and "initialized"
	if not CombatMusic_SavedDB.Enabled then return end
	if not CombatMusic.Info.Loaded then return end
	
	
	-- Make sure we're not in combat before trying to enter it again
	if CombatMusic.Info.InCombat then
		CombatMusic.RestoreSavedStates()
	end
	
	-- Cancel the music fade-out if it's fading.
	if CombatMusic.Info.FadeTimerVars then
		if CombatMusic.Info.FadeTimerVars.FadeTimer then
			CombatMusic:KillTimer(CombatMusic.Info.FadeTimerVars.FadeTimer)
		end
		-- Restore the saved states, so they can be saved again.
		CombatMusic.RestoreSavedStates()
	end
	
	--Cancel restoring saved states if it's trying to.
	if CombatMusic.Info.RestoreTimer then
		CombatMusic:KillTimer(CombatMusic.Info.RestoreTimer)
		CombatMusic.RestoreSavedStates()
	end
	-- Save the CVar's last states, before continuing
	CombatMusic.GetSavedStates()
	
	
	-- Check the BossList.
	local BossList = CombatMusic.CheckBossList()
	-- Check the player's target
	CombatMusic.Info["BossFight"] = CombatMusic.StartTargetChecks()

	
	-- Change the CVars to what they need to be
	SetCVar("Sound_EnableMusic", "1")
	SetCVar("Sound_MusicVolume", CombatMusic_SavedDB.Music.Volume)
	
	-- Check to see if music is already fading, stop here, if so.
	if CombatMusic.Info.IsFading then
		CombatMusic:PrintDebug("   IsFading!", false)
		CombatMusic.Info.IsFading = nil
		CombatMusic.Info.InCombat = true
		if CombatMusic.Info.EnabledMusic ~= "0" then return end
	end
	
	if BossList then return end
	
	CombatMusic.Info["InCombat"] = true
	-- Play the music
	local filePath = "Interface\\Music\\%s\\%s%d.mp3"
	if CombatMusic.Info.BossFight then
		if CombatMusic_SavedDB.Music.numSongs.Bosses > 0 then
			PlayMusic(format(filePath, "Bosses", "Boss", random(1, CombatMusic_SavedDB.Music.numSongs.Bosses)))
		else
			CombatMusic.leaveCombat(1)
		end
	else
		if CombatMusic_SavedDB.Music.numSongs.Battles > 0 then
			PlayMusic(format(filePath, "Battles", "Battle", random(1, CombatMusic_SavedDB.Music.numSongs.Battles)))
		else
			CombatMusic.leaveCombat(1)
		end
	end
end



-- GetTargetList: generates a target list for the functions that require it.
local function GetTargetList()
	-- Generate our list of targets to check
	local focusFirst = CombatMusic_SavedDBPerChar.PreferFocusTarget
	local tList = {}
	if focusFirst then
		tList = {"focustarget", "target"}
	else
		tList = {"target", "focusTarget"}
	end
	
	if CombatMusic_SavedDBPerChar.CheckBossTargets then
		for i = 1, 4 do
			tList[#tList + 1] = "boss" .. i
		end
	end
	CombatMusic:PrintDebug("   tList = {" .. table.concat(tList, ", ") .. "}")
	return tList
end

--[[ TargetChanged: The player's target changed.
	This function is linked to a timer, and thus returns a value when the timer should stop
	The value returned depends on why the timer needed to stop:
	1 = Not_Enabled_Error
	2 = In_Combat_Error
	3 = No_Target_Error
]]
function CombatMusic.TargetChanged(unit)
	CombatMusic:PrintDebug("TargetChanged(".. debugNils(unit) ..")", false)
	
	if not CombatMusic_SavedDB.Enabled then return -1 end
	if not CombatMusic.Info.Loaded then return -1 end
	
	-- There's no need to do this again if we already have a boss.
	if CombatMusic.Info.BossFight then return 0 end
	if not CombatMusic.Info.InCombat then return 2 end
	
	local notargets = true
	-- No need to check if there are no valid targets
	-- Generate our list of targets to check
	local tList = GetTargetList()
	
	for _, v in ipairs(tList) do
		if UnitExists(v) then notargets = false end
	end	
	
	if notargets then return 3; end
	
	-- Check BossList
	local BossList = CombatMusic.CheckBossList()
	if BossList then return 0 end
	
	CombatMusic.Info["BossFight"] = CombatMusic.StartTargetChecks()
	
	-- Get that music changed
	local filePath = "Interface\\Music\\%s\\%s%d.mp3"
	if CombatMusic.Info.BossFight then
		PlayMusic(format(filePath, "Bosses", "Boss", random(1, CombatMusic_SavedDB.Music.numSongs.Bosses)))
		return 0
	end
end


-- StartTargetChecks: Starts the target checks, and acts as a wrapper for CheckTarget
function CombatMusic.StartTargetChecks()
	CombatMusic:PrintDebug("StartTargetChecks()", false)
	if not CombatMusic_SavedDB.Enabled then return end
	if not CombatMusic.Info.Loaded then return end
	
	-- Generate our list of targets to check
	local tList = GetTargetList()
	
	-- Generate our results lists based off of all of the targets.
	for _, v in ipairs(tList) do
		isBoss, startTimer = CombatMusic.CheckTarget(v)
		CombatMusic:PrintDebug(format("  $E===$C" .. v .. ": isBoss = $V%s$C, startTimer = $V%s$C", tostring(isBoss), tostring(startTimer)))
		
		-- Check the list
		if startTimer then
			local t = CombatMusic:SetTimer(0.5, CombatMusic.TargetChanged, true, "CMUpdateTimer")
			if t ~= -1 then
				CombatMusic.Info["UpdateTimer"] = t
			end
		end
		
		if isBoss then
			return true
		end
		
	end
		
	-- If we made it this far, then none of them are valid bosses...
	return false
end

-- CheckTarget: Check the unit passed to the function
-- Returns: isBoss, startTimer
function CombatMusic.CheckTarget(unit)
	CombatMusic:PrintDebug("CheckTarget(" .. debugNils(unit) .. ")", false)
	-- Define our return value's default state
	local isBoss = nil
	
	-- They didn't send a unit declaration
	assert(unit, "Usage: CheckTarget(\"unit\")")
	
	-- If it's already a boss, we're not changing anything
	if CombatMusic.Info.BossFight then
		return true, false
	end
	
	-- If the target doesn't exist, return false
	if not UnitExists(unit) then
		CombatMusic:PrintDebug("$V" .. tostring(unit) .. "$C doesn't exist.", true)
		return false, false
	end
	
	-- Get the info we need
	local unitInfo = {
		level = {
			raw = UnitLevel(unit),
			adj = UnitLevel(unit)
		},
		isPvP = UnitIsPVP(unit) or UnitIsPVPFreeForAll(unit),
		isPlayer = UnitIsPlayer(unit),
		inCombat = function()		
				if UnitAffectingCombat(unit) then
					return true
				elseif not UnitAffectingCombat(unit) and CombatMusic.DebugMode then
					return true
				else 
					return false
				end
			end,
		mobType = function()
				local enumC = {normal = 1, rare = 2, elite = 3, rareelite = 4, worldboss = 5}
				local C = UnitClassification(unit)
				return enumC[C]
			end,
		inGroup = (UnitInParty(unit) or UnitInRaid(unit)),
		isTrivial = UnitIsTrivial(unit)
	}
	
	local playerInfo = {
		level = UnitLevel('player'),
		instanceType = select(2, GetInstanceInfo('player'))
	}
	
	
	
	-- If the target's not in combat, then don't play boss music
	-- In debug mode, the addon will skip checking this
	if not unitInfo.inCombat() then
		CombatMusic:PrintDebug(format("   inCombat = $V%s$C", tostring(unitInfo.inCombat())))
		return false, true
	end

	-- Check the monster's type, and if we're in an instance:
	CombatMusic:PrintDebug(format("   mobType = $V%s$C, instanceType = $V%s$C", tostring(unitInfo.mobType()), tostring(playerInfo.instanceType)))
	if unitInfo.mobType() ~= 1 then
		-- We give elites a +3 to the adjusted level check, appropriately. This is how we can tell what NPCs are bosses in 5-mans
		if unitInfo.mobType() == 3 or unitInfo.mobType() == 4 then
			unitInfo.level.adj = unitInfo.level.raw + 3
		end
	
		-- Instance check
		if playerInfo.instanceType == "party" or playerInfo.instanceType == "raid" then
			-- Check the mobtype again here.
			-- Instances are populated with elites, so playing boss music all the time is bad
			if unitInfo.mobType() == 3 then	
				isBoss = false
			else
				isBoss = true
			end
		else
			isBoss = true
		end

		-- WorldBoss check
		if unitInfo.mobType() == 5 then
			isBoss = true
		end
	end
	CombatMusic:PrintDebug(format("     isBoss = $V%s$C", tostring(isBoss)))
	
	--[[ The sections of code below are a bit tricky to understand, so I'll explain it
			Each path of code seperated by the horizontal lines can both be run, but if one
			is set to false, then the other cannot set a true.
		]]
		
	
	------------------------------------
	--[[ Checking the levels of our units, this is how we can find out if a mob is a boss in an instance.
			This has the added bonus that it also affects world NPCs.
			* Anything with an adjusted level of > 5 will play boss music
				- This does not apply to raid instance mobs, because they frequently are 2 to 3 levels above the raid's 'par level'
			* A 'trivial' (grey) NPC will never play boss music
	]]
	
	CombatMusic:PrintDebug(format("   raw = $V%s$C, adj = $V%s$C, playerLevel = $V%s$C", tostring(unitInfo.level.raw), tostring(unitInfo.level.adj), tostring(playerInfo.level)))
	-- Check if we're in a raid instance. General raid mobs can, and have triggered boss fights
	if playerInfo.instanceType ~= "raid" then
		if unitInfo.level.adj >= 5 + playerInfo.level then
			isBoss = true
		end
	end
	
	-- If the unit's level is -1 then it means they're more than 10 levels higer than the player or a worldboss
	if unitInfo.level.raw == -1 then
		isBoss = true
	end
	
	-- Check to see if the unit is trivial or not
	if unitInfo.isTrival then
		isBoss = false
		CombatMusic:PrintDebug("TRIVAL", true)
		return isBoss, true
	end
	CombatMusic:PrintDebug(format("     isBoss = $V%s$C", tostring(isBoss)))
	------------------------------------
	
	
	------------------------------------
	--[[ Checking to see if a player is targetted
			A player that is flagged for PvP will play boss music if:
			* They are not considered 'trival'.
			* They are not in your group.
		]]
	CombatMusic:PrintDebug(format("   isPlayer = $V%s$C, isPvP = $V%s$C, inGroup = $V%s$C", tostring(unitInfo.isPlayer), tostring(unitInfo.isPvP), tostring(unitInfo.inGroup)))
	if unitInfo.isPlayer then
		if unitInfo.isPvP then
			isBoss = true
		else
			isBoss = false
		end
		if unitInfo.inGroup then
			isBoss = false
			CombatMusic:PrintDebug("IN GROUP", true)
			return isBoss, true
		end
	end
	CombatMusic:PrintDebug(format("     isBoss = $V%s$C", tostring(isBoss)))
	------------------------------------
	-- Return if the target's a boss or not, and if we should check again. We only really need to check again if the target's not in combat.
	return isBoss or false, not unitInfo.inCombat()
end


-- CheckBossList: Check, and get the songpath for units on the bosslist
function CombatMusic.CheckBossList()
	CombatMusic:PrintDebug("CheckBossList()", false)
	if CombatMusic_BossList then

		local tList = GetTargetList()
		-- use ipairs to do the focus/target checks.
		for k, v in ipairs(tList) do
			if CombatMusic_BossList[UnitName(v)] then
				PlayMusic(CombatMusic_BossList[UnitName(v)])
				CombatMusic.Info.BossFight = true
				CombatMusic.Info.InCombat = true
				CombatMusic:PrintDebug("   " .. v .. " found.. playing " .. CombatMusic_BossList[UnitName(v)])
				return true
			end
		end
		
		CombatMusic:PrintDebug("Target not on BossList.", false)
	end
end


-- leaveCombat: Stop the music playing, and reset all our variables
-- If isDisabling, then don't play a victory fanfare when the music stops.
function CombatMusic.leaveCombat(isDisabling)
CombatMusic:PrintDebug("$GleaveCombat(" .. debugNils(isDisabling) .. ")", false)
	--Check that CombatMusic is turned on
	if not CombatMusic_SavedDB.Enabled then return end
	if not CombatMusic.Info.Loaded then return end
	if not CombatMusic.Info.InCombat then return end
	
	-- OhNoes! The player's dead, don't want no fanfares playing...
	if UnitIsDeadOrGhost("player") then return end
	
	-- Check for boss fight, and if the user wants to hear it....
	if CombatMusic_SavedDB.Victory.Enabled and not isDisabling and CombatMusic.Info.BossFight then
		StopMusic()
		--Boss Only?
		if (not CombatMusic.Info.FanfareCD) or (GetTime() >= CombatMusic.Info.FanfareCD) then
			CombatMusic.Info["FanfareCD"] = GetTime() + CombatMusic_SavedDB.Victory.Cooldown
			PlaySoundFile("Interface\\Music\\Victory.mp3", "Master")
		end
		CombatMusic.RestoreSavedStates()
	elseif isDisabling then
		StopMusic()
		CombatMusic.RestoreSavedStates()
	else
		-- Left Combat normally, start the fading cycle
		CombatMusic.FadeOutStart()
	end
	
	CombatMusic.Info.InCombat = nil
	CombatMusic.Info.BossFight = nil
	
end


-- GameOver: Play a little... jingle... when they player dies
-- Aww, I died, play some game over music for me
function CombatMusic.GameOver()
	CombatMusic:PrintDebug("GameOver()", false)
	--Check that CombatMusic is turned on
	if not CombatMusic_SavedDB.Enabled then return end
	if not CombatMusic.Info.Loaded then return end
	
	StopMusic()
	if CombatMusic.Info.InCombat then
		--Leaving Combat, restore the saved vars.
		CombatMusic.RestoreSavedStates()
	end
		
	-- No music fading for game over, so skip that step
	
	-- Too bad, play the gameover, if it's not on CD, and the user wants to hear it
	if CombatMusic_SavedDB.GameOver.Enabled then
		if (not CombatMusic.Info.GameOverCD) or (GetTime() >= CombatMusic.Info.GameOverCD) then
			CombatMusic.Info["GameOverCD"] = GetTime() + CombatMusic_SavedDB.GameOver.Cooldown
			PlaySoundFile("Interface\\Music\\GameOver.mp3", "Master")
		end
	end
	
	CombatMusic.Info.InCombat = nil
	CombatMusic.Info.BossFight = nil
end


-- LevelUp: Play a jingle when the player levels up.
-- This plays the jingle on top of the rest of the sounds.
function CombatMusic.LevelUp()	
	CombatMusic:PrintDebug("LevelUp()", false)
	--Check that CombatMusic is turned on
	if not CombatMusic_SavedDB.Enabled then return end
	if not CombatMusic.Info.Loaded then return end
	
	-- Yay, play the fanfare.. if it's not on cooldown, and the user wants to hear it.
	-- We have two options here, Check to see if they want to use their victory fanfare, or the new
	--   level up fanfare.
	if CombatMusic_SavedDB.LevelUp.Enabled and CombatMusic_SavedDB.LevelUp.NewFanfare then
		if (not CombatMusic.Info.FanfareCD) or (GetTime() >= CombatMusic.Info.FanfareCD) then
			CombatMusic.Info["FanfareCD"] = GetTime() + CombatMusic_SavedDB.Victory.Cooldown
			PlaySoundFile("Interface\\Music\\DING.mp3", "Master")
		end
	elseif CombatMusic_SavedDB.LevelUp.Enabled and not CombatMusic_SavedDB.LevelUp.NewFanfare then
		if (not CombatMusic.Info.FanfareCD) or (GetTime() >= CombatMusic.Info.FanfareCD) then
			CombatMusic.Info["FanfareCD"] = GetTime() + CombatMusic_SavedDB.Victory.Cooldown
			PlaySoundFile("Interface\\Music\\Victory.mp3", "Master")
		end
	end
end


-- Saves music state so we can restore it out of combat
function CombatMusic.GetSavedStates()
	CombatMusic:PrintDebug("GetSavedStates()", false)
	-- Music was turned on?
	CombatMusic.Info["EnabledMusic"] = GetCVar("Sound_EnableMusic") or "0"
	-- Music Volume?
	CombatMusic.Info["MusicVolume"] = GetCVar("Sound_MusicVolume") or "1"
end


-- Restore the settings that were changed by CombatMusic
function CombatMusic.RestoreSavedStates()
	CombatMusic:PrintDebug("RestoreSavedStates()", false)
	CombatMusic.Info.FadeTimerVars = nil
	CombatMusic.Info.RestoreTimer = nil
	if not CombatMusic.Info.EnabledMusic then return end
	SetCVar("Sound_EnableMusic", tostring(CombatMusic.Info.EnabledMusic))
	if not CombatMusic.Info.MusicVolume then return end
	SetCVar("Sound_MusicVolume", tostring(CombatMusic.Info.MusicVolume))
end


-- Fading start
function CombatMusic.FadeOutStart()
	CombatMusic:PrintDebug("FadeOutStart()", false)
	local FadeTime = CombatMusic_SavedDB.Music.FadeOut
	if FadeTime == 0 then 
		StopMusic()
		CombatMusic.RestoreSavedStates()
		return
	end
	-- Check to make sure a fade timer isn"t already running.
	if CombatMusic.Info.IsFading then
		return
	end
	
	-- Divide the process up into 20 steps.
	local interval = FadeTime / 20
	local volStep = CombatMusic_SavedDB.Music.Volume / 20
	CombatMusic.Info["FadeTimerVars"] = {
		FadeTimer = CombatMusic:SetTimer(interval, CombatMusic.FadeOutPlayingMusic, true),
		MaxVol = CombatMusic_SavedDB.Music.Volume,
		VolStep = volStep,
	}
	CombatMusic.Info["IsFading"] = true
end

-- Fading function
function CombatMusic.FadeOutPlayingMusic()
	CombatMusic:PrintDebug("FadeOutPlayingMusic()", false)
	-- Set some args
	local MaxVol = CombatMusic.Info.FadeTimerVars.MaxVol
	local CurVol = CombatMusic.Info.FadeTimerVars.CurVol
	local Step = CombatMusic.Info.FadeTimerVars.VolStep
	local FadeFinished
	
	-- Check if CurVol is set
	if not CurVol then
		CurVol = tonumber(MaxVol)
	end
	-- Subtract a step
	CurVol = CurVol - Step
	
	-- Because of stupid floating point:
	if CurVol <= 0 then
		CurVol = 0
		FadeFinished = true
	end
	
	CombatMusic:PrintDebug("   FadeVolume: " .. CurVol * 100, false)
		
	SetCVar("Sound_MusicVolume", tostring(CurVol))
	CombatMusic.Info.FadeTimerVars.CurVol = CurVol
	if FadeFinished then
		CombatMusic.Info.FadeTimerVars = nil
		SetCVar("Sound_MusicVolume", "0")
		StopMusic()
		CombatMusic.Info["RestoreTimer"] = CombatMusic:SetTimer(2, CombatMusic.RestoreSavedStates)
		CombatMusic.Info.IsFading = nil
		return true
	end
end


-- My survey function
--[=[ DISCLAIMER: 
		THIS CODE IS USED TO SEND INFORMATION ABOUT YOUR CURRENT COMBATMUSIC 
		CONFIGURATION TO THE PLAYER WHO ASKS FOR IT. THE INFORMATION SENT IS AS FOLLOWS:
		 -YOUR TOON'S NAME (THIS IS AVAILABLE TO THE DEFAULT API AND IS IN NO WAY USED
				TO IDENTIFY YOU BEYOND SEPERATING REPLIES.)
		 -YOUR VERSION OF COMBATMUSIC
		 -YOUR NUMBER OF BOSS AND BATTLE SONGS
		 
		I ADDED THIS FUNCTIONALITY IN, MERELY OUT OF CURIOSITY AS TO WHO USES THE ADDON.
		DON'T WORRY, YOUR INFORMATION IS NOT STORED, OR USED IN ANY WAY.
		
		TO DISABLE THIS, ENTER INTO YOUR CHAT '/cm comm off' WITHOUT THE QUOTES.
		IF YOU SHOULD CHANGE YOUR MIND, ENTER '/cm comm on' WITHOUT QUOTES TO RE-ENABLE.
]=]

function CombatMusic.CheckComm(prefix, message, channel, sender)
	CombatMusic:PrintDebug("CheckComm(" .. debugNils(prefix, message, channel, sender) .. ")", false)
	if not CombatMusic_SavedDB.Enabled then return end
	if not CombatMusic_SavedDB.AllowComm then return end
	if not CombatMusic.Info.Loaded then return end
	if prefix ~= "CM3" then return end
	if message ~= "SETTINGS" then return end
	CombatMusic.CommSettings(channel, sender)
end

function CombatMusic.CommSettings(channel, target)
	CombatMusic:PrintDebug("CommSettings(" .. debugNils(channel, target) .. ")", false)
	if not CombatMusic_SavedDB.AllowComm then return end
	if not CombatMusic_SavedDB.Enabled then return end
	if not CombatMusic.Info.Loaded then return end
	local AddonMsg = format(L.OTHER.CommString, CombatMusic_SavedDB.Music.numSongs.Battles, CombatMusic_SavedDB.Music.numSongs.Bosses)
	if channel ~= "WHISPER" then
		SendAddonMessage("CM3", AddonMsg, channel)
	else
		SendAddonMessage("CM3", AddonMsg, channel, target)
	end
end
