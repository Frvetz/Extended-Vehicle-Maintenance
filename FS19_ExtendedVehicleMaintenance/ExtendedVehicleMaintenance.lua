-- by Frvetz
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


Changelog Version 1.0.0.6:
- Confirmation window for maintenance
- Damage is no longer deducted directly (with Seasons-Mod) for vehicles that already have engine hours (borrowed vehicles from a contract), but starts again as intended without damage.
- No more error message that appeared when something was sold that was not a vehicle
- Individual adjustment of the maintenance price for each vehicle
- Shorter maintenance now costs less and longer maintenance costs more
- Depending on the length of the maintenance, a certain number of engine hours/days is added to the others (vehicle is not going to be completely repaired)
- Maintenance system generally improved to make it more realistic
- Description adjusted
- Ingame texts adapted
- Repair feature in the shop has been completely deactivated due to bugs (also for non-driveable equipment)
- Automatic engine start can be activated again (the engine stall function is then deactivated though)


Ideas that may be included in the next update (how or if they are included is not sure):
- Adjustment of the pallets to better distinguish them from each other (Please send ideas to ExtendedVehicleMaintenance@gmail.com.)
- Other small gimmicks
--]]

-- Thanks to Ian for the help with the xml!
-- Thanks to Glowin for the help with the last bugs and for the lua with the server stuff!

-- Thanks to the main testers: 
--  SneakyBeaky
--  Simba
--  Glowin

source(g_currentModDirectory.."events/ExtendedVehicleMaintenanceEvent.lua")
source(g_currentModDirectory.."events/ExtendedVehicleMaintenanceEventFinish.lua")

ExtendedVehicleMaintenance = {};
ExtendedVehicleMaintenance.rootNodePallet = {};
ExtendedVehicleMaintenance.l10nEnv = "FS19_ExtendedVehicleMaintenance";

ExtendedVehicleMaintenance.eventActive = false
ExtendedVehicleMaintenance.wartungsEvent = nil

function ExtendedVehicleMaintenance.prerequisitesPresent(specializations)
	return true;
end;

function ExtendedVehicleMaintenance.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ExtendedVehicleMaintenance);
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ExtendedVehicleMaintenance);
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ExtendedVehicleMaintenance);
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", ExtendedVehicleMaintenance);
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", ExtendedVehicleMaintenance);
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", ExtendedVehicleMaintenance);
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", ExtendedVehicleMaintenance);
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ExtendedVehicleMaintenance);
end;

function ExtendedVehicleMaintenance.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanMotorRun", ExtendedVehicleMaintenance.getCanMotorRun);
end

function ExtendedVehicleMaintenance:onRegisterActionEvents()
    if self.getIsEntered ~= nil and self:getIsEntered() then
		ExtendedVehicleMaintenance.actionEvents = {}
		_, ExtendedVehicleMaintenance.wartungsEvent = self:addActionEvent(ExtendedVehicleMaintenance.actionEvents, 'VEHICLE_MAINTENANCE', self, ExtendedVehicleMaintenance.DIALOG_MAINTENANCE, false, true, false, true, nil)
		g_inputBinding:setActionEventTextPriority(ExtendedVehicleMaintenance.wartungsEvent, GS_PRIO_NORMAL)
		g_inputBinding:setActionEventTextVisibility(ExtendedVehicleMaintenance.wartungsEvent, ExtendedVehicleMaintenance.eventActive)
	end
end

