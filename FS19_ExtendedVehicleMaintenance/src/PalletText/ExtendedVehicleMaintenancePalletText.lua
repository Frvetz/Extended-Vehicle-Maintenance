-- by Frvetz
-- Contact: ExtendedVehicleMaintenancePalletText@gmail.com
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

ExtendedVehicleMaintenancePalletText = {};
ExtendedVehicleMaintenancePalletText.l10nEnv = "FS19_ExtendedVehicleMaintenancePalletText";
ExtendedVehicleMaintenancePalletText.currentModDirectory = g_currentModDirectory;



function ExtendedVehicleMaintenancePalletText:update(dt)
	--[[if g_currentMission.environment.weather.environment ~= nil then
		SeasonsDays = g_currentMission.environment.weather.environment.daysPerSeason * 4
	else
		SeasonsDays = 36
	end;
	for id,rootNode in pairs(ExtendedVehicleMaintenance.rootNodePallet) do 
		if g_currentMission.nodeToObject[rootNode] ~= nil then
			local px, py, pz = getWorldTranslation(rootNode) -- Palette
			local vx, vy, vz = getWorldTranslation(g_currentMission.player.rootNode) -- Player
			local EVMnodeToObject = g_currentMission.nodeToObject[rootNode].spec_ExtendedVehicleMaintenance
			
			if MathUtil.vector3Length(px-vx, py-vy, pz-vz) < 2 then
				if g_currentMission.nodeToObject[rootNode].configurations.design == 1 then
					OriginalTime = 1				
					HoursToAdd = 3
					DaysToAdd = 1
				elseif g_currentMission.nodeToObject[rootNode].configurations.design == 2 then
					OriginalTime = 4
					HoursToAdd = 9
					DaysToAdd = ExtendedVehicleMaintenance:RoundValue(SeasonsDays / 7,2)
				elseif g_currentMission.nodeToObject[rootNode].configurations.design == 3 then
					OriginalTime = 8
					HoursToAdd = 18
					DaysToAdd = ExtendedVehicleMaintenance:RoundValue(SeasonsDays / 3)
				elseif g_currentMission.nodeToObject[rootNode].configurations.design == 4 then
					OriginalTime = 24
					HoursToAdd = 35
					DaysToAdd = SeasonsDays
				elseif g_currentMission.nodeToObject[rootNode].configurations.design == 5 then
					OriginalTime = 48
					HoursToAdd = 48
					DaysToAdd = SeasonsDays / 0.6
				end
				if (OriginalTime and HoursToAdd and DaysToAdd) ~= nil then
					--g_currentMission:addExtraPrintText(g_i18n:getText("information_pallet", ExtendedVehicleMaintenancePalletText.l10nEnv):format(OriginalTime, HoursToAdd, DaysToAdd))
				end
			end
		end
	end--]]
end

function ExtendedVehicleMaintenancePalletText:loadMap(name)
    self.IconProposal = Overlay:new(Utils.getFilename("icons/proposal.dds", ExtendedVehicleMaintenancePalletText.currentModDirectory), 1, 1, 0.035, 0.06);
    self.IconPlus = Overlay:new(Utils.getFilename("icons/plus.dds", ExtendedVehicleMaintenancePalletText.currentModDirectory), 1, 1, 0.014, 0.025);
    self.IconTime = Overlay:new(Utils.getFilename("icons/time.dds", ExtendedVehicleMaintenancePalletText.currentModDirectory), 1, 1, 0.014, 0.025);
	
	self.allowFarmColor = true;
end;

