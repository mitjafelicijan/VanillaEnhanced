local _G = getfenv(0)
VE_NEXT_ID = 0

local function GetNextID()
	VE_NEXT_ID = VE_NEXT_ID + 1
	return VE_NEXT_ID
end

VE.elements.Checkbox = function(parent, x, y, componentWidth, labelText, tooltipTitle, tooltipDescription, initialState, callback, superWoWRequired)
	local name = "CheckBox"..tostring(GetNextID())

	local frame = CreateFrame("Button", name, parent)
	frame:SetPoint("TopLeft", x, y)
	frame:SetWidth(componentWidth)
	frame:SetHeight(25)

	frame.checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
	frame.checkbox:SetPoint("TopLeft", -4, 4)
	frame.checkbox:SetChecked(initialState)
	frame.checkbox:SetScript("OnClick", function(self)
		local checked = this:GetChecked() and true or false
		callback(checked)
	end)

	frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.label:SetPoint("TopLeft", 28, -6)
	frame.label:SetText(labelText)

	if superWoWRequired and not SUPERWOW_VERSION then
		frame.checkbox:Disable()
		frame.label:SetTextColor(0.5, 0.5, 0.5)
		tooltipTitle = "|cffff3333SuperWoW missing.|r\n" .. tooltipTitle
	end

	frame:SetScript("OnClick", function(self)
		this.checkbox:SetChecked(not this.checkbox:GetChecked())
		local checked = this.checkbox:GetChecked() and true or false
		callback(checked)
	end)

	frame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")

		if tooltipTitle ~= nil then
			GameTooltip:SetText(tooltipTitle, nil, nil, nil, nil, 1) -- title line
		end

		if tooltipDescription ~= nil then
			GameTooltip:AddLine(tooltipDescription, "", 1.0, 1.0, 1.0) -- additional line
		end

		GameTooltip:Show()
	end)

	frame:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	if VE.config.Debug then VE.dframe(frame, 1.0, 0.0, 1.0, 0.4) end
	return frame
end

VE.elements.Slider = function(parent, x, y, componentWidth, labelText, tooltipTitle, tooltipDescription, minValue, maxValue, stepValue, initialValue, callback)
	local name = "Slider"..tostring(GetNextID())

	local frame = CreateFrame("Button", name, parent)
	frame:SetPoint("TopLeft", x, y)
	frame:SetWidth(componentWidth)
	frame:SetHeight(44)

	frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.label:SetPoint("TOP", 0, 0)
	frame.label:SetWidth(componentWidth)
	frame.label:SetJustifyH("CENTER")
	frame.label:SetText(labelText)

	frame.slider = CreateFrame("Slider", name .. "Slider", frame, "OptionsSliderTemplate")
	frame.slider:SetPoint("TOP", frame.label, "BOTTOM", 0, -2)
	frame.slider:SetWidth(componentWidth)
	frame.slider:SetHeight(18)
	frame.slider:SetMinMaxValues(minValue, maxValue)
	frame.slider:SetValueStep(stepValue)
	frame.slider:SetValue(initialValue)

	frame.low = getglobal(frame.slider:GetName() .. "Low")
	frame.high = getglobal(frame.slider:GetName() .. "High")
	frame.text = getglobal(frame.slider:GetName() .. "Text")

	-- The template's Text is usually anchored to the TOP of the slider.
	-- Since we have our own label there, we should move the template's Text 
	-- to show the value somewhere else or just hide it.
	-- Standard Blizzard style often puts the value in the High label or a separate one.
	-- Let's put the value in the template's Text but move it to the bottom.
	if frame.text then
		frame.text:ClearAllPoints()
		frame.text:SetPoint("TOP", frame.slider, "BOTTOM", 0, 2)
		frame.text:SetText(initialValue)
	end

	if frame.low then frame.low:SetText(minValue) end
	if frame.high then frame.high:SetText(maxValue) end

	frame.slider:SetScript("OnValueChanged", function(self)
		if frame.text then frame.text:SetText(this:GetValue()) end
		callback(this:GetValue())
	end)

	frame.slider:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")

		if tooltipTitle ~= nil then
			GameTooltip:SetText(tooltipTitle, nil, nil, nil, nil, 1) -- title line
		end

		if tooltipDescription ~= nil then
			GameTooltip:AddLine(tooltipDescription, "", 1.0, 1.0, 1.0) -- additional line
		end

		GameTooltip:Show()
	end)

	frame.slider:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	if VE.config.Debug then VE.dframe(frame, 1.0, 0.0, 1.0, 0.4) end
	return frame
