﻿--[[
------------------------------------------------------------------------
	Project: Van32sCombatMusic
	File: Main Operations, revision @file-revision@
	Date: @project-date-iso@
	Purpose: The main operations of CombatMusic.
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


CombatMusic["Info"]= {}



-- Entering Combat
function CombatMusic.enterCombat()

	--Check that CombatMusic is turned on
	if not CombatMusic_SavedDB.Enabled then return end
	
	-- Make sure we're not in combat before trying to enter it again
	if CombatMusic.Info.InCombat then
		CombatMusic.RestoreSavedStates()
	end
	
	if CombatMusic.Info.FadeTimerVars then
		if CombatMusic.Info.FadeTimerVars.FadeTimer then
			CombatMusic.KillTimer(CombatMusic.Info.FadeTimerVars.FadeTimer)
		end
		if CombatMusic.Info.FadeTimerVars.RestoreTimer then
			CombatMusic.KillTimer(CombatMusic.Info.FadeTimerVars.RestoreTimer)
		end
		CombatMusic.Info.FadeTimerVars = nil
		CombatMusic.RestoreSavedStates()
	end
	
	-- Save the CVar's last states, before continuing
	CombatMusic.GetSavedStates()
	
	-- Check the player's target
	CombatMusic.Info["BossFight"] = CombatMusic.CheckTarget()
	-- Set the timer to check the target every 0.5 seconds:
	if not CombatMusic.Info["BossFight"] then
		CombatMusic.Info["TargetUpdateTimer"] = CombatMusic.SetTimer(0.5, CombatMusic.TargetChanged, true, "player")
		CombatMusic.Info["TargetUpdateTimer"] = CombatMusic.SetTimer(0.5, CombatMusic.TargetChanged, true, "focus")
	end
	
	-- Change the CVars to what they need to be
	SetCVar("Sound_EnableMusic", "1")
	SetCVar("Sound_MusicVolume", CombatMusic_SavedDB.MusicVolume)
	
	-- Make sure i'm not fading out music, or already in combat, otherwise, just quit before trying to play new music.
	if CombatMusic.Info.IsFading then
		CombatMusic.Info.IsFading = nil
		return
	end
	
	-- Play the music
	local filePath = "Interface\\Music\\%s\\%s%d.mp3"
	
	-- Check Boss music selections...
	if CombatMusic_BossList then
		if CombatMusic_BossList[UnitName('target')] then
			PlayMusic(CombatMusic_BossList[UnitName('target')])
			CombatMusic.Info.BossFight = true
			CombatMusic.PrintMessage("Target on BossList. Playing ".. tostring(CombatMusic_BossList[UnitName('target')]), false, true)
			return
		elseif CombatMusic_BossList[UnitName('focustarget')] then
			PlayMusic(CombatMusic_BossList[UnitName('focustarget')])
			CombatMusic.Info.BossFight = true
			CombatMusic.PrintMessage("FocusTarget on BossList. Playing " .. tostring(CombatMusic_BossList[UnitName('focustarget')]), false, true)
			return
		end
		CombatMusic.PrintMessage("Target not on BossList", false, true)
	end
	if CombatMusic.Info.BossFight then
		PlayMusic(format(filePath, "Bosses", "Boss", random(1, CombatMusic_SavedDB.numSongs.Bosses)))
	else
		PlayMusic(format(filePath, "Battles", "Battle", random(1, CombatMusic_SavedDB.numSongs.Battles)))
	end
	CombatMusic.Info["InCombat"] = true
end

-- Player Changed Target
function CombatMusic.TargetChanged(unit)
	if not CombatMusic_SavedDB.Enabled then return end
	
	-- Only changing target, so addtional checks, it's not going to change the music unless it's from reg to boss
	if CombatMusic.Info.BossFight then return end
	if not CombatMusic.Info.InCombat then return end
	
	CombatMusic.Info["BossFight"] = CombatMusic.CheckTarget(unit .. "target")
	
	-- Get that music changed
	local filePath = "Interface\\Music\\%s\\%s%d.mp3"
	if CombatMusic.Info.BossFight then
		-- Check Boss music selections...
		if CombatMusic_BossList then
			if CombatMusic_BossList[UnitName('target')] then
				PlayMusic(CombatMusic_BossList[UnitName('target')])
				return
			elseif CombatMusic_BossList[UnitName('focustarget')] then
				PlayMusic(CombatMusic_BossList[UnitName('focustarget')])
				return
			end
		end
		PlayMusic(format(filePath, "Bosses", "Boss", random(1, CombatMusic_SavedDB.numSongs.Bosses)))
		if CombatMusic.Info.TargetUpdateTimer then
			CombatMusic.KillTimer(CombatMusic.Info.TargetUpdateTimer)
		end
		return true
	end
end


-- Leaving Combat
-- Stop the music playing if it's leaving combat.
-- If isDisabling, then don't play a victory fanfare when the music stops.
function CombatMusic.leaveCombat(isDisabling)
	--Check that CombatMusic is turned on
	if not CombatMusic_SavedDB.Enabled then return end
	if not CombatMusic.Info.InCombat then return end
	
	-- OhNoes! The player's dead, don't want no fanfares playing...
	if UnitIsDeadOrGhost("player") then return end
	

	
	-- Check for boss fight, and if the user wants to hear it...
	if CombatMusic.Info.BossFight and CombatMusic_SavedDB.PlayWhen.CombatFanfare and not isDisabling then
		StopMusic()
		-- Yay, play the fanfare.. if it's not on cooldown.
		if (not CombatMusic.Info.FanfareCD) or (GetTime() >= CombatMusic.Info.FanfareCD) then
			CombatMusic.Info["FanfareCD"] = GetTime() + CombatMusic_SavedDB.timeOuts.Fanfare
			PlaySoundFile("Interface\\Music\\Victory.mp3")
		end
	else
		-- Left Combat normally, start the fading cycle
		CombatMusic.FadeOutStart()
	end
	
	
	if CombatMusic.Info.TargetUpdateTimer then
		CombatMusic.KillTimer(CombatMusic.Info.TargetUpdateTimer)
	end
	CombatMusic.Info.InCombat = nil
	CombatMusic.Info.BossFight = nil
	CombatMusic.Info.TargetUpdateTimer = nil
	
end

-- Game Over
-- Aww, I died, play some game over music for me
function CombatMusic.GameOver()
	--Check that CombatMusic is turned on
	if not CombatMusic_SavedDB.Enabled then return end
	
	StopMusic()
	if CombatMusic.Info.InCombat then
		--Leaving Combat, restore the saved vars.
		CombatMusic.RestoreSavedStates()
	end
		
	-- No music fading for game over, so skip that step
	
	-- Too bad, play the gameover, if it's not on CD, and the user wants to hear it
	if CombatMusic_SavedDB.PlayWhen.GameOver then
		if (not CombatMusic.Info.GameOverCD) or (GetTime() >= CombatMusic.Info.GameOverCD) then
			CombatMusic.Info["GameOverCD"] = GetTime() + CombatMusic_SavedDB.timeOuts.GameOver
			PlaySoundFile("Interface\\Music\\GameOver.mp3")
		end
	end
	
	-- Clear those vars, we're not in combat anymore...
	if CombatMusic.Info.TargetUpdateTimer then
		CombatMusic.KillTimer(CombatMusic.Info.TargetUpdateTimer)
	end
	CombatMusic.Info.InCombat = nil
	CombatMusic.Info.BossFight = nil
	CombatMusic.Info.TargetUpdateTimer = nil
	
end


-- DING! Level up handler, just plays the fanfare overtop of whatever's playing... on purpose.
function CombatMusic.LevelUp()
	--Check that CombatMusic is turned on
	if not CombatMusic_SavedDB.Enabled then return end
	
	-- Yay, play the fanfare.. if it's not on cooldown, and the user wants to hear it.
	if CombatMusic_SavedDB.PlayWhen.LevelUp then
		if (not CombatMusic.Info.FanfareCD) or (GetTime() >= CombatMusic.Info.FanfareCD) then
			CombatMusic.Info["FanfareCD"] = GetTime() + CombatMusic_SavedDB.timeOuts.Fanfare
			PlaySoundFile("Interface\\Music\\Victory.mp3")
		end
	end

end

-- target Checking. Same logic as the original CombatMusic script I've written in the past.
function CombatMusic.CheckTarget(unit)
	--Check that CombatMusic is turned on
	if not unit then unit = 'target' end
	if not CombatMusic_SavedDB.Enabled then return end
	if not UnitAffectingCombat(unit) then 
		CombatMusic.PrintMessage("Unit not in combat", false, true)
		return nil
	end
	
	local isBoss = false
	
	-- It's automatically a boss if the target is on the list, provided the unit is in combat.
	if CombatMusic_BossList then
		if CombatMusic_BossList[UnitName(unit)] then
			isBoss = true
			return isBoss
		end
	end
	
	-- Get all the info we're going to need
	local targetInfo = {
		["level"] = {
			["raw"] = function()
				local ft, t = UnitLevel("focustarget"), UnitLevel("target")
				-- Either target is a worldboss, return -1
				if ft == -1 or t == -1 then
					return -1
				end
				-- Checking if focustarget exists
				if UnitExists('focustarget') then
					if ft > t then
						-- Focustarget is stronger than target
						return ft
					else
						-- Target is stronger
						return t
					end
				else
					-- No focustarget
					return t
				end
			end,
		},
		["isPvP"] = UnitIsPVP("focustarget") or UnitIsPVP("target"),
		["isPlayer"] = UnitIsPlayer("focustarget") or UnitIsPlayer("target"),
		["mobType"] = function()
			local ft, t = UnitClassification("focustarget"), UnitClassification("target")
			local ct = {normal = 1, rare = 2, elite = 3, rareelite = 4, worldboss = 5 }
			ft, t = ct[ft], ct[t]
			if UnitExists('focustarget') then
				if ft > t then
					-- Focustarget is stronger than target
					return ft
				else
					-- Target is stronger
					return t
				end
			else
				-- No focustarget
				return t
			end
		end,
		["inGroup"] = (UnitInParty("focustarget") or UnitInRaid("focustarget")) or (UnitInParty("target") or UnitInRaid("target")),
		["factionGroup"] = UnitFactionGroup("focustarget") or UnitFactionGroup("target"),
	}
	local playerInfo = {
		["level"] = UnitLevel("player"),
		["factionGroup"] = UnitFactionGroup("player"),
		["instanceType"] = select(2, GetInstanceInfo()),
	}
	local reason = ""
	-- Make those checks
	targetInfo.level["adjusted"] = targetInfo.level.raw()
	-- Checking the mob type, normal mobs aren't bosses...
	if targetInfo.mobType() ~= 1 then
	
		-- Give it a 3 level bonus for being an elite, worldbosses have -1 for a level, and that's checked later.
		if targetInfo.mobType() == 3 or targetInfo.mobType() == 4 then
			targetInfo.level["adjusted"] = targetInfo.level.raw() + 3
		end
		
		isBoss = true
		
		-- If I'm in an instance full of elite mobs, I don't want it playing boss music all the time D.
		if playerInfo.instanceType == "party" or playerInfo.instanceType == "raid" then
		
			-- it's a regular mob in an instance
			if targetInfo.mobType() == 3 then 
				isBoss = false
				reason = reason .. "Elite in instance,"
			else
				-- Lo and behold, it's a boss!
				isBoss = true
			end
		end
	end
	
	-- Checking for players
	if targetInfo.isPlayer and targetInfo.isPvP then
		if not targetInfo.inGroup then
			isBoss = true
		else
			isBoss = false
			reason = reason .. "Player Ingroup,"
		end
	end
	
	-- ogod, it's got -1 for a level(worldBoss, ??) or it's 5 levels higher than me!
	if targetInfo.level.raw() == -1 or targetInfo.level.adjusted >= 5 + playerInfo.level then
		isBoss = true
	elseif targetInfo.level.adjusted <= 5 - playerInfo.level then
		-- Heh, this is too easy... Not a boss anymore.
		isBoss = false
		reason = reason .. "Level too low(" .. targetInfo.level.adjusted ..")"
	end
	if reason == "" then
		reason = "No critera met(" .. targetInfo.level.adjusted .. ")"
	end
	--[[
	MobType: <>
	Level: <>
	Flagged/Player: <> <>
	IsBoss: <>:<>
	]]
	CombatMusic.PrintMessage("MobType: " .. (targetInfo.mobType() or "nil") .. "\n" .. "Level: " .. (targetInfo.level.raw() or "nil") .. "\n" .. "Flagged/Player: " .. (targetInfo.isPvP or "nil") .. " " .. (targetInfo.isPlayer or "nil") .. "\n" .. "IsBoss: " .. (tostring(isBoss) or "nil") .. ":" .. reason, false, true)
	targetInfo = nil
	playerInfo = nil
	return isBoss
	
end

-- Saves music state so we can restore it out of combat
function CombatMusic.GetSavedStates()
	-- Music was turned on?
	CombatMusic.Info["EnabledMusic"] = GetCVar("Sound_EnableMusic") or "0"
	-- Music was looping?
	--CombatMusic.Info["LoopMusic"] = GetCVar("Sound_ZoneMusicNoDelay") or "1"
	-- Music Volume?
	CombatMusic.Info["MusicVolume"] = GetCVar("Sound_MusicVolume") or "1"
end

function CombatMusic.RestoreSavedStates()
	if not CombatMusic.Info.EnabledMusic then return end
	SetCVar("Sound_EnableMusic", tostring(CombatMusic.Info.EnabledMusic))
	if not CombatMusic.Info.MusicVolume then return end
	SetCVar("Sound_MusicVolume", tostring(CombatMusic.Info.MusicVolume))
end


-- Fading start
function CombatMusic.FadeOutStart()
	local FadeTime = CombatMusic_SavedDB.FadeTime
	if FadeTime == 0 then 
		StopMusic()
		CombatMusic.RestoreSavedStates()
		return
	end
	-- Check to make sure a fade timer isn't already running.
	if CombatMusic.Info.IsFading then
		return
	end
	
	-- Divide the process up into 20 steps.
	local interval = FadeTime / 20
	local volStep = CombatMusic_SavedDB.MusicVolume / 20
	CombatMusic.Info["FadeTimerVars"] = {
		FadeTimer = CombatMusic.SetTimer(interval, CombatMusic.FadeOutPlayingMusic, true),
		MaxVol = CombatMusic_SavedDB.MusicVolume,
		VolStep = volStep,
	}
	CombatMusic.Info["IsFading"] = true
end

-- Fading function
function CombatMusic.FadeOutPlayingMusic()
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
	CombatMusic.PrintMessage("FadeVolume: " .. CurVol * 100, false, true)
	
	-- Because of stupid floating point integers:
	if CurVol <= 0 then
		CurVol = 0
		FadeFinished = true
	end
	
	SetCVar("Sound_MusicVolume", tostring(CurVol))
	CombatMusic.Info.FadeTimerVars.CurVol = CurVol
	if FadeFinished then
		--CombatMusic.Info.FadeTimerVars = nil
		SetCVar("Sound_MusicVolume", "0")
		StopMusic()
		CombatMusic.Info.FadeTimerVars["RestoreTimer"] = CombatMusic.SetTimer(2, CombatMusic.RestoreSavedStates)
		CombatMusic.Info.IsFading = nil
		return true
	end
end




-- Timer lib functions:

-- The code below was brought to you in part by the author of Hack.


if CombatMusic.SetTimer then return end
local timers = {}

function CombatMusic.SetTimer(interval, callback, recur, ...)
   local timer = {
      interval = interval,
      callback = callback,
      recur = recur,
      update = 0,
      ...
   }
  timers[timer] = timer
   return timer
end

function CombatMusic.KillTimer(timer)
   timers[timer] = nil
end

-- How often to check timers. Lower values are more CPU intensive.
local granularity = 0.1

local totalElapsed = 0
local function OnUpdate(self, elapsed)
   totalElapsed = totalElapsed + elapsed
   if totalElapsed > granularity then
      for k,t in pairs(timers) do
         t.update = t.update + totalElapsed
         if t.update > t.interval then
            local success, rv = pcall(t.callback, unpack(t))
            if not rv and t.recur then
               t.update = 0
            else
               timers[t] = nil
               if not success then CombatMusic.PrintMessage("Timer Callback failed:" .. rv , true, true) end
            end
         end
      end
      totalElapsed = 0
   end
end
CreateFrame('Frame'):SetScript('OnUpdate', OnUpdate)
