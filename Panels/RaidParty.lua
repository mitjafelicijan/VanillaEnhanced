VE.panels.RaidParty = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedRaidPartyFrame", parent)
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

	do
		local module = VE.getModule("CompactFrames")
		if module then
			VE.elements.Checkbox(frame, 20, -180, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	VE.elements.DropDown(frame, 50, -210, 160, nil, VanillaEnhancedOptions["CompactFramesAuras"], {
		{ key = 0, text = "No Auras on Unit Frames", tooltip = "Do not show auras" },
		{ key = 1, text = "Show Only Buffs", tooltip = "Show only party buffs" },
		{ key = 2, text = "Show Only Debuffs", tooltip = "Show only party debuffs" },
		{ key = 3, text = "Show Only HOT's", tooltip = "Show only party HOT's" },
	}, function(key)
		VanillaEnhancedOptions["CompactFramesAuras"] = key
	end)

	do
		local option = VE.getOption("CompactFramesShowPets")
		VE.elements.Checkbox(frame, 50, -245, 140, option.meta.label, option.meta.description, nil, option.enabled, function(checked)
			if checked then VE.enableOption(option.identifier) else VE.disableOption(option.identifier) end
		end, option.superWoWRequired)
	end

	do
		local option = VE.getOption("CompactFramesShowFocusFrames")
		VE.elements.Checkbox(frame, 50, -275, 140, option.meta.label, option.meta.description, nil, option.enabled, function(checked)
			if checked then VE.enableOption(option.identifier) else VE.disableOption(option.identifier) end
		end, option.superWoWRequired)
	end
	
	do
		local module = VE.getModule("RaidTargetMarkers")
		if module then
			VE.elements.Checkbox(frame, 20, -310, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	-- Right column

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
