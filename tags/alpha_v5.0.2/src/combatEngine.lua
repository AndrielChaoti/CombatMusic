--[[
  Project: CombatMusic
  Friendly Name: CombatMusic
  Author: Vandesdelca32

  File: combatEngine.lua
  Purpose: The Engine that makes the magic happen

  Version: @file-revision@


  This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
  See http://creativecommons.org/licenses/by-sa/3.0/deed.en_CA for more info.
]]

-- These functions are global API functions used by this module.
--GLOBALS: debugprofilestop, SetCVar, CombatMusicDB
--GLOBALS: UnitExists, UnitLevel, UnitIsPlayer, UnitIsPVP, UnitClassification, UnitAffectingCombat, UnitIsTrivial
--GLOBALS: GetInstanceInfo, UnitInRaid, UnitInParty, UnitIsPVPFreeForAll
--GLOBALS: StopMusic, PlaySoundFile, StopSound
--GLOBALS: CombatMusicBossList

--Import Engine, Locale, Defaults.
local E, L, DF = unpack(select(2, ...))
local CE = E:NewModule("CombatEngine", "AceEvent-3.0", "AceTimer-3.0")

-- Locals for faster lookups
local pairs, select, random = pairs, select, random
local tostring, tostringall, wipe, format = tostring, tostringall, wipe, format
local exp, log = math.exp, math.log


-- Debugging
local printFuncName = E.printFuncName

-- Difficulty level for encounters.
local DIFFICULTY_NONE = 0
local DIFFICULTY_NORMAL = 1
local DIFFICULTY_BOSS = 2




--- Handles the events for entering combat
function CE:EnterCombat(event, ...)
	printFuncName("EnterCombat", event, ...)

	-- for debugging, mark the time we started target checking
	self._TargetCheckTime = debugprofilestop()

	-- Check Fading
	if self.FadeTimer then
		self.FadeTimer = nil
		self:CancelAllTimers()
	end

	-- Restore volume to defaults if we're already in combat
	if self.InCombat then E:SetVolumeLevel(true) end

	-- Save the last volume state and then set our InCombat volume
	E:SaveLastVolumeState()
	E:SetVolumeLevel()

	-- Begin target checking
	self.InCombat = true
	return self:BuildTargetInfo()
end


--- Update the TargetInfo table
local function UpdateTargetInfoTable(unit)
	if not unit then return end
	CE.TargetInfo[unit] = {CE:GetTargetInfo(unit)}
	E:PrintDebug(format("  ==§b%s, isBoss = %s, inCombat = %s", tostringall(unit, CE.TargetInfo[unit][1], CE.TargetInfo[unit][2])))
end


--- Handles target changes
function CE:UNIT_TARGET(event, ...)
	printFuncName("UNIT_TARGET", ...)
	local unit = ...
	-- This check only applies if the player is in combat.
	if not self.InCombat then return end

	-- Reset our target check timer
	self._TargetCheckTime = debugprofilestop()

	-- This is only to check player and focus target changes
	-- other changes don't matter, so Get the new target info
	if unit == "player" then
		UpdateTargetInfoTable("target")
	elseif unit == "focus" then
		UpdateTargetInfoTable("focustarget")
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
		-- Check the BossList, as this trumps TargetInfo
		-- because that function will play the music for us.
		if E:CheckBossList(targetList[i]) then 
			self.EncounterLevel = DIFFICULTY_BOSS
			E:PrintDebug("  ==§cON BOSSLIST")
			break --Bosslist trumps all.
		end
		UpdateTargetInfoTable(targetList[i])
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
		level = UnitLevel('player'),
		instanceType = select(2, GetInstanceInfo('player'))
	}

	-- 1)
	if unitInfo.mobType() > 1 then
		-- Do the level adjustment here, while we're checking
		-- unit type.
		if unitInfo.mobType == 3 or unitInfo.mobType == 4 then
			unitInfo.level.adj = unitInfo.level.raw + 3
		end

		-- Instance check:
		if playerInfo.instanceType == "party" 
			or playerInfo.instanceType == "raid" then
			-- Quick check to negate elites
			if unitInfo.mobType ~= 3 then
				isBoss = true
			else
				isBoss = false
			end
		else
			-- Outside instances
			isBoss = true
		end
	end

	-- 2)
	if UnitIsTrivial(unit) then
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


