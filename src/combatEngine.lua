--[[
	Project: CombatMusic
	Friendly Name: CombatMusic
	Author: Vandesdelca32

	File: combatEngine.lua
	Purpose: The Engine that makes the magic happen

	Version: @file-revision@

	ALL RIGHTS RESERVED.
	COPYRIGHT (c)2010-2014 VANDESDELCA32
]]

-- These functions are global API functions used by this module.
-- GLOBALS: SetCVar, CombatMusicDB, WorldFrame, CreateFrame

--Import Engine, Locale, Defaults.
local E, L, DF = unpack(select(2, ...))
local CE = E:NewModule("CombatEngine", "AceEvent-3.0", "AceTimer-3.0")

-- Locals for faster lookups
local pairs, select, random = pairs, select, random
local tostring, tostringall, wipe, format = tostring, tostringall, wipe, format
local exp, log = math.exp, math.log

-- Locals for Target Info lookups:
local debugprofilestop = debugprofilestop
local UnitExists, UnitLevel, UnitIsPlayer, UnitIsPVP, UnitClassification = UnitExists, UnitLevel, UnitIsPlayer, UnitIsPVP, UnitClassification
local UnitAffectingCombat, UnitIsTrivial, GetInstanceInfo, UnitInRaid = UnitAffectingCombat, UnitIsTrivial, GetInstanceInfo, UnitInRaid
local UnitInParty, UnitIsPVPFreeForAll, UnitIsDeadOrGhost = UnitInParty, UnitIsPVPFreeForAll, UnitIsDeadOrGhost
local StopMusic, PlaySoundFile, StopSound = StopMusic, PlaySoundFile, StopSound


-- Debugging
local printFuncName = E.printFuncName

-- Difficulty level for encounters.
local DIFFICULTY_NONE = 0
local DIFFICULTY_NORMAL = 1
local DIFFICULTY_BOSS = 2
local DIFFICULTY_BOSSLIST = 3

--- Handles the events for entering combat
function CE:EnterCombat(event, ...)
	printFuncName("EnterCombat", event, ...)
	if not E:GetSetting("Enabled") then return end

	-- for debugging, mark the time we started target checking
	self._TargetCheckTime = debugprofilestop()

	-- Check Fading
	if self.FadeTimer then
		self.FadeTimer = nil
		self:CancelAllTimers()
	end

	-- Restore volume to defaults if we're already in combat
	if self.InCombat then E:SetVolumeLevel(true) end
	if UnitIsDeadOrGhost('player') then return end -- Don't play music if we're dead...


	-- Begin target checking
	self.InCombat = true
	self.isPlayingMusic = self:BuildTargetInfo()

	-- Save the last volume state...
	E:SaveLastVolumeState()

	if self.isPlayingMusic then
		-- Don't change the volume if we're not playing music
		E:SetVolumeLevel()
	end

	-- This is the very end of the checking cylce.
	-- Where music is finally played, so figure out how much time it took
	E:PrintDebug(format("  ==§dTime taken: %fms",  debugprofilestop() - self._TargetCheckTime))
	E:SendMessage("COMBATMUSIC_ENTER_COMBAT")
end


--- Update the TargetInfo table
function CE:UpdateTargetInfoTable(unit)
	printFuncName("UpdateTargetInfo", unit)
	if not unit then return end
	-- This check only applies if the player is in combat
	-- or not fading out...
	if not self.InCombat then return true end
	if self.FadeTimer then return true end

	-- No checks if we're already using a song on the BossList
	if self.EncounterLevel == DIFFICULTY_BOSSLIST then return true end

	-- Check the bosslist first.
	if E:CheckBossList(unit) and self.EncounterLevel ~= DIFFICULTY_BOSSLIST then
		self.EncounterLevel = DIFFICULTY_BOSSLIST
		E:PrintDebug("  ==§cON BOSSLIST")
		return true
	end

	-- Get the target's information.
	self.TargetInfo[unit] = {self:GetTargetInfo(unit)}
	E:PrintDebug(format("  ==§b%s, isBoss = %s, inCombat = %s", tostringall(unit, self.TargetInfo[unit][1], self.TargetInfo[unit][2])))