function ExtendedVehicleMaintenance:onLoad(savegame)
	local spec = self.spec_ExtendedVehicleMaintenance

	if self.spec_motorized ~= nil then

		spec.Variable = 30.0;

		spec.WartezeitStunden = 2;
		
		spec.WartezeitMinuten = 60;

		spec.CurrentMinuteBackup = g_currentMission.hud.environment.currentMinute;

		spec.Minus = 30;

		spec.WartungKnopfGedrueckt = false;

		spec.Differenz = 0;
		
		spec.DifferenzNextMaxCheck = 0;

		spec.MotorDieTimer = -1;
		
		spec.BackupOperatingTimeXML = 0;
		
		spec.DontAllowXmlNumberReset = false;
		
		spec.MaintenanceTimes = 1;
		
		spec.DarfNichtAusgehen = false;
		
		spec.RandomNumber = 0;
		
		spec.SecondSound = 2;
		
		spec.NumberMotorDieTimer = 0;
		
		spec.Costs = 0;
		
		spec.AmountVariable = 0;
		
		spec.AmountDays = 0;
		
		spec.Amount = 0;
		
		spec.AmountBeforeMinus = 0;
		
		spec.Wartung = 0;
		
		spec.OriginalTimeBackup = 0
		
		spec.CostsBackup = 0
		
		spec.AddNumber = 0
		
		spec.HoursToAdd = 0
		
		spec.SchadenVergleich = 30
		
		-- days

		spec.Days = 36;

		spec.SeasonsDays = 36;

		spec.BackupAge = 0;

		spec.BackupAgeXML = 0;

		spec.DifferenzDays = 0;
		
		spec.DifferenzDaysNextMaxCheck = 0;
		
		spec.DaysToAdd = 0;
		
		spec.DaysBackup = 0;
		
		-- costs
		
		spec.wartungsKosten = 0;
		spec.wartungsKostenServer = 0;
		spec.wartungClient = false
		
		
		spec.dirtyFlag = self:getNextDirtyFlag()
	end;
	if self.spec_tensionBeltObject ~= nil then
	    spec.OriginalTime = 0
	    spec.Costs = 0
	end
	--g_currentMission.missionInfo.automaticMotorStartEnabled = false
  --  g_currentMission.inGameMenu.pageSettingsGame.checkAutoMotorStart:setVisible(false)
end;

function ExtendedVehicleMaintenance:onPostLoad(savegame)
	local spec = self.spec_ExtendedVehicleMaintenance

	if savegame ~= nil then
		spec.BackupAgeXML = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#BackupAgeXML"), spec.BackupAgeXML)
		spec.BackupOperatingTimeXML = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#backupOperatingTime"), spec.BackupOperatingTimeXML)
		spec.MaintenanceTimes = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#MaintenanceTimes"), spec.MaintenanceTimes)
		spec.Differenz = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#Differenz"), spec.Differenz)
		spec.DifferenzNextMaxCheck = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#DifferenzNextMaxCheck"), spec.DifferenzNextMaxCheck)
		spec.DifferenzDays = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#DifferenzDays"), spec.DifferenzDays)
		spec.DifferenzDaysNextMaxCheck = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#DifferenzDaysNextMaxCheck"), spec.DifferenzDaysNextMaxCheck)
		spec.WartezeitStunden = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#WartezeitStunden"), spec.WartezeitStunden)
		spec.WartezeitMinuten = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#WartezeitMinuten"), spec.WartezeitMinuten)
		spec.CurrentMinuteBackup = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#CurrentMinuteBackup"), spec.CurrentMinuteBackup)
		spec.SchadenVergleich = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#SchadenVergleich"), spec.SchadenVergleich)
		spec.HoursToAdd = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#HoursToAdd"), spec.HoursToAdd)
		spec.DaysToAdd = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#DaysToAdd"), spec.DaysToAdd)
		spec.DaysBackup = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#DaysBackup"), spec.DaysBackup)
		spec.Days = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#Days"), spec.Days)
		spec.Variable = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#Variable"), spec.Variable)
		spec.WartungKnopfGedrueckt = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#WartungKnopfGedrueckt"), spec.WartungKnopfGedrueckt)
		if Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#BackupAgeXML")) ~= nil and Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#backupOperatingTime")) ~= nil then
	        spec.DontAllowXmlNumberReset = true
	    end;
	end

end