end

VE.elements.DropDown = function(parent, x, y, componentWidth, labelText, initialState, items, callback, superWoWRequired)
	local name = "DropDown"..tostring(GetNextID())
	local labelOffset = 0

	-- Calculate offset of DropDown if label is also provided.
	if labelText then labelOffset = 20 end

	local frame = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
	frame:SetPoint("TopLeft", x - 20, y - labelOffset)

	-- Add label to the element.
	if labelText then
		frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		frame.label:SetPoint("TopLeft", 20, 16)
		frame.label:SetWidth(componentWidth)
		frame.label:SetJustifyH("Left")
		frame.label:SetText(labelText)
	end

	frame.items = items
	frame.selectedID = nil

	-- Find the default selected ID based on initialState.
	for i, item in ipairs(items) do
		if item.key == initialState then
			frame.selectedID = i
			break
		end
	end

	-- Create a unique initialization function for each dropdown.
	_G["DropDownInit_" .. name] = function()
		local currentFrame = this
		for i, item in ipairs(frame.items) do
			local info = {}
			info.text = item.text
			info.value = i
			info.key = item.key
			info.func = function()
				UIDropDownMenu_SetSelectedID(frame, info.value)
				callback(info.key)
			end
			UIDropDownMenu_AddButton(info)
		end
	end

	-- Initialize the dropdown with the unique function
	UIDropDownMenu_Initialize(frame, _G["DropDownInit_" .. name])

	-- Set active value and width.
	if frame.selectedID then
		UIDropDownMenu_SetSelectedID(frame, frame.selectedID)
	else
		UIDropDownMenu_SetSelectedID(frame, 1)
	end

	-- Force the width to component width.
	UIDropDownMenu_SetWidth(componentWidth, frame)

	if superWoWRequired and not SUPERWOW_VERSION then
		frame:Disable()
		frame.label:SetTextColor(0.5, 0.5, 0.5)
		--tooltipTitle = "|cffff3333SuperWoW missing.|r\n" .. tooltipTitle
	end

	-- VE.dframe(frame, 1, 0, 0, 0.5)

	return frame
end

VE.elements.InputArea = function(parent, x, y, width, height, labelText, tooltipTitle, tooltipDescription, initialValue, maxLetters, callback)
	local name = "InputArea"..tostring(GetNextID())

	local frame = CreateFrame("Frame", name, parent)
	frame:SetPoint("TopLeft", x, y)
	frame:SetWidth(width)
	frame:SetHeight(height)

	frame.editbox = CreateFrame("EditBox", name, frame)
	frame.editbox:SetAllPoints(frame)
	frame.editbox:SetFontObject(ChatFontNormal)
	frame.editbox:SetAutoFocus(false)
	frame.editbox:EnableMouse(true)
	frame.editbox:SetMaxLetters(maxLetters or 255)
	frame.editbox:SetText(initialValue or "")
	frame.editbox:SetTextInsets(18, 2, 2, 2)

	frame.border = CreateFrame("Frame", nil, frame)
	frame.border:SetAllPoints(frame)
	frame.border:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	frame.border:SetBackdropColor(0, 0, 0, 0.5)

	frame.editbox:SetScript("OnEscapePressed", function()
		frame.editbox:ClearFocus()
	end)

	frame.editbox:SetScript("OnTextChanged", function()
		if callback then
			callback(frame.editbox:GetText())
		end
	end)

	frame.editbox:SetTextInsets(8, 8, 0, 0)

	return frame
end
