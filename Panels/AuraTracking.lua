VE.panels.AuraTracking = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedAuraTrackingFrame", parent)
	frame:SetAllPoints(parent)

	local module = VE.getModule("AuraTracker")
	if not module then return frame end

	-- Header / Enable - Aligned with other modules at -20
	VE.elements.Checkbox(frame, 20, -20, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
		if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
	end, module.superWoWRequired)

	if not VanillaEnhancedData["AuraTrackerSlots"] then
		VanillaEnhancedData["AuraTrackerSlots"] = {}
	end

	-- Column Labels
	local headerY = -60
	local l1 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l1:SetPoint("TOPLEFT", 25, headerY)
	l1:SetText("Spell Name")

	local l2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l2:SetPoint("TOPLEFT", 225, headerY)
	l2:SetText("Condition")

	local l3 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l3:SetPoint("TOPLEFT", 335, headerY)
	l3:SetText("Target")

	local l4 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l4:SetPoint("TOPLEFT", 435, headerY)
	l4:SetText("Type")

	local function CreateSlotUI(index, rowY)
		local x = 20
		if not VanillaEnhancedData["AuraTrackerSlots"][index] then
			VanillaEnhancedData["AuraTrackerSlots"][index] = {
				name = "",
				showWhen = "present",
				target = "player",
				type = "buff",
			}
		end
		local data = VanillaEnhancedData["AuraTrackerSlots"][index]

		-- Name
		VE.elements.InputArea(frame, x, rowY, 195, 25, nil, nil, nil, data.name, 50, function(text)
			data.name = text
		end)

		-- Show When (Condition)
		VE.elements.DropDown(frame, x + 200, rowY + 2, 90, nil, data.showWhen, {
			{ text = "Present", key = "present" },
			{ text = "Missing", key = "missing" },
		}, function(key)
			data.showWhen = key
		end)

		-- Target
		VE.elements.DropDown(frame, x + 305 + 2, rowY + 2, 85, nil, data.target, {
			{ text = "Player", key = "player" },
			{ text = "Target", key = "target" },
		}, function(key)
			data.target = key
		end)

		-- Type
		VE.elements.DropDown(frame, x + 405 + 4, rowY + 2, 75, nil, data.type, {
			{ text = "Buff", key = "buff" },
			{ text = "Debuff", key = "debuff" },
		}, function(key)
			data.type = key
		end)
	end

	for i = 1, 8 do
		CreateSlotUI(i, -80 - (i-1) * 35)
	end

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	frame:Hide()
	return frame
end