function ExtendedVehicleMaintenance:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_ExtendedVehicleMaintenance

	if spec.BackupAgeXML ~= nil then
		setXMLInt(xmlFile, key .. "#BackupAgeXML", spec.BackupAgeXML)
	end
	if spec.BackupOperatingTimeXML ~= nil then
		setXMLInt(xmlFile, key .. "#backupOperatingTime", spec.BackupOperatingTimeXML)
	end	
	if spec.MaintenanceTimes ~= nil then
		setXMLInt(xmlFile, key .. "#MaintenanceTimes", spec.MaintenanceTimes)
	end
    if spec.Differenz ~= nil then
		setXMLInt(xmlFile, key .. "#Differenz", spec.Differenz)
	end
	if spec.DifferenzNextMaxCheck ~= nil then
		setXMLInt(xmlFile, key .. "#DifferenzNextMaxCheck", spec.DifferenzNextMaxCheck)
	end
	if spec.DifferenzDays ~= nil then
		setXMLInt(xmlFile, key .. "#DifferenzDays", spec.DifferenzDays)
	end
	if spec.DifferenzDaysNextMaxCheck ~= nil then
		setXMLInt(xmlFile, key .. "#DifferenzDaysNextMaxCheck", spec.DifferenzDaysNextMaxCheck)
	end
	if spec.WartezeitStunden ~= nil then
		setXMLInt(xmlFile, key .. "#WartezeitStunden", spec.WartezeitStunden)
	end
	if spec.WartezeitMinuten ~= nil then
		setXMLInt(xmlFile, key .. "#WartezeitMinuten", spec.WartezeitMinuten)
	end
	if spec.CurrentMinuteBackup ~= nil then
		setXMLInt(xmlFile, key .. "#CurrentMinuteBackup", spec.CurrentMinuteBackup)
	end
	if spec.SchadenVergleich ~= nil then
		setXMLInt(xmlFile, key .. "#SchadenVergleich", spec.SchadenVergleich)
	end
	if spec.HoursToAdd ~= nil then
		setXMLInt(xmlFile, key .. "#HoursToAdd", spec.HoursToAdd)
	end
	if spec.DaysToAdd ~= nil then
		setXMLInt(xmlFile, key .. "#DaysToAdd", spec.DaysToAdd)
	end
	if spec.DaysBackup ~= nil then
		setXMLInt(xmlFile, key .. "#DaysBackup", spec.DaysBackup)
	end
	if spec.Days ~= nil then
		setXMLInt(xmlFile, key .. "#Days", spec.Days)
	end
	if spec.Variable ~= nil then
		setXMLInt(xmlFile, key .. "#Variable", spec.Variable)
	end
	if spec.WartungKnopfGedrueckt ~= nil then
		setXMLBool(xmlFile, key .. "#WartungKnopfGedrueckt", spec.WartungKnopfGedrueckt)
	end
end

function ExtendedVehicleMaintenance:onReadStream(streamId, connection)
	local spec = self.spec_ExtendedVehicleMaintenance
	local motorized = self.spec_motorized ~= nil
	 if motorized then
		spec.BackupAgeXML = streamReadInt32(streamId)
		spec.BackupOperatingTimeXML = streamReadInt32(streamId)
		spec.MaintenanceTimes = streamReadInt32(streamId)
		spec.Differenz = streamReadInt32(streamId)
		spec.DifferenzNextMaxCheck = streamReadInt32(streamId)
		spec.DifferenzDays = streamReadInt32(streamId)
		spec.DifferenzDaysNextMaxCheck = streamReadInt32(streamId)
		spec.WartezeitStunden = streamReadInt32(streamId)
		spec.WartezeitMinuten = streamReadInt32(streamId)
		spec.CurrentMinuteBackup = streamReadInt32(streamId)
		spec.SchadenVergleich = streamReadInt32(streamId)
		spec.HoursToAdd = streamReadInt32(streamId)
		spec.DaysToAdd = streamReadInt32(streamId)
		spec.DaysBackup = streamReadInt32(streamId)
		spec.Days = streamReadInt32(streamId)
		spec.Variable = streamReadInt32(streamId)
		spec.DontAllowXmlNumberReset = streamReadBool(streamId)
		spec.WartungKnopfGedrueckt = streamReadBool(streamId)
	end
end

function ExtendedVehicleMaintenance:onWriteStream(streamId, connection)
	local spec = self.spec_ExtendedVehicleMaintenance
	local motorized = self.spec_motorized ~= nil
	
	if motorized then
		streamWriteInt32(streamId, spec.BackupAgeXML)
		streamWriteInt32(streamId, spec.BackupOperatingTimeXML)
		streamWriteInt32(streamId, spec.MaintenanceTimes)
		streamWriteInt32(streamId, spec.Differenz)
		streamWriteInt32(streamId, spec.DifferenzNextMaxCheck)
		streamWriteInt32(streamId, spec.DifferenzDays)
		streamWriteInt32(streamId, spec.DifferenzDaysNextMaxCheck)
		streamWriteInt32(streamId, spec.WartezeitStunden)
		streamWriteInt32(streamId, spec.WartezeitMinuten)
		streamWriteInt32(streamId, spec.CurrentMinuteBackup)
		streamWriteInt32(streamId, spec.SchadenVergleich)
		streamWriteInt32(streamId, spec.HoursToAdd)
		streamWriteInt32(streamId, spec.DaysToAdd)
		streamWriteInt32(streamId, spec.DaysBackup)
		streamWriteInt32(streamId, spec.Days)
		streamWriteInt32(streamId, spec.Variable)
		streamWriteBool(streamId, spec.DontAllowXmlNumberReset)
		streamWriteBool(streamId, spec.WartungKnopfGedrueckt)
	end
