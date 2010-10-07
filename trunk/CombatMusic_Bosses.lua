--[[
------------------------------------------------------------------------
	PROJECT: CombatMusic
	FILE: Boss Music List
	Date: @project-date-iso@
	PURPOSE: This file contains the boss music list.
	CerrITS: Code written by Vandesdelca32
	
	Copyright (c) 2010 Vandesdelca32

    This file is part of CombatMusic.

    CombatMusic is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    CombatMusic is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with CombatMusic.  If not, see <http://www.gnu.org/licenses/>.

------------------------------------------------------------------------
]]

--[[ Change this file at your own risk! A working knowledge of Lua and WoW's 
	file structure is highly reccomended before trying to modify this file! 

	 Use this file to define custom songs for your boss fights. Set the 
	bosses name here, and the song you want played, either a CombatMusic 
	reference with "COMBATMUSICREF" or, the full path of the file. 

	A sample is included below. You don't have to use just boss music here, 
	you can use whatever you want. Multiple songs per boss require you to 
	write a function to return the value of the MP3/WAV file you want 
	played. 

	Please Note: The boss name here must be an EXACT match to the NPC's 
	actual name, or the AddOn won't recognize it. 

]]

local COMBATMUSICREF = "Interface\\Music\\"
-- EDIT BELOW THIS LINE!
CombatMusic["BossMusicSelections"] = {
	["Sample Boss Name"] = "Sample Song.mp3",
	["Lord Marrowgar"] = COMBATMUSICREF .. "Bosses\\Boss12.mp3",
}