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
		_, ExtendedVehicleMaintenance.wartungsEvent = self:addActionEvent(ExtendedVehicleMaintenance.actionEvents, 'VEHICLE_MAINTENANCE', self, ExtendedVehicleMaintenance.DIALOG, false, true, false, true, nil)
		g_inputBinding:setActionEventTextPriority(ExtendedVehicleMaintenance.wartungsEvent, GS_PRIO_NORMAL)
		g_inputBinding:setActionEventTextVisibility(ExtendedVehicleMaintenance.wartungsEvent, ExtendedVehicleMaintenance.eventActive)
	end
end

function ExtendedVehicleMaintenance:onLoad(savegame)
	local spec = self.spec_ExtendedVehicleMaintenance

	if self.spec_motorized ~= nil then

		spec.Variable = 30.0;
		spec.VariableBackupCheck = 0;

		spec.WartezeitStunden = 2;
		
		spec.WartezeitMinuten = 60;

		spec.CurrentMinuteBackup = g_currentMission.hud.environment.currentMinute;

		spec.Minus = 30;

		spec.WartungKnopfGedrueckt = false;

		spec.Differenz = 0;

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
		
		-- days

		spec.Days = 36;

		spec.SeasonsDays = 36;

		spec.BackupAge = 0;

		spec.BackupAgeXML = 0;

		spec.DifferenzDays = 0;
		
		-- costs
		
		spec.wartungsKosten = 0;
		spec.wartungsKostenServer = 0;
		spec.wartungClient = false
		
		spec.dirtyFlag = self:getNextDirtyFlag()
	end;
	if self.spec_tensionBeltObject ~= nil then
	    self.spec_ExtendedVehicleMaintenance.OriginalTime = 0
	    self.spec_ExtendedVehicleMaintenance.Costs = 0
	end
	g_currentMission.missionInfo.automaticMotorStartEnabled = false
	g_currentMission.inGameMenu.pageSettingsGame.checkAutoMotorStart:setVisible(false)    
end;

