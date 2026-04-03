VE.panels.Display = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedDisplayFrame", parent)
	frame:SetAllPoints(parent)

	-- Left column

	VE.elements.Checkbox(frame, 20, -20, 140, STATUS_BAR_TEXT, OPTION_TOOLTIP_STATUS_BAR, nil, VE.GetCVarAsBoolean("statusBarText"), function(checked)
		VE.SetCVar("statusBarText", checked)
	end)

	VE.elements.Checkbox(frame, 20, -60, 140, SHOW_PLAYER_NAMES, OPTION_TOOLTIP_SHOW_PLAYER_NAMES, nil, VE.GetCVarAsBoolean("UnitNamePlayer"), function(checked)
		VE.SetCVar("UnitNamePlayer", checked)
	end)

	VE.elements.Checkbox(frame, 40, -90, 140, SHOW_GUILD_NAMES, OPTION_TOOLTIP_SHOW_GUILD_NAMES, nil, VE.GetCVarAsBoolean("UnitNamePlayerGuild"), function(checked)
		VE.SetCVar("UnitNamePlayer", checked)
	end)

	VE.elements.Checkbox(frame, 40, -120, 140, SHOW_PLAYER_TITLES, OPTION_TOOLTIP_SHOW_PLAYER_TITLES, nil, VE.GetCVarAsBoolean("UnitNamePlayerPVPTitle"), function(checked)
		VE.SetCVar("UnitNamePlayerPVPTitle", checked)
	end)

	VE.elements.Checkbox(frame, 20, -160, 140, SHOW_NPC_NAMES, OPTION_TOOLTIP_SHOW_NPC_NAMES, nil, VE.GetCVarAsBoolean("UnitNameNPC"), function(checked)
		VE.SetCVar("UnitNameNPC", checked)
	end)

	VE.elements.Checkbox(frame, 20, -190, 140, SHOW_OWN_NAME, OPTION_TOOLTIP_SHOW_OWN_NAME, nil, VE.GetCVarAsBoolean("UnitNameOwn"), function(checked)
		VE.SetCVar("UnitNameOwn", checked)
	end)

	VE.elements.Checkbox(frame, 20, -230, 140, SHOW_CLOAK, OPTION_TOOLTIP_SHOW_CLOAK, nil, ShowingCloak(), function(checked)
		ShowCloak(checked)
	end)

	VE.elements.Checkbox(frame, 20, -260, 140, SHOW_HELM, OPTION_TOOLTIP_SHOW_HELM, nil, ShowingHelm(), function(checked)
		ShowHelm(checked)
	end)

	-- Right column

	VE.elements.Checkbox(frame, 270, -20, 140, USE_UBERTOOLTIPS, OPTION_TOOLTIP_USE_UBERTOOLTIPS, nil, VE.GetCVarAsBoolean("UberTooltips"), function(checked)
		VE.SetCVar("UberTooltips", checked)
	end)

	VE.elements.Checkbox(frame, 270, -50, 190, SHOW_TIPOFTHEDAY_TEXT, OPTION_TOOLTIP_SHOW_TIPOFTHEDAY, nil, VE.GetCVarAsBoolean("showGameTips"), function(checked)
		VE.SetCVar("showGameTips", checked)
	end)

	VE.elements.Checkbox(frame, 270, -80, 170, SHOW_NEWBIE_TIPS_TEXT, OPTION_TOOLTIP_SHOW_NEWBIE_TIPS, nil, VE.GetUVarAsBoolean("SHOW_NEWBIE_TIPS"), function(checked)
		VE.SetUVar("SHOW_NEWBIE_TIPS", checked)
	end)

	do
		local module = VE.getModule("CompareTooltip")
		VE.elements.Checkbox(frame, 270, -110, 170, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
			if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
		end, module.superWoWRequired)
	end

	do
		local module = VE.getModule("RestedXPTooltip")
		VE.elements.Checkbox(frame, 270, -140, 170, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
			if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
		end, module.superWoWRequired)
	end

	VE.elements.Checkbox(frame, 270, -180, 160, SHOW_QUEST_FADING_TEXT, OPTION_TOOLTIP_SHOW_QUEST_FADING, nil, VE.GetUVarAsBoolean("QUEST_FADING_DISABLE"), function(checked)
		VE.SetUVar("QUEST_FADING_DISABLE", checked)
	end)

	VE.elements.Checkbox(frame, 270, -210, 210, HIDE_OUTDOOR_WORLD_STATE_TEXT, OPTION_TOOLTIP_HIDE_OUTDOOR_WORLD_STATE, nil, VE.GetUVarAsBoolean("HIDE_OUTDOOR_WORLD_STATE"), function(checked)
		VE.SetUVar("HIDE_OUTDOOR_WORLD_STATE", checked)
	end)

	VE.elements.Checkbox(frame, 270, -240, 210, AUTO_QUEST_WATCH_TEXT, OPTION_TOOLTIP_AUTO_QUEST_WATCH, nil, VE.GetUVarAsBoolean("AUTO_QUEST_WATCH"), function(checked)
		VE.SetUVar("AUTO_QUEST_WATCH", checked)
	end)

	do
		local module = VE.getModule("HideLuaErrors")
		if module then
			VE.elements.Checkbox(frame, 270, -270, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("QuestItemTooltip")
		if module then
			VE.elements.Checkbox(frame, 270, -310, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("ConsumablesPanel")
		if module then
			VE.elements.Checkbox(frame, 270, -340, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end
	
	do
		local module = VE.getModule("MapMarkers")
		if module then
			VE.elements.Checkbox(frame, 270, -370, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("QuestTracker")
		if module then
			VE.elements.Checkbox(frame, 270, -400, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
