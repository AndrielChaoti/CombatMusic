--[[
	Project: CombatMusic
	Friendly Name: CombatMusic
	Author: Donald "AndrielChaoti" Granger

	File: options.lua
	Purpose: All of the options that come with the standard kit.

	Version: @file-revision@

	ALL RIGHTS RESERVED.
	COPYRIGHT (c)2010-2017 Donald "AndrielChaoti" Granger
]]

-- GLOBALS: CombatMusicDB, CombatMusicBossList, InCombatLockdown, ReloadUI
-- GLOBALS: UnitName, InterfaceOptionsFrame_OpenToCategory

--Import Engine, Locale, Defaults, CanonicalTitle
local AddOnName = ...
local E, L, DF = unpack(select(2, ...))
local DEFAULT_WIDTH = 770
local DEFAULT_HEIGHT = 500
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
AC:RegisterOptionsTable(AddOnName, E.Options)
ACD:SetDefaultSize(AddOnName, DEFAULT_WIDTH, DEFAULT_HEIGHT)

--local f = ACD:AddToBlizOptions(AddOnName)
--f.default = function() E:RestoreDefaults() end

local strCredits=[[I want to give a special thank you to everyone who's helped out with CombatMusic's development, or donated money to the project. If I've missed your name, send me a PM on Curse, and I will add you!

§TCombatMusic's§r Authors:
------------------

    §TAndrielChaoti§r - Author / Project Manager
    yuningning520 - zhCN translation

§6Special Thanks:§r
------------------

    Zeshio@Proudmoore
]]


local tinsert, unpack, ipairs, pairs = table.insert, unpack, ipairs, pairs
local strfind = string.find
local printFuncName = E.printFuncName


--- toggles the optiosn frame
function E:ToggleOptions()
	printFuncName("ToggleOptions")
	if InCombatLockdown() then
		self:PrintError(L["Can't do that in combat."])
		return
	end
	ACD:Open(AddOnName)
end


local blName = ""
local blSong = ""
-- Adds the user's text to the bosslist.
function E:AddNewBossListEntry()
	printFuncName("AddNewBossListEntry")

	if not strfind(blSong, "\.mp3$") then

	end

	-- Get the current target's name if they picked it.1
	if blName == "%TARGET" then
		blName = UnitName("target")
	end

	-- Check to make sure there's a target and song
	if blName == "" or blName == nil then
		self:PrintError(L["Err_NoBossListNameTarget"])
		return
	end
	if blSong == "" or blSong == nil then
		self:PrintError(L["Err_NoBossListSong"])
		return
	elseif not strfind(blSong, "\.mp3$") then
		self:PrintError(L["Err_NeedsToBeMP3"])
		return
	end

	-- Add that song.
	CombatMusicBossList[blName] = blSong
	-- Rebuild the list of buttons! yay!
	self.Options.args.General.args.BossList.args.ListGroup.args = self:GetBosslistButtons()
	ACR:NotifyChange(AddOnName)
	blName = ""
	blSong = ""
end

--- Gets and creates the list of buttons that the user can click to remove bosslist entries.
function E:GetBosslistButtons()
	local t = {}
	local count = 0
	for k, v in pairs(CombatMusicBossList) do
		count = count + 1
		t["ListItem" .. count] = {
			type = "execute",
			name = k,
			desc = v,
			confirm = true,
			confirmText = L["RemoveBossList"],
			func = function()
				CombatMusicBossList[k] = nil
				-- redraw the list!
				self.Options.args.General.args.BossList.args.ListGroup.args = self:GetBosslistButtons()
				ACR:NotifyChange(AddOnName)
			end,
		}
	end
	return t
end

function E:RestoreDefaults()
	CombatMusicDB = DF
	CombatMusicBossList = {}
	ACR:NotifyChange(AddOnName)
end


----------------
--	Options Table
----------------