function ExtendedVehicleMaintenance:onPostLoad(savegame)
	local spec = self.spec_ExtendedVehicleMaintenance

	if savegame ~= nil then
		spec.BackupAgeXML = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#BackupAgeXML"), spec.BackupAgeXML)
		spec.BackupOperatingTimeXML = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#backupOperatingTime"), spec.BackupOperatingTimeXML)
		spec.MaintenanceTimes = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#MaintenanceTimes"), spec.MaintenanceTimes)
		spec.Differenz = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#Differenz"), spec.Differenz)
		spec.DifferenzDays = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#DifferenzDays"), spec.DifferenzDays)
		spec.WartezeitStunden = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#WartezeitStunden"), spec.WartezeitStunden)
		spec.WartezeitMinuten = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#WartezeitMinuten"), spec.WartezeitMinuten)
		spec.CurrentMinuteBackup = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".ExtendedVehicleMaintenance#CurrentMinuteBackup"), spec.CurrentMinuteBackup)
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
	if spec.DifferenzDays ~= nil then
		setXMLInt(xmlFile, key .. "#DifferenzDays", spec.DifferenzDays)
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
		spec.DifferenzDays = streamReadInt32(streamId)
		spec.WartezeitStunden = streamReadInt32(streamId)
		spec.WartezeitMinuten = streamReadInt32(streamId)
		spec.CurrentMinuteBackup = streamReadInt32(streamId)
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
		streamWriteInt32(streamId, spec.DifferenzDays)
		streamWriteInt32(streamId, spec.WartezeitStunden)
		streamWriteInt32(streamId, spec.WartezeitMinuten)
		streamWriteInt32(streamId, spec.CurrentMinuteBackup)
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
			spec.DifferenzDays = streamReadInt32(streamId)
			spec.WartezeitStunden = streamReadInt32(streamId)
			spec.WartezeitMinuten = streamReadInt32(streamId)
			spec.CurrentMinuteBackup = streamReadInt32(streamId)
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
				streamWriteInt32(streamId, spec.DifferenzDays)
				streamWriteInt32(streamId, spec.WartezeitStunden)
				streamWriteInt32(streamId, spec.WartezeitMinuten)
				streamWriteInt32(streamId, spec.CurrentMinuteBackup)
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
	
    if g_directSellDialog.isOpen == true and g_directSellDialog.vehicle ~= nil and g_directSellDialog.vehicle.spec_drivable ~= nil then
        g_directSellDialog.repairButton.disabled = true
    end
	
	if self.typeName == "FS19_ExtendedVehicleMaintenance.palletMaintencance" then -- searches for the Pallet
		ExtendedVehicleMaintenance.rootNodePallet[self.id] = self.rootNode;
		if self.configurations.design == 1 then
		    self.spec_ExtendedVehicleMaintenance.OriginalTime = 1
		    self.spec_ExtendedVehicleMaintenance.Costs = 25000
		elseif self.configurations.design  == 2 then
		    self.spec_ExtendedVehicleMaintenance.OriginalTime = 4
		    self.spec_ExtendedVehicleMaintenance.Costs = 20000
		elseif self.configurations.design == 3 then
		    self.spec_ExtendedVehicleMaintenance.OriginalTime = 8
		    self.spec_ExtendedVehicleMaintenance.Costs = 16000
		elseif self.configurations.design == 4 then
		    self.spec_ExtendedVehicleMaintenance.OriginalTime = 24
		    self.spec_ExtendedVehicleMaintenance.Costs = 12000
		elseif self.configurations.design == 5 then
		    self.spec_ExtendedVehicleMaintenance.OriginalTime = 48
		    self.spec_ExtendedVehicleMaintenance.Costs = 8000
		end
		
	end;

	if self.spec_motorized ~= nil then
		
	    if self.isClient and isActiveForInputIgnoreSelection and self.spec_ExtendedVehicleMaintenance.DontAllowXmlNumberReset ~= true then
	        self.spec_ExtendedVehicleMaintenance.BackupAgeXML = self.age
	        self.spec_ExtendedVehicleMaintenance.BackupOperatingTimeXML = self:getFormattedOperatingTime()
		    self.spec_ExtendedVehicleMaintenance.DontAllowXmlNumberReset = true
			changeFlag = true
	    end;
		if self.isClient and isActiveForInputIgnoreSelection and self.spec_ExtendedVehicleMaintenance.Variable < 0.05 or self.spec_ExtendedVehicleMaintenance.Days <= 0 then -- checks if a value is under 0
			self.spec_ExtendedVehicleMaintenance.Wartung = true
		end;
		if self.isClient and isActiveForInputIgnoreSelection and self.spec_ExtendedVehicleMaintenance.Variable >= 0.05 and self.spec_ExtendedVehicleMaintenance.Days > 0 then
			self.spec_ExtendedVehicleMaintenance.Wartung = false
		end;

		if self.isClient and isActiveForInputIgnoreSelection and self.spec_ExtendedVehicleMaintenance.Wartung == false and self.spec_ExtendedVehicleMaintenance.WartungKnopfGedrueckt == false then
			g_currentMission:addExtraPrintText(g_i18n:getText("information_Motor", ExtendedVehicleMaintenance.l10nEnv):format(self.spec_ExtendedVehicleMaintenance.Variable, self.spec_ExtendedVehicleMaintenance.Days)) -- 110n Text
			self.spec_ExtendedVehicleMaintenance.WartungKnopfGedrueckt = false
		end;
		
		if g_currentMission.environment.weather.environment ~= nil then
			self.spec_ExtendedVehicleMaintenance.SeasonsDays = g_currentMission.environment.weather.environment.daysPerSeason * 4
		else
			self.spec_ExtendedVehicleMaintenance.SeasonsDays = 36
		end;
		
		if self.isClient and isActiveForInputIgnoreSelection then
		    --hours
			self.spec_ExtendedVehicleMaintenance.Variable = (30 * self.spec_ExtendedVehicleMaintenance.MaintenanceTimes) - self:getFormattedOperatingTime() + self.spec_ExtendedVehicleMaintenance.Differenz + self.spec_ExtendedVehicleMaintenance.BackupOperatingTimeXML              -- Operating time number
			--days
			self.spec_ExtendedVehicleMaintenance.Days = (self.spec_ExtendedVehicleMaintenance.SeasonsDays * self.spec_ExtendedVehicleMaintenance.MaintenanceTimes) - self.age + self.spec_ExtendedVehicleMaintenance.DifferenzDays + self.spec_ExtendedVehicleMaintenance.BackupAgeXML                        -- day number
			
			--wear
			
			if g_currentMission.environment.weather.environment == nil then -- Seasons not active
			    self.spec_ExtendedVehicleMaintenance.AmountBeforeMinus = (100 - (self.spec_ExtendedVehicleMaintenance.Variable * 100 / 30)) / 100
				if self.spec_ExtendedVehicleMaintenance.AmountBeforeMinus < 1 then
				    self.spec_ExtendedVehicleMaintenance.AmountVariable = self.spec_ExtendedVehicleMaintenance.AmountBeforeMinus
				else
				    self.spec_ExtendedVehicleMaintenance.AmountVariable = 1
				end
			    self.spec_wearable.totalAmount = self.spec_ExtendedVehicleMaintenance.AmountVariable
			else                                                            -- Seasons active
			    local specRepair = self:seasons_getSpecTable("seasonsVehicle")
				self.spec_ExtendedVehicleMaintenance.AmountVariable =  (108000 * self.spec_ExtendedVehicleMaintenance.MaintenanceTimes) + (self.spec_ExtendedVehicleMaintenance.Differenz * 3600)
				
			    specRepair.nextRepair = self.spec_ExtendedVehicleMaintenance.AmountVariable
			end
		end		
		
		-- Action if number is 0	
		if self.isClient and isActiveForInputIgnoreSelection and self.spec_ExtendedVehicleMaintenance.Wartung == true and self.spec_ExtendedVehicleMaintenance.WartungKnopfGedrueckt ~= true then
			g_currentMission:addExtraPrintText(g_i18n:getText("warning_wartung", ExtendedVehicleMaintenance.l10nEnv))

			if self.spec_ExtendedVehicleMaintenance.RandomNumber == 0 then
				self.spec_ExtendedVehicleMaintenance.RandomNumber = math.random(1, 2)
			end;

			if self.spec_ExtendedVehicleMaintenance.DarfNichtAusgehen ~= true then

				if self:getIsMotorStarted() then
				    if self.spec_motorized.samples.motorStart ~= nil then
					    self.spec_ExtendedVehicleMaintenance.MotorDieTimer = self.spec_ExtendedVehicleMaintenance.MotorDieTimer - dt
					    self.spec_ExtendedVehicleMaintenance.NumberMotorDieTimer = math.min(-self.spec_ExtendedVehicleMaintenance.MotorDieTimer / 2000, 0.9)

					    local MaxNumber = self.spec_motorized.samples.motorStart.duration * 98 / 1000000
					    if self.spec_ExtendedVehicleMaintenance.NumberMotorDieTimer >= 0.290789 then
					    	g_soundManager:stopSample(self.spec_motorized.samples.motorStart)
					    	self.spec_ExtendedVehicleMaintenance.MotorDieTimer = -1
						    g_soundManager:playSample(self.spec_motorized.samples.motorStart)
						    self.spec_ExtendedVehicleMaintenance.SecondSound = self.spec_ExtendedVehicleMaintenance.SecondSound - 1
					    end;
                      
					    if self.spec_ExtendedVehicleMaintenance.RandomNumber == 1 and self.spec_ExtendedVehicleMaintenance.NumberMotorDieTimer >= 0.290789 and self.spec_ExtendedVehicleMaintenance.SecondSound == 0 then
						    self:stopMotor()
						    g_soundManager:stopSample(self.spec_motorized.samples.motorStop)
						    self.spec_ExtendedVehicleMaintenance.SecondSound = 2
						    self.spec_ExtendedVehicleMaintenance.RandomNumber = 0
					    elseif self.spec_ExtendedVehicleMaintenance.RandomNumber == 2 and self.spec_ExtendedVehicleMaintenance.NumberMotorDieTimer >= 0.290789 and self.spec_ExtendedVehicleMaintenance.SecondSound == 1 then
						    self.spec_ExtendedVehicleMaintenance.DarfNichtAusgehen = true
						    self.spec_ExtendedVehicleMaintenance.RandomNumber = 0
						    self.spec_ExtendedVehicleMaintenance.SecondSound = 2
					    end;
					end;
				end;
			end;
			if self:getIsMotorStarted() and OnlyWhenIsGettingActive == false then
				self.spec_ExtendedVehicleMaintenance.DarfNichtAusgehen = true
				OnlyWhenIsGettingActive = true
			else
				OnlyWhenIsGettingActive = true
			end;
			if self:getMotorLoadPercentage() > 0.999999 then
				self.spec_motorized.smoothedLoadPercentage = 0
				self:stopMotor()
			end;
			if self.spec_motorized.isMotorStarted == false then
				self.spec_ExtendedVehicleMaintenance.DarfNichtAusgehen = false
			end;
		end;
		if self.spec_ExtendedVehicleMaintenance.Wartung == false then
			OnlyWhenIsGettingActive = false
		end;

		-- looks for the position of the pallet and adds the action event
		if self.isClient and isActiveForInputIgnoreSelection then
		
			local paletteGefunden = false
			
			for id,rootNode in pairs(ExtendedVehicleMaintenance.rootNodePallet) do 
				
			    if g_currentMission.nodeToObject[rootNode] ~= nil then
			        local px, py, pz = getWorldTranslation(rootNode) -- Palette
			        local vx, vy, vz = getWorldTranslation(self.rootNode) -- Fahrzeug
				
				    
				    if MathUtil.vector3Length(px-vx, py-vy, pz-vz) < 6 and (g_currentMission.nodeToObject[rootNode]:getActiveFarm() == self.ownerFarmId) then		
				        paletteGefunden = true
						self.spec_ExtendedVehicleMaintenance.OriginalTimeBackup = g_currentMission.nodeToObject[rootNode].spec_ExtendedVehicleMaintenance.OriginalTime
						self.spec_ExtendedVehicleMaintenance.CostsBackup = g_currentMission.nodeToObject[rootNode].spec_ExtendedVehicleMaintenance.Costs
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
		if self.spec_ExtendedVehicleMaintenance.WartungKnopfGedrueckt == true then
			local spec = self.spec_ExtendedVehicleMaintenance
			self:stopMotor() -- to hold the vehicle active after exiting
			self.spec_motorized.showTurnOnMotorWarning = false
			-- subtracts the time from the 1 hour 
			if self.spec_ExtendedVehicleMaintenance.CurrentMinuteBackup ~= g_currentMission.hud.environment.currentMinute then
				self.spec_ExtendedVehicleMaintenance.CurrentMinuteBackup = g_currentMission.hud.environment.currentMinute
				self.spec_ExtendedVehicleMaintenance.WartezeitMinuten = self.spec_ExtendedVehicleMaintenance.WartezeitMinuten - 1
				changeFlag = true
			end;
			if self.spec_ExtendedVehicleMaintenance.WartezeitMinuten < 0 then
			    self.spec_ExtendedVehicleMaintenance.WartezeitMinuten = 59
			    self.spec_ExtendedVehicleMaintenance.WartezeitStunden = self.spec_ExtendedVehicleMaintenance.WartezeitStunden - 1
			end

			if self.isClient and isActiveForInputIgnoreSelection then
		        g_currentMission:addExtraPrintText(g_i18n:getText("information_wartung", ExtendedVehicleMaintenance.l10nEnv):format(self.spec_ExtendedVehicleMaintenance.WartezeitStunden, self.spec_ExtendedVehicleMaintenance.WartezeitMinuten))
		    end;
		end;

		-- action if 1 hour is over 
		if self.spec_ExtendedVehicleMaintenance.WartezeitStunden <= -1 and self.spec_ExtendedVehicleMaintenance.WartungKnopfGedrueckt == true then
			self.spec_ExtendedVehicleMaintenance.WartungKnopfGedrueckt = false
			self.spec_ExtendedVehicleMaintenance.BackupOperatingTimeXML = 0
			self.spec_ExtendedVehicleMaintenance.BackupAgeXML = 0
			self.spec_ExtendedVehicleMaintenance.MaintenanceTimes = self.spec_ExtendedVehicleMaintenance.MaintenanceTimes + 1
			self.spec_ExtendedVehicleMaintenance.Differenz = self:getFormattedOperatingTime() - (30 * (self.spec_ExtendedVehicleMaintenance.MaintenanceTimes - 1))
			self.spec_ExtendedVehicleMaintenance.DifferenzDays = self.age - (self.spec_ExtendedVehicleMaintenance.SeasonsDays * (self.spec_ExtendedVehicleMaintenance.MaintenanceTimes - 1))
		    ExtendedVehicleMaintenenanceEventFinish.sendEvent(self, spec.BackupAgeXML, spec.BackupOperatingTimeXML, spec.MaintenanceTimes, spec.Differenz, spec.DifferenzDays)
			changeFlag = true
		end;
	end;
	
	
	if spec.wartungsKosten ~= nil and spec.wartungsKosten > 0 then
        local farm = self.ownerFarmId
        if g_server ~= nil then 
            g_currentMission:addMoney(-spec.wartungsKosten, farm, MoneyType.VEHICLE_RUNNING_COSTS, true, true);
        else
            spec.wartungsKostenServer = spec.wartungsKostenServer + spec.wartungsKosten
            changeFlag = true
        end
        --[[if self:getIsEntered() then
            g_currentMission:showBlinkingWarning(g_i18n:getText("warning_moneyChange", ExtendedVehicleMaintenance.l10nEnv):format(self.spec_ExtendedVehicleMaintenance.OriginalTimeBackup, spec.wartungsKosten), 6000)
        end--]]
        spec.wartungsKosten = 0
    end

    if changeFlag then
        self:raiseDirtyFlags(self.spec_ExtendedVehicleMaintenance.dirtyFlag)
			
		ExtendedVehicleMaintenenanceEvent.sendEvent(self, spec.WartungKnopfGedrueckt, spec.CurrentMinuteBackup, spec.WartezeitStunden, spec.WartezeitMinuten, spec.OriginalTimeBackup, spec.CostsBackup, spec.DontAllowXmlNumberReset)
    end
