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

ExtendedVehicleMaintenenanceEvent = {}
local ExtendedVehicleMaintenenanceEvent_mt = Class(ExtendedVehicleMaintenenanceEvent, Event)
InitEventClass(ExtendedVehicleMaintenenanceEvent, "ExtendedVehicleMaintenenanceEvent")

function ExtendedVehicleMaintenenanceEvent:emptyNew()
	local event = Event:new(ExtendedVehicleMaintenenanceEvent_mt)

	return event
end

function ExtendedVehicleMaintenenanceEvent:new(vehicle, wartungsStatus, CurrentMinuteBackup, WartezeitStunden, WartezeitMinuten, OriginalTimeBackup, CostsBackup, DontAllowXmlNumberReset)
    local event = ExtendedVehicleMaintenenanceEvent:emptyNew()
	    event.vehicle = vehicle
	    event.wartungsStatus = wartungsStatus
        event.CurrentMinuteBackup = CurrentMinuteBackup
        event.WartezeitStunden = WartezeitStunden
        event.WartezeitMinuten = WartezeitMinuten
		
        event.OriginalTimeBackup = OriginalTimeBackup
        event.CostsBackup = CostsBackup
        event.DontAllowXmlNumberReset = DontAllowXmlNumberReset
       -- ExtendedVehicleMaintenance.OriginalTime = OriginalTimeEvent
	   
	return event
end

function ExtendedVehicleMaintenenanceEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.wartungsStatus = streamReadBool(streamId)
    self.CurrentMinuteBackup = streamReadInt32(streamId)
    self.WartezeitStunden = streamReadInt32(streamId)
    self.WartezeitMinuten = streamReadInt32(streamId)
	
    self.OriginalTimeBackup = streamReadInt32(streamId)
    self.CostsBackup = streamReadInt32(streamId)
    self.DontAllowXmlNumberReset = streamReadBool(streamId)
   -- ExtendedVehicleMaintenance.OriginalTime = streamReadInt32(streamId)
	
	self:run(connection)
end

function ExtendedVehicleMaintenenanceEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.wartungsStatus)
	streamWriteInt32(streamId, self.CurrentMinuteBackup)
	streamWriteInt32(streamId, self.WartezeitStunden)
	streamWriteInt32(streamId, self.WartezeitMinuten)
	
	streamWriteInt32(streamId, self.OriginalTimeBackup)
	streamWriteInt32(streamId, self.CostsBackup)
	streamWriteBool(streamId, self.DontAllowXmlNumberReset)
	--streamWriteInt32(streamId, ExtendedVehicleMaintenance.OriginalTime)
end

function ExtendedVehicleMaintenenanceEvent:run(connection)
	ExtendedVehicleMaintenance.setWartung(self.vehicle, self.wartungsStatus, self.CurrentMinuteBackup, self.WartezeitStunden, self.WartezeitMinuten, self.OriginalTimeBackup, self.CostsBackup, self.DontAllowXmlNumberReset)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.vehicle)
	end
end

function ExtendedVehicleMaintenenanceEvent.sendEvent(vehicle, wartungsStatus, CurrentMinuteBackup, WartezeitStunden, WartezeitMinuten, OriginalTimeBackup, CostsBackup, DontAllowXmlNumberReset)
	if g_server ~= nil then
		g_server:broadcastEvent(ExtendedVehicleMaintenenanceEvent:new(vehicle, wartungsStatus, CurrentMinuteBackup, WartezeitStunden, WartezeitMinuten, OriginalTimeBackup, CostsBackup, DontAllowXmlNumberReset), nil, nil, vehicle)
	else
	    g_client:getServerConnection():sendEvent(ExtendedVehicleMaintenenanceEvent:new(vehicle, wartungsStatus, CurrentMinuteBackup, WartezeitStunden, WartezeitMinuten, OriginalTimeBackup, CostsBackup, DontAllowXmlNumberReset))
	end
end
