-- EventFinish class to make license plates (in-)visible

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
