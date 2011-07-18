--[[
------------------------------------------------------------------------
	Project: Van32s_CombatMusic
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

local addonName, CM = ...

CM["Info"]= {}



-- Entering Combat
function CM.enterCombat()
	CM.PrintMessage(CM.Colours.var .. "enterCombat()", false, true)
	--Check that CM is turned on
	if not CM_SavedDB.Enabled then return end
	
	-- Make sure we're not in combat before trying to enter it again
	if CM.Info.InCombat then
		CM.RestoreSavedStates()
	end
	
	-- Cancel the music fade-out if it's fading.
	if CM.Info.FadeTimerVars then
		if CM.Info.FadeTimerVars.FadeTimer then
			CM.KillTimer(CM.Info.FadeTimerVars.FadeTimer)
		end
		-- Restore the saved states, so they can be saved again.
		CM.RestoreSavedStates()
	end
	
	--Cancel restoring saved states if it's trying to.
	if CM.Info.RestoreTimer then
		CM.KillTimer(CM.Info.RestoreTimer)
		CM.RestoreSavedStates()
	end
	-- Save the CVar's last states, before continuing
	CM.GetSavedStates()
	
	-- Check the player's target
	CM.Info["BossFight"] = CM.CheckTarget("_EC")

	-- Change the CVars to what they need to be
	SetCVar("Sound_EnableMusic", "1")
	SetCVar("Sound_MusicVolume", CM_SavedDB.Music.Volume)
	
	
	-- Check the BossList.
	local BossList = CM.CheckBossList()
	
	-- Check to see if music is already fading, stop here, if so.
	if CM.Info.IsFading then
		CM.PrintMessage("IsFading!", false, true)
		CM.Info.IsFading = nil
		CM.Info.InCombat = true
		if CM.Info.EnabledMusic ~= "0" then return end
	end
	
	if BossList then return end
	
	CM.Info["InCombat"] = true
	-- Play the music
	local filePath = "Interface\\Music\\%s\\%s%d.mp3"
	if CM.Info.BossFight then
		if CM_SavedDB.Music.numSongs.Bosses > 0 then
			PlayMusic(format(filePath, "Bosses", "Boss", random(1, CM_SavedDB.Music.numSongs.Bosses)))
		else
			CM.leaveCombat(1)
		end
	else
		if CM_SavedDB.Music.numSongs.Battles > 0 then
			PlayMusic(format(filePath, "Battles", "Battle", random(1, CM_SavedDB.Music.numSongs.Battles)))
		else
			CM.leaveCombat(1)
		end
	end
end

-- Player Changed Target
-- This function is linked to a timer, and thus returns a value when the timer should stop
-- The value returned depends on why the timer needed to stop:
-- 1 = Not_Enabled_Error
-- 2 = In_Combat_Error
-- 3 = No_Target_Error
function CM.TargetChanged(unit)
	CM.PrintMessage(CM.Colours.var .. "TargetChanged(".. CM.ns(unit) ..")", false, true)
	if not CM_SavedDB.Enabled then return 1 end
	
	-- There's no need to do this again if we already have a boss.
	if CM.Info.BossFight then return 0 end
	if not CM.Info.InCombat then return 2 end
	
	-- Check BossList
	local BossList = CM.CheckBossList()
	if BossList then return 0 end
	
	-- Why am I checking targets if they don't exist?
	if not (UnitExists("focustarget") or UnitExists("target")) then 
		CM.PrintMessage("No targets selected!", true, true)
		return 3
	end
	CM.Info["BossFight"] = CM.CheckTarget(unit)
	
	-- Get that music changed
	local filePath = "Interface\\Music\\%s\\%s%d.mp3"
	if CM.Info.BossFight then
		PlayMusic(format(filePath, "Bosses", "Boss", random(1, CM_SavedDB.Music.numSongs.Bosses)))
		return 0
	end
end

function CM.CheckBossList()
	CM.PrintMessage(CM.Colours.var .. "CheckBossList()", false, true)
	if CM_BossList then
		if CM_BossList[UnitName("target")] then
			PlayMusic(CM_BossList[UnitName("target")])
			CM.Info.BossFight = true
			CM.Info.InCombat = true
			CM.PrintMessage("Target on BossList. Playing ".. tostring(CM_BossList[UnitName("target")]), false, true)
			return true
		elseif CM_BossList[UnitName("focustarget")] then
			PlayMusic(CM_BossList[UnitName("focustarget")])
			CM.Info.BossFight = true
			CM.Info.InCombat = true
			CM.PrintMessage("FocusTarget on BossList. Playing " .. tostring(CM_BossList[UnitName("focustarget")]), false, true)
			return true
		end
		CM.PrintMessage("Target not on BossList.", false, true)
	end
end


-- Leaving Combat
-- Stop the music playing if it's leaving combat.
-- If isDisabling, then don't play a victory fanfare when the music stops.
function CM.leaveCombat(isDisabling)
	CM.PrintMessage(CM.Colours.var .. "leaveCombat("..CM.ns(isDisabling)..")", false, true)
	--Check that CM is turned on
	if not CM_SavedDB.Enabled then return end
	if not CM.Info.InCombat then return end
	
	-- OhNoes! The player's dead, don't want no fanfares playing...
	if UnitIsDeadOrGhost("player") then return end
	
	-- Check for boss fight, and if the user wants to hear it....
	if CM_SavedDB.Victory.Enabled and not isDisabling and CM.Info.BossFight then
		StopMusic()
		--Boss Only?
		if (not CM.Info.FanfareCD) or (GetTime() >= CM.Info.FanfareCD) then
			CM.Info["FanfareCD"] = GetTime() + CM_SavedDB.Victory.Cooldown
			PlaySoundFile("Interface\\Music\\Victory.mp3")
			CM.RestoreSavedStates()
		end
	elseif isDisabling then
		StopMusic()
		CM.RestoreSavedStates()
	else
		-- Left Combat normally, start the fading cycle
		CM.FadeOutStart()
	end
	
	CM.Info.InCombat = nil
	CM.Info.BossFight = nil
	
end

-- Game Over
-- Aww, I died, play some game over music for me
function CM.GameOver()
	CM.PrintMessage(CM.Colours.var .. "GameOver()", false, true)
	--Check that CM is turned on
	if not CM_SavedDB.Enabled then return end
	
	StopMusic()
	if CM.Info.InCombat then
		--Leaving Combat, restore the saved vars.
		CM.RestoreSavedStates()
	end
		
	-- No music fading for game over, so skip that step
	
	-- Too bad, play the gameover, if it's not on CD, and the user wants to hear it
	if CM_SavedDB.GameOver.Enabled then
		if (not CM.Info.GameOverCD) or (GetTime() >= CM.Info.GameOverCD) then
			CM.Info["GameOverCD"] = GetTime() + CM_SavedDB.GameOver.Cooldown
			PlaySoundFile("Interface\\Music\\GameOver.mp3", "Master")
		end
	end
	
	CM.Info.InCombat = nil
	CM.Info.BossFight = nil
end


-- DING! Level up handler, just plays the fanfare overtop of whatever's playing... on purpose.
function CM.LevelUp()	
	CM.PrintMessage(CM.Colours.var .. "LevelUp()", false, true)
	--Check that CM is turned on
	if not CM_SavedDB.Enabled then return end
	
	-- Yay, play the fanfare.. if it's not on cooldown, and the user wants to hear it.
	-- We have two options here, Check to see if they want to use their victory fanfare, or the new
	--   level up fanfare.
	if CM_SavedDB.LevelUp.Enabled and CM_SavedDB.LevelUp.NewFanfare then
		if (not CM.Info.FanfareCD) or (GetTime() >= CM.Info.FanfareCD) then
			CM.Info["FanfareCD"] = GetTime() + CM_SavedDB.Victory.Cooldown
			PlaySoundFile("Interface\\Music\\DING.mp3", "Master")
		end
	elseif CM_SavedDB.LevelUp.Enabled and not CM_SavedDB.LevelUp.NewFanfare then
		if (not CM.Info.FanfareCD) or (GetTime() >= CM.Info.FanfareCD) then
			CM.Info["FanfareCD"] = GetTime() + CM_SavedDB.Victory.Cooldown
			PlaySoundFile("Interface\\Music\\Victory.mp3", "Master")
		end
	end
end

-- Target Checking.
-- Checks combat -> mobType/instance -> level -> player/inGroup
function CM.CheckTarget(unit)
	CM.PrintMessage(CM.Colours.var .. "CheckTarget(".. CM.ns(unit) ..")", false, true)
	
	-- If it's a boss fight, I don't need to check anything.
	if CM.Info.BossFight then
		return true
	end
	
	-- Why am I checking targets if they don't exist?
	if not (UnitExists("focustarget") or UnitExists("target")) then 
		CM.PrintMessage("No targets selected!", true, true)
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
	CM.PrintMessage("inCombat: " .. CM.ns(targetInfo.inCombat), false, true)
	if not CM.DebugMode then
		if not targetInfo.inCombat then
			isBoss = false
			if not isBoss then
				local t = CM.SetTimer(0.5, CM.TargetChanged, true, 0, unit)
				if t ~= -1 then
					CM.Info["updateTimer"] = t
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
	CM.PrintMessage("mobType: " .. CM.ns(targetInfo.mobType()) .. " / instanceType: " .. CM.ns(playerInfo.instanceType), false, true)
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
				CM.PrintMessage("FALSE!", false, true)
			else
				CM.PrintMessage("TRUE!", false, true)
				isBoss = true
			end
		else
			isBoss = true
			CM.PrintMessage("TRUE!", false, true)
		end
	elseif targetInfo.mobType() == -2 then
		-- Why are we still here? This means there was no target
		CM.PrintMessage("No targets selected!", true, true)
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
	CM.PrintMessage("level.raw: " .. CM.ns(targetInfo.level.raw()) .. " / level.adj: " .. CM.ns(targetInfo.level.adj) .. " / isTrivial: " .. CM.ns(targetInfo.isTrival()) , false, true)
	if targetInfo.level.raw() == -1 or targetInfo.level.adj >= (5 + playerInfo.level) then 
		isBoss = true
		CM.PrintMessage("TRUE!", false, true)
	-- If the target is grey to me, do NOT under any circumstances allow the code to continue
	elseif targetInfo.isTrival() then
		isBoss = false
		CM.PrintMessage("FALSE! STOPPING CHECK!", false, true)
		-- Recurse this function every half a second if there is no boss.
		CM.SetTimer(0.5, CM.TargetChanged)
		return isBoss
	elseif targetInfo.level.raw() == -2 then
		-- Why are we still here? This means there was no target
		CM.PrintMessage("No targets selected!", true, true)
		return false
	end
	------------------------------------
	
	
	------------------------------------
	--[[ Checking to see if a player is targetted
			A player that is flagged for PvP will play boss music if:
			* They are not considered 'trival'.
			* They are not in your group.
		]]
	CM.PrintMessage("isPlayer: " .. CM.ns(targetInfo.isPlayer) .. " / isPvP: " .. CM.ns(targetInfo.isPvP) .. " / inGroup: " .. CM.ns(targetInfo.inGroup()), false, true)
	if targetInfo.isPlayer then
		-- Is the player flagged?
		if targetInfo.isPvP then
			isBoss = true
			CM.PrintMessage("TRUE!", false, true)
		else
			isBoss = false
			CM.PrintMessage("FALSE!", false, true)
		end
		-- They're in my group?
		if targetInfo.inGroup() then
			isBoss = false
			CM.PrintMessage("FALSE! STOPPING CHECK!", false, true)
			-- Recurse this function every half a second if there is no boss.
			CM.SetTimer(0.5, CM.TargetChanged)
			return isBoss or false
		end
	end
	------------------------------------
	
	-- All right, return what we got, if we made it that far.
	CM.PrintMessage("Final Result: ".. CM.ns(isBoss), false, true)
	-- Recurse this function every half a second if there is no boss.
	if not isBoss then
		local t = CM.SetTimer(0.5, CM.TargetChanged, true, 0, unit)
		if t ~= -1 then
			CM.Info["updateTimer"] = t
		end
	end
	return isBoss or false
end


-- Saves music state so we can restore it out of combat
function CM.GetSavedStates()
	CM.PrintMessage(CM.Colours.var .. "GetSavedStates()", false, true)
	-- Music was turned on?
	CM.Info["EnabledMusic"] = GetCVar("Sound_EnableMusic") or "0"
	-- Music Volume?
	CM.Info["MusicVolume"] = GetCVar("Sound_MusicVolume") or "1"
end

function CM.RestoreSavedStates()
	CM.PrintMessage(CM.Colours.var .. "RestoreSavedStates()", false, true)
	CM.Info.FadeTimerVars = nil
	CM.Info.RestoreTimer = nil
	if not CM.Info.EnabledMusic then return end
	SetCVar("Sound_EnableMusic", tostring(CM.Info.EnabledMusic))
	if not CM.Info.MusicVolume then return end
	SetCVar("Sound_MusicVolume", tostring(CM.Info.MusicVolume))
end


-- Fading start
function CM.FadeOutStart()
	CM.PrintMessage(CM.Colours.var .. "FadeOutStart()", false, true)
	local FadeTime = CM_SavedDB.Music.FadeOut
	if FadeTime == 0 then 
		StopMusic()
		CM.RestoreSavedStates()
		return
	end
	-- Check to make sure a fade timer isn"t already running.
	if CM.Info.IsFading then
		return
	end
	
	-- Divide the process up into 20 steps.
	local interval = FadeTime / 20
	local volStep = CM_SavedDB.Music.Volume / 20
	CM.Info["FadeTimerVars"] = {
		FadeTimer = CM.SetTimer(interval, CM.FadeOutPlayingMusic, true),
		MaxVol = CM_SavedDB.Music.Volume,
		VolStep = volStep,
	}
	CM.Info["IsFading"] = true
end

-- Fading function
function CM.FadeOutPlayingMusic()
	CM.PrintMessage(CM.Colours.var .. "FadeOutPlayingMusic()", false, true)
	-- Set some args
	local MaxVol = CM.Info.FadeTimerVars.MaxVol
	local CurVol = CM.Info.FadeTimerVars.CurVol
	local Step = CM.Info.FadeTimerVars.VolStep
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
	
	CM.PrintMessage("FadeVolume: " .. CurVol * 100, false, true)
		
	SetCVar("Sound_MusicVolume", tostring(CurVol))
	CM.Info.FadeTimerVars.CurVol = CurVol
	if FadeFinished then
		CM.Info.FadeTimerVars = nil
		SetCVar("Sound_MusicVolume", "0")
		StopMusic()
		CM.Info["RestoreTimer"] = CM.SetTimer(2, CM.RestoreSavedStates)
		CM.Info.IsFading = nil
		return true
	end
end


-- My survey function
--[=[ DISCLAIMER: THIS CODE IS USED TO SEND INFORMATION ABOUT YOUR CURRENT CM 
		CONFIGURATION TO THE PLAYER WHO ASKS FOR IT. THE INFORMATION SENT IS AS FOLLOWS:
		 -YOUR TOON'S NAME (THIS IS AVAILABLE TO THE DEFAULT API AND IS IN NO WAY USED
				TO IDENTIFY YOU BEYOND SEPERATING REPLIES.)
		 -YOUR VERSION OF CM
		 -YOUR NUMBER OF BOSS AND BATTLE SONGS
		 
		I ADDED THIS FUNCTIONALITY IN, MERELY OUT OF CURIOSITY AS TO WHO USES THE ADDON.
		DON'T WORRY, YOUR INFORMATION IS NOT STORED, OR USED IN ANY WAY.
		
		TO DISABLE THIS, ENTER INTO YOUR CHAT '/cm comm off' WITHOUT THE QUOTES.
		IF YOU SHOULD CHANGE YOUR MIND, ENTER '/cm comm on' WITHOUT QUOTES TO RE-ENABLE.
]=]
function CM.CheckComm(prefix, message, channel, sender)
	CM.PrintMessage(CM.Colours.var .. "CheckComm(" .. CM.ns(prefix) .. "," ..  CM.ns(message) .. "," ..  CM.ns(channel) .. "," .. CM.ns(sender) .. ")", false, true)
	if not CM_SavedDB.AllowComm or not CM_SavedDB.Enabled then return end
	if prefix ~= "CM3" then return end
	if message ~= "SETTINGS" then return end
	CM.CommSettings(channel, sender)
end

function CM.CommSettings(channel, target)
	CM.PrintMessage(CM.Colours.var .. "CommSettings(" .. CM.ns(channel) .. ", " .. CM.ns(target) .. ")", false, true)
	if not CM_SavedDB.AllowComm or not CM_SavedDB.Enabled then return end
	local AddonMsg = format("%s,%d,%d", CM.VerStr .. " r" .. CM.Rev, CM_SavedDB.Music.numSongs.Battles, CM_SavedDB.Music.numSongs.Bosses)
	if channel ~= "WHISPER" then
		SendAddonMessage("CM3", AddonMsg, channel)
	else
		SendAddonMessage("CM3", AddonMsg, channel, target)
	end
end

-- Timer lib functions:

-- The code below was brought to you in part by the author of Hack.


if CM.SetTimer then return end
local timers = {}

-- SetTimer(interval, callback, [recur], [id], [parameters...])
function CM.SetTimer(interval, callback, recur, id, ...)
   local timer = {
      interval = interval,
		ID = (id or nil),
      callback = callback,
      recur = recur,
      update = 0,
      ...
   }
	if id then
		-- they want a unique timer:
		for k,_ in pairs(timers) do
			if k.ID == id then
				CM.PrintMessage("Timer creation failed. ID already used!", true, true)
				return -1
			end
		end
	end
	timers[timer] = timer
   return timer
end

function CM.KillTimer(timer)
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
               if not success then CM.PrintMessage("Timer Callback failed:" .. rv , true, true) end
            end
         end
      end
      totalElapsed = 0
   end
end
CreateFrame("Frame"):SetScript("OnUpdate", OnUpdate)
