if not CombatMusic_SavedDB.metrics then
	CombatMusic_SavedDB.metcrics = {
		UniqueGUIDList = {}
		UniqueCount = 0

local OldSV = CombatMusic.SendVersion
CombatMusic.SendVersion = function()
	OldSV()
	-- Is this a raid group?
	local gType
	
	if GetNumRaidMembers() > 0 then
		gType = "RAID"
	elseif GetNumPartyMembers() > 0 then
		gType = "PARTY"
	else
		return
	end
	
	SendAddonMessage("CM3", "\001", gType)
end

local function SendSettingsRequest(channel, target)
	SendAddonMessage("CM3", "\001", channel, target)
end

local OldCCM = CombatMusic.CheckComm
CombatMusic.CheckComm = function(...)
	OldCCM(...)
	local prefix, msg, channel, sender = ...
	local senderGUID = UnitGUID(sender)
	if strfind("^S:", msg) then
		local ver, battles, bosses = strsplit(",", msg)
		-- We found the settings commstring, show the player
		CombatMusic:PrintMessage(format("Found that $V%s$C is using CombatMusic version $V%s$C.\nSong Counts:\n&GBattles$C=$V%s$C;$GBosses$V=$V%s$C", sender, ver, battles, bosses))
		if not CombatMusic_SavedDB.metrics.UniqueGUIDList[senderGUID] then
			CombatMusic_SavedDB.metrics.UniqueGUIDList[senderGUID] = true
			CombatMusic_SavedDB.metrics.UniqueCount = CombatMusic_SavedDB.metrics.UniqueCount + 1
		end
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