end


--- Handles target changes
function CE:UNIT_TARGET(event, ...)
	printFuncName("UNIT_TARGET", ...)
	local unit = ...

	if not E:GetSetting("Enabled") then return end
	if not self.InCombat then return end

	-- Reset our target check timer
	self._TargetCheckTime = debugprofilestop()

	-- This is only to check player and focus target changes
	-- other changes don't matter, so Get the new target info
	if unit == "player" then
		self:UpdateTargetInfoTable("target")
	elseif unit == "focus" then
		self:UpdateTargetInfoTable("focustarget")
	else
		return
	end

	-- and run a quick parse again
	self:ParseTargetInfo()
end


--- Builds target information necessary to choose a song, then attempts to
-- parse that information
function CE:BuildTargetInfo()
	printFuncName("BuildTargetInfo")
	local targetList = {}
	self.TargetInfo = {}

	-- Check to see if we should check the focustarget before the target
	if E:GetSetting("General", "CombatEngine", "PreferFocus") then
		targetList = {"focustarget", "target"}
	else
		targetList= {"target", "focustarget"}
	end

	-- Add the boss targets if enabled.
	-- This can be a CPU hog, so some might wish to disable it.
	if E:GetSetting("General","CombatEngine", "CheckBoss") then
		for i = 1, 5 do
			if UnitExists("boss"..i) then
				targetList[i+2] = "boss" .. i
			end
		end
	end

	-- Get the information required on each target and parse the returns:
	for i = 1, #targetList do
		if self:UpdateTargetInfoTable(targetList[i]) then break end
	end
	-- Parse the information we got
	return self:ParseTargetInfo()
end

--- Checks specific information about 'unit' to attempt to determine if it is a boss or not
--@arg unit The unit token of the unit to check
--@return isBoss, InCombat, whether or not the unit is a boss or we are in combat with it
function CE:GetTargetInfo(unit)
	printFuncName("GetTargetInfo", unit)

	-- No target check if there's no unit to check.
	if not unit then return end
	if not UnitExists(unit) then
		E:PrintDebug("  ==§c" .. unit .. " doesn't exist.")
		return
	end

	-- Initialize
	local isBoss = false
	local function InCombat()
		if UnitAffectingCombat(unit) then
			return true
		elseif not UnitAffectingCombat(unit) and E._DebugMode then
			return true
		else
			return false
		end
	end

	--[[There is some pretty complicated, yet pretty simple logic behind
	the way that this program checks a target for a boss, and I am going
	to attempt to explain it sensibly here. The following critera must
	be met for the target to be a boss:
		1) It is of "elite", "rareelite", "rare", or "worldboss" type
			- With the exception of party/raid instances, where "elite"
				is excluded.
		2) The target is NOT "trivial"
			- if the unit is such, then the check is forced false,
				regardless of anything else.
		3) One of the following:
			a) The target's level > 5 + The player's level.
				- Except in Raid instances
				- -1 counts as being infintely greater than the player's level,
					so it counts here.
				- "elite" and "rareelite" recieve a 3 level bonus against the player
					thus requiring them to only be 2 levels higher to qualify.
			-- OR --
			b) The target is a PVP flagged player.
				- Excepting players that are in the current party or raid.
					If the unit is such a player, then the check is forced false
					regardless of what may have been picked before.
	]]

	-- Cache a table of collected information to parse
	local unitInfo = {
		level = {
			raw = UnitLevel(unit),
			adj = UnitLevel(unit)
		},
		isPlayer = UnitIsPlayer(unit),
		isPvP = UnitIsPVP(unit) or UnitIsPVPFreeForAll(unit),
		mobType = function()
			local enumC = {trivial = -1, minus = 0, normal = 1, rare = 2, elite = 3, rareelite = 4, worldboss = 5}
			local C = UnitClassification(unit)
			return enumC[C]
		end,
		inGroup = (UnitInParty(unit) or UnitInRaid(unit)),
	}

	local playerInfo = {
		level = E.dungeonLevel or UnitLevel('player'),
		instanceType = select(2, GetInstanceInfo())
	}

	-- 1)
	if unitInfo.mobType() > 1 then
		-- Do the level adjustment here, while we're checking
		-- unit type.
		if unitInfo.mobType() == 3 or unitInfo.mobType() == 4 then
			unitInfo.level.adj = unitInfo.level.raw + 3
		end

		-- Instance check:
		if playerInfo.instanceType == "party"
			or playerInfo.instanceType == "raid" then
			-- Quick check to negate elites
			if unitInfo.mobType() == 3 then
				isBoss = false
			else
				isBoss = true
			end
		else
			-- Outside instances
			isBoss = true
		end
	end

	-- 2)
	if (not E.dungeonLevel) and UnitIsTrivial(unit) then
		return false, InCombat()
	end

	-- 3.a)
	if playerInfo.instanceType ~= "raid" then
		if unitInfo.level.adj >= 5 + playerInfo.level then
			isBoss = true
		end
	else
		isBoss = false
	end

	-- Level -1 check
	if unitInfo.level.raw == -1 then
		isBoss = true
	end

	-- 3.b)
	if unitInfo.isPlayer then
		-- is the player flagged?
		if unitInfo.isPvP then
			isBoss = true
		end

		-- The clincher of 3.b)
		if unitInfo.inGroup then
			return false, InCombat()
		end
	end

	-- Return what we figured out
	return (isBoss or false), InCombat()
