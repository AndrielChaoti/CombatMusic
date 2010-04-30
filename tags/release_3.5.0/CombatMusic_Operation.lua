--[[
------------------------------------------------------------------------
	PROJECT: CombatMusic
	FILE: Main Operations
	VERSION: 3.5
	DATE: 06-Apr-2010 08:50 -0600
	PURPOSE: The main operations of CombatMusic.
	CREDITS: Code written by Vandesdelca32
	
	Copyright (c) 2010 Vandesdelca32
	
	This program is free software. you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http.//www.gnu.org/licenses/>.
------------------------------------------------------------------------
]]


CombatMusic["Info"]= {}



-- Entering Combat
function CombatMusic.enterCombat()

	--Check that CombatMusic is turned on
	if not CombatMusic_SavedDB.Enabled then return end
	
	-- Save the CVar's last states, before continuing
	CombatMusic.GetSavedStates()
	
	-- Check the player's target
	CombatMusic.Info["BossFight"] = CombatMusic.CheckTarget()
	
	-- Change the CVars to what they need to be
	SetCVar("Sound_EnableMusic", "1")
	SetCVar("Sound_ZoneMusicNoDelay", "1")
	SetCVar("Sound_MusicVolume", "1")
	
	-- Play the music
	local filePath = "Interface\\Music\\%s\\%s%d.mp3"
	if CombatMusic.Info.BossFight then
		PlayMusic(format(filePath, "Bosses", "Boss", random(1, CombatMusic_SavedDB.numSongs.Bosses)))
	else
		PlayMusic(format(filePath, "Battles", "Battle", random(1, CombatMusic_SavedDB.numSongs.Battles)))
	end
	CombatMusic.Info["InCombat"] = true
end

-- Player Changed Target
function CombatMusic.TargetChanged()
	if not CombatMusic_SavedDB.Enabled then return end
	
	-- Only changing target, so addtional checks, it's not going to change the music unless it's from reg to boss
	if CombatMusic.Info.BossFight then return end
	if not CombatMusic.Info.InCombat then return end
	
	CombatMusic.Info["BossFight"] = CombatMusic.CheckTarget()
	
	-- Get that music changed
	local filePath = "Interface\\Music\\%s\\%s%d.mp3"
	if CombatMusic.Info.BossFight then
		PlayMusic(format(filePath, "Bosses", "Boss", random(1, CombatMusic_SavedDB.numSongs.Bosses)))
	end
end


-- Leaving Combat
-- Stop the music playing if it's leaving combat.
-- If isDisabling, then don't play a victory fanfare when the music stops.
function CombatMusic.leaveCombat(isDisabling)
	--Check that CombatMusic is turned on
	if not CombatMusic_SavedDB.Enabled then return end
	
	-- OhNoes! The player's dead, don't want no fanfares playing...
	if UnitIsDeadOrGhost("player") then return end
	
	StopMusic()
	-- Left Combat, Restore states.
	SetCVar("Sound_EnableMusic", CombatMusic.Info.EnabledMusic or "0")
	SetCVar("Sound_ZoneMusicNoDelay", CombatMusic.Info.LoopMusic or "1")
	SetCVar("Sound_MusicVolume", CombatMusic.Info.MusicVolume or "1")
	
	-- Check for boss fight, and if the user wants to hear it...
	if CombatMusic.Info.BossFight and CombatMusic_SavedDB.PlayWhen.CombatFanfare and not isDisabling then
		-- Yay, play the fanfare.. if it's not on cooldown.
		if (not CombatMusic.Info.FanfareCD) or (GetTime() >= CombatMusic.Info.FanfareCD) then
			CombatMusic.Info["FanfareCD"] = GetTime() + CombatMusic_SavedDB.timeOuts.Fanfare
			PlaySoundFile("Interface\\Music\\Victory.mp3")
		end
	end
	CombatMusic.Info.InCombat = nil
	CombatMusic.Info.BossFight = nil
	
end

