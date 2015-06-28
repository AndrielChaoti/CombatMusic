--[[
	Project: CombatMusic
	Friendly Name: CombatMusic
	Author: Vandesdelca32

	File: zhCN.lua
	Purpose: Simplified Chinese locale

	Version: @file-revision@


	This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	See http://creativecommons.org/licenses/by-sa/3.0/deed.en_CA for more info.
]]

local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "zhCN")

if L then
	--@localization(locale="zhCN", format="lua_additive_table", same-key-is-true=true)@
	--@do-not-package@--
	-- I put localization here if I really care...
	L["AddonLoaded"] = "%s §6%s§r 成功加载。输入 §6/combatmusic§r 获取选项" -- Needs review
	L["BossList"] = "Boss列表" -- Needs review
	-- L["BossListHelp1"] = ""
	L["BossListName"] = "NPC/玩家名" -- Needs review
	L["BossListSong"] = "歌曲路径" -- Needs review
	L["BossNever"] = "仅常规战斗" -- Needs review
	L["BossOnly"] = "仅Boss战" -- Needs review
	L["Can't do that in combat."] = "不能在战斗中这样做。" -- Needs review
	-- L["Chat_BirthdayMessage"] = ""
	L["Chat_Can'tDoThat"] = "现在不能使用这个！" -- Needs review
	L["Chat_ChallengeModeCompleted"] = "挑战模式完成！音乐继续播放 §6%0.3f 秒§r！" -- Needs review
	L["Chat_ChallengeModeOff"] = "挑战模式已被禁用" -- Needs review
	-- L["Chat_ChallengeModeOn"] = ""
	L["Chat_ChallengeModeReset"] = "挑战模式已经重置，可以再试！" -- Needs review
	L["Chat_ChallengeModeStarted"] = "挑战模式开始！祝好运！" -- Needs review
	L["Chat_LevelReset"] = "地下城等级已重置。" -- Needs review
	L["Chat_LevelSet"] = "地下城等级设置为 §6%d§r 。" -- Needs review
	L["Chat_NeedsNumber"] = "该命令要求数字1到%d之间！" -- Needs review
	L["CheckBoss"] = "检查 'bossx' 单位" -- Needs review
	L["CombatEngine"] = "战斗" -- Needs review
	L["ConfigLoadError"] = "您的配置无法加载。这是您第一次运行这个插件？使用默认设置。" -- Needs review
	L["ConfigOutOfDate"] = "您的配置已经过时，加载默认配置。" -- Needs review
	L["Confirm_Reload"] = "您需要重载界面以使设置生效。" -- Needs review
	L["Confirm_RestoreDefaults"] = "您确定重置所有选项和Boss列表？" -- Needs review
	L["Count"] = "数量" -- Needs review
	L["Desc_AddBossList"] = "添加到Boss列表。" -- Needs review
	L["Desc_BossListName"] = "添加NPC的名字到Boss列表，如果您想添加当前目标请使用\"%TARGET\"。" -- Needs review
	L["Desc_BossListSong"] = "要播放的歌曲路径。例如 Interface\\Music\\Bosses\\song1.mp3 或 Sound\\Music\\ZoneMusic\\­DMF_L70ETC01.mp3" -- Needs review
	L["Desc_CheckBoss"] = "检查 'bossx' 单位ID，以及目标和焦点目标。" -- Needs review
	L["Desc_Count"] = "歌曲数量。" -- Needs review
	L["Desc_Enabled"] = "启用/禁用插件或模块。" -- Needs review
	L["Desc_FadeLog"] = "切换对数音乐衰减。" -- Needs review
	L["Desc_FadeMode"] = "当您的音乐应该淡出..." -- Needs review
	L["Desc_FadeTimer"] = "音乐淡出所需时间。" -- Needs review
	L["Desc_FanfareEnable"] = "胜利时应该听到..." -- Needs review
	L["Desc_GameOverEnable"] = "GameOver时应该听到..." -- Needs review
	L["Desc_PreferFocus"] = "单位检查时首先检查您的焦点目标。" -- Needs review
	L["Desc_RestoreDefaults"] = "重置所有设置为默认值。" -- Needs review
	L["Desc_UseDing"] = "当你升级时，使用 'DING.mp3' 而不是 'Victory.mp3' 。" -- Needs review
	L["Desc_UseMaster"] = "使用主声道播放歌曲。" -- Needs review
	L["Enabled"] = "启用" -- Needs review
	L["Err_NeedsToBeMP3"] = "歌曲路径使用 .mp3 结尾。" -- Needs review
	-- L["Err_NoBossListNameTarget"] = ""
	L["Err_NoBossListSong"] = "您需要放置一个歌曲来播放。" -- Needs review
	L["FadeLog"] = "对数淡出" -- Needs review
	L["FadeMode"] = "淡出音乐..." -- Needs review
	L["FadeTimer"] = "歌曲淡出" -- Needs review
	L["FanfareEnable"] = "播放胜利..." -- Needs review
	L["GameOverEnable"] = "播放GameOver..." -- Needs review
	L["InCombat"] = "只在战斗中" -- Needs review
	L["ListGroup"] = "当前Boss列表目标" -- Needs review
	L["LoginMessage"] = "登录信息" -- Needs review
	L["MiscFeatures"] = "其他功能" -- Needs review
	-- L["MusicDisabled"] = ""
	L["NumSongs"] = "歌曲数量" -- Needs review
	L["PreferFocus"] = "首先检查 '焦点目标'" -- Needs review
	L["RemoveBossList"] = "从Boss列表中移除这个单位？" -- Needs review
	L["RestoreDefaults"] = "恢复默认值" -- Needs review
	L["SongTypeBattles"] = "战斗" -- Needs review
	L["SongTypeBosses"] = "Boss" -- Needs review
	L["UseDing"] = "升级时使用 '叮' 而不是 '提升'" -- Needs review
	L["UseMaster"] = "使用主声道" -- Needs review
	L["Volume"] = "音乐音量" -- Needs review

	--@end-do-not-package@
end
