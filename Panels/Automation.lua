VE.panels.Automation = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedAutomationFrame", parent)
	frame:SetAllPoints(parent)
	
	-- Left column

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

	do
		local module = VE.getModule("LootAtCursor")
		if module then
			VE.elements.Checkbox(frame, 20, -90, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("AutoLoot")
		if module then
			VE.elements.Checkbox(frame, 20, -120, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	-- Right column

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
			VE.elements.Checkbox(frame, 20, -160, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)

			local yStart = -190
			local yOffset = 50
			
			-- Left Column
			VE.elements.DropDown(frame, 20, yStart, 160, "Green Items", module.config.options.Green or false, rollOptions, function(key)
				module.config.options.Green = key
				if not VanillaEnhancedData["AutoRoll"] then VanillaEnhancedData["AutoRoll"] = {} end
				VanillaEnhancedData["AutoRoll"].Green = key
			end, module.superWoWRequired)

			VE.elements.DropDown(frame, 20, yStart - yOffset, 160, "Zul'Gurub (Coin, Bijou)", module.config.options.ZG or false, rollOptions, function(key)
				module.config.options.ZG = key
				if not VanillaEnhancedData["AutoRoll"] then VanillaEnhancedData["AutoRoll"] = {} end
				VanillaEnhancedData["AutoRoll"].ZG = key
			end, module.superWoWRequired)

			-- Right Column
			VE.elements.DropDown(frame, 270, yStart, 160, "Molten Core", module.config.options.MC or false, rollOptions, function(key)
				module.config.options.MC = key
				if not VanillaEnhancedData["AutoRoll"] then VanillaEnhancedData["AutoRoll"] = {} end
				VanillaEnhancedData["AutoRoll"].MC = key
			end, module.superWoWRequired)

			VE.elements.DropDown(frame, 270, yStart - yOffset, 160, "Ahn'Qiraj (Idols, Scarabs)", module.config.options.AQ or false, rollOptions, function(key)
				module.config.options.AQ = key
				if not VanillaEnhancedData["AutoRoll"] then VanillaEnhancedData["AutoRoll"] = {} end
				VanillaEnhancedData["AutoRoll"].AQ = key
			end, module.superWoWRequired)
		end
	end

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
