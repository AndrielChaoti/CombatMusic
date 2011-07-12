--[[
------------------------------------------------------------------------
	Project: Van32sCombatMusic
	File: Main Operations, revision @file-revision@
	Date: @project-date-iso@
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
		CombatMusic.RestoreSavedStates()
	end
	
	if CombatMusic.Info.RestoreTimer then
		CombatMusic.KillTimer(CombatMusic.Info.RestoreTimer)
		CombatMusic.RestoreSavedStates()
	end
	-- Save the CVar's last states, before continuing
	CombatMusic.GetSavedStates()
	
	-- Check the player's target
	CombatMusic.Info["BossFight"] = CombatMusic.CheckTarget()
	-- Set the timer to check the target every 0.5 seconds:
	if not CombatMusic.Info["BossFight"] then
		CombatMusic.Info["UpdateTimers"] = {
			Target = CombatMusic.SetTimer(0.5, CombatMusic.TargetChanged, true, "player"),
			Focus = CombatMusic.SetTimer(0.5, CombatMusic.TargetChanged, true, "focus"),
		}
	end
	
	-- Change the CVars to what they need to be
	SetCVar("Sound_EnableMusic", "1")
	SetCVar("Sound_MusicVolume", CombatMusic_SavedDB.Music.Volume)
	
	
	-- Check Boss music selections...
	local BossList = 	CombatMusic.CheckBossList()
	
	-- Check to see if music is already fading, stop here, if so.
	if CombatMusic.Info.IsFading then
		CombatMusic.PrintMessage("IsFading!", false, true)
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

-- Player Changed Target
function CombatMusic.TargetChanged(unit)
	if not CombatMusic_SavedDB.Enabled then return end
	
	-- There's no need to do this again if we already have a boss.
	if CombatMusic.Info.BossFight then return end
	if not CombatMusic.Info.InCombat then return end
	
	-- Check Boss music selections...
	local BossList = CombatMusic.CheckBossList()
	if BossList then return end
		
	CombatMusic.Info["BossFight"] = CombatMusic.CheckTarget(unit .. "target")
	
	-- Get that music changed
	local filePath = "Interface\\Music\\%s\\%s%d.mp3"
	if CombatMusic.Info.BossFight then

		PlayMusic(format(filePath, "Bosses", "Boss", random(1, CombatMusic_SavedDB.Music.numSongs.Bosses)))
		if CombatMusic.Info.UpdateTimers then
			CombatMusic.KillTimer(CombatMusic.Info.UpdateTimers.Target)
			CombatMusic.KillTimer(CombatMusic.Info.UpdateTimers.Focus)
		end
		return true
	end
end

function CombatMusic.CheckBossList()
	CombatMusic.PrintMessage("CheckBossList", false, true)
	if CombatMusic_BossList then
		if CombatMusic_BossList[UnitName("target")] then
			PlayMusic(CombatMusic_BossList[UnitName("target")])
			CombatMusic.Info.BossFight = true
			CombatMusic.Info.InCombat = true
			CombatMusic.PrintMessage("Target on BossList. Playing ".. tostring(CombatMusic_BossList[UnitName("target")]), false, true)
			return true
		elseif CombatMusic_BossList[UnitName("focustarget")] then
			PlayMusic(CombatMusic_BossList[UnitName("focustarget")])
			CombatMusic.Info.BossFight = true
			CombatMusic.Info.InCombat = true
			CombatMusic.PrintMessage("FocusTarget on BossList. Playing " .. tostring(CombatMusic_BossList[UnitName("focustarget")]), false, true)
			return true
		end
		CombatMusic.PrintMessage("Target not on BossList.", false, true)
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
	
	
	if CombatMusic.Info.UpdateTimers then
		CombatMusic.KillTimer(CombatMusic.Info.UpdateTimers.Target)
		CombatMusic.KillTimer(CombatMusic.Info.UpdateTimers.Focus)
	end
	CombatMusic.Info.InCombat = nil
	CombatMusic.Info.BossFight = nil
	CombatMusic.Info.UpdateTimers = nil
	
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
	if CombatMusic_SavedDB.GameOver.Enabled then
		if (not CombatMusic.Info.GameOverCD) or (GetTime() >= CombatMusic.Info.GameOverCD) then
			CombatMusic.Info["GameOverCD"] = GetTime() + CombatMusic_SavedDB.GameOver.Cooldown
			PlaySoundFile("Interface\\Music\\GameOver.mp3", "Master")
		end
	end
	
	-- Clear those vars, we"re not in combat anymore...
	if CombatMusic.Info.UpdateTimers then
		CombatMusic.KillTimer(CombatMusic.Info.UpdateTimers.Target)
		CombatMusic.KillTimer(CombatMusic.Info.UpdateTimers.Focus)
	end
	CombatMusic.Info.InCombat = nil
	CombatMusic.Info.BossFight = nil
	CombatMusic.Info.UpdateTimers = nil
	
end


-- DING! Level up handler, just plays the fanfare overtop of whatever's playing... on purpose.
function CombatMusic.LevelUp()
	--Check that CombatMusic is turned on
	if not CombatMusic_SavedDB.Enabled then return end
	
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

-- Target Checking.
-- Checks mobtype, player, group, level
function CombatMusic.CheckTarget(unit)
	-- Lazy coding ftw:
	if not unit then unit = "target" end
	
	-- Why am I checking targets if they don't exist?
	if not UnitExists("target") or UnitExists("focustarget") then 
		CombatMusic.PrintMessage("No targets selected!", true, true)
		return false
	end
	
	-- Prepare a table full of values we need.
	local targetInfo = {
		level = {
			-- This function gets the greater of the two levels.
			raw = function()
				-- Get level info
				-- UnitLevel will never be lower than -1 so, use -2 as a placeholder instead of nil
				return math.max((UnitLevel("target") or -2), (UnitLevel("focusTarget") or -2))
			end,
		},
		-- Get if they"re flagged:
		isPvP = UnitIsPVP("focustarget") or UnitIsPVP("target"),
		-- Get if they"re a player:
		isPlayer = UnitIsPlayer("focustarget") or UnitIsPlayer("target")
		-- Get the unit"s classification:
		mobType = function()
			-- Get the types
			local ft, t = UnitClassification("focustarget"), UnitClassification("target")
			local ct = {normal = 1, rare = 2, elite = 3, rareelite = 4, worldboss = 5 }
			-- Make them into something comparable:
			ft, t = ct[ft], ct[t]
			return math.max(ft or -2, t or -2)
			end
		end,
		-- Get if they're in my group: (AND is used here to make sure NEITHER are in the group.)
		inGroup = (UnitInParty("focustarget") or UnitInRaid("focustarget")) and (UnitInParty("target") or UnitInRaid("target")),
		-- Get if the unit is grey: (AND is used here, to make sure that NEITHER unit is grey.)
		isTrival = (UnitIsTrival("focustarget") and UnitIsTrival("target"))
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
	-- Check to see if it needs to be changed.
	if targetInfo.mobType() ~= 1 then
	
		-- A target that's elite or rareElite gets a bonus of 3 levels:
		if targetInfo.mobType() == 2 or targetInfo.mobType() == 3 then
			targetInfo.level.adj = targetInfo.level.adj + 3
		end
		
		-- The monster's only a boss if I'm not in a group dungeon.
		if (playerInfo.instanceType == "party" or playerInfo.instanceType == "raid") then
			-- And it's non-elite
			if targetInfo.mobType() == 3 then
				isBoss = false
			else
				isBoss = true
			end
		end
	elseif targetInfo.mobType() == -2 then
		-- Why are we still here? This means there was no target
		CombatMusic.PrintMessage("No targets selected!", true, true)
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
	-- Level checking.
	-- Start by seeing if its level is -1 or a weighted 5 levels higher than me:
	if targetInfo.level.raw() == -1 or targetInfo.level.adj >= (5 + playerInfo.level) then 
		isBoss = true
	-- If the target is grey to me, do NOT under any circumstances allow the code to continue
	elseif targetInfo.isTrival then
		isBoss = false
		return isBoss
	elseif targetInfo.level.raw() == -2 then
		-- Why are we still here? This means there was no target
		CombatMusic.PrintMessage("No targets selected!", true, true)
		return false
	end
	------------------------------------
	
	
	------------------------------------
	-- Player/PvP and Group Checking
	-- Checks to see if the player's in my group.
	if targetInfo.isPlayer then
		-- They can't be in my group, at all
		if targetInfo.isPvP and not targetInfo.inGroup then
			isBoss = true
		else
			isBoss = false
			return isBoss or false
		end
	end
	------------------------------------
	
	-- All right, return what we got, if we made it that far.
	return isBoss or false
end


-- Saves music state so we can restore it out of combat
function CombatMusic.GetSavedStates()
	CombatMusic.PrintMessage("GetSavedStates", false, true)
	-- Music was turned on?
	CombatMusic.Info["EnabledMusic"] = GetCVar("Sound_EnableMusic") or "0"
	-- Music Volume?
	CombatMusic.Info["MusicVolume"] = GetCVar("Sound_MusicVolume") or "1"
end

function CombatMusic.RestoreSavedStates()
	CombatMusic.PrintMessage("RestoreSavedStates", false, true)
	CombatMusic.Info.FadeTimerVars = nil
	CombatMusic.Info.RestoreTimer = nil
	if not CombatMusic.Info.EnabledMusic then return end
	SetCVar("Sound_EnableMusic", tostring(CombatMusic.Info.EnabledMusic))
	if not CombatMusic.Info.MusicVolume then return end
	SetCVar("Sound_MusicVolume", tostring(CombatMusic.Info.MusicVolume))
end


-- Fading start
function CombatMusic.FadeOutStart()
	CombatMusic.PrintMessage("FadeOutStart", false, true)
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
		FadeTimer = CombatMusic.SetTimer(interval, CombatMusic.FadeOutPlayingMusic, true),
		MaxVol = CombatMusic_SavedDB.Music.Volume,
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
	
	-- Because of stupid floating point:
	if CurVol <= 0 then
		CurVol = 0
		FadeFinished = true
	end
	
	CombatMusic.PrintMessage("FadeVolume: " .. CurVol * 100, false, true)
		
	SetCVar("Sound_MusicVolume", tostring(CurVol))
	CombatMusic.Info.FadeTimerVars.CurVol = CurVol
	if FadeFinished then
		CombatMusic.Info.FadeTimerVars = nil
		SetCVar("Sound_MusicVolume", "0")
		StopMusic()
		CombatMusic.Info["RestoreTimer"] = CombatMusic.SetTimer(2, CombatMusic.RestoreSavedStates)
		CombatMusic.Info.IsFading = nil
		return true
	end
end


-- My survey function
--[=[ DISCLAIMER: THIS CODE IS USED TO SEND INFORMATION ABOUT YOUR CURRENT COMBATMUSIC 
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
	if not CombatMusic_SavedDB.AllowComm or not CombatMusic_SavedDB.Enabled thAllows you to enable/disable responding to settings requests from other players.en return end
	if prefix ~= "CM3" then return end
	if message ~= "SETTINGS" then return end
	CombatMusic.CommSettings(channel, sender)
end

function CombatMusic.CommSettings(channel, target)
	if not CombatMusic_SavedDB.AllowComm or not CombatMusic_SavedDB.Enabled then return end
	local AddonMsg = format("%s,%d,%d", CombatMusic_VerStr .. " r" .. CombatMusic_Rev, CombatMusic_SavedDB.Music.numSongs.Battles, CombatMusic_SavedDB.Music.numSongs.Bosses)
	if channel ~= "WHISPER" then
		SendAddonMessage("CM3", AddonMsg, channel)
	else
		SendAddonMessage("CM3", AddonMsg, channel, target)
	end
end
-- ]]

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
CreateFrame("Frame"):SetScript("OnUpdate", OnUpdate)