function ExtendedVehicleMaintenancePalletText:draw()
	if g_currentMission.environment.weather.environment ~= nil then
		SeasonsDays = g_currentMission.environment.weather.environment.daysPerSeason * 4
	else
		SeasonsDays = 36
	end;
	for id,rootNode in pairs(ExtendedVehicleMaintenance.rootNodePallet) do 
		if g_currentMission.nodeToObject[rootNode] ~= nil then
			px, py, pz = getWorldTranslation(rootNode) -- Palette
			vx, vy, vz = getWorldTranslation(g_currentMission.player.rootNode) -- Player
			rx, ry, ry = getRotation(g_currentMission.player.rootNode) -- Player
			pz = pz + 0.555
			py = py + 1.35
			
			EVMnodeToObject = g_currentMission.nodeToObject[rootNode].spec_ExtendedVehicleMaintenance
			
			local objectFarm = g_farmManager:getFarmById(g_currentMission.nodeToObject[rootNode]:getOwnerFarmId());
			
			if MathUtil.vector3Length(px-vx, py-vy, pz-vz) < 4 then
				if g_currentMission.nodeToObject[rootNode].configurations.design == 1 then
					EVMnodeToObject.PalletOriginalTime = 1				
					EVMnodeToObject.PalletHoursToAdd = 3
					EVMnodeToObject.PalletDaysToAdd = 1
				elseif g_currentMission.nodeToObject[rootNode].configurations.design == 2 then
					EVMnodeToObject.PalletOriginalTime = 4
					EVMnodeToObject.PalletHoursToAdd = 9
					EVMnodeToObject.PalletDaysToAdd = ExtendedVehicleMaintenance:RoundValue(SeasonsDays / 7,2)
				elseif g_currentMission.nodeToObject[rootNode].configurations.design == 3 then
					EVMnodeToObject.PalletOriginalTime = 8
					EVMnodeToObject.PalletHoursToAdd = 18
					EVMnodeToObject.PalletDaysToAdd = ExtendedVehicleMaintenance:RoundValue(SeasonsDays / 3)
				elseif g_currentMission.nodeToObject[rootNode].configurations.design == 4 then
					EVMnodeToObject.PalletOriginalTime = 24
					EVMnodeToObject.PalletHoursToAdd = 35
					EVMnodeToObject.PalletDaysToAdd = SeasonsDays
				elseif g_currentMission.nodeToObject[rootNode].configurations.design == 5 then
					EVMnodeToObject.PalletOriginalTime = 48
					EVMnodeToObject.PalletHoursToAdd = 48
					EVMnodeToObject.PalletDaysToAdd = SeasonsDays / 0.6
				end
				if (EVMnodeToObject.PalletOriginalTime and EVMnodeToObject.PalletHoursToAdd and EVMnodeToObject.PalletDaysToAdd) ~= nil then
					local sx, sy, sz = project(px, py, pz);
					
					local farmColor = ExtendedVehicleMaintenancePalletText.getColorForFarm(objectFarm, self.allowFarmColor);
					
					if sx <= 1 and sx >= 0 and sy <= 1 and sy >= 0 and sz <= 1 and sz >= 0 then
						ExtendedVehicleMaintenancePalletText.renderPalletText(sx, sy, (g_i18n:getText("information_palletLength", ExtendedVehicleMaintenancePalletText.l10nEnv):format(EVMnodeToObject.PalletOriginalTime)) .. "\n" .. "\n" .. "\n" .. (g_i18n:getText("information_palletOperatingHours", ExtendedVehicleMaintenancePalletText.l10nEnv):format(EVMnodeToObject.PalletHoursToAdd)) .. "\n" .. "\n" .. "\n" .. (g_i18n:getText("information_palletDays", ExtendedVehicleMaintenancePalletText.l10nEnv):format(EVMnodeToObject.PalletDaysToAdd)), getCorrectTextSize(0.01235), 0.13, farmColor);
						ExtendedVehicleMaintenancePalletText.renderIcons(self.IconProposal,      {1, 1, 1, 0.87}, sx + 0.02, sy + 0.2);
						ExtendedVehicleMaintenancePalletText.renderIcons(self.IconTime, 	 {1, 1, 1, 0.87}, sx - 0.02, sy + 0.124);
						ExtendedVehicleMaintenancePalletText.renderIcons(self.IconPlus,      {1, 1, 1, 0.87}, sx - 0.02, sy + 0.083);
						ExtendedVehicleMaintenancePalletText.renderIcons(self.IconPlus,      {1, 1, 1, 0.87}, sx - 0.02, sy + 0.042);
					end
				end
			end
		end
	end
end

function ExtendedVehicleMaintenancePalletText.renderPalletText(x, y, text, textSize, textOffset, farmColor)
    setTextAlignment(RenderText.ALIGN_LEFT);
    setTextBold(true);
    setTextColor(0, 0, 0, 1);
    renderText(x, y - 0.0018 + textOffset, textSize, text);
        
    setTextColor(unpack(farmColor));
    renderText(x, y + textOffset, textSize, text);

    setTextColor(1, 1, 1, 1);
    setTextAlignment(RenderText.ALIGN_LEFT);
end;

function ExtendedVehicleMaintenancePalletText.renderIcons(icon, iconColor, x, y)
    icon:setColor(unpack(iconColor));
    icon:setPosition(x, y)
    icon:render();
end;

function ExtendedVehicleMaintenancePalletText.getColorForFarm(farmId, allowFarmColor)
    if farmId ~= nil and allowFarmColor then
        local colorTable = Farm.COLORS[farmId.color];
        
        if colorTable ~= nil then
            return colorTable;
        end;
    end;

    return {1, 1, 1, 1};
end;
addModEventListener(ExtendedVehicleMaintenancePalletText)