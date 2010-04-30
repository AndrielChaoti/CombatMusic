--[[
------------------------------------------------------------------------
	PROJECT. CombatMusic
	FILE. English Localization
	VERSION: 3.5
	DATE: 06-Apr-2010 08:50 -0600
	PURPOSE: The English string localization for CombatMusic.
	CREDITS: Code written by Vandesdelca32
	
	Copyright (c) 2010 Vandesdelca32
	
	This program is free software. you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either VERSION: 3.5
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http.//www.gnu.org/licenses/>.
------------------------------------------------------------------------
]]

CombatMusic_AddonTitle = "CombatMusic"

-- This shouldn't ever need to be localized, it's color strings.
CombatMusic_Colors = {
	["Red"] = "|cffFF0000",
	["Title"] = "|cff70DFAF",
	["VarOrange"] = "|cffFFB300"
}

CombatMusic_Messages = {
	-- Message headers.. These get added onto a message to specify it's type.
	["DebugHeader"] = "<Debug> ",
	["ErrorHeader"] = CombatMusic_Colors.Red .. "[ERROR]|r ",
	
	-- Error Messages
	["ErrorMessages"] = {
		["InvalidArg"] = CombatMusic_Colors.VarOrange .. "\"%s\"|r is an invalid argument.",
		["NotImplemented"] = "The feature you are trying to use has not been implemented yet.",
	},
	
	-- Debug Messages, These are most likely going to be hardcoded into the acutal files...
	["DebugMessages"] = {},
	
	-- Other Messages
	["OtherMessages"] = {
		["AddonLoaded"] = "CombatMusic successfully loaded! " .. CombatMusic_Colors.VarOrange .. "/combatmusic|r shows command help.",
		["VarsLoaded"] = "Configuration Loaded.",
		["LoadDefaults"] = "No settings found, loading default settings...",
		["Enabled"] = CombatMusic_AddonTitle .. " has been " .. CombatMusic_Colors.VarOrange .. "enabled|r.",
		["Disabled"] = CombatMusic_AddonTitle .. " has been " .. CombatMusic_Colors.VarOrange .. "disabled|r.",
		-- This is the readme text found in ReadMe.txt file, but made nicer for the addon.
		["README"] = {
			["PG1"] = [[ |cff70DFAFCombatMusic - ReadMe.|r
No doubt, if you're seeing this text, you've successfully installed CombatMusic. This is going to help you figure out how to set it up.

|cffFF0000NOTICE.|r You will have to restart World of Warcraft when you have completed this setup. World of Warcraft only detects new files when it starts, so you won't be able to use CombatMusic until you've completely exited the game.

|cffFFB300HINT!.|r This will be a lot easier if you put your World of Warcraft into |cffFFB300windowed mode|r. Press <ESC> until the game menu opens, or click on the small computer icon in your micro menu. Click 'Video' to open the Video Settings pane. On the first category, check the box besided Windowed Mode. Click OK when you're done.

|cffFFB300Step 1.|r
The first step in this process is finding where your World of Warcraft directory is, which I'll be referring to as <WoWDIR> from hereon in.
To do this, just click your Start button, and go to Search.. Vista machines need only type the name in the box on the start menu. But, the name you're looking for is "WoW.EXE", so search for that. Once you find it... Go to your Interface folder inside your WoW's directory.]],

			["PG2"] = [[|cffFFB300Step 2.|r
Okay, now you're going to make the folders you need, and put the songs you're going to want to listen to in here.
Start by creating a "Music" folder inside of your "Interface" folder. Once you have completed that, create a "Battles" and "Bosses" folder inside that new "Music" folder.

To pick music, All your files have to be in the mp3 format, unfortunately. CombatMusic only looks for the MP3 file extention.
Now you can start picking music. Pick a song you want to use as a "victory fanfare" and name it "Victory.mp3" inside that folder.
For your "game over" theme, pick a song you want to represent that, and name it "GameOver.mp3".

CombatMusic is cool because it supports as many battle and boss themes as you can shake a stick at. Unlimited, but there's a catch.. You have to name them right, or it won't find them. For your battle themes, put them in the "Battles" folder, with the name "Battle", followed by a sequential (1, 2, 3, etc.) number, followed by ".mp3". If you are of a shortening mind, "Battle#.mp3".
For Boss themes, You do the same thing, essentially.. "Boss#.mp3" in the "Bosses" folder.

Now, I can hear you saying, "What if I don't want a game over theme?!" Don't worry.. World of Warcraft is nice like that, and if you don't supply the file, it won't throw lots of nasty errors at you.. It just won't do anything at all, so if you don't want a particular type of music, then just don't include those files.]],

			["PG3"] = [[|cffFFb300Step 3.|r
Now you have to tell the addon how many songs you put in the "Battles" and "Bosses" folder, as well as setting up anything else you want to.
|cffFFB300/cm|r - This is the main slash command, it accepts the following arguments.
  |cffFFB300on|r/|cffFFB300off|r - This is used to completely enable or disable CombatMusic.
  |cffFFB300help|r - Shows this window
  |cffFFB300config|r - Does nothing yet, but should show the configuration window.
  
|cffFF0000 This is only a temporary way of doing things until I get a configuration UI for this addon!|r
Seeing as how this developer can't write UI's, here's how to set the number of songs.
|cffFFB300/run CombatMusic_SavedDB.numSongs.Battles = #; CombatMusic_SavedDB.numSongs.Bosses = #|r -- Replace the # signs with the actual number of songs you put in each folder.

|cffFFB300/run CombatMusic_SavedDB.timeOuts.Fanfare = #; CombatMusic_SavedDB.timeOuts.GameOver = #|r -- For this one, just replace the # signs with the duration of the "fanfare" and "game over" songs you chose, respectively. Adding a second or two doesn't hurt either. This just sets a cooldown, so the addon doesn't try to overlap playing these songs, and give you a headache.]],

			["PG4"] = [[|cffFFB300Step 4.|r
Here's hoping I didn't forget anything... 

CombatMusic is now ready for your using pleasure!

If you click the button at the bottom of this page, it will close World of Warcraft for you, saving your settings, so you can actually use CombatMusic!

Okay, maybe you don't want to quit just yet, because you're in a raid or something... Don't worry, the little X in the top corner will close this window without quitting World of Warcraft...

Either way, you'll never see this window again, unless you use |cffFFB300/combatmusic help|r.]]
		},
	},
}

CombatMusic_SlashArgs = {
	["Help"]    = "help",
	["Enable"]  = "on",
	["Disable"] = "off",
	["Config"]  = "config",
}
	