end

-- Schedule a recheck
function CE:Recheck(k)
	self._TargetCheckTime = debugprofilestop()
	-- figure out if the timer needs to be cancelled
	if UnitAffectingCombat(k) then
		self:CancelTimer(self.RecheckTimer[k])
		self.RecheckTimer[k] = nil
	end
	self:UpdateTargetInfoTable(k)
	self:ParseTargetInfo()
end


--- Iterates through the module's target information table and plays music appropriately
function CE:ParseTargetInfo()
	printFuncName("ParseTargetInfo")
	if not self.TargetInfo then return end
	if not self.EncounterLevel then self.EncounterLevel = DIFFICULTY_NONE end
	if self.FadeTimer then return end -- Don't change music if we're fading out...

	-- We need to let it know to change the volume
	if self.EncounterLevel == DIFFICULTY_BOSSLIST then return true end

	local musicType
	for k, v in pairs(self.TargetInfo) do
		-- The TargetInfo table is built {[1] = isBoss, [2] = InCombat}

		-- What information were we given?
		if v[1] and v[2] then
			-- This is a boss, and we are in combat with it
			-- Check to see if our encounter level is below what we're trying to play
			if self.EncounterLevel < DIFFICULTY_BOSS then
				musicType = "Bosses"
				self.EncounterLevel = DIFFICULTY_BOSS
				break -- this trumps all other stuff.
			end
		elseif v[1] and not v[2] then
			-- This IS a boss, but not in combat.
			if self.EncounterLevel < DIFFICULTY_NORMAL then
				musicType = "Battles"
				self.EncounterLevel = DIFFICULTY_NORMAL
			end
			if not self.RecheckTimer then self.RecheckTimer = {} end
			-- Fix a serious bug that can lock up the gameclient by stacking timers endlessly.
			if not self.RecheckTimer[k] then
				self.RecheckTimer[k] = self:ScheduleRepeatingTimer("Recheck", 0.5, k)
			end
		else
			if self.EncounterLevel < DIFFICULTY_NORMAL then
				musicType = "Battles"
				self.EncounterLevel = DIFFICULTY_NORMAL
			end
		end
	end

	-- Play the music
	if musicType then
		return E:PlayMusicFile(musicType)
	elseif not musicType and self.isPlayingMusic then
		return true
	end
end

local function ResetCombatState()
	if not CE.InCombat then return end
	printFuncName("ResetCombatState")
	-- Clear variables:
	CE.InCombat = nil
	CE.EncounterLevel = nil
	CE.FadeTimer = nil
	CE.isPlayingMusic = nil
	CE:CancelAllTimers()

	-- Wipe tables
	if CE.TargetInfo then
		wipe(CE.TargetInfo)
	end

	if CE.FadeVars then
		wipe(CE.FadeVars)
	end

	if CE.RecheckTimer then
		wipe(CE.RecheckTimer)
	end

	-- Reset volume after a second
	CE.FadeTimer = CE:ScheduleTimer(function() E:SetVolumeLevel(true); CE.FadeTimer = nil end, 1)
