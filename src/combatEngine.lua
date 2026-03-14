--[[
	Project: CombatMusic
	Friendly Name: CombatMusic

	File: combatEngine.lua
	Purpose: The Engine that makes the magic happen

	Version: f47258e63967c37858aba8886be2e40aa301bd65
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
local GetInstanceInfo, UnitAffectingCombat, UnitIsDeadOrGhost, UnitIsPlayer = GetInstanceInfo, UnitAffectingCombat, UnitIsDeadOrGhost, UnitIsPlayer
local StopMusic, StopSound = StopMusic, StopSound


-- Debugging
local printFuncName = E.printFuncName

-- Difficulty level for encounters.
local DIFFICULTY_NONE = 0
local DIFFICULTY_NORMAL = 1
local DIFFICULTY_BOSS = 2
local DIFFICULTY_BOSSLIST = 10


function CE:EncounterStarted(event, ...)
	--- Grabs the active encounter ID
	printFuncName("EncounterStarted", event, ...)

    local encounterID = ...
    if encounterID then
        self.encounterID = tostring(encounterID)
    end

    self:ParseInfo()
end


function CE:EncounterEnded(event, ...)
	--- Clears the encounter ID when the encounter ends
	printFuncName("EncounterEnded", event, ...)

	self.encounterID = nil
    self.encounterName = nil
    if self.encounterLevel ~= DIFFICULTY_BOSSLIST then
        self.encounterLevel = DIFFICULTY_NONE
    end
    self:ParseInfo()
end


--- Handles the events for entering combat
function CE:EnterCombat(event, ...)
	printFuncName("EnterCombat", event, ...)
	if not E:GetSetting("Enabled") then return end

	-- for debugging, mark the time we started target checking
	self._TargetCheckTime = debugprofilestop()

    if not self.savedVolume then
        self.savedVolume = true
        E:SaveLastVolumeState()
    end

	-- Check Fading
	if self.fadeTimer then
        self:CancelTimer(self.fadeTimer)
		self.fadeTimer = nil
        if self.savedVolume then E:SetVolumeLevel(false) end
    end
    if self.resetTimer then
        self:CancelTimer(self.resetTimer)
        self.resetTimer = nil
    end

	if UnitIsDeadOrGhost('player') then return end -- Don't play music if we're dead...

	self.inCombat = true
    if not self.isPlayingMusic then
        -- Delay music start in case we get an ENCOUNTER_START trigger
        self:ScheduleTimer(function()
            if not self.isPlayingMusic and self.inCombat then
				E:SetVolumeLevel(false)
                self:ParseInfo()
            end
            -- This is the very end of the checking cycle.
	        -- Where music is finally played, so figure out how much time it took
            E:PrintDebug(format("  ==§dTime taken: %fms", debugprofilestop() - self._TargetCheckTime))
            E:SendMessage("COMBATMUSIC_ENTER_COMBAT")
        end, 1)
        return

    -- User might not want the song to change if music is already playing...
    elseif E:GetSetting("General", "CombatEngine", "SkipSongChange") and self.isPlayingMusic then
        return
    end
end


-- Use these instance IDs to ignore the garrisons.
local garrisonIDs = {
	[1152] = true, --	FW Horde Garrison Level 1
	[1330] = true, --	FW Horde Garrison Level 2
	[1153] = true, --	FW Horde Garrison Level 3
	[1154] = true, --	FW Horde Garrison Level 4
	[1158] = true, --	SMV Alliance Garrison Level 1
	[1331] = true, --	SMV Alliance Garrison Level 2
	[1159] = true, --	SMV Alliance Garrison Level 3
	[1160] = true, --	SMV Alliance Garrison Level 4
}


local INSTANCE_OUTDOORS = 0
local INSTANCE_DUNGEON = 1
local INSTANCE_RAID = 2
--- Figures out what kind of instance the player is in.
--@return instanceEnum An enumeration of the instance type, 0 = outdoors, 1 = dungeon, 2 = raid
function CE:GetInstanceInfo()
	local _, instanceType, _, _, _, _, _, instanceMap, _ = GetInstanceInfo()
	if garrisonIDs[instanceMap] and E:GetSetting("General", "CombatEngine", "GarrisonsAreOutdoors") then
		return INSTANCE_OUTDOORS
	else
		if instanceType == "party" then
			return INSTANCE_DUNGEON
		elseif instanceType == "raid" then
			return INSTANCE_RAID
		else
			return INSTANCE_OUTDOORS
		end
	end
end


-- Schedule a recheck
function CE:Recheck(k)
	self._TargetCheckTime = debugprofilestop()
	-- figure out if the timer needs to be cancelled
	if UnitAffectingCombat(k) then
		self:CancelTimer(self.RecheckTimer[k])
		self.RecheckTimer[k] = nil
	end
	self:ParseInfo()
end


--- Iterates through the module's target information table and plays music appropriately
function CE:ParseInfo(unit)
    printFuncName("ParseInfo")
    if not self.inCombat then return end
    if not self.encounterLevel then self.encounterLevel = DIFFICULTY_NONE end

    -- Don't change music if we're fading out...
    if self.fadeTimer then return end

    if self.encounterLevel == DIFFICULTY_BOSSLIST and self.isPlayingMusic then return end
    if self.encounterLevel == DIFFICULTY_BOSS and self.isPlayingMusic then return end

    if self.encounterID then
        if self.inCombat and self.encounterLevel < DIFFICULTY_BOSS then
            E:PrintDebug("  ==§cEncounter Level Set: DIFFICULTY_BOSS")
            self.encounterLevel = DIFFICULTY_BOSS
            E:PlayMusicFile("Bosses")
            self.isPlayingMusic = true
        end
    elseif self.inCombat and self.encounterLevel < DIFFICULTY_NORMAL then
        E:PrintDebug("  ==§cEncounter Level Set: DIFFICULTY_NORMAL")
        self.encounterLevel = DIFFICULTY_NORMAL
        E:PlayMusicFile("Battles")
        self.isPlayingMusic = true
    end
end


local function ResetCombatState()
	printFuncName("ResetCombatState")
	-- Clear variables:
	CE.inCombat = nil
	CE.encounterLevel = nil
	CE.fadeTimer = nil
	CE.isPlayingMusic = nil
    CE.musicType = nil
    E.currentMusicPath = ""

    if CE.RecheckTimer then
        for k, t in pairs(CE.RecheckTimer) do
            if t then
                CE:CancelTimer(t)
                CE.RecheckTimer[k] = nil
            end
        end
		wipe(CE.RecheckTimer)
	end

	if CE.FadeVars then
		wipe(CE.FadeVars)
	end
end


local MAX_FADE_STEPS = 50
--- Handles the leaving of combat
--@arg forceStop Pass as true to force the music to stop instead of fade out.
function CE:LeaveCombat(event, forceStop)
	printFuncName("LeaveCombat", event, forceStop)
	-- Need to be in combat to leave it!
	if not self.inCombat then return end

    -- This check only applies if the player is in combat
    -- or not fading out...
    if not self.inCombat and self.fadeTimer then return true end

	-- Check event:
	if event == "PLAYER_LEAVING_WORLD" then forceStop = true end

	-- Make sure the player's not dead and firing a normal LeaveCombat... God Blizz
	if event == "PLAYER_REGEN_ENABLED" and UnitIsDeadOrGhost("player") then return end

	-- Register a message to mark when fadeout is complete
	self:RegisterMessage("COMBATMUSIC_FADE_COMPLETED")

	-- Forcing the music stopped?
	if forceStop then
		-- Force it to not be a boss fight first, so we don't get a fanfare.
		self.encounterLevel = DIFFICULTY_NONE
		self:SendMessage("COMBATMUSIC_FADE_COMPLETED")
		return
	else
		-- We don't want to always fade the music out if the user doesn't want it to
		-- so check that here.
		local fadeMode = E:GetSetting("General", "CombatEngine", "FadeMode")
		if (fadeMode == "ALL") or
			 (fadeMode == "BOSSNEVER" and self.encounterLevel == DIFFICULTY_NORMAL) or
			 (fadeMode == "BOSSONLY" and self.encounterLevel > DIFFICULTY_NORMAL) then
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
	self:LeaveCombat("PLAYER_DEAD", true)

	-- Get the game over setting
	local GameOverWhen = E:GetSetting("General", "CombatEngine", "GameOverEnable")

	-- play the fanfare :D
	if GameOverWhen == "ALL" then
		self:PlayFanfare("GameOver")
	elseif GameOverWhen == "INCOMBAT" and self.inCombat then
		self:PlayFanfare("GameOver")
	end
end


--- Fade Cycle timer callback
-- @arg logMode set to true to switch to log mode
local function FadeStepCallback(logMode)
	-- printFuncName("FadeStep")
	if not CE.fadeTimer then return end
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
        CE:CancelTimer(CE.fadeTimer)
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
	if self.fadeTimer then return end

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
	self.fadeTimer = self:ScheduleRepeatingTimer(FadeStepCallback, self.FadeVars.interval, E:GetSetting("General", "CombatEngine", "FadeLog"))
end


function CE:OnUnitVisibilityChanged(event, unit)
    -- printFuncName("OnUnitVisibilityChanged")
    if not self.inCombat then return end
    if not UnitAffectingCombat(unit) or not UnitCanAttack(unit, "player") then return end

    if not self.encounterLevel then self.encounterLevel = DIFFICULTY_NONE end
    if self.encounterLevel == DIFFICULTY_BOSSLIST then return end

    if E:GetSetting("General","CombatEngine", "CheckBoss") and self.encounterLevel < DIFFICULTY_BOSSLIST then
		if self.encounterID or unit then
            if E:CheckBossList(self.encounterID, unit) then
                -- Playing bosslist song
                E:PrintDebug("  ==§cEncounter Level Set: DIFFICULTY_BOSSLIST")
                self.encounterLevel = DIFFICULTY_BOSSLIST
                self.isPlayingMusic = true
            end
        end
    end
end


---Handles the message for when fadeouts are finished.
function CE:COMBATMUSIC_FADE_COMPLETED()
	printFuncName("COMBATMUSIC_FADE_COMPLETED")
	-- Unregister the message
	self:UnregisterMessage("COMBATMUSIC_FADE_COMPLETED")

	-- If this was a boss fight:
	local playWhen = E:GetSetting("General", "CombatEngine", "FanfareEnable")
	if playWhen == "BOSSONLY" then
		if self.encounterLevel > 1 then
			self:PlayFanfare("Victory")
		end
	elseif playWhen == "ALL" then
		self:PlayFanfare("Victory")
	end

    -- Stop the music
    StopMusic()
    -- Reset the users music settings
    E:SetVolumeLevel(true)
    self.savedVolume = false

	-- Reset the combat state finally
    if self.resetTimer then self:CancelTimer(self.resetTimer) end
	self.resetTimer = self:ScheduleTimer(ResetCombatState, 1)
end


function CE:LevelUp()
	printFuncName("LevelUp")

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
	if self.soundId then
		StopSound(self.soundId)
	end

	-- Play our chosen fanfare
	self.soundId = select(2, E:PlaySoundFile("Interface/AddOns/CombatMusic_Music/" .. fanfare .. ".mp3"))
end


-- Starts the CombatMusic Challenge, and marks some things.
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
		self.challengeStartTime = debugprofilestop()
		self.challengeModeRunning = true
		self.challengeFinishTime = nil

		-- Set the user's Fadeout timer to 10 seconds:
		self.oldFadeMode = E:GetSetting("General", "CombatEngine", "FadeMode")
		self.oldFadeOut = E:GetSetting("General", "CombatEngine", "FadeTimer")
		CombatMusicDB.General.CombatEngine.FadeTimer = 10
		CombatMusicDB.General.CombatEngine.FadeMode = "ALL"

		-- Notify the user that the challenge has started.
		-- Some sort of shiny popup maybe goes here.
		E:Print(L["Chat_ChallengeModeStarted"])

		-- Register our fade listener to call EndCombatChallenge
        if not self._challengeFadeHandler then
            self._challengeFadeHandler = function() self:EndCombatChallenge() end
        end
		self:RegisterMessage("COMBATMUSIC_FADE_COMPLETED", self._challengeFadeHandler)

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
		self.challengeFinishTime = debugprofilestop()
		self.challengeModeRunning = false
		CombatMusicDB.General.CombatEngine.FadeTimer = self.oldFadeOut or DF.General.CombatEngine.FadeTimer
		CombatMusicDB.General.CombatEngine.FadeMode = self.oldFadeMode or DF.General.CombatEngine.FadeMode

		-- Disable the challenge mode option so it doesn't start again.
		CombatMusicDB.General.InCombatChallenge = false

		-- Flash a fancy popup here
		E:Print(format(L["Chat_ChallengeModeCompleted"], (self.challengeFinishTime - startTime) / 1000))
		self:UnregisterMessage("COMBATMUSIC_FADE_COMPLETED")
		self:SendMessage("COMBATMUSIC_CHALLENGE_MODE_FINISHED")
	end
end


--- Resets the Challenge Mode
function CE:ResetCombatChallenge()
	printFuncName("ResetCombatChallenge")

	self.challengeModeRunning = nil
	self.challengeStartTime = nil
	self.challengeFinishTime = nil

	-- Let the user know that the challenge is ready to start again.
	E:Print(L["Chat_ChallengeModeReset"])
end


--- Gets current Challenge Mode state
--@return several values that represent the current state.
--@usage local isEnabled, isRunning, isComplete, startTime, finishTime = CE:GetChallengeModeState()
function CE:GetChallengeModeState()
	printFuncName("GetChallengeModeState")

	-- Tell us what we need to know, the third argument is true when the Challenge Mode is NOT running, but has a start and finish time.
	return E:GetSetting("General", "InCombatChallenge"), self.challengeModeRunning, (self.challengeFinishTime and self.challengeStartTime), self.challengeStartTime, self.challengeFinishTime
end


-----------------
--	Module Options
-----------------
local defaults = {
	FadeTimer = 10,
	GameOverEnable = "ALL",         -- Valid are "ALL", "BOSSONLY", "NONE"
	FanfareEnable = "BOSSONLY",     -- Valid are "ALL", "BOSSONLY", "NONE"
	PreferFocus = false,
	CheckBoss = true,
	UseDing = true,
	FadeMode = "ALL",               -- Valid are "ALL", "BOSSONLY", "BOSSNEVER", "NONE"
	FadeLog = true,
	GarrisonsAreOutdoors = true,
	SkipSongChange = false,
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
			order = 315,
			--width = "double",
		},
		FadeLog = {
			name = L["FadeLog"],
			desc = L["Desc_FadeLog"],
			disabled = function()
				local FadeMode = E:GetSetting("General", "CombatEngine", "FadeMode")
				if FadeMode == "NEVER" then return true end
			end,
			type = "toggle",
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
			type = "toggle",
			width = "full",
			order = 320,
		},
		GarrisonsAreOutdoors = {
			name = L["GarrisonsAreOutdoors"],
			desc = L["Desc_GarrisonsAreOutdoors"],
			type = "toggle",
			width = "full",
			order = 330,
		},
		SkipSongChange = {
			name = L["SkipSongChange"],
			desc = L["Desc_SkipSongChange"],
			type = "toggle",
			width = "full",
			order = 340,
		}
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
	self:RegisterEvent("ENCOUNTER_START", "EncounterStarted")
    self:RegisterEvent("ENCOUNTER_END", "EncounterEnded")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "EnterCombat")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "LeaveCombat")
	self:RegisterEvent("PLAYER_LEVEL_UP", "LevelUp")
	self:RegisterEvent("PLAYER_DEAD", "GameOver")
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED", "OnUnitVisibilityChanged")
	self:RegisterEvent("PLAYER_LEAVING_WORLD", "LeaveCombat")
end

function CE:OnDisable()
	-- Disabling module, unregister events!
	self:LeaveCombat(nil, true)
    self:UnregisterEvent("ENCOUNTER_START")
    self:UnregisterEvent("ENCOUNTER_END")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_LEVEL_UP")
	self:UnregisterEvent("PLAYER_DEAD")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("PLAYER_LEAVING_WORLD")
end
