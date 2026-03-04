local module = VE.registerModule({
	identifier = "TrinketManager",
	meta = {
		label = "Trinket Manager",
		description = "Adds a frame to the bottom of the screen to manage your trinkets and idols.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		iconSize = 36,
		iconScale = 1.2,
		slots = {
			trinket1 = 13,
			trinket2 = 14,
			idol1 = 18,
		},
	},
	data = {},
})

local print = VE.print

local function ScanBagsForType(equipLoc)
	local items = {}
	for bag = 0, 4 do
		local numSlots = GetContainerNumSlots(bag)
		if numSlots and numSlots > 0 then
			for slot = 1, numSlots do
				local link = GetContainerItemLink(bag, slot)
				if link then
					local _, _, itemString = string.find(link, "|H(.+)|h")
					if itemString then
						local name, _, _, _, _, iType, iSubType, iEquipLoc = GetItemInfo(itemString)
						local texture = GetContainerItemInfo(bag, slot)
						if iEquipLoc == equipLoc then
							tinsert(items, {
								bag = bag,
								slot = slot,
								link = link,
								texture = texture,
								name = name
							})
						end
					end
				end
			end
		end
	end
	return items
end

local function FindEmptyBagSlot()
	for bag = 0, 4 do
		local numSlots = GetContainerNumSlots(bag)
		if numSlots and numSlots > 0 then
			for slot = 1, numSlots do
				if not GetContainerItemLink(bag, slot) then
					return bag, slot
				end
			end
		end
	end
	return nil, nil
end

-- Forward declarations
local UpdateTrinketSlot
local UpdateIdolSlot

local flyoutFrame = nil
local flyoutButtons = {}
local currentFlyoutTarget = nil
local currentFlyoutItems = nil

local function HideFlyout()
	if flyoutFrame then
		flyoutFrame:Hide()
		for i = 1, 20 do
			if flyoutButtons[i] then
				flyoutButtons[i]:Hide()
			end
		end
		currentFlyoutTarget = nil
		currentFlyoutItems = nil
	end
	if flyoutClickFrame then
		flyoutClickFrame:Hide()
	end
end

if not flyoutClickFrame then
	flyoutClickFrame = CreateFrame("Button", "VE_TrinketFlyoutClickFrame", UIParent)
	flyoutClickFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	flyoutClickFrame:SetAllPoints(UIParent)
	flyoutClickFrame:Hide()
	flyoutClickFrame:SetScript("OnClick", function()
		HideFlyout()
	end)
	flyoutClickFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

