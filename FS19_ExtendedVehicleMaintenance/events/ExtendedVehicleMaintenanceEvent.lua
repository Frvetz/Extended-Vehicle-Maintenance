-- Contact: ExtendedVehicleMaintenance@gmail.com
-- Date 23.10.2020

--[[
Changelog Version 1.0.0.1:
- Description adapted.
- New icon.
- Day limit adapts to the Seasons-Mod.
- Engine may fail to start when starting the motor after reaching the limit.
- Engine can stall if engine load is too high.
- Bugs fixed when servicing several times.
- No longer subtracts engine hours and age on first load.
- Fixed a bug with "bulk buy mod" (pallet could not be bought).
- Fixed multiplayer problems.


Changelog Version 1.0.0.2:
- FPS problems fixed.
- Dedicated server problems fixed.
- Lamp light removed.
- Description slightly adjusted.
- Fixed bug where the button did not appear.
- Fixed bug where the old state of the vehicle was not restored.


Changelog Version 1.0.0.3:
- Description adapted.
- Fixed a bug where the button has still not appeared.
- The remaining time needed for maintenance is now saved and continued when re-entering the savegame.
- Maintenance can now be done at any time.
- Maintenance is now only necessary 1 time per season with the Seasons-Mod.
- At the pallet it is now possible to configure how long it takes until the maintenance is completed. (Less time = higher costs for maintenance).
- Maintenance now costs a certain amount.
- Damage system from the Fs19 now adapts to maintenance.


Changelog Version 1.0.0.4:
- Description slightly adapted
- Fixed error with machines that do not have a motor (for example: conveyor belt).
- Added translation for the configuration.


Changelog Version 1.0.0.5:
- Vehicle no longer needs to be selected to see the maintenance information and to service the vehicle.
- The engine cuts-off again correctly if the engine load is too high and another implement is selected than the current vehicle.
- Multiplayer sync problems fixed.
- Fixed multiplayer money problems.
- Dedi problems fixed.
- All equipment (except drivable) can now be repaired normally.
- Drivable vehicles can now no longer be repaired normally at all.
- Added blink text when servicing.
- Damage now works correctly in combination with the Seasons mod.
- Engine hours now count as a "damage maintenance" and days as an "interval maintenance" -- (damage only adjusts to engine hours).
- Engine can now no longer be started at all during maintenance.


Changelog Version 1.0.0.6:
- Confirmation window for maintenance.
- Damage is no longer deducted directly (with Seasons-Mod) for vehicles that already have engine hours (borrowed vehicles from a contract), but starts again as intended without damage.
- No more error message that appeared when something was sold that was not a vehicle.
- Individual adjustment of the maintenance price for each vehicle.
- Shorter maintenance now costs less and longer maintenance costs more.
- Depending on the length of the maintenance, a certain number of engine hours/days is added to the others (vehicle is not going to be completely repaired).
- Maintenance system generally improved to make it more realistic.
- Description adjusted.
- Ingame texts adapted.
- Repair feature in the shop has been completely deactivated due to bugs (also for non-driveable equipment).
- Automatic engine start can be activated again (the engine stall function is then deactivated though).


Changelog Version 1.0.0.7:
- Fixed bug where nothing happened after maintenance (still "maintenance needed" or the same number of remaining engine hours/days).


Changelog Version 1.0.0.8:
- Description slightly adapted.
- Text appears when approaching a pallet (on foot) that better indicates the configured waiting time/added days/added engine hours until the next maintenance and makes it easier to identify the correct pallet.
- Polish translation added.
--]]

-- Thanks to Ian for the help with the xml!
-- Thanks to Glowin for the help with the last bugs and for the lua with the server stuff!
-- Thanks to Ifko[nator] for letting me use his text-display-function!!

-- Thanks to the main testers: 
--  SneakyBeaky
--  Simba!
--  Glowin

ExtendedVehicleMaintenenanceEvent = {}
local ExtendedVehicleMaintenenanceEvent_mt = Class(ExtendedVehicleMaintenenanceEvent, Event)
InitEventClass(ExtendedVehicleMaintenenanceEvent, "ExtendedVehicleMaintenenanceEvent")

function ExtendedVehicleMaintenenanceEvent:emptyNew()
	local event = Event:new(ExtendedVehicleMaintenenanceEvent_mt)

	return event
end