end

function ExtendedVehicleMaintenance:onReadUpdateStream(streamId, timestamp, connection)
	if not connection:getIsServer() then
		local spec = self.spec_ExtendedVehicleMaintenance
		
		if streamReadBool(streamId) then
			spec.BackupAgeXML = streamReadInt32(streamId)
			spec.BackupOperatingTimeXML = streamReadInt32(streamId)
			spec.MaintenanceTimes = streamReadInt32(streamId)
			spec.Differenz = streamReadInt32(streamId)
			spec.DifferenzNextMaxCheck = streamReadInt32(streamId)
			spec.DifferenzDays = streamReadInt32(streamId)
			spec.DifferenzDaysNextMaxCheck = streamReadInt32(streamId)
			spec.WartezeitStunden = streamReadInt32(streamId)
			spec.WartezeitMinuten = streamReadInt32(streamId)
			spec.CurrentMinuteBackup = streamReadInt32(streamId)
			spec.SchadenVergleich = streamReadInt32(streamId)
			spec.HoursToAdd = streamReadInt32(streamId)
			spec.DaysToAdd = streamReadInt32(streamId)
			spec.DaysBackup = streamReadInt32(streamId)
			spec.Days = streamReadInt32(streamId)
			spec.Variable = streamReadInt32(streamId)
			spec.OriginalTimeBackup = streamReadInt32(streamId)
			spec.CostsBackup = streamReadInt32(streamId)
			spec.DontAllowXmlNumberReset = streamReadBool(streamId)
			spec.WartungKnopfGedrueckt = streamReadBool(streamId)
			spec.wartungsKostenServer = streamReadInt32(streamId)
			if spec.wartungsKostenServer > 0 then 
				spec.wartungsKosten = spec.wartungsKosten + spec.wartungsKostenServer
				spec.wartungsKostenServer = 0
			end
		end
	end
end

function ExtendedVehicleMaintenance:onWriteUpdateStream(streamId, connection, dirtyMask)
	if connection:getIsServer() then
		local spec = self.spec_ExtendedVehicleMaintenance
		if spec.dirtyFlag ~= nil then
			if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
				streamWriteInt32(streamId, spec.BackupAgeXML)
				streamWriteInt32(streamId, spec.BackupOperatingTimeXML)
				streamWriteInt32(streamId, spec.MaintenanceTimes)
				streamWriteInt32(streamId, spec.Differenz)
				streamWriteInt32(streamId, spec.DifferenzNextMaxCheck)
				streamWriteInt32(streamId, spec.DifferenzDays)
				streamWriteInt32(streamId, spec.DifferenzDaysNextMaxCheck)
				streamWriteInt32(streamId, spec.WartezeitStunden)
				streamWriteInt32(streamId, spec.WartezeitMinuten)
				streamWriteInt32(streamId, spec.CurrentMinuteBackup)
				streamWriteInt32(streamId, spec.SchadenVergleich)
				streamWriteInt32(streamId, spec.HoursToAdd)
				streamWriteInt32(streamId, spec.DaysToAdd)
				streamWriteInt32(streamId, spec.DaysBackup)
				streamWriteInt32(streamId, spec.Days)
				streamWriteInt32(streamId, spec.Variable)
				streamWriteInt32(streamId, spec.OriginalTimeBackup)
				streamWriteInt32(streamId, spec.CostsBackup)
				streamWriteBool(streamId, spec.DontAllowXmlNumberReset)
				streamWriteBool(streamId, spec.WartungKnopfGedrueckt)
				streamWriteInt32(streamId, spec.wartungsKostenServer)
				spec.wartungsKostenServer = 0
			end
		else 
			streamWriteBool(streamId, false)
		end
	end
end

