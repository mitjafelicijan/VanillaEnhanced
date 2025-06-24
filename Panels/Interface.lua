VE.panels.Interface = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedInterfaceFrame", parent)
	frame:SetAllPoints(parent)

	-- Left column

	VE.elements.Checkbox(frame, 20, -20, 120, SHOW_BUFF_DURATION_TEXT, OPTION_TOOLTIP_SHOW_BUFF_DURATION, nil, VE.GetUVarAsBoolean("SHOW_BUFF_DURATIONS"), function(checked)
		VE.SetUVar("SHOW_BUFF_DURATIONS", checked)
	end)

	do
		local module = VE.getModule("MinimapClock")
		if module then
			VE.elements.Checkbox(frame, 20, -50, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("ManaBarColor")
		if module then
			VE.elements.Checkbox(frame, 20, -80, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("CastingBarPosition")
		if module then
			VE.elements.Checkbox(frame, 20, -120, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("TargetCastingBar")
		if module then
			VE.elements.Checkbox(frame, 20, -150, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("LastMessageOnly")
		if module then
			VE.elements.Checkbox(frame, 20, -190, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("AutoLoot")
		if module then
			VE.elements.Checkbox(frame, 20, -220, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("HideEBC")
		if module then
			VE.elements.Checkbox(frame, 20, -260, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("HideLFT")
		if module then
			VE.elements.Checkbox(frame, 20, -290, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("HideBGF")
		if module then
			VE.elements.Checkbox(frame, 20, -320, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("BigPlayerFrame")
		VE.elements.Checkbox(frame, 20, -360, 140, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
			if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
		end, module.superWoWRequired)
	end

	do
		local option = VE.getOption("BigPlayerFrameClassColors")
		VE.elements.Checkbox(frame, 40, -390, 140, option.meta.label, option.meta.description, nil, option.enabled, function(checked)
			if checked then VE.enableOption(option.identifier) else VE.disableOption(option.identifier) end
		end, option.superWoWRequired)
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
		local module = VE.getModule("DruidManaBar")
		if module then
			VE.elements.Checkbox(frame, 270, -90, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("EnergyManaTick")
		if module then
			VE.elements.Checkbox(frame, 270, -120, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("TrinketManager")
		if module then
			VE.elements.Checkbox(frame, 270, -150, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("OutOfRange")
		if module then
			VE.elements.Checkbox(frame, 270, -180, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("MiniPlayerFrame")
		if module then
			VE.elements.Checkbox(frame, 270, -220, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("MiniPowerFrame")
		if module then
			VE.elements.Checkbox(frame, 270, -250, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("BulletinBoard")
		if module then
			VE.elements.Checkbox(frame, 270, -290, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("ItemLevel")
		if module then
			VE.elements.Checkbox(frame, 270, -320, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("MaxAuraButtons")
		if module then
			VE.elements.Checkbox(frame, 270, -360, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
