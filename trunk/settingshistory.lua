--CombatMusic_SavedDB: Version 1
	CombatMusic_SavedDB = {
		["SVVersion"] = "1",
		["Enabled"] = true, 
		["PlayWhen"] = {
			["LevelUp"] = true,
			["CombatFanfare"] = true,
			["GameOver"] = true,
		},
		["numSongs"] = {
			["Battles"] = -1,
			["Bosses"] = -1,
		},
		["MusicVolume"] = 0.85,
		["timeOuts"] = {
			["Fanfare"] = 30,
			["GameOver"] = 30,
		},
		["FadeTime"] = 5,
	}
-- CombatMusic_SavedDB: Version 2
	CombatMusic_SavedDB = {
		["SVVersion"] = currentSVVersion,
		["Enabled"] = true,
		["Music"] = {
			["Enabled"] = true,
			["numSongs"] = {
				["Battles"] = -1,
				["Bosses"] = -1,
			},
			["Volume"] = 0.85,
			["FadeOut"] = 5,
		},
		["GameOver"] = {
			["Enabled"] = true,
			["Cooldown"] = 30,
		},
		["Victory"] = {
			["Enabled"] = true,
			["Cooldown"] = 30,
		},
		["LevelUp"] = {
			["Enabled"] = true,
			["NewFanfare"] = false,
		},
		["AllowComm"] = true,
	}