local function ShowFlyout(targetButton, items, equipSlot, isIdol)
	HideFlyout()
	
	local itemCount = table.getn(items)
	if itemCount == 0 then
		return
	end
	
	local iconSize = module.config.iconSize * module.config.iconScale
	local numItems = itemCount + 1
	
	if not flyoutFrame then
		flyoutFrame = CreateFrame("Frame", nil, UIParent)
		flyoutFrame:SetFrameStrata("TOOLTIP")
	end
	
	local flyoutWidth = iconSize
	local flyoutHeight = (iconSize + 2) * numItems
	
	flyoutFrame:ClearAllPoints()
	flyoutFrame:SetPoint("BOTTOM", targetButton, "TOP", 0, 5)
	flyoutFrame:SetWidth(flyoutWidth)
	flyoutFrame:SetHeight(flyoutHeight)
	flyoutFrame:SetBackdrop(nil)
	flyoutFrame:Show()
	
	flyoutClickFrame:Show()
	
	-- Show item buttons
	for i = 1, itemCount do
		local item = items[i]
		if not flyoutButtons[i] then
			flyoutButtons[i] = CreateFrame("Button", nil, flyoutFrame)
			flyoutButtons[i]:SetFrameStrata("TOOLTIP")
			flyoutButtons[i]:SetFrameLevel(flyoutFrame:GetFrameLevel() + 10)
			flyoutButtons[i]:SetWidth(iconSize)
			flyoutButtons[i]:SetHeight(iconSize)
			flyoutButtons[i]:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
			flyoutButtons[i]:GetHighlightTexture():SetAllPoints()
			flyoutButtons[i]:GetHighlightTexture():SetBlendMode("ADD")
		end
		
		local btn = flyoutButtons[i]
		btn:SetNormalTexture(item.texture)
		btn:SetPushedTexture(item.texture)
		btn:SetAlpha(1.0)
		btn.item = item
		btn.equipSlot = equipSlot
		btn.isIdol = isIdol
		
		btn:ClearAllPoints()
		btn:SetPoint("BOTTOM", flyoutFrame, "BOTTOM", 0, (i - 1) * (iconSize + 2))
		
		btn:SetScript("OnClick", function()
			local item = this.item
			local equipSlot = this.equipSlot
			local isIdol = this.isIdol
			PickupContainerItem(item.bag, item.slot)
			PickupInventoryItem(equipSlot)
			if CursorHasItem() then
				PickupContainerItem(item.bag, item.slot)
			end
			HideFlyout()
			if isIdol then
				VE.executeWithDelay(0.1, function() UpdateIdolSlot("Idol1", module.config.slots.idol1) end)
			else
				VE.executeWithDelay(0.1, function()
					if equipSlot == 13 then UpdateTrinketSlot("Trinket1", 13)
					elseif equipSlot == 14 then UpdateTrinketSlot("Trinket2", 14) end
				end)
			end
		end)
		btn:Show()
	end
	
	-- Show remove button
	local removeIndex = itemCount + 1
	if not flyoutButtons[removeIndex] then
		flyoutButtons[removeIndex] = CreateFrame("Button", nil, flyoutFrame)
		flyoutButtons[removeIndex]:SetFrameStrata("TOOLTIP")
		flyoutButtons[removeIndex]:SetFrameLevel(flyoutFrame:GetFrameLevel() + 10)
		flyoutButtons[removeIndex]:SetWidth(iconSize)
		flyoutButtons[removeIndex]:SetHeight(iconSize)
		flyoutButtons[removeIndex]:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		flyoutButtons[removeIndex]:GetHighlightTexture():SetAllPoints()
		flyoutButtons[removeIndex]:GetHighlightTexture():SetBlendMode("ADD")
	end
	
	local removeBtn = flyoutButtons[removeIndex]
	removeBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
	removeBtn:SetPushedTexture("Interface\\Buttons\\UI-StopButton")
	removeBtn:SetAlpha(0.7)
	removeBtn.equipSlot = equipSlot
	removeBtn.isIdol = isIdol
	
	removeBtn:ClearAllPoints()
	removeBtn:SetPoint("BOTTOM", flyoutFrame, "BOTTOM", 0, (removeIndex - 1) * (iconSize + 2))
	
	removeBtn:SetScript("OnClick", function()
		local equipSlot = this.equipSlot
		local isIdol = this.isIdol
		if GetInventoryItemLink("player", equipSlot) then
			local emptyBag, emptySlot = FindEmptyBagSlot()
			if emptyBag and emptySlot then
				PickupInventoryItem(equipSlot)
				PickupContainerItem(emptyBag, emptySlot)
			else
				VE.iprint("No empty bag slot to unequip")
			end
		end
		HideFlyout()
		if isIdol then
			VE.executeWithDelay(0.1, function() UpdateIdolSlot("Idol1", module.config.slots.idol1) end)
		else
			VE.executeWithDelay(0.1, function()
				if equipSlot == 13 then UpdateTrinketSlot("Trinket1", 13)
				elseif equipSlot == 14 then UpdateTrinketSlot("Trinket2", 14) end
			end)
		end
	end)
	removeBtn:Show()
	
	currentFlyoutTarget = targetButton
	currentFlyoutItems = items
end