function ExtendedVehicleMaintenenanceEvent:new(vehicle, wartungsStatus, CurrentMinuteBackup, SchadenVergleich, WartezeitStunden, WartezeitMinuten, HoursToAdd, DaysToAdd, OriginalTimeBackup, CostsBackup, DaysBackup, Days, Variable, DifferenzNextMaxCheck, DifferenzDaysNextMaxCheck, DontAllowXmlNumberReset)
    local event = ExtendedVehicleMaintenenanceEvent:emptyNew()
	    event.vehicle = vehicle
	    event.wartungsStatus = wartungsStatus
        event.CurrentMinuteBackup = CurrentMinuteBackup
        event.SchadenVergleich = SchadenVergleich
        event.WartezeitStunden = WartezeitStunden
        event.WartezeitMinuten = WartezeitMinuten
        event.HoursToAdd = HoursToAdd
        event.DaysToAdd = DaysToAdd
        event.OriginalTimeBackup = OriginalTimeBackup
        event.CostsBackup = CostsBackup
        event.DaysBackup = DaysBackup
        event.Days = Days
        event.Variable = Variable
        event.DifferenzNextMaxCheck = DifferenzNextMaxCheck
        event.DifferenzDaysNextMaxCheck = DifferenzDaysNextMaxCheck
        event.DontAllowXmlNumberReset = DontAllowXmlNumberReset
       -- ExtendedVehicleMaintenance.OriginalTime = OriginalTimeEvent
	   
	return event
end

function ExtendedVehicleMaintenenanceEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.wartungsStatus = streamReadBool(streamId)
    self.CurrentMinuteBackup = streamReadInt32(streamId)
    self.SchadenVergleich = streamReadInt32(streamId)
    self.WartezeitStunden = streamReadInt32(streamId)
    self.WartezeitMinuten = streamReadInt32(streamId)
    self.HoursToAdd = streamReadInt32(streamId)
    self.DaysToAdd = streamReadInt32(streamId)
    self.OriginalTimeBackup = streamReadInt32(streamId)
    self.CostsBackup = streamReadInt32(streamId)
    self.DaysBackup = streamReadInt32(streamId)
    self.Days = streamReadInt32(streamId)
    self.Variable = streamReadInt32(streamId)
    self.DifferenzNextMaxCheck = streamReadInt32(streamId)
    self.DifferenzDaysNextMaxCheck = streamReadInt32(streamId)
    self.DontAllowXmlNumberReset = streamReadBool(streamId)
   -- ExtendedVehicleMaintenance.OriginalTime = streamReadInt32(streamId)
	
	self:run(connection)
end

function ExtendedVehicleMaintenenanceEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.wartungsStatus)
	streamWriteInt32(streamId, self.CurrentMinuteBackup)
	streamWriteInt32(streamId, self.SchadenVergleich)
	streamWriteInt32(streamId, self.WartezeitStunden)
	streamWriteInt32(streamId, self.WartezeitMinuten)
	streamWriteInt32(streamId, self.HoursToAdd)
	streamWriteInt32(streamId, self.DaysToAdd)
	streamWriteInt32(streamId, self.OriginalTimeBackup)
	streamWriteInt32(streamId, self.CostsBackup)
	streamWriteInt32(streamId, self.DaysBackup)
	streamWriteInt32(streamId, self.Days)
	streamWriteInt32(streamId, self.Variable)
	streamWriteInt32(streamId, self.DifferenzNextMaxCheck)
	streamWriteInt32(streamId, self.DifferenzDaysNextMaxCheck)
	streamWriteBool(streamId, self.DontAllowXmlNumberReset)
	--streamWriteInt32(streamId, ExtendedVehicleMaintenance.OriginalTime)
end

function ExtendedVehicleMaintenenanceEvent:run(connection)
	ExtendedVehicleMaintenance.setWartung(self.vehicle, self.wartungsStatus, self.CurrentMinuteBackup, self.SchadenVergleich, self.WartezeitStunden, self.WartezeitMinuten, self.HoursToAdd, self.DaysToAdd, self.OriginalTimeBackup, self.CostsBackup, self.DaysBackup, self.Days, self.Variable, self.DifferenzNextMaxCheck, self.DifferenzDaysNextMaxCheck, self.DontAllowXmlNumberReset)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.vehicle)
	end
end

function ExtendedVehicleMaintenenanceEvent.sendEvent(vehicle, wartungsStatus, CurrentMinuteBackup, SchadenVergleich, WartezeitStunden, WartezeitMinuten, HoursToAdd, DaysToAdd, OriginalTimeBackup, CostsBackup, DaysBackup, Days, Variable, DifferenzNextMaxCheck, DifferenzDaysNextMaxCheck, DontAllowXmlNumberReset)
	if g_server ~= nil then
		g_server:broadcastEvent(ExtendedVehicleMaintenenanceEvent:new(vehicle, wartungsStatus, CurrentMinuteBackup, SchadenVergleich, WartezeitStunden, WartezeitMinuten, HoursToAdd, DaysToAdd, OriginalTimeBackup, CostsBackup, DaysBackup, Days, Variable, DifferenzNextMaxCheck, DifferenzDaysNextMaxCheck, DontAllowXmlNumberReset), nil, nil, vehicle)
	else
	    g_client:getServerConnection():sendEvent(ExtendedVehicleMaintenenanceEvent:new(vehicle, wartungsStatus, CurrentMinuteBackup, SchadenVergleich, WartezeitStunden, WartezeitMinuten, HoursToAdd, DaysToAdd, OriginalTimeBackup, CostsBackup, DaysBackup, Days, Variable, DifferenzNextMaxCheck, DifferenzDaysNextMaxCheck, DontAllowXmlNumberReset))
	end
end
