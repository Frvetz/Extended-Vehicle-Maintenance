-- event class to make license plates (in-)visible

ExtendedVehicleMaintenenanceEvent = {}
local ExtendedVehicleMaintenenanceEvent_mt = Class(ExtendedVehicleMaintenenanceEvent, Event)
InitEventClass(ExtendedVehicleMaintenenanceEvent, "ExtendedVehicleMaintenenanceEvent")

function ExtendedVehicleMaintenenanceEvent:emptyNew()
	local self = Event:new(ExtendedVehicleMaintenenanceEvent_mt)

	return self
end

function ExtendedVehicleMaintenenanceEvent:new(vehicle, wartungsStatus, CurrentMinuteBackup, WartezeitStunden, WartezeitMinuten)
	local self = ExtendedVehicleMaintenenanceEvent:emptyNew()
	self.vehicle = vehicle
	self.wartungsStatus = wartungsStatus
    self.CurrentMinuteBackup = CurrentMinuteBackup
    self.WartezeitStunden = WartezeitStunden
    self.WartezeitMinuten = WartezeitMinuten
   -- ExtendedVehicleMaintenance.OriginalTime = OriginalTimeEvent

print(OriginalTimeEvent)
	return self
end

function ExtendedVehicleMaintenenanceEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.wartungsStatus = streamReadBool(streamId)
    self.CurrentMinuteBackup = streamReadInt32(streamId)
    self.WartezeitStunden = streamReadInt32(streamId)
    self.WartezeitMinuten = streamReadInt32(streamId)
   -- ExtendedVehicleMaintenance.OriginalTime = streamReadInt32(streamId)
	
	self:run(connection)
end

function ExtendedVehicleMaintenenanceEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.wartungsStatus)
	streamWriteInt32(streamId, self.CurrentMinuteBackup)
	streamWriteInt32(streamId, self.WartezeitStunden)
	streamWriteInt32(streamId, self.WartezeitMinuten)
	--streamWriteInt32(streamId, ExtendedVehicleMaintenance.OriginalTime)
end

function ExtendedVehicleMaintenenanceEvent:run(connection)
	ExtendedVehicleMaintenance.setWartung(self.vehicle, self.wartungsStatus, self.CurrentMinuteBackup, self.WartezeitStunden, self.WartezeitMinuten)
print("OriginalTime: "..tostring(ExtendedVehicleMaintenance.OriginalTime))
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.vehicle)
	end
end

function ExtendedVehicleMaintenenanceEvent.sendEvent(vehicle, wartungsStatus, CurrentMinuteBackup, WartezeitStunden, WartezeitMinuten)
	if g_server then
		g_server:broadcastEvent(ExtendedVehicleMaintenenanceEvent:new(vehicle, wartungsStatus, CurrentMinuteBackup, WartezeitStunden, WartezeitMinuten), nil, nil, vehicle)
		print(OriginalTimeEvent)
	end
end