local function ToggleFlyout(button, equipSlot, isIdol)
	local items = {}
	
	if isIdol then
		items = ScanBagsForType("INVTYPE_RELIC")
	else
		items = ScanBagsForType("INVTYPE_TRINKET")
	end
	
	-- Limit to max 8 buttons total (7 items + 1 remove)
	if table.getn(items) > 7 then
		local limited = {}
		for i = 1, 7 do table.insert(limited, items[i]) end
		items = limited
	end

	if flyoutFrame and flyoutFrame:IsVisible() and currentFlyoutTarget == button then
		HideFlyout()
	else
		ShowFlyout(button, items, equipSlot, isIdol)
	end
end

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function FormatBindingText(keyText)
	if not keyText or type(keyText) ~= "string" then
		return ""
	end

	local replacements = {
		["SHIFT%-"] = "s-",
		["CTRL%-"] = "c-", 
		["ALT%-"] = "a-",
		["NUMPAD"] = "N",
		["PAGEUP"] = "PgUp",
		["PAGEDOWN"] = "PgDn"
	}

	local formatted = keyText
	for pattern, replacement in pairs(replacements) do
		formatted = string.gsub(formatted, pattern, replacement)
	end

	return formatted
end

local function GetBindingKeyText(name)
	local key = ""
	local key1, key2 = GetBindingKey("VE_USE_" .. string.upper(name))

	if key2 ~= "" then key = key2 end
	if key1 ~= "" then key = key1 end

	return FormatBindingText(key)
end

UpdateTrinketSlot = function(name, slot)
	local trinketLink = GetInventoryItemLink("player", slot)
	local texture = GetInventoryItemTexture("player", slot)

	if not texture then
		module.plug.frame[name]:Hide()
		return
	end

	module.plug.frame[name]:SetNormalTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
	module.plug.frame[name]:SetPushedTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

	module.plug.frame[name]:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
	module.plug.frame[name]:GetHighlightTexture():SetAllPoints()
	module.plug.frame[name]:GetHighlightTexture():SetBlendMode("ADD")
	module.plug.frame[name]:Show()

	local start, duration, enable = GetInventoryItemCooldown("player", slot)
	CooldownFrame_SetTimer(module.plug.frame[name].cooldown, start or 0, duration or 0, enable or 0)

	module.plug.frame[name]:SetScript("OnEnter", function()
		if trinketLink then
			GameTooltip:SetOwner(module.plug.frame[name], "ANCHOR_RIGHT")
			GameTooltip:SetInventoryItem("player", slot)
			GameTooltip:Show()
		end
	end)
	module.plug.frame[name]:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

local function CreateTrinketSlot(parent, name, offset, slot)
	module.plug.frame[name] = CreateFrame("Button", name, parent)
	module.plug.frame[name]:SetWidth(module.config.iconSize * module.config.iconScale)
	module.plug.frame[name]:SetHeight(module.config.iconSize * module.config.iconScale)
	module.plug.frame[name]:SetPoint("Left", parent, "Left", offset, 0)

	module.plug.frame[name].cooldown = CreateFrame("Model", name.."Cooldown", module.plug.frame[name], "CooldownFrameTemplate")
	module.plug.frame[name].cooldown:SetAllPoints()
	module.plug.frame[name].cooldown:SetFrameLevel(module.plug.frame[name]:GetFrameLevel() + 1)
	module.plug.frame[name].cooldown:SetScale(module.config.iconScale)
	module.plug.frame[name].cooldown.ScaleSet = true

	module.plug.frame[name].hotkey = module.plug.frame[name]:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	module.plug.frame[name].hotkey:SetPoint("TOPRIGHT", -2, -2)
	module.plug.frame[name].hotkey:SetTextColor(0.7, 0.7, 0.7)
	module.plug.frame[name].hotkey:SetText(GetBindingKeyText(name))

	VE.executeWithDelay(0.5, function()
		UpdateTrinketSlot(name, slot)
	end)

	module.plug.frame[name]:SetScript("OnMouseDown", function()
		local button = arg1
		if button == "LeftButton" then
			UseInventoryItem(slot)
		elseif button == "RightButton" then
			ToggleFlyout(this, slot, false)
		end
	end)
end

