-- Contact: ExtendedVehicleMaintenance@gmail.com
-- Date 23.10.2020

--[[
Changelog Version 1.0.0.1:
- Description adapted
- New icon
- Day limit adapts to the Seasons-Mod
- Engine may fail to start when starting the motor after reaching the limit
- Engine can stall if engine load is too high
- Bugs fixed when servicing several times
- No longer subtracts engine hours and age on first load
- Fixed a bug with "bulk buy mod" (pallet could not be bought)
- Fixed multiplayer problems


Changelog Version 1.0.0.2:
- FPS problems fixed
- Dedicated server problems fixed
- Lamp light removed
- Description slightly adjusted
- Fixed bug where the button did not appear
- Fixed bug where the old state of the vehicle was not restored


Changelog Version 1.0.0.3:
- Description adapted
- Fixed a bug where the button has still not appeared.
- The remaining time needed for maintenance is now saved and continued when re-entering the savegame
- Maintenance can now be done at any time
- Maintenance is now only necessary 1 time per season with the Seasons-Mod
- At the pallet it is now possible to configure how long it takes until the maintenance is completed. (Less time = higher costs for maintenance)
- Maintenance now costs a certain amount
- Damage system from the Fs19 now adapts to maintenance


Changelog Version 1.0.0.4:
- Description slightly adapted
- Fixed error with machines that do not have a motor (for example: conveyor belt)
- Added translation for the configuration


Changelog Version 1.0.0.5:
- Vehicle no longer needs to be selected to see the maintenance information and to service the vehicle.
- The engine cuts-off again correctly if the engine load is too high and another implement is selected than the current vehicle
- Multiplayer sync problems fixed
- Fixed multiplayer money problems
- Dedi problems fixed
- All equipment (except drivable) can now be repaired normally.
- Drivable vehicles can now no longer be repaired normally at all.
- Added blink text when servicing
- Damage now works correctly in combination with the Seasons mod
- Engine hours now count as a "damage maintenance" and days as an "interval maintenance" -- (damage only adjusts to engine hours)
- Engine can now no longer be started at all during maintenance 


Ideas that may be included in the next update (how or if they are included is not sure):
- Adjustment of the damage at "Maintenance needed".
- Confirmation window if you really want to service the vehicle
- Adjustment of the pallets to better distinguish them from each other
- Individual adjustment of the maintenance price for each vehicle
- Price is also adjusted according to the damage/time left on the vehicle.
- Pallet is needed permanently for maintenance
- Adjusted damage can be deactivated
- Other small gimmicks
--]]

-- Thanks to Ian for the help with the xml!
-- Thanks to Glowin for the help with the last bugs and for the lua with the server stuff!

-- Thanks to the main tester: 
--  SneakyBeaky
--  Simba
--  Glowin

ExtendedVehicleMaintenenanceEventFinish = {}
local ExtendedVehicleMaintenenanceEvent_mt = Class(ExtendedVehicleMaintenenanceEventFinish, Event)
InitEventClass(ExtendedVehicleMaintenenanceEventFinish, "ExtendedVehicleMaintenenanceEventFinish")

function ExtendedVehicleMaintenenanceEventFinish:emptyNew()
	local event = Event:new(ExtendedVehicleMaintenenanceEvent_mt)

	return event
end

function ExtendedVehicleMaintenenanceEventFinish:new(vehicle, BackupAgeXML, BackupOperatingTimeXML, MaintenanceTimes, Differenz, DifferenzDays)
    local event = ExtendedVehicleMaintenenanceEventFinish:emptyNew()
	event.vehicle = vehicle
	event.BackupAgeXML = BackupAgeXML
	event.BackupOperatingTimeXML = BackupOperatingTimeXML
	event.MaintenanceTimes = MaintenanceTimes
	event.Differenz = Differenz
	event.DifferenzDays = DifferenzDays
	   --self.wartungsStatus = wartungsStatus
       -- ExtendedVehicleMaintenance.OriginalTime = OriginalTimeEvent
	   
	return event
end

function ExtendedVehicleMaintenenanceEventFinish:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	    --self.wartungsStatus = streamReadBool(streamId)
    self.BackupAgeXML = streamReadInt32(streamId)
    self.BackupOperatingTimeXML = streamReadInt32(streamId)
    self.MaintenanceTimes = streamReadInt32(streamId)
    self.Differenz = streamReadInt32(streamId)
    self.DifferenzDays = streamReadInt32(streamId)

   -- ExtendedVehicleMaintenance.OriginalTime = streamReadInt32(streamId)
	
	self:run(connection)
end

function ExtendedVehicleMaintenenanceEventFinish:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	--streamWriteBool(streamId, self.wartungsStatus)
	--streamWriteInt32(streamId, self.CurrentMinuteBackup)
	streamWriteInt32(streamId, self.BackupAgeXML)
	streamWriteInt32(streamId, self.BackupOperatingTimeXML)
	streamWriteInt32(streamId, self.MaintenanceTimes)
	streamWriteInt32(streamId, self.Differenz)
	streamWriteInt32(streamId, self.DifferenzDays)
end

function ExtendedVehicleMaintenenanceEventFinish:run(connection)
	ExtendedVehicleMaintenance.setFinished(self.vehicle, self.BackupAgeXML, self.BackupOperatingTimeXML, self.MaintenanceTimes, self.Differenz, self.DifferenzDays)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.vehicle)
	end
end

function ExtendedVehicleMaintenenanceEventFinish.sendEvent(vehicle, BackupAgeXML, BackupOperatingTimeXML, MaintenanceTimes, Differenz, DifferenzDays)
	if g_server ~= nil then
		g_server:broadcastEvent(ExtendedVehicleMaintenenanceEventFinish:new(vehicle, BackupAgeXML, BackupOperatingTimeXML, MaintenanceTimes, Differenz, DifferenzDays), nil, nil, vehicle)
	else
	    g_client:getServerConnection():sendEvent(ExtendedVehicleMaintenenanceEventFinish:new(vehicle, BackupAgeXML, BackupOperatingTimeXML, MaintenanceTimes, Differenz, DifferenzDays))
	end
end
