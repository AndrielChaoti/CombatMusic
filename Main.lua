--[[
------------------------------------------------------------------------
	Project: Van32sCombatMusic
	File: Main Operations, revision @file-revision@
	Date: @file-date-iso@
	Purpose: The main operations of CombatMusic.
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


CombatMusic["Info"]= {}

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

-- This file contains the addon itself, this is how everything works


-- EnterCombat: We just dropped into combat
function CombatMusic.enterCombat()
	cmPrint("enterCombat()", false, true)
	
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
	
	-- Check the player's target
	CombatMusic.Info["BossFight"] = CombatMusic.CheckTarget("_EC")

	-- Change the CVars to what they need to be
	SetCVar("Sound_EnableMusic", "1")
	SetCVar("Sound_MusicVolume", CombatMusic_SavedDB.Music.Volume)
	
	
	-- Check the BossList.
	local BossList = CombatMusic.CheckBossList()
	
	-- Check to see if music is already fading, stop here, if so.
	if CombatMusic.Info.IsFading then
		cmPrint("IsFading!", false, true)
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


--[[ TargetChanged: The player's target changed.
	This function is linked to a timer, and thus returns a value when the timer should stop
	The value returned depends on why the timer needed to stop:
	1 = Not_Enabled_Error
	2 = In_Combat_Error
	3 = No_Target_Error
]]
function CombatMusic.TargetChanged(unit)
	cmPrint("TargetChanged(".. debugNils(unit) ..")", false, true)
	
	if not CombatMusic_SavedDB.Enabled then return -1 end
	if not CombatMusic.Info.Loaded then return -1 end
	
	-- There's no need to do this again if we already have a boss.
	if CombatMusic.Info.BossFight then return 0 end
	if not CombatMusic.Info.InCombat then return 2 end
	
	-- Check BossList
	local BossList = CombatMusic.CheckBossList()
	if BossList then return 0 end
	
	-- Why am I checking targets if they don't exist?
	if not (UnitExists("focustarget") or UnitExists("target")) then 
		cmPrint("No targets selected!", true, true)
		return 3
	end
	
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
	cmPrint("StartTargetChecks()", false, true)
	if not CombatMusic_SavedDB.Enabled then return end
	if not CombatMusic.Info.Loaded then return end
	
	local focusFirst = CombatMusic_SavedDBPerChar.PreferFocusTarget
	
end


-- CheckBossList: Check, and get the songpath for units on the bosslist
function CombatMusic.CheckBossList()
	cmPrint("CheckBossList()", false, true)
	if CombatMusic_BossList then
		if CombatMusic_BossList[UnitName("target")] then
			PlayMusic(CombatMusic_BossList[UnitName("target")])
			CombatMusic.Info.BossFight = true
			CombatMusic.Info.InCombat = true
			cmPrint("Target on BossList. Playing ".. tostring(CombatMusic_BossList[UnitName("target")]), false, true)
			return true
		elseif CombatMusic_BossList[UnitName("focustarget")] then
			PlayMusic(CombatMusic_BossList[UnitName("focustarget")])
			CombatMusic.Info.BossFight = true
			CombatMusic.Info.InCombat = true
			cmPrint("FocusTarget on BossList. Playing " .. tostring(CombatMusic_BossList[UnitName("focustarget")]), false, true)
			return true
		end
		cmPrint("Target not on BossList.", false, true)
	end
end


-- leaveCombat: Stop the music playing, and reset all our variables
-- If isDisabling, then don't play a victory fanfare when the music stops.
function CombatMusic.leaveCombat(isDisabling)
	cmPrint("leaveCombat(" .. debugNils(isDisabling) .. ")", false, true)
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
			PlaySoundFile("Interface\\Music\\Victory.mp3")
			CombatMusic.RestoreSavedStates()
		end
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
	cmPrint("GameOver()", false, true)
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
	cmPrint("LevelUp()", false, true)
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

-- Re-do this section

-- CheckTarget: Check the unit passed to the function
-- Returns 1 if the target's a boss, otherwise it returns nil
function CombatMusic.CheckTarget(unit)
	cmPrint("CheckTarget(" .. debugNils(unit) .. ")", false, true)
	
	return 1
	return nil
end
--[=[
-- Target Checking.
-- Checks combat -> mobType/instance -> level -> player/inGroup
function CombatMusic.CheckTarget(unit)
	cmPrint("CheckTarget(".. debugNils(unit) ..")", false, true)
	
	-- If it's a boss fight, I don't need to check anything.
	if CombatMusic.Info.BossFight then
		return true
	end
	
	-- Why am I checking targets if they don't exist?
	if not (UnitExists("focustarget") or UnitExists("target")) then 
		cmPrint("No targets selected!", true, true)
		return false
	end
	
	-- Prepare a table full of values we need.
	local targetInfo = {
		level = {
			-- Check for the greater of the two. -1 is forced as the biggest value:
			raw = function()
				-- Get the values
				local t, ft = UnitLevel('target'), UnitLevel('focustarget')
				local te, fte = UnitExists('target'), UnitExists('focusTarget')
				-- If they both exist:
				if te and fte then
					if t == -1 or ft == -1 then
						return -1
					else
						return math.max(t, ft)
					end
				-- Only target exists
				elseif te then
					return t
				-- Only focustarget exists
				elseif fte then
					return ft
				end
			end,
		},
		-- Get if they"re flagged:
		isPvP = UnitIsPVP("focustarget") or UnitIsPVP("target"),
		-- Get if they"re a player:
		isPlayer = UnitIsPlayer("focustarget") or UnitIsPlayer("target"),
		inCombat = UnitAffectingCombat("target") or UnitAffectingCombat("focustarget"),
		-- Get the unit"s classification:
		mobType = function()
			-- Get the types
			-- Get the values
			local t, ft = UnitClassification('target'), UnitClassification('focustarget')
			local te, fte = UnitExists('target'), UnitExists('focusTarget')
			local enumC = {normal = 1, rare = 2, elite = 3, rareelite = 4, worldboss = 5}
			t, ft = enumC[t], enumC[ft]
			-- If they both exist:
			if te and fte then
				return math.max(t, ft)
			-- Only target exists
			elseif te then
				return t
			-- Only focustarget exists
			elseif fte then
				return ft
			end
		end,
		-- Get if the unit's in my group:
		inGroup = function()
			-- Get the values
			local t, ft = (UnitInParty('target') or UnitInRaid('target')), (UnitInParty('focustarget') or UnitInRaid('focustarget'))
			local te, fte = UnitExists('target'), UnitExists('focusTarget')
			-- If they both exist, and both are in my group:
			if te and fte then
				if t and ft then
					return true
				else 
					return false
				end
			-- Only target exists
			elseif te then
				return t
			-- Only focustarget exists
			elseif fte then
				return ft
			end
		end,
		-- Get if the unit is grey:
		isTrival = function()
			-- Get the values
			local t, ft = UnitIsTrivial('target'), UnitIsTrivial('focustarget')
			local te, fte = UnitExists('target'), UnitExists('focusTarget')
			-- If they both exist, and both are trival:
			if te and fte then
				if t and ft then
					return true
				else 
					return false
				end
			-- Only target exists
			elseif te then
				return t
			-- Only focustarget exists
			elseif fte then
				return ft
			end
		end,
	}
	
	-- Get some info about the player:
	local playerInfo = {
		["level"] = UnitLevel("player"),
		["factionGroup"] = UnitFactionGroup("player"),
		["instanceType"] = select(2, GetInstanceInfo()),
	}
	
	-- Prepare a local var
	-- When this is set to true at the end,
	-- the unit is determined to be a boss;
	-- otherwise it's nil.
	local isBoss
	
	-- Set the adjusted level:
	targetInfo.level.adj = targetInfo.level.raw()
	
	-- The actual target check logic starts here:
	
	--[[ Check to see if I'm in combat with one of my targets:
		This is disabled while in debug mode!
		Debug text below to tell me if it would have passed an inCombat check
	]]
	cmPrint("inCombat: " .. CombatMusic.ns(targetInfo.inCombat), false, true)
	if not CombatMusic_DebugMode then
		if not targetInfo.inCombat then
			isBoss = false
			if not isBoss then
				local t = CombatMusic:SetTimer(0.5, CombatMusic.TargetChanged, true, 0, unit)
				if t ~= -1 then
					CombatMusic.Info["updateTimer"] = t
				end
			end
			return isBoss
		end
	end
	
	--[[ Check the monser's classificaton:
			* A 'normal' will never play boss music
			* An 'elite' will never play boss music while inside an instance
			* Anything else, will always play boss music
	]]
	cmPrint("mobType: " .. CombatMusic.ns(targetInfo.mobType()) .. " / instanceType: " .. CombatMusic.ns(playerInfo.instanceType), false, true)
	if targetInfo.mobType() ~= 1 then
		-- We're giving something that's flagged as an elite a 3 level bonus.
		-- This is how we're going to tell if the monster's a boss in an instance.
		if targetInfo.mobType() == 3 or targetInfo.mobType() == 4 then
			targetInfo.level.adj = targetInfo.level.adj + 3
		end
		
		-- Check to see if I'm in an instance
		if (playerInfo.instanceType == "party" or playerInfo.instanceType == "raid") then
			--[[ Check that the mob is a non-elite.
				WoW instances are populated solely by elites and rareelites, so
				we don't want to always have boss music.]]
			if targetInfo.mobType() == 3 then
				isBoss = false
				cmPrint("FALSE!", false, true)
			else
				cmPrint("TRUE!", false, true)
				isBoss = true
			end
		else
			isBoss = true
			cmPrint("TRUE!", false, true)
		end
	elseif targetInfo.mobType() == -2 then
		-- Why are we still here? This means there was no target
		cmPrint("No targets selected!", true, true)
		return false
	end
	

	--[[ This section of code is a bit iffy, I"m not quite sure how to implement it.
			If EITHER codepath returns false, the other MAY NOT provide a TRUE. But if the
			EITHER codepath remains unchanged, it can continue to execute the next.
			In essence, it needs to change the order operators are preferred in:
				- false (stop the code)
				- nil (This is where code would normally stop)
				- true
	]]
	
	
	------------------------------------
	--[[ Checking the levels of our units, this is how we can find out if a mob is a boss in an instance.
			This has the added bonus that it also affects world NPCs.
			* Anything with an adjusted level of > 5 will play boss music
			* A 'trivial' (grey) NPC will never play boss music
	]]
	cmPrint("level.raw: " .. CombatMusic.ns(targetInfo.level.raw()) .. " / level.adj: " .. CombatMusic.ns(targetInfo.level.adj) .. " / isTrivial: " .. CombatMusic.ns(targetInfo.isTrival()) , false, true)
	if targetInfo.level.raw() == -1 or targetInfo.level.adj >= (5 + playerInfo.level) then 
		isBoss = true
		cmPrint("TRUE!", false, true)
	-- If the target is grey to me, do NOT under any circumstances allow the code to continue
	elseif targetInfo.isTrival() then
		isBoss = false
		cmPrint("FALSE! STOPPING CHECK!", false, true)
		-- Recurse this function every half a second if there is no boss.
		CombatMusic:SetTimer(0.5, CombatMusic.TargetChanged)
		return isBoss
	elseif targetInfo.level.raw() == -2 then
		-- Why are we still here? This means there was no target
		cmPrint("No targets selected!", true, true)
		return false
	end
	------------------------------------
	
	
	------------------------------------
	--[[ Checking to see if a player is targetted
			A player that is flagged for PvP will play boss music if:
			* They are not considered 'trival'.
			* They are not in your group.
		]]
	cmPrint("isPlayer: " .. CombatMusic.ns(targetInfo.isPlayer) .. " / isPvP: " .. CombatMusic.ns(targetInfo.isPvP) .. " / inGroup: " .. CombatMusic.ns(targetInfo.inGroup()), false, true)
	if targetInfo.isPlayer then
		-- Is the player flagged?
		if targetInfo.isPvP then
			isBoss = true
			cmPrint("TRUE!", false, true)
		else
			isBoss = false
			cmPrint("FALSE!", false, true)
		end
		-- They're in my group?
		if targetInfo.inGroup() then
			isBoss = false
			cmPrint("FALSE! STOPPING CHECK!", false, true)
			-- Recurse this function every half a second if there is no boss.
			CombatMusic:SetTimer(0.5, CombatMusic.TargetChanged)
			return isBoss or false
		end
	end
	------------------------------------
	
	-- All right, return what we got, if we made it that far.
	cmPrint("Final Result: ".. CombatMusic.ns(isBoss), false, true)
	-- Recurse this function every half a second if there is no boss.
	if not isBoss then
		local t = CombatMusic:SetTimer(0.5, CombatMusic.TargetChanged, true, 0, unit)
		if t ~= -1 then
			CombatMusic.Info["updateTimer"] = t
		end
	end
	return isBoss or false
end
]=]


-- Saves music state so we can restore it out of combat
function CombatMusic.GetSavedStates()
	cmPrint("GetSavedStates()", false, true)
	-- Music was turned on?
	CombatMusic.Info["EnabledMusic"] = GetCVar("Sound_EnableMusic") or "0"
	-- Music Volume?
	CombatMusic.Info["MusicVolume"] = GetCVar("Sound_MusicVolume") or "1"
end


-- Restore the settings that were changed by CombatMusic
function CombatMusic.RestoreSavedStates()
	cmPrint("RestoreSavedStates()", false, true)
	CombatMusic.Info.FadeTimerVars = nil
	CombatMusic.Info.RestoreTimer = nil
	if not CombatMusic.Info.EnabledMusic then return end
	SetCVar("Sound_EnableMusic", tostring(CombatMusic.Info.EnabledMusic))
	if not CombatMusic.Info.MusicVolume then return end
	SetCVar("Sound_MusicVolume", tostring(CombatMusic.Info.MusicVolume))
end


-- Fading start
function CombatMusic.FadeOutStart()
	cmPrint("FadeOutStart()", false, true)
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
	cmPrint("FadeOutPlayingMusic()", false, true)
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
	
	cmPrint("FadeVolume: " .. CurVol * 100, false, true)
		
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
	cmPrint(CombatMusic_Colors.var .. "CheckComm(" .. CombatMusic.ns(prefix) .. "," ..  CombatMusic.ns(message) .. "," ..  CombatMusic.ns(channel) .. "," .. CombatMusic.ns(sender) .. ")", false, true)
	if not CombatMusic_SavedDB.Enabled then return end
	if not CombatMusic_SavedDB.AllowComm then return end
	if not CombatMusic.Info.Loaded then return end
	if prefix ~= "CM3" then return end
	if message ~= "SETTINGS" then return end
	CombatMusic.CommSettings(channel, sender)
end

function CombatMusic.CommSettings(channel, target)
	cmPrint(CombatMusic_Colors.var .. "CommSettings(" .. CombatMusic.ns(channel) .. ", " .. CombatMusic.ns(target) .. ")", false, true)
	if not CombatMusic_SavedDB.AllowComm then return end
	if not CombatMusic_SavedDB.Enabled then return end
	if not CombatMusic.Info.Loaded then return end
	local AddonMsg = format("%s,%d,%d", CombatMusic_VerStr .. " r" .. CombatMusic_Rev, CombatMusic_SavedDB.Music.numSongs.Battles, CombatMusic_SavedDB.Music.numSongs.Bosses)
	if channel ~= "WHISPER" then
		SendAddonMessage("CM3", AddonMsg, channel)
	else
		SendAddonMessage("CM3", AddonMsg, channel, target)
	end
end