E.Options.args = {
	VerHeader = {
		name = E:GetVersion(),
		type = "header",
		order = 0,
	},
	Enabled = {
		name = L["Enabled"],
		desc = L["Desc_Enabled"],
		type = "toggle",
		confirm = true,
		confirmText = L["Confirm_Reload"],
		get = function(info) return E:GetSetting("Enabled") end,
		set = function(info, val) CombatMusicDB.Enabled = val; if val then E:Enable(); else E:Disable(); end; ReloadUI(); end,
	},
	LoginMessage = {
		name = L["LoginMessage"],
		type = "toggle",
		get = function(info) return E:GetSetting("LoginMessage") end,
		set = function(info, val) CombatMusicDB.LoginMessage = val end,
		order = 110,
	},
	RestoreDefaults = {
		name = L["RestoreDefaults"],
		desc = L["Desc_RestoreDefaults"],
		type = "execute",
		confirm = true,
		confirmText = L["Confirm_RestoreDefaults"],
		func = function() E:RestoreDefaults() end,
		order = 120,
	},

	-- About Screen --
	------------------
	About = {
		name = L["About"],
		type = "group",
		order = 600,
		args = {
			DescText = {
				name = L["Desc_About"],
				type = "description",
				width = "full",
				order = 601
			},
			Author = {
				name = L["Author"],
				type = "input",
				width = "full",
				order = 602,
				get = function(...)
					return GetAddOnMetadata(AddOnName, "author")
				end
			},
			website = {
				name = L["Website"],
				type = "input",
				width = "full",
				order = 604,
				get = function(...)
					return "https://wow.curseforge.com/projects/van32s-combatmusic"
				end
			},
			github = {
				name = L["GitHub"],
				type = "input",
				width = "full",
				order = 605,
				get = function(...)
					return "https://github.com/AndrielChaoti/CombatMusic"
				end
			},
			VerStr = {
				name = L["Version"],
				desc = L["Desc_Version"],
				type = "input",
				width = "full",
				order = 603,
				get = function(...)
					return E:GetVersion()
				end
			}
		}
	},

	-- Contributors & Credits --
	----------------------------
	Credits = {
		name = "Credits",
		type = "group",
		order = 500,
		args = {
			ContList = {
				name = E:ParseColoredString(strCredits),
				--desc = ""
				type = "description",
				fontSize = "medium",
			},
		},
	},

	General = {
		name = "General",
		type = "group",
		order = 0,
		get = function(info) return E:GetSetting("General", info[#info]) end,
		set = function(info, val) CombatMusicDB.General[info[#info]] = val end,
		args = {
			UseMaster = {
				name = L["UseMaster"],
				desc = L["Desc_UseMaster"],
				type = "toggle",
			},
			Volume = {
				name = L["Volume"],
				--desc = L["Desc_Volume"],
				type = "range",
				width = "double",
				min = 0.01,
				max = 1,
				step = 0.001,
				bigStep = 0.01,
				isPercent = true,
				order = 200,
			},
			-- ["Fix5.3Bug"] = {
			-- 	name = L["Fix5.3Bug"],
			-- 	desc = L["Fix5.3Bug_Desc"],
			-- 	type = "toggle",
			-- 	width = "full",
			-- 	order = 201,
			-- },
			SongList = {
				name = L["NumSongs"],
				--desc = L["Desc_NumSongs"],
				type = "group",
				inline = true,
				order = 400,
				args = {} -- This will be filled in by our :RegisterSongType
			},
			BossList = {
				name = L["BossList"],
				type = "group",
				order = -1,
				args = {
					Help1 = {
						name = L["BossListHelp1"],
						--desc = L["Desc_Help1"],
						type = "description",
						order = 90,
					},
					BossListName = {
						name = L["BossListName"],
						desc = L["Desc_BossListName"],
						order = 100,
						type = "input",
						set = function(info,val) blName = val end,
						get = function(info) return blName end,
					},
					BossListSong = {
						name = L["BossListSong"],
						desc = L["Desc_BossListSong"],
						type = "input",
						width = "double",
						order = 110,
						set = function(info, val) blSong = val end,
						get = function(info) return blSong end,
					},
					AddBossList = {
						name = ADD,
						desc = L["Desc_AddBossList"],
						type = "execute",
						width = "full",
						order = 120,
						func = function() E:AddNewBossListEntry() end,
					},
					ListGroup = {
						name = L["ListGroup"],
						--desc = L["Desc_ListGroup"],
						type = "group",
						order = -1,
						inline = true,
						args = {} -- Get the bosslist buttons dynamically as well.
					}
				}
			}
		}
	}
}
