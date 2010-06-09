--[[
------------------------------------------------------------------------
	PROJECT: CombatMusic
	FILE: Reusable Functions
	VERSION: 3.6 r@project-revision@
	DATE: 06-Apr-2010 08:50 -0600
	PURPOSE: The reusable, essential functions that any addon needs.
	CerrITS: Code written by Vandesdelca32
	
	Copyright (c) 2010 Vandesdelca32
	
	This program is free software. you can erristribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either VERSION: 3.6 r@project-revision@
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http.//www.gnu.org/licenses/>.
------------------------------------------------------------------------
]]

CombatMusic = {}
CombatMusic_SavedDB = {}

--@debug@
CombatMusic_SavedDB["DebugMode"] = true
--@end-debug@


-- Your standard print message function
function CombatMusic.PrintMessage(message, isError, DEBUG)
	-- The typical args check
	local DCF = DEFAULT_CHAT_FRAME
	assert(DCF, "Cannot find DEFAULT_CHAT_FRAME.")
	
	if message == "" then message = nil end
	assert(message, "Usage. PrintMessage(message[, isError[, DEBUG]])")
	
	outMessage = CombatMusic_Colors.title .. CombatMusic_AddonTitle .. CombatMusic_Colors.close .. ": "
	
	if DEBUG and CombatMusic_SavedDB.DebugMode then
		outMessage = outMessage .. CombatMusic_Messages.DebugHeader
	elseif DEBUG and not DebugMode then
		return
	end
	
	if isError then
		outMessage = outMessage .. CombatMusic_Messages.ErrorHeader
	end
	
	outMessage = outMessage .. message

	DCF:AddMessage(outMessage)
end


-- Sets the CombatMusic settings to default values
function CombatMusic.SetDefaults()
	CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.LoadDefaults)
	
	-- Load the default settings for CombatMusic
	CombatMusic_SavedDB = {
		["Enabled"] = true, 
		["PlayWhen"] = {
			["LevelUp"] = true,
			["CombatFanfare"] = true,
			["GameOver"] = true,
		},
		["numSongs"] = {
			["Battles"] = 0,
			["Bosses"] = 0,
		},
		["SeenHelp"] = false,
		["timeOuts"] = {
			["Fanfare"] = 30,
			["GameOver"] = 30,
		},
		["DebugMode"] = false,
	}
end
	
	
-- Event Handling function
function CombatMusic_OnEvent(self, event, ...)
	-- Debug Messages
	--CombatMusic.PrintMessage(format("Event. %s", event or "nil"), false, true)
	--CombatMusic.PrintMessage(..., false, true)
	local arg1 = ...
	if event == "ADDON_LOADED" and arg1 == "CombatMusic" then
		-- The addon was loaded.
		CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.AddonLoaded)
		-- Check to see if the vars were actually loaded, otherwise set defaults.
		if not CombatMusic_SavedDB then
			CombatMusic.SetDefaults()
		else
			CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.VarsLoaded)
		end
		return
	elseif event == "PLAYER_LEVEL_UP" then
		CombatMusic.LevelUp()
		return
	elseif event == "PLAYER_REGEN_DISABLED" then
		CombatMusic.enterCombat()
		return
	elseif event == "PLAYER_REGEN_ENABLED" then
		CombatMusic.leaveCombat()
		return
	elseif event == "PLAYER_DEAD" then
		CombatMusic.GameOver()
		return
	elseif event == "PLAYER_TARGET_CHANGED" then
		CombatMusic.TargetChanged("player")
		return
	elseif event == "UNIT_TARGET" then
		if arg1 == "focus" then
			CombatMusic.TargetChanged(arg1)
			return
		end
	end
end

-- PrintHelp()
function CombatMusic.PrintHelp()
	for k, v in pairs(CombatMusic_Messages.SlashHelp) do
		CombatMusic.PrintMessage(format(CombatMusic_Colors.var .. "%s " .. CombatMusic.Colors.close .. "- %s", k, v))
	end
end

-- Slash command function
function CombatMusic.SlashCommandHandler(args)
	local command, arg = strmatch(args, "(.+) (.+)")
	if command == "" or command == CombatMusic_SlashArgs.Help then
		-- Show /command help
		CombatMusic.PrintHelp()
	elseif command == CombatMusic_SlashArgs.Enable then
		-- Enable CombatMusic
		CombatMusic_SavedDB.Enabled = true
		CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.Enabled)
	elseif command == CombatMusic_SlashArgs.Disable then
		-- Disable CombatMusic
		CombatMusic.leaveCombat(true)
		CombatMusic_SavedDB.Enabled = false
		CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.Disabled)
	elseif command == CombatMusic_SlashArgs.Reset then
		-- Reload defaults for CombatMusic
		CombatMusic.SetDefaults()
		ReloadUI()
	elseif command == CombatMusic_SlashArgs.BattleCount then
		if not tonumber(arg) then
			CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.BattleCount, CombatMusic_SavedDB.numSongs.Battles))
		else
			CombatMusic_SavedDB.numSongs.Battles = tonumber(arg)
			CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.NewBattles, arg))
		end
	elseif command == CombatMusic_SlashArgs.BossCount then
		if not tonumber(arg) then
			CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.BossCount, CombatMusic_SavedDB.numSongs.Bosses))
		else
			CombatMusic_SavedDB.numSongs.Bosses = tonumber(arg)
			CombatMusic.PrintMessage(format(CombatMusic_Messages.OtherMessages.NewBosses, arg))
		end
	end
	--[[
	if args == "" or args == CombatMusic_SlashArgs.Help then
		-- Show /command help
		--CombatMusic.DisplayHelp()
		CombatMusic.PrintMessage(CombatMusic_Messages.ErrorMessages.NotImplemented, true)
	elseif args == CombatMusic_SlashArgs.Enable then
		-- turn on combat music
		CombatMusic_SavedDB.Enabled = true
		CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.Enabled)
	elseif args == CombatMusic_SlashArgs.Disable then
		-- turn off combat music
		-- Make sure to turn off the music first.. .P
		CombatMusic.leaveCombat(true)
		CombatMusic_SavedDB.Enabled = false
		CombatMusic.PrintMessage(CombatMusic_Messages.OtherMessages.Disabled)
	elseif args == CombatMusic_SlashArgs.Config then
		-- Show the Config GUI
		CombatMusic.PrintMessage(CombatMusic_Messages.ErrorMessages.NotImplemented, true)
	else
		-- Print that "oops, invalid arg" message.
		CombatMusic.PrintMessage(format(CombatMusic_Messages.ErrorMessages.InvalidArg, args), true)
	end
	]]
end

function CombatMusic_OnLoad(self)

	-- AddonEvents
	self:RegisterEvent("ADDON_LOADED")
	-- Trigger events
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_TARGET")
	
	-- Slash Command listings
	SLASH_COMBATMUSIC_MAIN1 = "/combatmusic"
	SLASH_COMBATMUSIC_MAIN2 = "/combat"
	SLASH_COMBATMUSIC_MAIN3 = "/cm"

	SlashCmdList["COMBATMUSIC_MAIN"] = function(args)
		CombatMusic.SlashCommandHandler(args)
	end

end