--- Iterates through the module's target information table and plays music appropriately
function CE:ParseTargetInfo()
	printFuncName("ParseTargetInfo")
	if not self.TargetInfo then return end
	if not self.EncounterLevel then self.EncounterLevel = DIFFICULTY_NONE end
	if self.FadeTimer then return end -- Don't change music if we're fading out...

	for k, v in pairs(self.TargetInfo) do
		-- The TargetInfo table is built {[1] = isBoss, [2] = InCombat}

		-- What information were we given?
		if v[1] and v[2] then
			-- This is a boss, and we are in combat with it
			-- Check to see if our encounter level is below what we're trying to play
			if self.EncounterLevel < DIFFICULTY_BOSS then
				E:PlayMusicFile("Bosses")
				self.EncounterLevel = DIFFICULTY_BOSS
				break -- this trumps all other stuff.
			end
		elseif v[1] and not v[2] then
			-- This IS a boss, but not in combat.
			if self.EncounterLevel < DIFFICULTY_NORMAL then
				E:PlayMusicFile("Battles")
				self.EncounterLevel = DIFFICULTY_NORMAL
			end
			-- Schedule a recheck
			local function recheck()
				self._TargetCheckTime = debugprofilestop()
				UpdateTargetInfoTable(k)
				return self:ParseTargetInfo()
			end
			self:ScheduleTimer(recheck, 0.5)
		else
			if self.EncounterLevel < DIFFICULTY_NORMAL then
				E:PlayMusicFile("Battles")
				self.EncounterLevel = DIFFICULTY_NORMAL
			end
		end
	end
	-- This is the very end of the checking cylce.
	-- Where music is finally played, so figure out how much time it took
	E:PrintDebug(format("  ==§dTime taken: %fms",  debugprofilestop() - self._TargetCheckTime))
end

local function ResetCombatState()
	printFuncName("ResetCombatState")
	-- Wipe the target info table
	wipe(CE.TargetInfo)
	-- Clear combat variables
	CE.InCombat = false
	CE.EncounterLevel = DIFFICULTY_NONE
	-- Clear fade variables
	wipe(CE.FadeVars)
	CE.FadeTimer = nil
	-- Cancel all timers
	CE:CancelAllTimers()
	-- Restore the volume after a second.
	CE.FadeTimer = CE:ScheduleTimer(function() E:SetVolumeLevel(true) end, 1)
end


local MAX_FADE_STEPS = 50

--- Handles the leaving of combat
--@arg forceStop Pass as true to force the music to stop instead of fade out.
function CE:LeaveCombat(event, forceStop)
	printFuncName("LeaveCombat", event, forceStop)

	-- Need to be in combat to leave it!
	if not self.InCombat then return end

	-- Register a message to mark when fadeout is complete
	self:RegisterMessage("CombatMusic_FadeComplete")
	-- Stop all the timers, in case we've got any rechecks going
	self:CancelAllTimers()

	-- Forcing the music stopped?
	if forceStop then
		-- Force it to not be a boss fight first, so we don't get a fanfare.
		self.EncounterLevel = DIFFICULTY_NONE
		self:SendMessage("CombatMusic_FadeComplete")
		return
	else
		-- Begin fadeout "magic"
		self:BeginMusicFade()
	end
end


-- Handles event PLAYER_DEAD, as it requires a slightly different touch
function CE:GameOver()
	self:LeaveCombat("PLAYER_DEAD", true)
	local GameOverWhen = E:GetSetting("General", "CombatEngine", "GameOverEnable")
	if GameOverWhen == "ALL" then
		self:PlayFanfare("GameOver")
	elseif GameOverWhen == "INCOMBAT" and self.InCombat then
		self:PlayFanfare("GameOver")
	end
end