end


local MAX_FADE_STEPS = 50

--- Handles the leaving of combat
--@arg forceStop Pass as true to force the music to stop instead of fade out.
function CE:LeaveCombat(event, forceStop)
	printFuncName("LeaveCombat", event, forceStop)

	-- Need to be in combat to leave it!
	if not self.InCombat then return end
	if not E:GetSetting("Enabled") then return end

	-- Check event:
	if event == "PLAYER_LEAVING_WORLD" then forceStop = true end

	-- Register a message to mark when fadeout is complete
	self:RegisterMessage("COMBATMUSIC_FADE_COMPLETED")
	-- Stop all the timers, in case we've got any rechecks going
	self:CancelAllTimers()

	-- Forcing the music stopped?
	if forceStop then
		-- Force it to not be a boss fight first, so we don't get a fanfare.
		self.EncounterLevel = DIFFICULTY_NONE
		self:SendMessage("COMBATMUSIC_FADE_COMPLETED")
		return
	else
		-- We don't want to always fade the music out if the user doesn't want it to
		-- so check that here.
		local fadeMode = E:GetSetting("General", "CombatEngine", "FadeMode")
		if (fadeMode == "ALL") or
			 (fadeMode == "BOSSNEVER" and self.EncounterLevel == DIFFICULTY_NORMAL) or
			 (fadeMode == "BOSSONLY" and self.EncounterLevel > DIFFICULTY_NORMAL) then
			-- They actually want music fading? Start it up!
			self:BeginMusicFade()
		else
			-- If they don't want a fade, this will just stop the music without it,
			-- everything else will happen as configured.
			self:SendMessage("COMBATMUSIC_FADE_COMPLETED")
		end
	end
end


-- Handles event PLAYER_DEAD, as it requires a slightly different touch
function CE:GameOver()
	printFuncName("GameOver")
	if not E:GetSetting("Enabled") then return end
	self:LeaveCombat("PLAYER_DEAD", true)

	-- Get the game over setting
	local GameOverWhen = E:GetSetting("General", "CombatEngine", "GameOverEnable")

	-- play the fanfare :D
	if GameOverWhen == "ALL" then
		self:PlayFanfare("GameOver")
	elseif GameOverWhen == "INCOMBAT" and self.InCombat then
		self:PlayFanfare("GameOver")
	end
end


--- Fade Cycle timer callback
-- @arg logMode set to true to switch to log mode
local function FadeStepCallback(logMode)
	printFuncName("FadeStep")
	if not CE.FadeTimer then return end

	if not CE.FadeVars.StepCount then

			CE.FadeVars.StepCount = 0
			CE.FadeVars.CurrentVolume = E:GetSetting("General", "Volume")
			if logMode then
				-- Logarithmic Fading...
				CE.FadeVars.VolumeStep = exp(CE.FadeVars.CurrentVolume)
				CE.FadeVars.VolumeStepDelta = (CE.FadeVars.VolumeStep - 1) / (MAX_FADE_STEPS - 1)
			else
				-- Linear fading
				CE.FadeVars.VolumeStep = CE.FadeVars.CurrentVolume / MAX_FADE_STEPS
				CE.FadeVars.VolumeStepDelta = 0
			end

	end

	-- Increment the step counter
	CE.FadeVars.StepCount = CE.FadeVars.StepCount + 1

	-- Update the current volume
	if logMode then
		CE.FadeVars.CurrentVolume = log(CE.FadeVars.VolumeStep)
  else
		CE.FadeVars.CurrentVolume = CE.FadeVars.CurrentVolume - CE.FadeVars.VolumeStep
  end

	E:PrintDebug(format("  ==§bStepCount = %d, CurrentVolume = %f",  CE.FadeVars.StepCount, CE.FadeVars.CurrentVolume))
	-- And change our VolumeStep
	CE.FadeVars.VolumeStep = CE.FadeVars.VolumeStep - CE.FadeVars.VolumeStepDelta

	-- Volume can't fall below 0, and we don't want to go farther than MAX_FADE_STEPS
	if CE.FadeVars.CurrentVolume <= 0 or CE.FadeVars.StepCount >= MAX_FADE_STEPS then
		CE.FadeVars.CurrentVolume = 0
		-- Set the volume, stop the music, and wait for it to finish fading off before sending the
		-- fading complete message.
		SetCVar("Sound_MusicVolume", CE.FadeVars.CurrentVolume)
		CE:CancelTimer(CE.FadeTimer)
		StopMusic()
		CE:SendMessage("COMBATMUSIC_FADE_COMPLETED")
		return
	end

	-- And set our volume
	SetCVar("Sound_MusicVolume", CE.FadeVars.CurrentVolume)
