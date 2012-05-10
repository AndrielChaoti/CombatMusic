--[[
-------------------------------------------------------------------------------
	Project: Van32's CombatMusic
	Author: Vandesdelca32
	Date: @file-date-iso@
	
	File: CombatEngine, r@file-revision@
	Purpose: The engine behind playing the music.
	
	
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
-------------------------------------------------------------------------------
]]

local E, L, DB, DF = unpack(select(2, ...))

local CE = {}


E["CombatEngine"] = CE