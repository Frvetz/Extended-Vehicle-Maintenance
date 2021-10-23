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



-- THANKS YOU FOR THE REGISTER.LUA IAN!

registerExtendedVehicleMaintenance = {}
registerExtendedVehicleMaintenance.specName = "ExtendedVehicleMaintenance"
registerExtendedVehicleMaintenance.className = "ExtendedVehicleMaintenance"
registerExtendedVehicleMaintenance.fileName = g_currentModDirectory.."ExtendedVehicleMaintenance.lua"

function registerExtendedVehicleMaintenance:registerSpecialization()

	local specName = registerExtendedVehicleMaintenance.specName

	if g_specializationManager:getSpecializationByName(specName) == nil then
		g_specializationManager:addSpecialization(registerExtendedVehicleMaintenance.specName, registerExtendedVehicleMaintenance.className, registerExtendedVehicleMaintenance.fileName, true, nil)

		for vehicleType, vehicle in pairs(g_vehicleTypeManager.vehicleTypes) do

			if vehicle ~= nil and vehicleType ~= "locomotive" and vehicleType ~= "ConveyorBelt" and vehicleType ~= "woodCrusherTrailerDrivable" then

				local isDrivable = false;
				local hasTBO = false;
				local hasNotEVM = true;

				for name, spec in pairs(vehicle.specializationsByName) do

					if name == "drivable" then
						isDrivable = true;
					elseif name == "tensionBeltObject" then
						hasTBO = true;
					elseif name == "ExtendedVehicleMaintenance" then
						hasNotEVM = false;
					end
				end

				if hasNotEVM and isDrivable or hasTBO then
					print("  adding ExtendedVehicleMaintenance to vehicleType '"..tostring(vehicleType).."'")

					local specObject = g_specializationManager:getSpecializationObjectByName(specName);

					vehicle.specializationsByName[specName] = specObject;
					table.insert(vehicle.specializationNames, specName);
					table.insert(vehicle.specializations, specObject);
				end
			end
		end
	end
end
registerExtendedVehicleMaintenance:registerSpecialization()

-- make localizations available
local i18nTable = getfenv(0).g_i18n
for l18nId,l18nText in pairs(g_i18n.texts) do
  i18nTable:setText(l18nId, l18nText)
end