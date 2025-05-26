local module = VE.registerModule({
	identifier = "BankBags",
	meta = {
		label = "Bank Bags",
		description = "Shows bank bag items even when not at the bank.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		slotSize = 37,
		slotsPerRow = 14,
		numRows = 8,
	},
	data = {
		bankItems = {},
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

-- Call this when your addon initializes
-- FIXME: When bank is opened and /rl is pressed with Bank Bags opened it doesn't save.
local function ScanAndStoreBankBags()
	module.data.bankItems = {}

	-- Get main bank slots (24 slots in vanilla, slots 1-24)
	for slot = 1, 24 do
		local texture, itemCount  = GetContainerItemInfo(BANK_CONTAINER, slot)
		local itemLink = GetContainerItemLink(BANK_CONTAINER, slot)
		if not itemLink then break end
		local _, _, name = string.find(itemLink, "|h%[(.-)%]|h|r")
		local _, _, itemId = string.find(itemLink, "item:(%d+):")
		table.insert(module.data.bankItems, {
			id = itemId,
			link = itemLink,
			count = itemCount,
			icon = texture,
			name = name,
			bag = BANK_CONTAINER,
			slot = slot,
		})
	end

	-- -- Get bank bags (slots 5-11 in vanilla) and their contents
	for bagID = 5, 11 do
		local numSlots = GetContainerNumSlots(bagID)
		if numSlots > 0 then
			for slot = 1, numSlots do
				local texture, itemCount  = GetContainerItemInfo(bagID, slot)
				local itemLink = GetContainerItemLink(bagID, slot)
				if not itemLink then break end
				local _, _, name = string.find(itemLink, "|h%[(.-)%]|h|r")
				local _, _, itemId = string.find(itemLink, "item:(%d+):")
				table.insert(module.data.bankItems, {
					id = itemId,
					link = itemLink,
					count = itemCount,
					icon = texture,
					name = name,
					bag = bagID,
					slot = slot,
				})
			end
		end
	end

	VanillaEnhancedData["bankItems"] = module.data.bankItems
end

local function UpdateBankBag()
	if not module.plug.frame.slots then return end

	for i = 1, (module.config.slotsPerRow * module.config.numRows) do
		local item = module.data.bankItems[i]
		local slot = getglobal("BankBagsSlot" .. i)

		if item and item.icon then
			slot.item:SetTexture(item.icon)

			if item.count and item.count > 1 then
				slot.count:SetText(item.count)
			end

			slot:SetScript("OnEnter", function()
				GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
				GameTooltip:SetHyperlink(string.format("item:%s:0:0:0:0:0:0:0", item.id))
				GameTooltip:Show()
			end)

			slot:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)

			slot.count:Show()
			slot.item:Show()
		else
			slot.count:Hide()
			slot.item:Hide()
		end
	end
end

-- Used by custom keybinding.
function BankBagsToggle()
	if not VE.isModuleEnabled(module.identifier) then return end
	if not module.plug.frame then return end

	if module.plug.frame:IsVisible() then
		module.plug.frame:Hide()
	else
		UpdateBankBag()
		module.plug.frame:Show()
	end
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("ADDON_LOADED")
module.plug:RegisterEvent("BANKFRAME_OPENED")
module.plug:RegisterEvent("BAG_UPDATE")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "ADDON_LOADED" and not module.plug.frame then
		if VanillaEnhancedData["bankItems"] then
			module.data.bankItems = VanillaEnhancedData["bankItems"]
		end

		module.plug.frame = CreateFrame("Frame", "BankBagsFrame", UIParent)
		module.plug.frame:SetPoint("Center", UIParent, "Center", 0, 0)
		module.plug.frame:SetWidth((module.config.slotSize * module.config.slotsPerRow) + 18)
		module.plug.frame:SetHeight((module.config.slotSize * module.config.numRows) + 35)
		module.plug.frame:EnableMouse(true)
		module.plug.frame:SetMovable(true)
		module.plug.frame:RegisterForDrag("LeftButton")
		module.plug.frame:SetScript("OnDragStart", function() this:StartMoving() end)
		module.plug.frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
		module.plug.frame:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\TutorialFrame\\TutorialFrameBorder",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 6, right = 6, top = 6, bottom = 6 }
		})
		module.plug.frame:Hide()

		module.plug.frame.close = CreateFrame("Button", nil, module.plug.frame, "UIPanelCloseButton")
		module.plug.frame.close:SetPoint("TopRight", module.plug.frame, "TopRight", 4, 4)

		module.plug.frame.title = module.plug.frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		module.plug.frame.title:SetText("Bank Bags")
		module.plug.frame.title:SetPoint("Top", 0, -6)

		module.plug.frame.slots = CreateFrame("Frame", nil, module.plug.frame)
		module.plug.frame.slots:SetPoint("Bottom", module.plug.frame, "Bottom", 1, 10)
		module.plug.frame.slots:SetWidth((module.config.slotSize * module.config.slotsPerRow))
		module.plug.frame.slots:SetHeight((module.config.slotSize * module.config.numRows))

		for row = 1, module.config.numRows do
			for col = 1, module.config.slotsPerRow do
				local index = ((row - 1) * module.config.slotsPerRow) + col
				local xOffset = (col - 1) * (module.config.slotSize)
				local yOffset = -(row - 1) * (module.config.slotSize)

				local slot = CreateFrame("Button", "BankBagsSlot"..index, module.plug.frame)
				slot:SetWidth(module.config.slotSize)
				slot:SetHeight(module.config.slotSize)
				slot:SetPoint("TopLeft", module.plug.frame.slots, "TopLeft", xOffset, yOffset)
				slot:SetNormalTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")

				local texture = slot:GetNormalTexture()
				texture:SetWidth(module.config.slotSize)
				texture:SetHeight(module.config.slotSize)
				texture:SetDrawLayer("BACKGROUND")
				texture:SetAlpha(0.9)

				slot.item = slot:CreateTexture(nil, "ARTWORK")
				slot.item:SetWidth(module.config.slotSize - 2)
				slot.item:SetHeight(module.config.slotSize - 2)
				slot.item:SetPoint("TopLeft", slot, "TopLeft", 1, -1)
				slot.item:SetDrawLayer("ARTWORK")
				slot.item:Hide()

				slot.count = slot:CreateFontString(nil, "ARTWORK", "NumberFontNormal")
				slot.count:SetPoint("BottomRight", slot, "BottomRight", -5, 2)
				slot.count:Hide()
			end
		end
	end

	if event == "BANKFRAME_OPENED" then
		OpenAllBags()
		ScanAndStoreBankBags()
		module.plug.frame:Hide()
	end

	if event == "BAG_UPDATE" then
		if BankFrame:IsVisible() then
			ScanAndStoreBankBags()
		end
	end
end)
