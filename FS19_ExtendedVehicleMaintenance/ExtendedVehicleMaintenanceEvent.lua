-- event class to make license plates (in-)visible

ExtendedVehicleMaintenenanceEvent = {}
local ExtendedVehicleMaintenenanceEvent_mt = Class(ExtendedVehicleMaintenenanceEvent, Event)
InitEventClass(ExtendedVehicleMaintenenanceEvent, "ExtendedVehicleMaintenenanceEvent")

function ExtendedVehicleMaintenenanceEvent:emptyNew()
	local self = Event:new(ExtendedVehicleMaintenenanceEvent_mt)

	return self
end

function ExtendedVehicleMaintenenanceEvent:new(vehicle, wartungsStatus)
	local self = ExtendedVehicleMaintenenanceEvent:emptyNew()
	self.vehicle = vehicle
	self.wartungsStatus = wartungsStatus

	return self
end

function ExtendedVehicleMaintenenanceEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.wartungsStatus = streamReadBool(streamId)

	self:run(connection)
end

function ExtendedVehicleMaintenenanceEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.wartungsStatus)
end

function ExtendedVehicleMaintenenanceEvent:run(connection)
	ExtendedVehicleMaintenance.setWartung(self.vehicle, self.wartungsStatus)

	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.vehicle)
	end
end

function ExtendedVehicleMaintenenanceEvent.sendEvent(vehicle, wartungsStatus)
	if g_server then
		g_server:broadcastEvent(ExtendedVehicleMaintenenanceEvent:new(vehicle, wartungsStatus), nil, nil, vehicle)
	end
end
