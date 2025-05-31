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
			VE.elements.Checkbox(frame, 270, -80, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("EnergyManaTick")
		if module then
			VE.elements.Checkbox(frame, 270, -110, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("LowHealth")
		if module then
			VE.elements.Checkbox(frame, 270, -140, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("OutOfRange")
		if module then
			VE.elements.Checkbox(frame, 270, -170, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("MiniPlayerFrame")
		if module then
			VE.elements.Checkbox(frame, 270, -200, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("MiniPowerFrame")
		if module then
			VE.elements.Checkbox(frame, 270, -230, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("TrinketManager")
		if module then
			VE.elements.Checkbox(frame, 270, -260, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end


	do
		local module = VE.getModule("CombatCursor")
		if module then
			VE.elements.Checkbox(frame, 270, -290, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	-- Aura tracker

	do
		local module = VE.getModule("AuraTracker")
		if module then
			VE.elements.Checkbox(frame, 20, -350, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	VE.elements.InputArea(frame, 16, -375, 500, 40, "title", "tooltip description", nil, (VanillaEnhancedData["AuraTrackerUserAuars"] or ""), 200, function(text)
		VanillaEnhancedData["AuraTrackerUserAuars"] = text
	end)

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