function ExtendedVehicleMaintenance:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)

	local spec = self.spec_ExtendedVehicleMaintenance
	local changeFlag = false

	if self.typeName == "FS19_ExtendedVehicleMaintenance.palletMaintencance" then -- searches for the Pallet
		ExtendedVehicleMaintenance.rootNodePallet[self.id] = self.rootNode;
	end;

	if self.spec_motorized ~= nil then
		
	    if self.isClient and isActiveForInputIgnoreSelection and spec.DontAllowXmlNumberReset ~= true then
	        spec.BackupAgeXML = self.age
	        spec.BackupOperatingTimeXML = self:getFormattedOperatingTime()
		    spec.DontAllowXmlNumberReset = true
			changeFlag = true
	    end;
		if self.isClient and isActiveForInputIgnoreSelection and spec.Variable < 0.05 or spec.Days <= 0 then -- checks if a value is under 0
			spec.Wartung = true
		end;
		if self.isClient and isActiveForInputIgnoreSelection and spec.Variable >= 0.05 and spec.Days > 0 then
			spec.Wartung = false
		end;

		if self.isClient and isActiveForInputIgnoreSelection and spec.Wartung == false and spec.WartungKnopfGedrueckt == false then
			g_currentMission:addExtraPrintText(g_i18n:getText("information_Motor", ExtendedVehicleMaintenance.l10nEnv):format(spec.Variable, spec.Days)) -- 110n Text
			spec.WartungKnopfGedrueckt = false
		end;
		
		if g_currentMission.environment.weather.environment ~= nil then
			spec.SeasonsDays = g_currentMission.environment.weather.environment.daysPerSeason * 4
		else
			spec.SeasonsDays = 36
		end;
		
		if self.isClient and isActiveForInputIgnoreSelection then
		    --hours
			spec.Variable = 30 - self:getFormattedOperatingTime() + spec.Differenz + spec.BackupOperatingTimeXML    -- Operating time number
			--days
			spec.Days = spec.SeasonsDays - self.age + spec.DifferenzDays + spec.BackupAgeXML     -- day number
			
			if spec.SchadenVergleich < spec.Variable then
				spec.SchadenVergleich = spec.Variable
				changeFlag = true
			end
			--wear
			if not g_currentMission.shopMenu.isOpen then
				if g_currentMission.environment.weather.environment == nil then -- Seasons not active
					spec.AmountBeforeMinus = (100 - (spec.Variable * 100 / spec.SchadenVergleich )) / 100
					if spec.AmountBeforeMinus < 1 then
						spec.AmountVariable = spec.AmountBeforeMinus
					else
						spec.AmountVariable = 1
					end
					
					
					if spec.AmountVariable > 1 then
					    spec.AmountVariable = 1
					elseif spec.AmountVariable < 0 then
					    spec.AmountVariable = 0
					end
					
					self.spec_wearable.totalAmount = spec.AmountVariable
					--print("damage: "..tostring(self:getVehicleDamage()))
				else                                                            -- Seasons active
					local specRepair = self:seasons_getSpecTable("seasonsVehicle")
					spec.AmountVariable =  (108000  + spec.Differenz * 3600) + spec.BackupOperatingTimeXML * 3600
	
					specRepair.nextRepair = spec.AmountVariable
				end
			end
		end		
		
		-- Action if number is 0	
		if self.isClient and isActiveForInputIgnoreSelection and spec.Wartung == true and spec.WartungKnopfGedrueckt ~= true then
			g_currentMission:addExtraPrintText(g_i18n:getText("warning_wartung", ExtendedVehicleMaintenance.l10nEnv))

			if g_currentMission.missionInfo.automaticMotorStartEnabled == false then
				if spec.RandomNumber == 0 then
					spec.RandomNumber = math.random(1, 2)
				end;

				if spec.DarfNichtAusgehen ~= true then

					if self:getIsMotorStarted() then
						if self.spec_motorized.samples.motorStart ~= nil then
							spec.MotorDieTimer = spec.MotorDieTimer - dt
							spec.NumberMotorDieTimer = math.min(-spec.MotorDieTimer / 2000, 0.9)


							local MaxNumber = self.spec_motorized.samples.motorStart.duration * 98 / 1000000
							if spec.NumberMotorDieTimer >= 0.290789 then
								g_soundManager:stopSample(self.spec_motorized.samples.motorStart)
								spec.MotorDieTimer = -1
								g_soundManager:playSample(self.spec_motorized.samples.motorStart)
								spec.SecondSound = spec.SecondSound - 1
							end;
						  
							if spec.RandomNumber == 1 and spec.NumberMotorDieTimer >= 0.290789 and spec.SecondSound == 0 then
								self:stopMotor()
								g_soundManager:stopSample(self.spec_motorized.samples.motorStop)
								spec.SecondSound = 2
								spec.RandomNumber = 0
							elseif spec.RandomNumber == 2 and spec.NumberMotorDieTimer >= 0.290789 and spec.SecondSound == 1 then
								spec.DarfNichtAusgehen = true
								spec.RandomNumber = 0
								spec.SecondSound = 2
							end;
						end;
					end;
				end;
				if self:getIsMotorStarted() and OnlyWhenIsGettingActive == false then
					spec.DarfNichtAusgehen = true
					OnlyWhenIsGettingActive = true
				else
					OnlyWhenIsGettingActive = true
				end;
				if self:getMotorLoadPercentage() > 0.999999 then
					self.spec_motorized.smoothedLoadPercentage = 0
					self:stopMotor()
				end;
				if self.spec_motorized.isMotorStarted == false then
					spec.DarfNichtAusgehen = false
				end
			end;
			if spec.Wartung == false then
				OnlyWhenIsGettingActive = false
			end;
		end

		-- looks for the position of the pallet and adds the action event
		if self.isClient and isActiveForInputIgnoreSelection then
		
			local paletteGefunden = false
			
			for id,rootNode in pairs(ExtendedVehicleMaintenance.rootNodePallet) do 
				
			    if g_currentMission.nodeToObject[rootNode] ~= nil then
			        local px, py, pz = getWorldTranslation(rootNode) -- Palette
			        local vx, vy, vz = getWorldTranslation(self.rootNode) -- Fahrzeug
				
				    
				    if MathUtil.vector3Length(px-vx, py-vy, pz-vz) < 4.5 and (g_currentMission.nodeToObject[rootNode]:getActiveFarm() == self.ownerFarmId) and spec.WartungKnopfGedrueckt ~= true then		
				        paletteGefunden = true
						local EVMnodeToObject = g_currentMission.nodeToObject[rootNode].spec_ExtendedVehicleMaintenance
						
						if g_currentMission.nodeToObject[rootNode].configurations.design == 1 then
							EVMnodeToObject.OriginalTime = 1
							EVMnodeToObject.Costs =  self.price / 600
							--print(self.price)
							
							spec.HoursToAdd = 3
							spec.DaysToAdd = 1
							changeFlag = true
							
						elseif g_currentMission.nodeToObject[rootNode].configurations.design == 2 then
							EVMnodeToObject.OriginalTime = 4
							EVMnodeToObject.Costs = self.price / 150
							--print(self.price)
							
							spec.HoursToAdd = 9
							spec.DaysToAdd = ExtendedVehicleMaintenance:RoundValue(spec.SeasonsDays / 7,2)
							changeFlag = true
							
						elseif g_currentMission.nodeToObject[rootNode].configurations.design == 3 then
							EVMnodeToObject.OriginalTime = 8
							EVMnodeToObject.Costs = self.price / 60
							--print(self.price)
							
							spec.HoursToAdd = 18
							spec.DaysToAdd = ExtendedVehicleMaintenance:RoundValue(spec.SeasonsDays / 3)
							changeFlag = true
							
						elseif g_currentMission.nodeToObject[rootNode].configurations.design == 4 then
							EVMnodeToObject.OriginalTime = 24
							EVMnodeToObject.Costs = self.price / 12
							--print(self.price)
							
							spec.HoursToAdd = 35
							spec.DaysToAdd = spec.SeasonsDays
							changeFlag = true
							
						elseif g_currentMission.nodeToObject[rootNode].configurations.design == 5 then
							EVMnodeToObject.OriginalTime = 48
							EVMnodeToObject.Costs = self.price / 6
							--print(self.price)
							
							spec.HoursToAdd = 48
							spec.DaysToAdd = spec.SeasonsDays / 0.6
							changeFlag = true
						end
						
						spec.OriginalTimeBackup = EVMnodeToObject.OriginalTime
						spec.CostsBackup = EVMnodeToObject.Costs
			        end
				end
			end
			if paletteGefunden then 
			    if self:getIsEntered() then
				    local spec = self.spec_ExtendedVehicleMaintenance;
				   
				    ExtendedVehicleMaintenance.eventActive = true and not spec.WartungKnopfGedrueckt
			    end
			else
			    if self:getIsEntered() then
				    ExtendedVehicleMaintenance.eventActive = false
				end
			end
			g_inputBinding:setActionEventTextVisibility(ExtendedVehicleMaintenance.wartungsEvent, ExtendedVehicleMaintenance.eventActive)
		end;
      
		-- action if action event input is pressed
		if spec.WartungKnopfGedrueckt == true then
			local spec = self.spec_ExtendedVehicleMaintenance
			self:stopMotor() -- to hold the vehicle active after exiting
			self.spec_motorized.showTurnOnMotorWarning = false
			-- subtracts the time from the 1 hour 
			if spec.CurrentMinuteBackup ~= g_currentMission.hud.environment.currentMinute then
				spec.CurrentMinuteBackup = g_currentMission.hud.environment.currentMinute
				spec.WartezeitMinuten = spec.WartezeitMinuten - 1
				changeFlag = true
			end;
			if spec.WartezeitMinuten < 0 then
			    spec.WartezeitMinuten = 59
			    spec.WartezeitStunden = spec.WartezeitStunden - 1
			end

			if self.isClient and isActiveForInputIgnoreSelection then
		        g_currentMission:addExtraPrintText(g_i18n:getText("information_wartung", ExtendedVehicleMaintenance.l10nEnv):format(spec.WartezeitStunden, spec.WartezeitMinuten))
		    end;
		end;

		-- action if 1 hour is over 
		if spec.WartezeitStunden <= -1 and spec.WartungKnopfGedrueckt == true then
			spec.WartungKnopfGedrueckt = false
			spec.BackupOperatingTimeXML = 0
			spec.BackupAgeXML = 0
			spec.MaintenanceTimes = spec.MaintenanceTimes + 1
			spec.SchadenVergleich = 30
			
			if spec.DifferenzNextMaxCheck == spec.Differenz then
				if spec.Variable < 0 then
					spec.Differenz = spec.Differenz + spec.HoursToAdd - spec.Variable
				else
					spec.Differenz = spec.Differenz + spec.HoursToAdd
				end
			end
			
			if spec.Days < 0 then
				spec.DifferenzDays = spec.DifferenzDays + spec.DaysToAdd - spec.Days + (spec.DaysBackup - spec.Days)
			else
				spec.DifferenzDays = spec.DifferenzDays + spec.DaysToAdd + (spec.DaysBackup - spec.Days)
			end
			
		    ExtendedVehicleMaintenenanceEventFinish.sendEvent(self, spec.BackupAgeXML, spec.BackupOperatingTimeXML, spec.MaintenanceTimes, spec.Differenz, spec.DifferenzDays, spec.SchadenVergleich)
			changeFlag = true
		end;
	end;
	--print("Variable: "..tostring(spec.Variable))
	--print("Differenz: "..tostring(spec.Differenz))
	--print("HoursToAdd: "..tostring(spec.HoursToAdd))

	if spec.wartungsKosten ~= nil and spec.wartungsKosten > 0 then
        local farm = self.ownerFarmId
        if g_server ~= nil then 
            g_currentMission:addMoney(-spec.wartungsKosten, farm, MoneyType.VEHICLE_RUNNING_COSTS, true, true);
        else
            spec.wartungsKostenServer = spec.wartungsKostenServer + spec.wartungsKosten
            changeFlag = true
        end
        --[[if self:getIsEntered() then
            g_currentMission:showBlinkingWarning(g_i18n:getText("warning_moneyChange", ExtendedVehicleMaintenance.l10nEnv):format(spec.OriginalTimeBackup, spec.wartungsKosten), 6000)
        end--]]
        spec.wartungsKosten = 0
    end

    if changeFlag then
        self:raiseDirtyFlags(spec.dirtyFlag)
			
		ExtendedVehicleMaintenenanceEvent.sendEvent(self, spec.WartungKnopfGedrueckt, spec.CurrentMinuteBackup, spec.SchadenVergleich, spec.WartezeitStunden, spec.WartezeitMinuten, spec.HoursToAdd, spec.DaysToAdd, spec.OriginalTimeBackup, spec.CostsBackup, spec.DaysBackup, spec.Days, spec.Variable, spec.DifferenzNextMaxCheck, spec.DifferenzDaysNextMaxCheck, spec.DontAllowXmlNumberReset)
    end
	
