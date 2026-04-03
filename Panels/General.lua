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
		local module = VE.getModule("QuestTracker")
		if module then
			VE.elements.Checkbox(frame, 20, -260, 170, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)

			local option = VE.getOption("QuestTrackerShowTrivial")
			if option then
				VE.elements.Checkbox(frame, 40, -290, 170, option.meta.label, option.meta.label, option.meta.description, option.enabled, function(checked)
					if checked then VE.enableOption(option.identifier) else VE.disableOption(option.identifier) end
					if option.callback then option.callback(checked) end
				end, option.superWoWRequired)
			end

			local option = VE.getOption("QuestTrackerShowEvents")
			if option then
				VE.elements.Checkbox(frame, 40, -320, 170, option.meta.label, option.meta.label, option.meta.description, option.enabled, function(checked)
					if checked then VE.enableOption(option.identifier) else VE.disableOption(option.identifier) end
					if option.callback then option.callback(checked) end
				end, option.superWoWRequired)
			end

			local option = VE.getOption("QuestTrackerShowPvP")
			if option then
				VE.elements.Checkbox(frame, 40, -350, 170, option.meta.label, option.meta.label, option.meta.description, option.enabled, function(checked)
					if checked then VE.enableOption(option.identifier) else VE.disableOption(option.identifier) end
					if option.callback then option.callback(checked) end
				end, option.superWoWRequired)
			end

			local option = VE.getOption("QuestTrackerShowTooltips")
			if option then
				VE.elements.Checkbox(frame, 40, -380, 170, option.meta.label, option.meta.label, option.meta.description, option.enabled, function(checked)
					if checked then VE.enableOption(option.identifier) else VE.disableOption(option.identifier) end
					if option.callback then option.callback(checked) end
				end, option.superWoWRequired)
			end
		end
	end

	-- Right column

	do
		local module = VE.getModule("HideEBC")
		if module then
			VE.elements.Checkbox(frame, 270, -20, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("HideLFT")
		if module then
			VE.elements.Checkbox(frame, 270, -50, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("HideBGF")
		if module then
			VE.elements.Checkbox(frame, 270, -80, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("ExtendedCommands")
		if module then
			VE.elements.Checkbox(frame, 270, -120, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end
	
	do
		local module = VE.getModule("ExtendedMacros")
		if module then
			VE.elements.Checkbox(frame, 270, -150, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