-- Game Over
-- Aww, I died, play some game over music for me
function CombatMusic.GameOver()
	--Check that CombatMusic is turned on
	if not CombatMusic_SavedDB.Enabled then return end
		
	StopMusic()
	-- Left Combat, Restore states.
	SetCVar("Sound_EnableMusic", CombatMusic.Info.EnabledMusic or "0")
	SetCVar("Sound_ZoneMusicNoDelay", CombatMusic.Info.LoopMusic or "1")
	SetCVar("Sound_MusicVolume", CombatMusic.Info.MusicVolume or "1")
	

	-- Too bad, play the gameover, if it's not on CD, and the user wants to hear it
	if CombatMusic_SavedDB.PlayWhen.GameOver then
		if (not CombatMusic.Info.GameOverCD) or (GetTime() >= CombatMusic.Info.GameOverCD) then
			CombatMusic.Info["GameOverCD"] = GetTime() + CombatMusic_SavedDB.timeOuts.GameOver
			PlaySoundFile("Interface\\Music\\GameOver.mp3")
		end
	end
	
	-- Clear those vars, we're not in combat anymore...
	CombatMusic.Info.InCombat = nil
	CombatMusic.Info.BossFight = nil
	
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
function CombatMusic.CheckTarget()
	--Check that CombatMusic is turned on
	if not CombatMusic_SavedDB.Enabled then return end
	
	local isBoss
	
	-- Get all the info we're going to need
	local targetInfo = {
		["level"] = {
			["raw"] = UnitLevel("target"),
		},
		["isPvP"] = UnitIsPVP("target"),
		["isPlayer"] = UnitIsPlayer("target"),
		["mobType"] = UnitClassification("target"),
		["inGroup"] = UnitInParty("target") or UnitInRaid("target"),
		["factionGroup"] = UnitFactionGroup("target"),
	}
	local playerInfo = {
		["level"] = UnitLevel("player"),
		["factionGroup"] = UnitFactionGroup("player"),
		["instanceType"] = select(2, GetInstanceInfo()),
	}
	
	-- Make those checks
	targetInfo.level["adjusted"] = targetInfo.level.raw
	-- Checking the mob type, normal mobs aren't bosses...
	if targetInfo.mobType ~= "normal" then
	
		-- Give it a 3 level bonus for being an elite, worldbosses have -1 for a level, and that's checked later.
		if targetInfo.mobType == "elite" or targetInfo.mobType == "rareelite" then
			targetInfo.level["adjusted"] = targetInfo.level.raw + 3
		end
		
		isBoss = true
		
		-- If I'm in an instance full of elite mobs, I don't want it playing boss music all the time D.
		if playerInfo.instanceType == "party" or playerInfo.instanceType == "raid" then
		
			-- it's a regular mob in an instance
			if targetInfo.mobType == "elite" then 
				isBoss = false
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
		end
	end
	
	-- ogod, it's got -1 for a level(worldBoss, ??) or it's 5 levels higher than me!
	if targetInfo.level.raw == -1 or targetInfo.level.adjusted >= 5 + playerInfo.level then
		isBoss = true
	elseif targetInfo.level.adjusted <= 5 - playerInfo.level then
		-- Heh, this is too easy... Not a boss anymore.
		isBoss = false
	end
	
	targetInfo = nil
	playerInfo = nil
	
	return isBoss
	
end

-- Saves music state so we can restore it out of combat
function CombatMusic.GetSavedStates()
	-- Music was turned on?
	CombatMusic.Info["EnabledMusic"] = GetCVar("Sound_EnableMusic") or "0"
	-- Music was looping?
	CombatMusic.Info["LoopMusic"] = GetCVar("Sound_ZoneMusicNoDelay") or "1"
	-- Music Volume?
	CombatMusic.Info["MusicVolume"] = GetCVar("Sound_MusicVolume") or "1"
end

-- Ugh, Show the /command help for the noobies.
function CombatMusic.ShowHelp()
	CombatMusic_HelpFrame.Show()
end

