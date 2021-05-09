-- event class to make license plates (in-)visible

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
