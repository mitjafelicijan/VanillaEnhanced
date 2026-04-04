VE.panels.AuraTracking = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedAuraTrackingFrame", parent)
	frame:SetAllPoints(parent)

	local module = VE.getModule("AuraTracker")
	if not module then return frame end

	-- Header / Enable
	do
		local cb = VE.elements.Checkbox(frame, 20, -10, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
			if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
		end, module.superWoWRequired)
	end

	if not VanillaEnhancedData["AuraTrackerSlots"] then
		VanillaEnhancedData["AuraTrackerSlots"] = {}
	end

	-- Column Labels
	local l1 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l1:SetPoint("TOPLEFT", 25, -45)
	l1:SetText("Spell Name")
	
	local l2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l2:SetPoint("TOPLEFT", 170, -45)
	l2:SetText("Condition")

	local l3 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l3:SetPoint("TOPLEFT", 270, -45)
	l3:SetText("Target")

	local l4 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l4:SetPoint("TOPLEFT", 370, -45)
	l4:SetText("Type")

	local l5 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l5:SetPoint("TOPLEFT", 465, -45)
	l5:SetText("S")
	
	local l6 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	l6:SetPoint("TOPLEFT", 490, -45)
	l6:SetText("D")

	local function CreateSlotUI(index, x, y)
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
		slotText:SetPoint("TOPLEFT", x - 15, y - 7)
		slotText:SetText(index)
		slotText:SetTextColor(0.5, 0.5, 0.5)

		-- Name
		VE.elements.InputArea(frame, x, y, 140, 25, nil, nil, nil, data.name, 50, function(text)
			data.name = text
		end)

		-- Show When
		VE.elements.DropDown(frame, x + 150, y + 10, 80, nil, data.showWhen, {
			{ text = "Present", key = "present" },
			{ text = "Missing", key = "missing" },
		}, function(key)
			data.showWhen = key
		end)

		-- Target
		VE.elements.DropDown(frame, x + 250, y + 10, 80, nil, data.target, {
			{ text = "Player", key = "player" },
			{ text = "Target", key = "target" },
		}, function(key)
			data.target = key
		end)

		-- Type
		VE.elements.DropDown(frame, x + 350, y + 10, 80, nil, data.type, {
			{ text = "Buff", key = "buff" },
			{ text = "Debuff", key = "debuff" },
		}, function(key)
			data.type = key
		end)

		-- Stacks
		local stacks = CreateFrame("CheckButton", "VEAuraSlotStacks"..index, frame, "UICheckButtonTemplate")
		stacks:SetPoint("TOPLEFT", x + 442, y + 4)
		stacks:SetScale(0.7)
		stacks:SetChecked(data.showStacks)
		stacks:SetScript("OnClick", function() 
			data.showStacks = this:GetChecked() and true or false 
		end)
		
		-- Duration
		local duration = CreateFrame("CheckButton", "VEAuraSlotDuration"..index, frame, "UICheckButtonTemplate")
		duration:SetPoint("TOPLEFT", x + 467, y + 4)
		duration:SetScale(0.7)
		duration:SetChecked(data.showDuration)
		duration:SetScript("OnClick", function() 
			data.showDuration = this:GetChecked() and true or false 
		end)
	end

	for i = 1, 8 do
		CreateSlotUI(i, 20, -60 - (i-1) * 38)
	end

	-- Help text
	local help = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	help:SetPoint("BOTTOMLEFT", 20, 20)
	help:SetText("S = Show Stacks, D = Show Duration (Requires SuperWoW for timers)")

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	frame:Hide()
	return frame
end