end;

function ExtendedVehicleMaintenance:getCanMotorRun(superFunc)
    if self.spec_ExtendedVehicleMaintenance.WartungKnopfGedrueckt ~= true then
        return superFunc(self)
    end

    return false
end

function ExtendedVehicleMaintenance.setWartung(vehicle, wartungsStatus, CurrentMinuteBackup, SchadenVergleich, WartezeitStunden, WartezeitMinuten, HoursToAdd, DaysToAdd, OriginalTimeBackup, CostsBackup, DaysBackup, Days, Variable, DifferenzNextMaxCheck, DifferenzDaysNextMaxCheck, DontAllowXmlNumberReset)
	local spec = vehicle.spec_ExtendedVehicleMaintenance
	spec.WartungKnopfGedrueckt = wartungsStatus
	spec.CurrentMinuteBackup = CurrentMinuteBackup
	spec.WartezeitStunden = WartezeitStunden
	spec.WartezeitMinuten = WartezeitMinuten
	spec.OriginalTimeBackup = OriginalTimeBackup
	spec.CostsBackup = CostsBackup
	spec.DaysBackup = DaysBackup
	spec.Days = Days
	spec.Variable = Variable
	spec.DifferenzNextMaxCheck = DifferenzNextMaxCheck
	spec.DifferenzDaysNextMaxCheck = DifferenzDaysNextMaxCheck
	spec.DontAllowXmlNumberReset = DontAllowXmlNumberReset
