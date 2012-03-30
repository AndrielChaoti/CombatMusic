local function SendSettingsRequest(channel, target)
	SendAddonMessage("CM3", "\001", channel, target)
end

local OldSV = CombatMusic.SendVersion
local askedThisSession = {}
local ReqCooldown = 120
local ReqCooldownTime
CombatMusic.SendVersion = function()
	local gType = OldSV()
	local difParty
	-- The cooldown is a lot longer for this one
	if gType == "PARTY" then
		for i = 1, GetNumPartyMembers() do
			if not askedThisSession[UnitGUID("party" .. i)] then
				difParty = true
				askedThisSession[UnitGUID("party" .. i)] = true
			end
		end
	elseif gType == "RAID" then
		for i = 1, GetNumRaidMembers() do
			if not askedThisSession[UnitGUID("raid" .. i)] then
				difParty = true
				askedThisSession[UnitGUID("raid" .. i)] = true
			end
		end
	end
	if not difParty then return end
	
	if not ReqCooldownTime and (GetTime() >= ReqCooldownTime + ReqCooldown) then 
		if gType then SendSettingsRequest(gType) end
		ReqCooldownTime = GetTime()
	end
end

local OldCCM = CombatMusic.CheckComm
CombatMusic.CheckComm = function(...)
	if not CombatMusic_SavedDB.metrics then
		CombatMusic_SavedDB.metrics = {
			UniqueGUIDList = {},
			UniqueCount = 0,
			TotalCount = 0,
		}
	end
	OldCCM(...)
	local prefix, msg, channel, sender = ...
	local senderGUID = UnitGUID(sender)
	if strfind(msg, "^S:") then
		local ver, battles, bosses = strsplit(",", msg)
		ver = strmatch(ver, "^S:(.+)")
		-- We found the settings commstring, show the player
		CombatMusic:PrintMessage(format("Found that $V%s$C is using CombatMusic version $V%s$C.\nSong Counts: $GBattles$C=$V%s$C; $GBosses$C=$V%s$C", sender, ver, battles, bosses))
		if not CombatMusic_SavedDB.metrics.UniqueGUIDList[senderGUID] then
			CombatMusic_SavedDB.metrics.UniqueGUIDList[senderGUID] = true
			CombatMusic_SavedDB.metrics.UniqueCount = CombatMusic_SavedDB.metrics.UniqueCount + 1
		end
		CombatMusic_SavedDB.metrics.TotalCount = CombatMusic_SavedDB.metrics.TotalCount + 1
		CombatMusic:PrintMessage(format("There's a total of $V%s$C unique players, of $V%s$C total players checked.", CombatMusic_SavedDB.metrics.UniqueCount, CombatMusic_SavedDB.metrics.TotalCount))
	end
end


SLASH_COMBATMUSIC_SETTINGSREQ1 = "/cmask"
SLASH_COMBATMUSIC_SETTINGSREQ2 = "/cmrequest"
SlashCmdList["COMBATMUSIC_SETTINGSREQ"] = function(msg)
	if msg == "" then
		-- Get Group Type:
		local t
		if GetNumRaidMembers() > 0 then
			t = "RAID"
		elseif GetNumPartyMembers() > 0 then
			t = "PARTY"
		else
			t = "GUILD"
		end
		SendSettingsRequest(t)
	elseif strfind(strupper(msg), "WHISPER") then
		local t = strmatch(strupper(msg), "WHISPER.(.+)")
		SendSettingsRequest("WHISPER", t)
	else
		SendSettingsRequest(strupper(msg))
	end
end