end


--- Begins the music fading cycle
function CE:BeginMusicFade()
	printFuncName("BeginMusicFade")

	-- Already fading?
	if self.FadeTimer then return end

	-- Get our fade timeout.
	self.fadeTime = E:GetSetting("General", "CombatEngine", "FadeTimer")
	-- Set FadeVars
	self.FadeVars = {}

	-- The user's disabled fading...
	-- or music isn't playing
	if (not self.isPlayingMusic) or self.fadeTime <= 0 then
		self:SendMessage("COMBATMUSIC_FADE_COMPLETED")
		return
	end

	-- Get the interval
	self.FadeVars.interval = self.fadeTime / MAX_FADE_STEPS
	-- Schedule the timer
	self.FadeTimer = self:ScheduleRepeatingTimer(FadeStepCallback, self.FadeVars.interval, E:GetSetting("General", "CombatEngine", "FadeLog"))
end


---Handles the message for when fadeouts are finished.
function CE:COMBATMUSIC_FADE_COMPLETED()
	printFuncName("COMBATMUSIC_FADE_COMPLETED")
	-- Unregister the message
	-- self:UnregisterMessage("COMBATMUSIC_FADE_COMPLETED")

	-- If this was a boss fight:
	local playWhen = E:GetSetting("General", "CombatEngine", "FanfareEnable")
	if playWhen == "BOSSONLY" then
		if self.EncounterLevel > 1 then
			self:PlayFanfare("Victory")
		end
	elseif playWhen == "ALL" then
		self:PlayFanfare("Victory")
	end

	-- Stop the music
	StopMusic()

	-- Reset the combat state finally
	ResetCombatState()
end


function CE:LevelUp()
	printFuncName("LevelUp")
	if not E:GetSetting("Enabled") then return end
	if E:GetSetting("General", "CombatEngine", "UseDing") then
		self:PlayFanfare("DING")
	else
		self:PlayFanfare("Victory")
	end
end


--- Plays a "fanfare"
--@arg fanfare The fanfare to play.
function CE:PlayFanfare(fanfare)
	printFuncName("PlayFanfare")

	-- Is there already a fanfare playing?
	if self.SoundId then
		StopSound(self.SoundId)
	end

	-- Play our chosen fanfare
	self.SoundId = select(2, E:PlaySoundFile("Interface\\Music\\" .. fanfare .. ".mp3"))
end