end

function ExtendedVehicleMaintenance.setFinished(vehicle, BackupAgeXML, BackupOperatingTimeXML, MaintenanceTimes, Differenz, DifferenzDays, SchadenVergleich)
	local spec = vehicle.spec_ExtendedVehicleMaintenance
	spec.BackupAgeXML = BackupAgeXML 
    spec.BackupOperatingTimeXML = BackupOperatingTimeXML
	spec.MaintenanceTimes = MaintenanceTimes
	spec.Differenz = Differenz
	spec.DifferenzDays = DifferenzDays

end

function ExtendedVehicleMaintenance:DIALOG_MAINTENANCE()
    if not ExtendedVehicleMaintenance.eventActive or self.spec_ExtendedVehicleMaintenance == nil then 
		return; 
	end
	g_gui:showYesNoDialog(
		{
			text = g_i18n:getText("dialog_maintenance_text", ExtendedVehicleMaintenance.l10nEnv):format(self.spec_ExtendedVehicleMaintenance.OriginalTimeBackup, self.spec_ExtendedVehicleMaintenance.HoursToAdd, self.spec_ExtendedVehicleMaintenance.DaysToAdd),
			title = g_i18n:getText("dialog_dialog_maintenance_title", ExtendedVehicleMaintenance.l10nEnv):format(self.spec_ExtendedVehicleMaintenance.wartungsKosten + self.spec_ExtendedVehicleMaintenance.CostsBackup),
			callback = ExtendedVehicleMaintenance.VEHICLE_MAINTENANCE,
			target = self
		}
	)