UpdateIdolSlot = function(name, slot)
	local trinketLink = GetInventoryItemLink("player", slot)
	local texture = GetInventoryItemTexture("player", slot)

	if not module.plug.frame[name] then return end

	module.plug.frame[name]:SetNormalTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
	module.plug.frame[name]:SetPushedTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

	module.plug.frame[name]:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
	module.plug.frame[name]:GetHighlightTexture():SetAllPoints()
	module.plug.frame[name]:GetHighlightTexture():SetBlendMode("ADD")

	module.plug.frame[name]:SetScript("OnEnter", function()
		if trinketLink then
			GameTooltip:SetOwner(module.plug.frame[name], "ANCHOR_RIGHT")
			GameTooltip:SetInventoryItem("player", slot)
			GameTooltip:Show()
		end
	end)
	module.plug.frame[name]:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

local function CreateIdolSlot(parent, name, offset, slot)
	module.plug.frame[name] = CreateFrame("Button", name, parent)
	module.plug.frame[name]:SetWidth(module.config.iconSize * module.config.iconScale)
	module.plug.frame[name]:SetHeight(module.config.iconSize * module.config.iconScale)
	module.plug.frame[name]:SetPoint("Left", parent, "Left", offset, 0)

	VE.executeWithDelay(0.5, function()
		UpdateIdolSlot(name, slot)
	end)

	module.plug.frame[name]:SetScript("OnMouseDown", function()
		local button = arg1
		if button == "LeftButton" then
			UseInventoryItem(slot)
		elseif button == "RightButton" then
			ToggleFlyout(this, slot, true)
		end
	end)
end

function UseTrinket1()
	UseInventoryItem(module.config.slots.trinket1)

	local start, duration = GetInventoryItemCooldown("player", module.config.slots.trinket1)
	CooldownFrame_SetTimer(module.plug.frame["Trinket1"].cooldown, start or GetTime(), duration or 30, 1)

	VE.executeWithDelay(0.5, function()
		UpdateTrinketSlot("Trinket1", module.config.slots.trinket1)
	end)
end

function UseTrinket2()
	UseInventoryItem(module.config.slots.trinket2)

	local start, duration = GetInventoryItemCooldown("player", module.config.slots.trinket2)
	CooldownFrame_SetTimer(module.plug.frame["Trinket2"].cooldown, start or GetTime(), duration or 30, 1)

	VE.executeWithDelay(0.5, function()
		UpdateTrinketSlot("Trinket2", module.config.slots.trinket2)
	end)
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("UNIT_INVENTORY_CHANGED")

-- module.plug:RegisterEvent("SPELL_UPDATE_COOLDOWN")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" and not module.plug.frame then
		local parent = MultiBarBottomRight

		if CompactActionBars and CompactActionBarsRight then
			parent = CompactActionBarsRight
		end

		module.plug.frame = CreateFrame("Frame", "TrinketManagerFrame", MultiBarBottomRight)
		module.plug.frame:SetPoint("Right", parent, "BottomRight", -1, (module.config.iconSize * 2) - 2)
		module.plug.frame:SetWidth(module.config.iconSize * 3 + 25)
		module.plug.frame:SetHeight(module.config.iconSize)
		module.plug.frame:SetFrameStrata("LOW")

		CreateTrinketSlot(module.plug.frame, "Trinket1", (module.config.iconSize * module.config.iconScale * 1) + 2, 13)
		CreateTrinketSlot(module.plug.frame, "Trinket2", (module.config.iconSize * module.config.iconScale * 2) + 4, 14)

		if UnitClass("player") == "Druid" then
			CreateIdolSlot(module.plug.frame, "Idol1", 0, module.config.slots.idol1)
		end
	end

	if event == "UNIT_INVENTORY_CHANGED" then
		if arg1 == "player" then
			UpdateTrinketSlot("Trinket1", 13)
			UpdateTrinketSlot("Trinket2", 14)
			UpdateIdolSlot("Idol1", module.config.slots.idol1)
		end
	end

	if event == "SPELL_UPDATE_COOLDOWN" then
		UpdateTrinketSlot("Trinket1", 13)
		UpdateTrinketSlot("Trinket2", 14)
	end
end)