-- Starts the CombatMusic Challenge, and markes some things.
function CE:StartCombatChallenge()
	printFuncName("StartCombatChallenge")
	-- We'll only make this check if debug mode is off
	local instanceType = select(2,GetInstanceInfo())
	if not E._DebugMode then
		if (instanceType ~= "party" and instanceType ~= "raid") then return end
	end

	local isEnabled, isRunning = CE:GetChallengeModeState()
	-- Make sure the challenge isn't already running:
	if isEnabled and not isRunning then
		-- Mark the start time of the challenge, clear the finish time
		self.ChallengeStartTime = debugprofilestop()
		self.ChallengeModeRunning = true
		self.ChallengeFinishTime = nil
		E:UnregisterMessage("COMBATMUSIC_ENTER_COMBAT")

		-- Set the user's Fadeout timer to 10 seconds:
		self.OldFadeMode = E:GetSetting("General", "CombatEngine", "FadeMode")
		self.OldFadeOut = E:GetSetting("General", "CombatEngine", "FadeTimer")
		CombatMusicDB.General.CombatEngine.FadeTimer = 10
		CombatMusicDB.General.CombatEngine.FadeMode = "ALL"

		-- Notify the user that the challenge has started.
		-- Some sort of shiny popup maybe goes here.
		E:PrintMessage(L["Chat_ChallengeModeStarted"])

		-- Register our fade listener to call EndCombatChallenge
		E:RegisterMessage("COMBATMUSIC_FADE_COMPLETED", function() E:GetModule("CombatEngine"):EndCombatChallenge() end)

		-- Fire an event just so we can make plugins for this easier. (I WANT TO MAKE A TIMER PLUGIN FOR THIS!)
		self:SendMessage("COMBATMUSIC_CHALLENGE_MODE_STARTED")
	end
end


--- Ends the current CombatMusic Challenge, and reports the time to the user!
function CE:EndCombatChallenge()
	printFuncName("EndCombatChallenge")

	local isEnabled, isRunning, _, startTime = self:GetChallengeModeState()
	-- Can't end a challenge if it's not running
	if isEnabled and isRunning then
		-- Mark the finish time, this marks challenge modes as completed.
		self.ChallengeFinishTime = debugprofilestop()
		self.ChallengeModeRunning = false
		CombatMusicDB.General.CombatEngine.FadeTimer = self.OldFadeOut or DF.General.CombatEngine.FadeTimer
		CombatMusicDB.General.CombatEngine.FadeMode = self.OldFadeMode or DF.General.CombatEngine.FadeMode

		-- Disable the challenge mode option so it doesn't start again.
		CombatMusicDB.General.InCombatChallenge = false

		-- Flash a fancy popup here
		E:PrintMessage(format(L["Chat_ChallengeModeCompleted"], (self.ChallengeFinishTime - startTime) / 1000))
		E:UnregisterMessage("COMBATMUSIC_FADE_COMPLETED")
		self:SendMessage("COMBATMUSIC_CHALLENGE_MODE_FINISHED")
	end
end

--- Resets the Challenge Mode
function CE:ResetCombatChallenge()
	printFuncName("ResetCombatChallenge")

	self.ChallengeModeRunning = nil
	self.ChallengeStartTime = nil
	self.ChallengeFinishTime = nil

	-- Let the user know that the challenge is ready to start again.
	E:PrintMessage(L["Chat_ChallengeModeReset"])
end

--- Gets current Challenge Mode state
--@return several values that represent the current state.
--@usage local isEnabled, isRunning, isComplete, startTime, finishTime = CE:GetChallengeModeState()
function CE:GetChallengeModeState()
	printFuncName("GetChallengeModeState")

	-- Tell us what we need to know, the third argument is true when the Challenge Mode is NOT running, but has a start and finish time.
	return E:GetSetting("General", "InCombatChallenge"), self.ChallengeModeRunning, (self.ChallengeFinishTime and self.ChallengeStartTime), self.ChallengeStartTime, self.ChallengeFinishTime
end


-----------------
--	Module Options
-----------------
local defaults = {
	FadeTimer = 10,
	GameOverEnable = "ALL", -- Valid are "ALL", "BOSSONLY", "NONE"
	FanfareEnable = "BOSSONLY", -- Valid are "ALL", "BOSSONLY", "NONE"
	PreferFocus = false,
	CheckBoss = true,
	UseDing = true,
	FadeMode = "ALL", -- Valid are "ALL", "BOSSONLY", "BOSSNEVER", "NONE"
	FadeLog = true,
}