end

function ExtendedVehicleMaintenance:VEHICLE_MAINTENANCE(yes)
    if yes then
		local spec = self.spec_ExtendedVehicleMaintenance
		if not ExtendedVehicleMaintenance.eventActive or spec == nil then 
			return; 
		end

		spec.WartezeitStunden = spec.OriginalTimeBackup
		spec.WartezeitMinuten = 0
		spec.CurrentMinuteBackup = g_currentMission.hud.environment.currentMinute
		
		spec.DaysBackup	= spec.Days
		
		spec.WartungKnopfGedrueckt = true
		
		spec.DifferenzNextMaxCheck = spec.Differenz
		spec.DifferenzDaysNextMaxCheck = spec.DifferenzDays
		
		ExtendedVehicleMaintenance.eventActive = false
		ExtendedVehicleMaintenenanceEvent.sendEvent(self, spec.WartungKnopfGedrueckt, spec.CurrentMinuteBackup, spec.SchadenVergleich, spec.WartezeitStunden, spec.WartezeitMinuten, spec.HoursToAdd, spec.DaysToAdd, spec.OriginalTimeBackup, spec.CostsBackup, spec.DaysBackup, spec.Days, spec.Variable, spec.DifferenzNextMaxCheck, spec.DifferenzDaysNextMaxCheck, spec.DontAllowXmlNumberReset)

		spec.wartungsKosten = spec.wartungsKosten + spec.CostsBackup
		spec.dirtyFlag = spec:getNextDirtyFlag()
    end
end;

function ExtendedVehicleMaintenance:RoundValue(x2)
	return x2>=0 and math.floor(x2+0.5) or math.ceil(x2-0.5)
end