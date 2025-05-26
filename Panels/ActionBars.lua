local function UpdateActionBars()
	SetActionBarToggles(SHOW_MULTI_ACTIONBAR_1, SHOW_MULTI_ACTIONBAR_2, SHOW_MULTI_ACTIONBAR_3, SHOW_MULTI_ACTIONBAR_4, ALWAYS_SHOW_MULTIBARS)
	-- MultiActionBar_Update() -- XXX: This messes up some operations but it does apply changes without reloading.
end

VE.panels.ActionBars = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedActionBarsFrame", parent)
	frame:SetAllPoints(parent)

	LOCK_ACTIONBAR = VE.GetUVarAsString("LOCK_ACTIONBAR") or "0" -- Strange hack, must be provided as string.
	UpdateActionBars()

	-- Left column

	VE.elements.Checkbox(frame, 20, -20, 210, LOCK_ACTIONBAR_TEXT, OPTION_TOOLTIP_LOCK_ACTIONBAR, nil, VE.GetUVarAsBoolean("LOCK_ACTIONBAR"), function(checked)
		LOCK_ACTIONBAR = VE.BoolToNumber(checked)
	end)

	VE.elements.Checkbox(frame, 20, -50, 210, ALWAYS_SHOW_MULTIBARS_TEXT, OPTION_TOOLTIP_ALWAYS_SHOW_MULTIBARS, nil, VE.GetUVarAsBoolean("ALWAYS_SHOW_MULTIBARS"), function(checked)
		ALWAYS_SHOW_MULTIBARS = VE.BoolToNumber(checked)
	end)

	VE.elements.Checkbox(frame, 20, -90, 210, SHOW_MULTIBAR1_TEXT, OPTION_TOOLTIP_SHOW_MULTIBAR1, nil, SHOW_MULTI_ACTIONBAR_1, function(checked)
		SHOW_MULTI_ACTIONBAR_1 = checked
		UpdateActionBars()
	end)

	VE.elements.Checkbox(frame, 20, -120, 210, SHOW_MULTIBAR2_TEXT, OPTION_TOOLTIP_SHOW_MULTIBAR2, nil, SHOW_MULTI_ACTIONBAR_2, function(checked)
		SHOW_MULTI_ACTIONBAR_2 = checked
		UpdateActionBars()
	end)

	VE.elements.Checkbox(frame, 20, -150, 210, SHOW_MULTIBAR3_TEXT, OPTION_TOOLTIP_SHOW_MULTIBAR3, nil, SHOW_MULTI_ACTIONBAR_3, function(checked)
		SHOW_MULTI_ACTIONBAR_3 = checked
		UpdateActionBars()
	end)

	VE.elements.Checkbox(frame, 20, -180, 210, SHOW_MULTIBAR4_TEXT, OPTION_TOOLTIP_SHOW_MULTIBAR4, nil, SHOW_MULTI_ACTIONBAR_4, function(checked)
		SHOW_MULTI_ACTIONBAR_4 = checked
		UpdateActionBars()
	end)

	do
		local module = VE.getModule("CooldownTimers")
		if module then
			VE.elements.Checkbox(frame, 20, -220, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
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
