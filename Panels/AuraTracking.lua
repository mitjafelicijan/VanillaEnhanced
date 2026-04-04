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
	local headerY = -55
	local l1 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l1:SetPoint("TOPLEFT", 25, headerY)
	l1:SetText("Spell Name")

	local l2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l2:SetPoint("TOPLEFT", 175, headerY)
	l2:SetText("Condition")

	local l3 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l3:SetPoint("TOPLEFT", 285, headerY)
	l3:SetText("Target")

	local l4 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l4:SetPoint("TOPLEFT", 385, headerY)
	l4:SetText("Type")

	local l5 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l5:SetPoint("TOPLEFT", 475, headerY)
	l5:SetText("S")

	local l6 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l6:SetPoint("TOPLEFT", 500, headerY)
	l6:SetText("D")

	local function CreateSlotUI(index, rowY)
		local x = 20
		if not VanillaEnhancedData["AuraTrackerSlots"][index] then
			VanillaEnhancedData["AuraTrackerSlots"][index] = {
				name = "",
				showWhen = "present",
				target = "player",
				type = "buff",
				showStacks = true,
				showDuration = true,
			}
		end
		local data = VanillaEnhancedData["AuraTrackerSlots"][index]

		-- Slot Number
		local slotText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		slotText:SetPoint("TOPLEFT", x - 15, rowY - 7)
		slotText:SetText(index)
		slotText:SetTextColor(0.5, 0.5, 0.5)

		-- Name
		VE.elements.InputArea(frame, x, rowY, 145, 25, nil, nil, nil, data.name, 50, function(text)
			data.name = text
		end)

		-- Show When (Condition)
		VE.elements.DropDown(frame, x + 150, rowY + 2, 90, nil, data.showWhen, {
			{ text = "Present", key = "present" },
			{ text = "Missing", key = "missing" },
		}, function(key)
			data.showWhen = key
		end)

		-- Target
		VE.elements.DropDown(frame, x + 255 + 2, rowY + 2, 85, nil, data.target, {
			{ text = "Player", key = "player" },
			{ text = "Target", key = "target" },
		}, function(key)
			data.target = key
		end)

		-- Type
		VE.elements.DropDown(frame, x + 355 + 4, rowY + 2, 75, nil, data.type, {
			{ text = "Buff", key = "buff" },
			{ text = "Debuff", key = "debuff" },
		}, function(key)
			data.type = key
		end)

		-- Stacks (S)
		local stacks = CreateFrame("CheckButton", "VEAuraSlotStacks"..index, frame, "UICheckButtonTemplate")
		stacks:SetWidth(24)
		stacks:SetHeight(24)
		stacks:SetPoint("TOPLEFT", x + 452, rowY - 1)
		stacks:SetChecked(data.showStacks)
		stacks:SetScript("OnClick", function() 
			data.showStacks = this:GetChecked() and true or false 
		end)

		-- Duration (D)
		local duration = CreateFrame("CheckButton", "VEAuraSlotDuration"..index, frame, "UICheckButtonTemplate")
		duration:SetWidth(24)
		duration:SetHeight(24)
		duration:SetPoint("TOPLEFT", x + 477, rowY - 1)
		duration:SetChecked(data.showDuration)
		duration:SetScript("OnClick", function() 
			data.showDuration = this:GetChecked() and true or false 
		end)
	end

	for i = 1, 8 do
		CreateSlotUI(i, -80 - (i-1) * 35)
	end

	-- Help text
	local help = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	help:SetPoint("BOTTOMLEFT", 20, 20)
	help:SetText("S = Show Stacks, D = Show Duration (Requires SuperWoW for timers)")

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	frame:Hide()
	return frame
end
