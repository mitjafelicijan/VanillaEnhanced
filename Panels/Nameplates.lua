VE.panels.Nameplates = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedNameplatesFrame", parent)
	frame:SetAllPoints(parent)

	-- Left column

	VE.elements.Checkbox(frame, 20, -20, 140, SHOW_PLAYER_NAMES, OPTION_TOOLTIP_SHOW_PLAYER_NAMES, nil, VE.GetCVarAsBoolean("UnitNamePlayer"), function(checked)
		VE.SetCVar("UnitNamePlayer", checked)
	end)

	VE.elements.Checkbox(frame, 40, -50, 140, SHOW_GUILD_NAMES, OPTION_TOOLTIP_SHOW_GUILD_NAMES, nil, VE.GetCVarAsBoolean("UnitNamePlayerGuild"), function(checked)
		VE.SetCVar("UnitNamePlayerGuild", checked)
	end)

	VE.elements.Checkbox(frame, 40, -80, 140, SHOW_PLAYER_TITLES, OPTION_TOOLTIP_SHOW_PLAYER_TITLES, nil, VE.GetCVarAsBoolean("UnitNamePlayerPVPTitle"), function(checked)
		VE.SetCVar("UnitNamePlayerPVPTitle", checked)
	end)

	VE.elements.Checkbox(frame, 20, -120, 140, SHOW_NPC_NAMES, OPTION_TOOLTIP_SHOW_NPC_NAMES, nil, VE.GetCVarAsBoolean("UnitNameNPC"), function(checked)
		VE.SetCVar("UnitNameNPC", checked)
	end)

	VE.elements.Checkbox(frame, 20, -150, 140, SHOW_OWN_NAME, OPTION_TOOLTIP_SHOW_OWN_NAME, nil, VE.GetCVarAsBoolean("UnitNameOwn"), function(checked)
		VE.SetCVar("UnitNameOwn", checked)
	end)

	do
		local module = VE.getModule("RaidTargetMarkers")
		if module then
			VE.elements.Checkbox(frame, 20, -190, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	-- Right column

	do
		local module = VE.getModule("NameplateScaling")
		if module then
			VE.elements.Checkbox(frame, 270, -20, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("NameplateComboPoints")
		if module then
			VE.elements.Checkbox(frame, 270, -50, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("NameplateThreat")
		if module then
			VE.elements.Checkbox(frame, 270, -80, 140, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
