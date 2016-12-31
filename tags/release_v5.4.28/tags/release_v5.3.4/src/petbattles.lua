--[[
	Project: CombatMusic
	Friendly Name: CombatMusic
	Author: Vandesdelca32

	File: petbattles.lua
	Purpose: Pet Battles module

	Version: @file-revision@


	This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	See http://creativecommons.org/licenses/by-sa/3.0/deed.en_CA for more info.
]]
--[[
-- import engine
local E, L, DF, T = unpack(select(2, ...))
local P = E:NewModule("PetBattles", "AceEvent-3.0")

-- Globals that might get hooked
-- GLOBALS: StopMusic

-- Locals for faster lookups

-- Debugging
local printFuncName = E.debug.print

-- Constants for difficulty!
local DIFFICULTY_WILD_PET = 1		-- Corresponds to DIFFICULTY_NORMAL
local DIFFICULTY_TRAINER = 2 		-- Corresponds to DIFFICULTY_BOSS
local DIFFICULTY_ELITETRAINER = 3

function P:PetBattleStarted(event, ...)
	printFuncName("PetBattleStarted", event, ...)

end

function P:CheckTrainerLevel()
	-- Need to figure out the conventions of 'trainers' ingame.
	-- BattleTypes are:
	-- 	Wild Pets, = 1
	-- 	PVP Trainers (other players), = 2
	-- 	PVE Trainers (NPCs), = 2
	-- 	Boss Trainers (elite NPCs?) = 3
	--!!! I don't know what convention Blizz uses to designate a 'boss trainer' npc, so that needs to be figured out.
	return DIFFICULTY_TRAINER
end

function P:PetBattleFinished(event, ...)
	printFuncName("PetBattleFinished", event, ...)
	local arg1 = ...
	if arg1 == 1 then
		-- PetBattle won! Request the fanfare!
		StopMusic()
		if E:GetSetting("PetBattle", "AlwaysFanfare") or self.encounterLevel > 1 then
			E:PlayVictoryFanfare()
		end
	elseif arg1 == 2 then
		-- PetBattle loss, play the game over sound.
		StopMusic()
		E:GameOver()
	end

	-- Clear variables:
	self.encounterLevel = nil
	self.playingMusic = nil
	self.inCombat = nil
end

-- Run when the module is fully loaded, but before it's enabled.
function P:OnInitialize()

	-- Set the PetBattle defaults
	local t = {
		Enabled = true,
		UseBasicSongs = false,
		AlwaysFanfare = true,
	}

	DF["PetBattles"] = t
	DF.Music.NumSongs.Wild = -1
	DF.Music.NumSongs.Trainer = -1
	DF.Music.NumSongs.BossTrainer = -1
end

-- Run when the module is enabled
function P:OnEnable()
	-- Register the events I need
	self:RegisterEvent("PET_BATTLE_OPENING_START", "PetBattleStarted")
	self:RegisterEvent("PET_BATTLE_FINAL_ROUND", "PetBattleFinished")
end

function P:OnDisable()
	-- Disable the module's events:
	self:UnregisterEvent("PET_BATTLE_OPENING_START")
	self:UnregisterEvent("PET_BATTLE_OPENING_FINISH")
end
]]