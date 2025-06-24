VE.panels.Combat = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedCombatFrame", parent)
	frame:SetAllPoints(parent)

	-- This fixes combat text not appearing if enabled.
	if VE.GetUVarAsBoolean("SHOW_COMBAT_TEXT") then
		UIParentLoadAddOn("Blizzard_CombatText")
	end

	-- Left

	VE.elements.Checkbox(frame, 20, -20, 210, SHOW_TARGET_OF_TARGET_TEXT, OPTION_TOOLTIP_SHOW_TARGET_OF_TARGET, nil, VE.GetUVarAsBoolean("SHOW_TARGET_OF_TARGET"), function(checked)
		VE.SetUVar("SHOW_TARGET_OF_TARGET", checked)
	end)

	VE.elements.DropDown(frame, 50, -50, 160, nil, VE.GetUVarAsNumber("SHOW_TARGET_OF_TARGET_STATE"), {
		{ key = 1, text = RAID, tooltip = nil },
		{ key = 2, text = PARTY, tooltip = nil },
		{ key = 3, text = SOLO, tooltip = nil },
		{ key = 4, text = RAID_AND_PARTY, tooltip = nil },
		{ key = 5, text = ALWAYS, tooltip = nil },
	}, function(key)
		VE.SetUVar("SHOW_TARGET_OF_TARGET_STATE", key)
	end)

	VE.elements.Checkbox(frame, 20, -100, 210, SHOW_COMBAT_TEXT_TEXT, OPTION_TOOLTIP_SHOW_COMBAT_TEXT, nil, VE.GetUVarAsBoolean("SHOW_COMBAT_TEXT"), function(checked)
		VE.SetUVar("SHOW_COMBAT_TEXT", checked)
	end)

	VE.elements.DropDown(frame, 50, -130, 160, COMBAT_TEXT_LABEL, VE.GetUVarAsNumber("COMBAT_TEXT_FLOAT_MODE"), {
		{ key = 1, text = COMBAT_TEXT_SCROLL_UP, tooltip = nil },
		{ key = 2, text = COMBAT_TEXT_SCROLL_DOWN, tooltip = nil },
		{ key = 3, text = COMBAT_TEXT_SCROLL_ARC, tooltip = nil },
	}, function(key)
		VE.SetUVar("COMBAT_TEXT_FLOAT_MODE", key)
	end)

	VE.elements.Checkbox(frame, 50, -190, 210, COMBAT_TEXT_SHOW_LOW_HEALTH_MANA_TEXT, OPTION_TOOLTIP_SHOW_COMBAT_TEXT, nil, VE.GetUVarAsBoolean("COMBAT_TEXT_SHOW_LOW_HEALTH_MANA"), function(checked)
		VE.SetUVar("COMBAT_TEXT_SHOW_LOW_HEALTH_MANA", checked)
	end)

	VE.elements.Checkbox(frame, 50, -220, 210, COMBAT_TEXT_SHOW_AURAS_TEXT, OPTION_TOOLTIP_COMBAT_TEXT_SHOW_AURAS, nil, VE.GetUVarAsBoolean("COMBAT_TEXT_SHOW_AURAS"), function(checked)
		VE.SetUVar("COMBAT_TEXT_SHOW_AURAS", checked)
	end)

	VE.elements.Checkbox(frame, 50, -250, 240, COMBAT_TEXT_SHOW_AURA_FADE_TEXT, OPTION_TOOLTIP_COMBAT_TEXT_SHOW_AURA_FADE, nil, VE.GetUVarAsBoolean("COMBAT_TEXT_SHOW_AURA_FADE"), function(checked)
		VE.SetUVar("COMBAT_TEXT_SHOW_AURA_FADE", checked)
	end)

	VE.elements.Checkbox(frame, 50, -280, 240, COMBAT_TEXT_SHOW_COMBAT_STATE_TEXT, OPTION_TOOLTIP_COMBAT_TEXT_SHOW_COMBAT_STATE, nil, VE.GetUVarAsBoolean("COMBAT_TEXT_SHOW_COMBAT_STATE"), function(checked)
		VE.SetUVar("COMBAT_TEXT_SHOW_COMBAT_STATE", checked)
	end)

	VE.elements.Checkbox(frame, 50, -310, 240, COMBAT_TEXT_SHOW_DODGE_PARRY_MISS_TEXT, OPTION_TOOLTIP_COMBAT_TEXT_SHOW_DODGE_PARRY_MISS, nil, VE.GetUVarAsBoolean("COMBAT_TEXT_SHOW_DODGE_PARRY_MISS"), function(checked)
		VE.SetUVar("COMBAT_TEXT_SHOW_DODGE_PARRY_MISS", checked)
	end)

	VE.elements.Checkbox(frame, 50, -340, 240, COMBAT_TEXT_SHOW_RESISTANCES_TEXT, OPTION_TOOLTIP_COMBAT_TEXT_SHOW_RESISTANCES, nil, VE.GetUVarAsBoolean("COMBAT_TEXT_SHOW_RESISTANCES"), function(checked)
		VE.SetUVar("COMBAT_TEXT_SHOW_RESISTANCES", checked)
	end)

	VE.elements.Checkbox(frame, 50, -370, 270, COMBAT_TEXT_SHOW_REPUTATION_TEXT, OPTION_TOOLTIP_COMBAT_TEXT_SHOW_REPUTATION, nil, VE.GetUVarAsBoolean("COMBAT_TEXT_SHOW_REPUTATION"), function(checked)
		VE.SetUVar("COMBAT_TEXT_SHOW_REPUTATION", checked)
	end)

	-- Right column
	do
		local module = VE.getModule("NameplateThreat")
		VE.elements.Checkbox(frame, 270, -20, 140, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
			if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
		end, module.superWoWRequired)
	end

	do
		local module = VE.getModule("CombatCursor")
		if module then
			VE.elements.Checkbox(frame, 270, -50, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("NearbyTargets")
		if module then
			VE.elements.Checkbox(frame, 270, -80, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("LowHealth")
		if module then
			VE.elements.Checkbox(frame, 270, -110, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	VE.elements.Checkbox(frame, 270, -190, 210, COMBAT_TEXT_SHOW_REACTIVES_TEXT, OPTION_TOOLTIP_COMBAT_TEXT_SHOW_REACTIVES, nil, VE.GetUVarAsBoolean("COMBAT_TEXT_SHOW_REACTIVES"), function(checked)
		VE.SetUVar("COMBAT_TEXT_SHOW_REACTIVES", checked)
	end)

	VE.elements.Checkbox(frame, 270, -220, 210, COMBAT_TEXT_SHOW_FRIENDLY_NAMES_TEXT, OPTION_TOOLTIP_COMBAT_TEXT_SHOW_FRIENDLY_NAMES, nil, VE.GetUVarAsBoolean("COMBAT_TEXT_SHOW_FRIENDLY_NAMES"), function(checked)
		VE.SetUVar("COMBAT_TEXT_SHOW_FRIENDLY_NAMES", checked)
	end)

	VE.elements.Checkbox(frame, 270, -250, 210, COMBAT_TEXT_SHOW_COMBO_POINTS_TEXT, OPTION_TOOLTIP_COMBAT_TEXT_SHOW_COMBO_POINTS, nil, VE.GetUVarAsBoolean("COMBAT_TEXT_SHOW_COMBO_POINTS"), function(checked)
		VE.SetUVar("COMBAT_TEXT_SHOW_COMBO_POINTS", checked)
	end)

	VE.elements.Checkbox(frame, 270, -280, 210, COMBAT_TEXT_SHOW_MANA_TEXT, OPTION_TOOLTIP_COMBAT_TEXT_SHOW_MANA, nil, VE.GetUVarAsBoolean("COMBAT_TEXT_SHOW_MANA"), function(checked)
		VE.SetUVar("COMBAT_TEXT_SHOW_MANA", checked)
	end)

	VE.elements.Checkbox(frame, 270, -310, 210, COMBAT_TEXT_SHOW_HONOR_GAINED_TEXT, OPTION_TOOLTIP_COMBAT_TEXT_SHOW_HONOR_GAINED, nil, VE.GetUVarAsBoolean("COMBAT_TEXT_SHOW_HONOR_GAINED"), function(checked)
		VE.SetUVar("COMBAT_TEXT_SHOW_HONOR_GAINED", checked)
	end)

	VE.elements.Checkbox(frame, 270, -350, 210, SHOW_DAMAGE_TEXT, OPTION_TOOLTIP_SHOW_DAMAGE, nil, VE.GetCVarAsBoolean("CombatDamage"), function(checked)
		VE.SetCVar("CombatDamage", checked)
	end)

	VE.elements.Checkbox(frame, 300, -380, 210, LOG_PERIODIC_EFFECTS, OPTION_TOOLTIP_LOG_PERIODIC_EFFECTS, nil, VE.GetCVarAsBoolean("CombatLogPeriodicSpells"), function(checked)
		VE.SetCVar("CombatLogPeriodicSpells", checked)
	end)

	VE.elements.Checkbox(frame, 300, -410, 210, SHOW_PET_MELEE_DAMAGE, OPTION_TOOLTIP_SHOW_PET_MELEE_DAMAGE, nil, VE.GetCVarAsBoolean("PetMeleeDamage"), function(checked)
		VE.SetCVar("PetMeleeDamage", checked)
	end)

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