end;

function ExtendedVehicleMaintenance:getCanMotorRun(superFunc)
    if self.spec_ExtendedVehicleMaintenance.WartungKnopfGedrueckt ~= true then
        return superFunc(self)
    end

    return false
end


function ExtendedVehicleMaintenance.setWartung(vehicle, wartungsStatus, CurrentMinuteBackup, WartezeitStunden, WartezeitMinuten, OriginalTimeBackup, CostsBackup, DontAllowXmlNumberReset)
	local spec = vehicle.spec_ExtendedVehicleMaintenance
	spec.WartungKnopfGedrueckt = wartungsStatus
	spec.CurrentMinuteBackup = CurrentMinuteBackup
	spec.WartezeitStunden = WartezeitStunden
	spec.WartezeitMinuten = WartezeitMinuten
	
	spec.OriginalTimeBackup = OriginalTimeBackup
	spec.CostsBackup = CostsBackup
	spec.DontAllowXmlNumberReset = DontAllowXmlNumberReset
end

function ExtendedVehicleMaintenance.setFinished(vehicle, BackupAgeXML, BackupOperatingTimeXML, MaintenanceTimes, Differenz, DifferenzDays)
	local spec = vehicle.spec_ExtendedVehicleMaintenance
	spec.BackupAgeXML = BackupAgeXML 
    spec.BackupOperatingTimeXML = BackupOperatingTimeXML
	spec.MaintenanceTimes = MaintenanceTimes
	spec.Differenz = Differenz
	spec.DifferenzDays = DifferenzDays

