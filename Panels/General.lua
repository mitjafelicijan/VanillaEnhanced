VE.panels.General = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedGeneralFrame", parent)
	frame:SetAllPoints(parent)

	-- Left column

	VE.elements.Checkbox(frame, 20, -20, 140, STATUS_BAR_TEXT, OPTION_TOOLTIP_STATUS_BAR, nil, VE.GetCVarAsBoolean("statusBarText"), function(checked)
		VE.SetCVar("statusBarText", checked)
	end)

	VE.elements.Checkbox(frame, 20, -60, 140, USE_UBERTOOLTIPS, OPTION_TOOLTIP_USE_UBERTOOLTIPS, nil, VE.GetCVarAsBoolean("UberTooltips"), function(checked)
		VE.SetCVar("UberTooltips", checked)
	end)

	VE.elements.Checkbox(frame, 20, -90, 190, SHOW_TIPOFTHEDAY_TEXT, OPTION_TOOLTIP_SHOW_TIPOFTHEDAY, nil, VE.GetCVarAsBoolean("showGameTips"), function(checked)
		VE.SetCVar("showGameTips", checked)
	end)

	VE.elements.Checkbox(frame, 20, -120, 170, SHOW_NEWBIE_TIPS_TEXT, OPTION_TOOLTIP_SHOW_NEWBIE_TIPS, nil, VE.GetUVarAsBoolean("SHOW_NEWBIE_TIPS"), function(checked)
		VE.SetUVar("SHOW_NEWBIE_TIPS", checked)
	end)

	VE.elements.Checkbox(frame, 20, -150, 140, SHOW_CLOAK, OPTION_TOOLTIP_SHOW_CLOAK, nil, ShowingCloak(), function(checked)
		ShowCloak(checked)
	end)

	VE.elements.Checkbox(frame, 20, -180, 140, SHOW_HELM, OPTION_TOOLTIP_SHOW_HELM, nil, ShowingHelm(), function(checked)
		ShowHelm(checked)
	end)

	do
		local module = VE.getModule("MinimapClock")
		if module then
			VE.elements.Checkbox(frame, 20, -220, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("QuestLogEnhancements")
		if module then
			VE.elements.Checkbox(frame, 20, -250, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	-- Right column
	do
		local module = VE.getModule("ExtendedCommands")
		if module then
			VE.elements.Checkbox(frame, 270, -20, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end
	
	do
		local module = VE.getModule("ExtendedMacros")
		if module then
			VE.elements.Checkbox(frame, 270, -50, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("CompareTooltip")
		if module then
			VE.elements.Checkbox(frame, 270, -90, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("RestedXPTooltip")
		if module then
			VE.elements.Checkbox(frame, 270, -120, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("HideLuaErrors")
		if module then
			VE.elements.Checkbox(frame, 270, -150, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("BagSearch")
		if module then
			VE.elements.Checkbox(frame, 270, -190, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("FreeBagSlots")
		if module then
			VE.elements.Checkbox(frame, 270, -220, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("BankBags")
		if module then
			VE.elements.Checkbox(frame, 270, -250, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
