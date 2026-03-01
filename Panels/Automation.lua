VE.panels.Automation = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedAutomationFrame", parent)
	frame:SetAllPoints(parent)
	
	-- Left

	do
		local module = VE.getModule("AutoDismount")
		if module then
			VE.elements.Checkbox(frame, 20, -20, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("AutoCancelForm")
		if module then
			VE.elements.Checkbox(frame, 20, -50, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	-- Right

	do
		local module = VE.getModule("AutoRepair")
		if module then
			VE.elements.Checkbox(frame, 270, -20, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("AutoSell")
		if module then
			VE.elements.Checkbox(frame, 270, -50, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	-- Auto Roll
	do
		local module = VE.getModule("AutoRoll")
		if module then
			local rollOptions = {
				{ text = "Disabled", key = false },
				{ text = "Need", key = 1 },
				{ text = "Greed", key = 2 },
				{ text = "Pass", key = 0 },
			}
			
			-- Enable/Disable master switch
			VE.elements.Checkbox(frame, 20, -100, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)

			local yStart = -130
			local yOffset = 50
			
			-- Left Column
			VE.elements.DropDown(frame, 20, yStart, 150, "Green Items", module.config.Green or false, rollOptions, function(key)
				module.config.Green = key
				if not VanillaEnhancedData["AutoRoll"] then VanillaEnhancedData["AutoRoll"] = {} end
				VanillaEnhancedData["AutoRoll"].Green = key
			end, module.superWoWRequired)

			VE.elements.DropDown(frame, 20, yStart - yOffset, 150, "Zul'Gurub", module.config.ZG or false, rollOptions, function(key)
				module.config.ZG = key
				if not VanillaEnhancedData["AutoRoll"] then VanillaEnhancedData["AutoRoll"] = {} end
				VanillaEnhancedData["AutoRoll"].ZG = key
			end, module.superWoWRequired)

			VE.elements.DropDown(frame, 20, yStart - (yOffset * 2), 150, "Molten Core", module.config.MC or false, rollOptions, function(key)
				module.config.MC = key
				if not VanillaEnhancedData["AutoRoll"] then VanillaEnhancedData["AutoRoll"] = {} end
				VanillaEnhancedData["AutoRoll"].MC = key
			end, module.superWoWRequired)

			VE.elements.DropDown(frame, 20, yStart - (yOffset * 3), 150, "Ahn'Qiraj", module.config.AQ or false, rollOptions, function(key)
				module.config.AQ = key
				if not VanillaEnhancedData["AutoRoll"] then VanillaEnhancedData["AutoRoll"] = {} end
				VanillaEnhancedData["AutoRoll"].AQ = key
			end, module.superWoWRequired)

			-- Right Column
			VE.elements.DropDown(frame, 270, yStart, 150, "Corrupted Sand", module.config.Sand or false, rollOptions, function(key)
				module.config.Sand = key
				if not VanillaEnhancedData["AutoRoll"] then VanillaEnhancedData["AutoRoll"] = {} end
				VanillaEnhancedData["AutoRoll"].Sand = key
			end, module.superWoWRequired)

			VE.elements.DropDown(frame, 270, yStart - yOffset, 150, "Emerald Sanctum", module.config.ES or false, rollOptions, function(key)
				module.config.ES = key
				if not VanillaEnhancedData["AutoRoll"] then VanillaEnhancedData["AutoRoll"] = {} end
				VanillaEnhancedData["AutoRoll"].ES = key
			end, module.superWoWRequired)

			VE.elements.DropDown(frame, 270, yStart - (yOffset * 2), 150, "Naxxramas", module.config.Naxx or false, rollOptions, function(key)
				module.config.Naxx = key
				if not VanillaEnhancedData["AutoRoll"] then VanillaEnhancedData["AutoRoll"] = {} end
				VanillaEnhancedData["AutoRoll"].Naxx = key
			end, module.superWoWRequired)
		end
	end

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
