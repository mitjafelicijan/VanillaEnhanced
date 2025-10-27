VE.panels.Controls = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedControlsFrame", parent)
	frame:SetAllPoints(parent)

	-- Left column

	VE.elements.Checkbox(frame, 20, -20, 140, INVERT_MOUSE, OPTION_TOOLTIP_INVERT_MOUSE, nil, VE.GetCVarAsBoolean("mouseInvertPitch"), function(checked)
		VE.SetCVar("mouseInvertPitch", checked)
	end)

	VE.elements.Checkbox(frame, 20, -50, 140, GAMEFIELD_DESELECT_TEXT, OPTION_TOOLTIP_GAMEFIELD_DESELECT, nil, not VE.GetCVarAsBoolean("deselectOnClick"), function(checked)
		VE.SetCVar("deselectOnClick", not checked)
	end)

	VE.elements.Checkbox(frame, 20, -80, 140, ASSIST_ATTACK, OPTION_TOOLTIP_ASSIST_ATTACK, nil, VE.GetCVarAsBoolean("assistAttack"), function(checked)
		VE.SetCVar("assistAttack", checked)
	end)

	VE.elements.Checkbox(frame, 20, -110, 140, CLEAR_AFK, OPTION_TOOLTIP_CLEAR_AFK, nil, VE.GetCVarAsBoolean("autoClearAFK"), function(checked)
		VE.SetCVar("autoClearAFK", checked)
	end)

	VE.elements.Checkbox(frame, 20, -140, 140, AUTO_SELF_CAST_TEXT, OPTION_TOOLTIP_AUTO_SELF_CAST, nil, VE.GetCVarAsBoolean("autoSelfCast"), function(checked)
		VE.SetCVar("autoSelfCast", checked)
	end)

	VE.elements.Checkbox(frame, 20, -170, 210, LOOT_AT_WINDOW_CURSOR_TEXT, OPTION_TOOLTIP_LOOT_AT_WINDOW_CURSOR, nil, VE.GetUVarAsBoolean("LOOT_WINDOW_AT_CURSOR"), function(checked)
		VE.SetUVar("LOOT_WINDOW_AT_CURSOR", checked)
	end)

	VE.elements.Slider(frame, 20, -220, 200, MOUSE_SENSITIVITY, OPTION_TOOLTIP_MOUSE_SENSITIVITY, nil, 0.5, 1.5, 0.1, VE.GetCVarAsNumber("mouseSpeed"), function(value)
		VE.SetCVar("mouseSpeed", value)
	end)

	do
		local module = VE.getModule("MaintainDruidForms")
		if module then
			VE.elements.Checkbox(frame, 20, -290, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("MaintainHunterAspects")
		if module then
			VE.elements.Checkbox(frame, 20, -320, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	-- Right column

	do
		local module = VE.getModule("AlignGrid")
		if module then
			VE.elements.Checkbox(frame, 270, -20, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("AutoRepair")
		if module then
			VE.elements.Checkbox(frame, 270, -50, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("AutoSell")
		if module then
			VE.elements.Checkbox(frame, 270, -80, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("BagSearch")
		if module then
			VE.elements.Checkbox(frame, 270, -120, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("FreeBagSlots")
		if module then
			VE.elements.Checkbox(frame, 270, -150, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("BankBags")
		if module then
			VE.elements.Checkbox(frame, 270, -180, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("TravelJournal")
		if module then
			VE.elements.Checkbox(frame, 270, -220, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("ExtendedCommands")
		if module then
			VE.elements.Checkbox(frame, 270, -250, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("AutoDismount")
		if module then
			VE.elements.Checkbox(frame, 270, -280, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
