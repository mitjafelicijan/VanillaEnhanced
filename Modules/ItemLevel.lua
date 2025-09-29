-- FIXME: When bag is missing Q items get offset when you move them outside of
--        main bag.

local module = VE.registerModule({
	identifier = "ItemLevel",
	meta = {
		label = "Item Level and Rarity",
		description = "Displays item levels and colors gear by rarity in your character panel, bags, and bank.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		quality = {
			[0] = {r = 0.5, g = 0.5, b = 0.5, key = "Poor" },      -- Poor (Gray)
			[1] = {r = 1.0, g = 1.0, b = 1.0, key = "Common" },    -- Common (White)
			[2] = {r = 0.1, g = 1.0, b = 0.1, key = "Uncommon" },  -- Uncommon (Green)
			[3] = {r = 0.0, g = 0.4, b = 1.0, key = "Rare" },      -- Rare (Blue)
			[4] = {r = 1.0, g = 0.1, b = 1.0, key = "Epic" },      -- Epic (Purple)
			[5] = {r = 1.0, g = 0.5, b = 0.0, key = "Legendary" }, -- Legendary (Orange)
		},
		itemType = {
			Quest = {r = 0.7, g = 0.2, b = 1.0 },
		},
		slots = {
			"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot",
			"TabardSlot", "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot",
			"Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot", "MainHandSlot",
			"SecondaryHandSlot", "RangedSlot"
		}
	},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function CreateLabelOrSkip(parent, quality, level)
	if not parent then return end

	-- Check if label already exists.
	local slotName = string.format("%sItemLevel", parent:GetName())
	if getglobal(slotName) then return end

	local label = parent:CreateFontString(slotName, "OVERLAY", "NumberFontNormal")
	label:SetText(level)
	label:SetPoint("TOPLEFT", 2, -2)
	label:SetTextColor(quality.r, quality.g, quality.b)
	label:SetShadowColor(0, 0, 0, 1)
	label:Hide()
end

local function AreBagsShown()
	if BankFrame:IsShown() then
		return true
	end

	for i = 1,5 do
		if getglobal("ContainerFrame"..i):IsShown() then
			return true
		end
	end

	return false
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("BAG_OPEN")
module.plug:RegisterEvent("BAG_UPDATE")
module.plug:RegisterEvent("BANKFRAME_OPENED")
module.plug:RegisterEvent("UNIT_INVENTORY_CHANGED")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	if not AreBagsShown() then return end

	if event == "PLAYER_ENTERING_WORLD" then
		-- OpenAllBags()
		-- ToggleCharacter("PaperDollFrame")
	end

	-- Update bags.
	for bagID = 0, NUM_BAG_SLOTS do
		local numSlots = GetContainerNumSlots(bagID)
		for slotIndex = 1, numSlots do
			local slot = getglobal(string.format("ContainerFrame%sItem%s", (bagID + 1), ((numSlots - slotIndex) + 1)))
			CreateLabelOrSkip(slot, module.config.quality[5], 60)

			local label = getglobal(string.format("%sItemLevel", slot:GetName()))
			if label then label:Hide() end

			local link = GetContainerItemLink(bagID, slotIndex)
			if link then
				local _, _, itemString  = string.find(link, "|H(.+)|h")
				local name, _, quality, level, _, itemType, _, equipLoc = GetItemInfo(itemString)
				if quality and level and equipLoc ~= "" and equipLoc ~= "INVTYPE_AMMO" or itemType == "Quest" then
					-- if level == 0 then level = "#" end

					if itemType == "Quest" then
						local color = module.config.itemType.Quest
						label:SetText("Q")
						label:SetTextColor(color.r, color.g, color.b)
						label:Show()
					end
					
					if level ~= 0 or level > 1 then
						local color = module.config.quality[tonumber(quality)]
						label:SetText(level)
						label:SetTextColor(color.r, color.g, color.b)
						label:Show()
					end
				end
			end
		end
	end

	-- Update paper doll.
	for _, slotName in ipairs(module.config.slots) do
		local slot = getglobal(string.format("Character%s", slotName))
		CreateLabelOrSkip(slot, module.config.quality[5], 60)

		local label = getglobal(string.format("%sItemLevel", slot:GetName()))
		if label then label:Hide() end

		local slotID = GetInventorySlotInfo(slotName)
		local link = GetInventoryItemLink("player", slotID)

		if link then
			local _, _, itemString  = string.find(link, "|H(.+)|h")
			local _, _, quality, level = GetItemInfo(itemString)
			if quality and level > 1 then
				local color = module.config.quality[tonumber(quality)]
				label:SetText(level)
				label:SetTextColor(color.r, color.g, color.b)
				label:Show()
			end
		end
	end
end)
