--[[
	Project: CombatMusic
	Friendly Name: CombatMusic
	Author: Vandesdelca32

	File: enUS.lua
	Purpose: enUS locale

	Version: @file-revision@


	This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	See http://creativecommons.org/licenses/by-sa/3.0/deed.en_CA for more info.
]]

local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true, true)

if L then

	--@localization(locale="enUS", format="lua_additive_table", same-key-is-true=true)@
	--@do-not-package@--
	L["AddBossList"] = "Add"
	L["AddonLoaded"] = "%s §6%s§r loaded successfully. Type §6/combatmusic§r to access options"
	L["BossList"] = "BossList"
	L["BossListHelp1"] = "This section lets you add specific NPCs or players to a list that will play a specific song when CombatMusic finds them. Simply enter your target's name in the first box, and the song you want it to play in the second, and click the \"Add\" button. To remove someone from the list, simply click their name in the box below. To change an existing entry, just re-add it like you would a new entry."
	L["BossListName"] = "NPC/Player name"
	L["BossListSong"] = "Song path"
	L["BossOnly"] = "Boss fight only"
	L["Can't do that in combat."] = "Can't do that in combat."
	L["CheckBoss"] = "Check 'bossx' units"
	L["CombatEngine"] = "Combat"
	L["ConfigLoadError"] = "Your configuration couldn't be loaded. Is this the first time you're running the addon? Using defaults."
	L["ConfigOutOfDate"] = "Your configuration is outdated, loading the default config."
	L["Confirm_Reload"] = "You need to reload your UI for this change to take effect."
	L["Confirm_RestoreDefaults"] = "Are you sure you want to reset all of your settings and Boss Lists?"
	L["Count"] = "Count"
	L["Desc_AddBossList"] = "Add this to the boss list."
	L["Desc_BossListName"] = "The name of the NPC to add to the bosslist, Use \"%TARGET\" if you want to add your current target."
	L["Desc_BossListSong"] = "The path to the song you want to play. A valid example might be Interface\\Music\\Bosses\\song1.mp3 or Sound\\Music\\ZoneMusic\\­DMF_L70ETC01.mp3"
	L["Desc_CheckBoss"] = "Check 'bossx' unitIDs, as well as target and focustarget."
	L["Desc_Count"] = "Number of songs."
	L["Desc_Enabled"] = "Enable/Disable the addon or module."
	L["Desc_FadeTimer"] = "The time in seconds that the music will spend fading out. 0 to disable."
	L["Desc_FanfareEnable"] = "Play fanfares on the following event:"
	L["Desc_GameOverEnable"] = "Play GameOver when you die."
	L["Desc_PreferFocus"] = "Check your focus' target first in unit checking."
	L["Desc_RestoreDefaults"] = "Restore all settings to their defaults."
	L["Desc_UseDing"] = "Use 'DING.mp3' instead of 'Victory.mp3' when you level up."
	L["Desc_UseMaster"] = "Use the master audio channel to play fanfares."
	L["Enabled"] = "Enabled"
	L["Err_NeedsToBeMP3"] = "Your song path needs to end in .mp3"
	L["Err_NoBossListNameTarget"] = "You need to specify a unit name to check for, or you didn't have a target."
	L["Err_NoBossListSong"] = "You need to put in a song to play."
	L["FadeTimer"] = "Song Fadeout"
	L["FanfareEnable"] = "Play Fanfare on..."
	L["GameOverEnable"] = "Play Game Over on..."
	L["InCombat"] = "In Combat only"
	L["ListGroup"] = "Current BossList targets"
	L["LoginMessage"] = "Login Message"
	L["MiscFeatures"] = "Miscellaneous features"
	L["NumSongs"] = "Song Counts"
	L["PreferFocus"] = "Check 'focustarget' first"
	L["RemoveBossList"] = "Remove this unit from the BossList?"
	L["RestoreDefaults"] = "Restore Defaults"
	L["SongTypeBattles"] = "Battles"
	L["SongTypeBosses"] = "Bosses"
	L["UseDing"] = "Use 'DING' instead of 'Victory' for levelling up"
	L["UseMaster"] = "Use Master Channel"
	L["Volume"] = "Music Volume"
	--@end-do-not-package@
end
