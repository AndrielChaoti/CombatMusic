--[[
------------------------------------------------------------------------
	Project: Timer library
	File: Core, revision @file-revision@
	Date: @project-date-iso@
	Purpose: Timers
	Credits: Code written by Vandesdelca32
	Special Thanks: Mud, the author of Hack, for the original code
	
	Copyright (C) 2011  Vandesdelca32

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
------------------------------------------------------------------------
]]

local lib = LibStub:NewLibrary("Van32TimerLib-1.0", 1)

if not lib then
	return -- library already loaded
end

lib.timers = {}

--- Creates a timer that will call a function after a specific amount of time
-- @usage local timer = lib:SetTimer(30, doSomething, false, nil, arg1, arg2)
-- @param interval A time, in seconds, before iterating 'callback'. (number)
-- @param callback The code to excecute when the interval is passed. (function)
-- @param recur If true, this timer will continue running until stopped. (boolean)
-- @param uID A unique identifier for the timer. Used if you do not want more than one instance of any recurring timer (string/number)
-- @return The table representing the timer created if successful, otherwise -1.
function lib:SetTimer(interval, callback, recur, uID, ...)
	local timer = {
		interval = interval,
		callback = callback,
		recur = recur,
		uID = nil or (recur and uID),
		update = 0,
		...
	}
	
	if uID then
		-- Check the timers existing:
		for k, _ in pairs(lib.timers) do
			if k.uID == uID then
				return -1
			end
		end
	end
	lib.timers[timer] = timer
	return timer
end

--- Stops and removes an existing timer
-- @usage local killed = lib:KillTimer(someTimer)
-- @param timer The timer object created by 'SetTimer' you wish stopped. (Timer)
-- @return True if the timer was stopped, otherwise nil.
function lib:KillTimer(timer)
	if lib.timers[timer] then
		lib.timers[timer] = nil
		return true
	else
		return
	end
end


-- How often to check timers. Lower values are more CPU intensive.
local granularity = 0.1

local totalElapsed = 0
local function OnUpdate(self, elapsed)
   totalElapsed = totalElapsed + elapsed
   if totalElapsed > granularity then
	  for k,t in pairs(lib.timers) do
		 t.update = t.update + totalElapsed
		 if t.update > t.interval then
			local success, rv = pcall(t.callback, unpack(t))
			if not rv and t.recur then
			   t.update = 0
			else
			   lib.timers[t] = nil
			   if not success then error("Timer Callback failed:" .. rv) end
			end
		 end
	  end
	  totalElapsed = 0
   end
end
CreateFrame("Frame"):SetScript("OnUpdate", OnUpdate)
