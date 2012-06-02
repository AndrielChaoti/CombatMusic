local function SendSettingsRequest(channel, target)
	CombatMusic:PrintDebug("SendSettingsRequest()")
	SendAddonMessage("CM3", "\001", channel, target)
end

local OldSV = CombatMusic.SendVersion
local askedThisSession = {}
local ReqCooldown = 120
local ReqCooldownTime
CombatMusic.SendVersion = function()
	local gType = OldSV()
	CombatMusic:PrintDebug("Metrics - SendVersion()")
	local difParty
	-- Check to see who's in the party, and stop asking if it hasn't changed
	-- or if everyone here's already been asked.
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
	-- The cooldown is a lot longer for this one
	if not ReqCooldownTime or (GetTime() >= ReqCooldownTime + ReqCooldown) then 
		if gType then SendSettingsRequest(gType) end
		ReqCooldownTime = GetTime()
	end
end

function CombatMusic.CheckMetricsReply(message, sender)
	CombatMusic:PrintDebug("CheckMetricsReply()")
	-- Check to see if the metrics data table exists and create if it doesn't
	if not CombatMusic_SavedDB._METRICS then
		CombatMusic_SavedDB._METRICS = {
			UniqueGUIDList = {},
			UniqueCount = 0,
			TotalCount = 0,
		}
	end
	
	-- Grab the GUID of the person sending the reply
	local senderGUID = UnitGUID(sender)
	
	-- Process the message
	local ver, battles, bosses = strsplit(",", message)
	ver = strmatch(ver, "^S:(.+)")
	-- We found the settings commstring, show the player
	CombatMusic:PrintMessage(format("§b%s§r - Version: §b%s§r. Song Counts: Battles=§b%s§r, Bosses=§b%s§r", sender, ver, battles, bosses))
	
	-- Make sure we have their GUID first... This will only work with nearby players and in parties.
	if senderGUID then
		if not CombatMusic_SavedDB._METRICS.UniqueGUIDList[senderGUID] then
			CombatMusic_SavedDB._METRICS.UniqueGUIDList[senderGUID] = true
			CombatMusic_SavedDB._METRICS.UniqueCount = CombatMusic_SavedDB._METRICS.UniqueCount + 1
		end
	end
	
	CombatMusic_SavedDB._METRICS.TotalCount = CombatMusic_SavedDB._METRICS.TotalCount + 1
	CombatMusic:PrintMessage(format("§b%s§r unique players, of §b%s§r total players checked.", CombatMusic_SavedDB._METRICS.UniqueCount, CombatMusic_SavedDB._METRICS.TotalCount))
	
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
