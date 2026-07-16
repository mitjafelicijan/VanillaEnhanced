VE.panels.RaidFrames = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedRaidFramesFrame", parent)
	frame:SetAllPoints(parent)

	-- Left column

	VE.elements.Checkbox(frame, 20, -20, 210, HIDE_PARTY_INTERFACE_TEXT, OPTION_TOOLTIP_HIDE_PARTY_INTERFACE, nil, VE.GetUVarAsBoolean("HIDE_PARTY_INTERFACE"), function(checked)
		VE.SetUVar("HIDE_PARTY_INTERFACE", checked)
	end)

	VE.elements.Checkbox(frame, 20, -50, 210, SHOW_PARTY_BACKGROUND_TEXT, OPTION_TOOLTIP_SHOW_PARTY_BACKGROUND, nil, VE.GetUVarAsBoolean("SHOW_PARTY_BACKGROUND"), function(checked)
		VE.SetUVar("SHOW_PARTY_BACKGROUND", checked)
	end)

	VE.elements.Checkbox(frame, 20, -80, 210, SHOW_PARTY_PETS_TEXT, OPTION_TOOLTIP_SHOW_PARTY_PETS, nil, VE.GetUVarAsBoolean("SHOW_PARTY_PETS"), function(checked)
		VE.SetUVar("SHOW_PARTY_PETS", checked)
	end)

	VE.elements.Checkbox(frame, 20, -110, 210, SHOW_DISPELLABLE_DEBUFFS_TEXT, OPTION_TOOLTIP_SHOW_DISPELLABLE_DEBUFFS, nil, VE.GetUVarAsBoolean("SHOW_DISPELLABLE_DEBUFFS"), function(checked)
		VE.SetUVar("SHOW_DISPELLABLE_DEBUFFS", checked)
	end)

	VE.elements.Checkbox(frame, 20, -140, 210, SHOW_CASTABLE_BUFFS_TEXT, OPTION_TOOLTIP_SHOW_CASTABLE_BUFFS, nil, VE.GetUVarAsBoolean("SHOW_CASTABLE_BUFFS"), function(checked)
		VE.SetUVar("SHOW_CASTABLE_BUFFS", checked)
	end)

	if not VanillaEnhancedOptions["CompactFramesUnitWidth"] then VanillaEnhancedOptions["CompactFramesUnitWidth"] = 76 end
	if not VanillaEnhancedOptions["CompactFramesUnitHeight"] then VanillaEnhancedOptions["CompactFramesUnitHeight"] = 38 end

	-- Right column

	do
		local module = VE.getModule("RaidTargetMarkers")
		if module then
			VE.elements.Checkbox(frame, 270, -20, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("CompactFrames")
		if module then
			VE.elements.Checkbox(frame, 270, -60, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)

			local showPets = VE.getOption("CompactFramesShowPets")
			if showPets then
				VE.elements.Checkbox(frame, 290, -90, 200, showPets.meta.label, showPets.meta.description, nil, showPets.enabled, function(checked)
					if checked then VE.enableOption(showPets.identifier) else VE.disableOption(showPets.identifier) end
				end, showPets.superWoWRequired)
			end

			local showFocus = VE.getOption("CompactFramesShowFocusFrames")
			if showFocus then
				VE.elements.Checkbox(frame, 290, -120, 200, showFocus.meta.label, showFocus.meta.description, nil, showFocus.enabled, function(checked)
					if checked then VE.enableOption(showFocus.identifier) else VE.disableOption(showFocus.identifier) end
				end, showFocus.superWoWRequired)
			end

			VE.elements.DropDown(frame, 300, -150, 160, "Display Auras", VanillaEnhancedOptions["CompactFramesAuras"], {
				{ key = 0, text = "None", tooltip = nil },
				{ key = 1, text = "Buffs", tooltip = nil },
				{ key = 2, text = "Debuffs", tooltip = nil },
				{ key = 3, text = "HOTs", tooltip = nil },
			}, function(key)
				VanillaEnhancedOptions["CompactFramesAuras"] = key
			end)

			local widthSlider
			widthSlider = VE.elements.Slider(frame, 270, -220, 200, "Unit Frame Width [76]", nil, nil, 60, 150, 1, VanillaEnhancedOptions["CompactFramesUnitWidth"], function(val)
				VanillaEnhancedOptions["CompactFramesUnitWidth"] = val
			end)

			local heightSlider
			heightSlider = VE.elements.Slider(frame, 270, -270, 200, "Unit Frame Height [38]", nil, nil, 25, 80, 1, VanillaEnhancedOptions["CompactFramesUnitHeight"], function(val)
				VanillaEnhancedOptions["CompactFramesUnitHeight"] = val
			end)
		end
	end

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
