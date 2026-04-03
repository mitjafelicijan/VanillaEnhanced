local module = VE.registerModule({
	identifier = "ConsumablesPanel",
	meta = {
		label = "Consumables Panel",
		description = "Adds a panel for easy access to consumables in your bags.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		buttonSize = 36,
		buttonPadding = 0,
		rows = 6,
		columns = 6,
	},
	data = {
		buttons = nil,
		consumables = {},
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function UpdateBagConsumables()
	wipe(module.data.consumables)

	for bagID = 0, NUM_BAG_SLOTS do
		for slotIndex = 1, GetContainerNumSlots(bagID) do
			local link = GetContainerItemLink(bagID, slotIndex)
			local texture, itemCount = GetContainerItemInfo(bagID, slotIndex)
			if link then
				local itemID = VE.find(link, "item:(%d+)")
				local name, _, _, _, _, itemType, itemSubType = GetItemInfo(itemID)

				-- if itemType and itemType == "Consumable" then
				-- 	VE.print(string.format("(%s) %s = %s", itemType, name, itemSubType))
				-- end
				
				if itemType and itemType == "Consumable" then
					table.insert(module.data.consumables, {
						name = name,
						id = itemID,
						link = link,
						texture = texture,
						count = itemCount,
						bag = bagID,
						slot = slotIndex,
					})
				end
			end
		end
	end
end

local function UpdateButtonConsumables()
	for idx = 1,(module.config.rows * module.config.columns) do
		local item = module.data.consumables[idx]
		local button = getglobal("ConsumableButton" .. idx)
		if not button then return end

		if item then
			local normal = button:GetNormalTexture()
			normal:SetTexture(item.texture)
			normal:SetTexCoord(0, 1, 0, 1)
			normal:ClearAllPoints()
			normal:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
			normal:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)

			local pushed = button:GetPushedTexture()
			pushed:SetTexture(item.texture)
			pushed:SetTexCoord(0, 1, 0, 1)
			pushed:ClearAllPoints()
			pushed:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
			pushed:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)

			local highlight = button:GetHighlightTexture()
			highlight:SetAllPoints(button)
			highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
			highlight:SetBlendMode("ADD")

			button.text:SetText(string.format("%s", item.count))

			button.meta = item
			button:Show()
		else
			button.meta = nil
			button:Hide()
		end
	end
end

function ToggleConsumablesPanel()
	if not module.plug.frame then return end

	if module.plug.frame:IsShown() then
		module.plug.frame:Hide()
	else
		module.plug.frame:Show()
	end
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("ADDON_LOADED")
module.plug:RegisterEvent("UNIT_INVENTORY_CHANGED")
module.plug:RegisterEvent("BAG_UPDATE")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "ADDON_LOADED" and not module.plug.frame then
		local width = (module.config.buttonSize + module.config.buttonPadding) * module.config.columns + 20
		local height = (module.config.buttonSize + module.config.buttonPadding) * module.config.rows + 30

		module.plug.frame = CreateFrame("Frame", "Consumables", UIParent)
		module.plug.frame:SetWidth(width)
		module.plug.frame:SetHeight(height)
		module.plug.frame:SetPoint("CENTER", 0, 0)
		module.plug.frame:SetFrameStrata("HIGH")
		module.plug.frame:EnableMouse(true)
		module.plug.frame:SetMovable(true)
		module.plug.frame:SetClampedToScreen(true)
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
		module.plug.frame.close:SetPoint("TopRight", module.plug.frame, "TopRight", 3, 4)

		module.plug.frame.title = module.plug.frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		module.plug.frame.title:SetText("Consumables")
		module.plug.frame.title:SetPoint("Top", 0, -6)

		local idx = 1
		for r = 1, module.config.rows do
			for c = 1, module.config.columns do
				local size = module.config.buttonSize + module.config.buttonPadding

				local button = CreateFrame("Button", "ConsumableButton" .. idx, module.plug.frame, "ActionButtonTemplate")
				button:SetWidth(module.config.buttonSize)
				button:SetHeight(module.config.buttonSize)
				button:SetPoint("TOPLEFT", ((c - 1) * size) + 11, - ((r - 1) * size) - 26)
				button:SetFrameStrata("HIGH")

				local normal = button:GetNormalTexture()
				normal:SetTexture(nil)

				local pushed = button:GetPushedTexture()
				pushed:SetTexture(nil)

				local highlight = button:GetHighlightTexture()
				highlight:SetTexture(nil)

				button:SetScript("OnClick", function()
					if this.meta then
						UseContainerItem(this.meta.bag, this.meta.slot)
					end
				end)

				button:SetScript("OnEnter", function(self)
					if this.meta then
						GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
						GameTooltip:SetBagItem(this.meta.bag, this.meta.slot)
						GameTooltip:Show()
					end
				end)

				button:SetScript("OnLeave", function(self)
					GameTooltip:Hide()
				end)

				button.text = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
				button.text:SetTextColor(1, 1, 1)
				button.text:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
				button.text:SetDrawLayer("OVERLAY", 2)

				idx = idx + 1
			end
		end

		SLASH_CONSUMABLES1 = "/consumables"
		SlashCmdList["CONSUMABLES"] = function(msg)
			ToggleConsumablesPanel()
		end
	end

	if (event == "BAG_UPDATE" or event == "UNIT_INVENTORY_CHANGED") and module.plug.frame then
		UpdateBagConsumables()
		UpdateButtonConsumables()
	end
end)
