VE.panels.UnitFrames = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedUnitFramesFrame", parent)
	frame:SetAllPoints(parent)

	-- Left column
	VE.elements.Checkbox(frame, 20, -20, 120, SHOW_BUFF_DURATION_TEXT, OPTION_TOOLTIP_SHOW_BUFF_DURATION, nil, VE.GetUVarAsBoolean("SHOW_BUFF_DURATIONS"), function(checked)
		VE.SetUVar("SHOW_BUFF_DURATIONS", checked)
	end)

	do
		local module = VE.getModule("ClassPortraits")
		if module then
			VE.elements.Checkbox(frame, 20, -60, 140, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("BigPlayerFrame")
		if module then
			VE.elements.Checkbox(frame, 20, -100, 140, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)

			local option = VE.getOption("BigPlayerFrameClassColors")
			if option then
				VE.elements.Checkbox(frame, 40, -130, 140, option.meta.label, option.meta.description, nil, option.enabled, function(checked)
					if checked then VE.enableOption(option.identifier) else VE.disableOption(option.identifier) end
				end, option.superWoWRequired)
			end
		end
	end

	do
		local module = VE.getModule("ManaBarColor")
		if module then
			VE.elements.Checkbox(frame, 20, -170, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("DruidManaBar")
		if module then
			VE.elements.Checkbox(frame, 20, -200, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("EnergyManaTick")
		if module then
			VE.elements.Checkbox(frame, 20, -230, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("MiniPlayerFrame")
		if module then
			VE.elements.Checkbox(frame, 20, -270, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("MiniPowerFrame")
		if module then
			VE.elements.Checkbox(frame, 20, -300, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	-- Right column
	VE.elements.Checkbox(frame, 270, -20, 210, SHOW_TARGET_OF_TARGET_TEXT, OPTION_TOOLTIP_SHOW_TARGET_OF_TARGET, nil, VE.GetUVarAsBoolean("SHOW_TARGET_OF_TARGET"), function(checked)
		VE.SetUVar("SHOW_TARGET_OF_TARGET", checked)
	end)

	VE.elements.DropDown(frame, 300, -50, 160, nil, VE.GetUVarAsNumber("SHOW_TARGET_OF_TARGET_STATE"), {
		{ key = 1, text = RAID, tooltip = nil },
		{ key = 2, text = PARTY, tooltip = nil },
		{ key = 3, text = SOLO, tooltip = nil },
		{ key = 4, text = RAID_AND_PARTY, tooltip = nil },
		{ key = 5, text = ALWAYS, tooltip = nil },
	}, function(key)
		VE.SetUVar("SHOW_TARGET_OF_TARGET_STATE", key)
	end)

	do
		local module = VE.getModule("CastingBarPosition")
		if module then
			VE.elements.Checkbox(frame, 270, -100, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("TargetCastingBar")
		if module then
			VE.elements.Checkbox(frame, 270, -130, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