local opt = {
	type = "group",
	--inline = true,
	name = L["CombatEngine"],
	set = function(info, val) CombatMusicDB.General.CombatEngine[info[#info]] = val end,
	get = function(info) return E:GetSetting("General", "CombatEngine", info[#info]) end,
	args = {
		PreferFocus = {
			name = L["PreferFocus"],
			desc = L["Desc_PreferFocus"],
			type = ".mp3le",
			width =  "double",
			order = 120,
		},
		CheckBoss = {
			name = L["CheckBoss"],
			desc = L["Desc_CheckBoss"],
			type = ".mp3le",
			order = 110,
		},
		SPACER1 = {
			name = L["MiscFeatures"],
			type = "header",
			order = 200
		},
		FadeMode = {
			name = L["FadeMode"],
			desc = L["Desc_FadeMode"],
			disabled = function()
				local _, isRunning = CE:GetChallengeModeState()
				return isRunning
			end,
			type = "select",
			style = "dropdown",
			values = {
				["ALL"] = ALWAYS,
				["BOSSONLY"] = L["BossOnly"],
				["BOSSNEVER"] = L["BossNever"],
				["NEVER"] = NEVER
			},
			order = 310
		},
		FadeTimer = {
			name = L["FadeTimer"],
			desc = L["Desc_FadeTimer"],
			disabled = function()
				local _, isRunning = CE:GetChallengeModeState()
				if isRunning then return true end
				local FadeMode = E:GetSetting("General", "CombatEngine", "FadeMode")
				if FadeMode == "NEVER" then return true end
			end,
			type = "range",
			min = 0.1,
			max = 30,
			step = 0.1,
			bigStep = 1,
			order = 315,
			width = "double",
		},
		FadeLog = {
			name = L["FadeLog"],
			desc = L["Desc_FadeLog"],
			disabled = function()
				local FadeMode = E:GetSetting("General", "CombatEngine", "FadeMode")
				if FadeMode == "NEVER" then return true end
			end,
			type = ".mp3le",
			order = 320,
		},
		GameOverEnable = {
			name = L["GameOverEnable"],
			desc = L["Desc_GameOverEnable"],
			type = "select",
			style = "dropdown",
			order = 305,
			values = {
				["ALL"] = ALWAYS,
				["INCOMBAT"] = L["InCombat"],
				["NEVER"] = NEVER
			}
		},
		FanfareEnable = {
			name = L["FanfareEnable"],
			desc = L["Desc_FanfareEnable"],
			type = "select",
			style = "dropdown",
			order = 300,
			values = {
				["ALL"] = ALWAYS,
				["BOSSONLY"] = L["BossOnly"],
				["NEVER"] = NEVER
			}
		},
		UseDing = {
			name = L["UseDing"],
			desc = L["Desc_UseDing"],
			type = ".mp3le",
			width = "full",
			order = 320,
		}
	}
}



-------------------
--	Module Functions
-------------------
local function CheckForCombat(self, elapsed)
	if CE.isPlayingMusic then
		CE:LeaveCombat(nil, 1)
		CE:ScheduleTimer("EnterCombat", 2)
	end
	self:Hide()
end


function CE:OnInitialize()
	-- Include our default setttings
	DF.General.CombatEngine = defaults

	-- And register our song types
	E:RegisterNewSongType("Battles", true)
	E:RegisterNewSongType("Bosses", true)

	-- Last: mark this module to be loaded, seeing
	-- as this module cannot be disabled.
	DF.Modules.CombatEngine = true
	-- Last, but not least, add it's config to the options.
	E.Options.args.General.args.CombatEngine = opt
	local f = CreateFrame("Frame")
	f:Hide()
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:SetScript("OnUpdate", CheckForCombat)
	f:SetScript("OnEvent", function(self, event, ...) self:Show(); end)
end

function CE:OnEnable()
	-- Enabling module, register events!
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "EnterCombat")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "LeaveCombat")
	self:RegisterEvent("PLAYER_LEVEL_UP", "LevelUp")
	self:RegisterEvent("PLAYER_DEAD", "GameOver")
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "BuildTargetInfo")
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("PLAYER_LEAVING_WORLD", "LeaveCombat")
end

function CE:OnDisable()
	-- Disabling module, unregister events!
	self:LeaveCombat(nil, true)
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_LEVEL_UP")
	self:UnregisterEvent("PLAYER_DEAD")
	self:UnregisterEvent("UNIT_TARGET")
	self:UnregisterEvent("PLAYER_LEAVING_WORLD")
end