end

function ExtendedVehicleMaintenance:DIALOG()
    if not ExtendedVehicleMaintenance.eventActive or self.spec_ExtendedVehicleMaintenance == nil then 
		return; 
	end
	g_gui:showYesNoDialog(
		{
			text = g_i18n:getText("dialog_maintenance_text", ExtendedVehicleMaintenance.l10nEnv):format(self.spec_ExtendedVehicleMaintenance.wartungsKosten + self.spec_ExtendedVehicleMaintenance.CostsBackup, self.spec_ExtendedVehicleMaintenance.OriginalTimeBackup),
			title = g_i18n:getText("dialog_dialog_maintenance_title"),
			callback = ExtendedVehicleMaintenance.VEHICLE_MAINTENANCE,
			target = self
		}
	)
	one = true
end

function ExtendedVehicleMaintenance:VEHICLE_MAINTENANCE(yes)
    if yes then
		local spec = self.spec_ExtendedVehicleMaintenance
		if not ExtendedVehicleMaintenance.eventActive or spec == nil then 
			return; 
		end

		spec.WartezeitStunden = self.spec_ExtendedVehicleMaintenance.OriginalTimeBackup
		spec.WartezeitMinuten = 0
		spec.CurrentMinuteBackup = g_currentMission.hud.environment.currentMinute
		
		spec.WartungKnopfGedrueckt = true
		
		ExtendedVehicleMaintenance.eventActive = false
		ExtendedVehicleMaintenenanceEvent.sendEvent(self, spec.WartungKnopfGedrueckt, spec.CurrentMinuteBackup, spec.WartezeitStunden, spec.WartezeitMinuten, spec.OriginalTimeBackup, spec.CostsBackup, spec.DontAllowXmlNumberReset)

		spec.wartungsKosten = spec.wartungsKosten + self.spec_ExtendedVehicleMaintenance.CostsBackup
		spec.dirtyFlag = spec:getNextDirtyFlag()
    end
end;