--- Fade Cycle timer callback
local function FadeStepCallback()
	printFuncName("FadeStep")
	if not CE.FadeTimer then return end

	if not CE.FadeVars.StepCount then
		CE.FadeVars.StepCount = 0
		CE.FadeVars.CurrentVolume = E:GetSetting("General", "Volume")
		CE.FadeVars.VolumeStep = exp(CE.FadeVars.CurrentVolume)
		CE.FadeVars.VolumeStepDelta = (CE.FadeVars.VolumeStep - 1) / (MAX_FADE_STEPS - 1)
	end

	-- Increment the step counter
	CE.FadeVars.StepCount = CE.FadeVars.StepCount + 1

	-- Update the current volume
	CE.FadeVars.CurrentVolume = log(CE.FadeVars.VolumeStep)
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
		CE:SendMessage("CombatMusic_FadeComplete")
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
	if self.fadeTime <= 0 then 
		self:SendMessage("CombatMusic_FadeComplete")
		return
	end
	



	-- Get the interval
	self.FadeVars.interval = self.fadeTime / MAX_FADE_STEPS
	-- Schedule the timer
	self.FadeTimer = self:ScheduleRepeatingTimer(FadeStepCallback, self.FadeVars.interval)
end


---Handles the message for when fadeouts are finished.
function CE:CombatMusic_FadeComplete()
	printFuncName("CombatMusic_FadeComplete")
	-- Unregister the message
	self:UnregisterMessage("CombatMusic_FadeComplete")

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
	if E:GetSetting("General", "CombatEngine", "DingEnabled") then
		if E:GetSetting("General", "CombatEngine", "UseDing") then
			self:PlayFanfare("DING")
		else
			self:PlayFanfare("Victory")
		end
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


-----------------
--	Module Options
-----------------
local defaults = {
	FadeTimer = 10,
	GameOverEnable = "ALL",
	FanfareEnable = "BOSSONLY",
	PreferFocus = false,
	CheckBoss = true,
	UseDing = true,
}


local opt = {
	type = "group",
	--inline = true,
	name = L["CombatEngine"],
	set = function(info, val) CombatMusicDB.General.CombatEngine[info[#info]] = val end,
	get = function(info) return E:GetSetting("General", "CombatEngine", info[#info]) end,
	order = 600,
	args = {

		PreferFocus = {
			name = L["PreferFocus"],
			desc = L["Desc_PreferFocus"],
			type = "toggle",
			width =  "double",
			order = 120,
		},
		CheckBoss = {
			name = L["CheckBoss"],
			desc = L["Desc_CheckBoss"],
			type = "toggle",
			order = 110,
		},
		SPACER1 = {
			name = L["MiscFeatures"],
			type = "header",
			order = 200
		},
		FadeTimer = {
			name = L["FadeTimer"],
			desc = L["Desc_FadeTimer"],
			type = "range",
			min = 0,
			max = 30,
			step = 0.1,
			bigStep = 1,
			order = 311,
		},
		GameOverEnable = {
			name = L["GameOverEnable"],
			desc = L["Desc_GameOverEnable"],
			type = "select",
			order = 310,
			values = {
				["ALL"] = ALL,
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
				["ALL"] = ALL,
				["BOSSONLY"] = L["BossOnly"],
				["NEVER"] = NEVER
			}
		},
		UseDing = {
			name = L["UseDing"],
			desc = L["Desc_UseDing"],
			type = "toggle",
			width = "full",
			order = 320,
		},
	}
}


-------------------
--	Module Functions
-------------------
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
end

function CE:OnEnable()
	-- Enabling module, register events!
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "EnterCombat")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "LeaveCombat")
	self:RegisterEvent("PLAYER_LEVEL_UP", "LevelUp")
	self:RegisterEvent("PLAYER_DEAD", "GameOver")
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "BuildTargetInfo")
	self:RegisterEvent("UNIT_TARGET")
end

function CE:OnDisable()
	-- Disabling module, unregister events!
	self:LeaveCombat(true)
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_LEVEL_UP")
	self:UnregisterEvent("PLAYER_DEAD")
	self:UnregisterEvent("UNIT_TARGET")
end

