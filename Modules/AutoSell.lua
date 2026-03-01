local module = VE.registerModule({
	identifier = "AutoSell",
	meta = {
		label = "Automatically Sell Items",
		description = "Automatically sells items upon interacting with a merchant.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		updateInterval = 0.1,
	},
	data = {
		timeSinceLastUpdate = 0,
		allSold = false,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("MERCHANT_SHOW")
module.plug:RegisterEvent("MERCHANT_CLOSED")
module.plug:RegisterEvent("BAG_OPEN")
module.plug:RegisterEvent("BAG_CLOSED")

local scanTooltip = CreateFrame("GameTooltip", "VEAutoSellScanTooltip", nil, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local function GetItemPrice(bag, slot)
	local price = 0
	if scanTooltip then
		scanTooltip:SetScript("OnTooltipAddMoney", function()
			price = arg1
		end)
		scanTooltip:SetBagItem(bag, slot)
		scanTooltip:SetScript("OnTooltipAddMoney", nil)
	end
	return price
end

local function ShouldSellItem(id)
	if not id then return false, false end
	
	local sellList = {}
	if VanillaEnhancedData[module.identifier] and VanillaEnhancedData[module.identifier].sellList then
		sellList = VanillaEnhancedData[module.identifier].sellList
	end
	
	local status = sellList[id]
	if status == true then
		return true, true
	elseif status == false then
		return false, false
	else
		local _, _, quality = GetItemInfo(id)
		if quality == 0 then
			return true, false
		end
	end
	
	return false, false
end

local function UpdateFrameIcons(frame)
	if not frame then frame = this end
	if not frame then return end

	if not VE.isModuleEnabled(module.identifier) then return end

	local bag = frame:GetID()
	if bag >= 0 and bag <= 4 then
		local name = frame:GetName()
		local size = GetContainerNumSlots(bag)

		for j = 1, size do
			local buttonName = name .. "Item" .. j
			local button = getglobal(buttonName)

			if button then
				local slot = button:GetID()
				local link = GetContainerItemLink(bag, slot)
				local shouldSell, isForced = false, false

				if link then
					local _, _, id = string.find(link, "item:(%d+)")
					if id then
						shouldSell, isForced = ShouldSellItem(tonumber(id))
					end
				end

				local iconName = buttonName .. "AutoSellIcon"
				local icon = getglobal(iconName)

				if shouldSell then
					if not icon then
						icon = button:CreateTexture(iconName, "OVERLAY")
						icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
						icon:SetWidth(12)
						icon:SetHeight(12)
						icon:SetPoint("TOPRIGHT", -3, -3)
					end
					
					if isForced then
						icon:SetVertexColor(0, 1, 0)
					else
						icon:SetVertexColor(1, 1, 1)
					end
					
					icon:Show()
				elseif icon then
					icon:Hide()
				end
			end
		end
	end
end

local function UpdateAllOpenBags()
	for i = 1, 5 do
		local frame = getglobal("ContainerFrame" .. i)
		if frame and frame:IsVisible() then
			UpdateFrameIcons(frame)
		end
	end
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

local function OnBagItemClick(button)
	if not VE.isModuleEnabled(module.identifier) then return end
	if button == "LeftButton" and IsAltKeyDown() then
		local bag = this:GetParent():GetID()
		local slot = this:GetID()
		local link = GetContainerItemLink(bag, slot)
		
		if link then
			local _, _, id = string.find(link, "item:(%d+)")
			if id then
				id = tonumber(id)

				if not VanillaEnhancedData[module.identifier].sellList then
					VanillaEnhancedData[module.identifier].sellList = {}
				end

				local sellList = VanillaEnhancedData[module.identifier].sellList
				local shouldSell, _ = ShouldSellItem(id)
				local _, _, quality = GetItemInfo(id)

				if shouldSell then
					-- Currently selling. Toggle to NOT selling.
					if quality == 0 then
						sellList[id] = false -- Explicitly ignore grey
					else
						sellList[id] = nil -- Return to default (no sell)
					end
					VE.print("Removed " .. link .. " from AutoSell list.")
				else
					-- Currently NOT selling. Toggle to selling.
					if quality == 0 then
						sellList[id] = nil -- Return to default (sell grey)
					else
						sellList[id] = true -- Explicitly sell
					end
					VE.print("Added " .. link .. " to AutoSell list.")
				end

				ClearCursor()
				UpdateAllOpenBags()
			end
		end
	end
end

if ContainerFrame_Update then
	VE.hooksecurefunc("ContainerFrame_Update", UpdateFrameIcons, true)
end

if ContainerFrameItemButton_OnClick then
	VE.hooksecurefunc("ContainerFrameItemButton_OnClick", OnBagItemClick, true)
end

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if not VanillaEnhancedData[module.identifier] then
		VanillaEnhancedData[module.identifier] = {}
	end
	if not VanillaEnhancedData[module.identifier].sellList then
		VanillaEnhancedData[module.identifier].sellList = {}
	end

	UpdateAllOpenBags()

	if event == "MERCHANT_SHOW" or event == "MERCHANT_CLOSED" then
		module.data.allSold = false
	end
end)

module.plug:SetScript("OnUpdate", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	if IsShiftKeyDown() then return end

	module.data.timeSinceLastUpdate = module.data.timeSinceLastUpdate + arg1
	if module.data.timeSinceLastUpdate < module.config.updateInterval then return end
	module.data.timeSinceLastUpdate = 0

	if AreBagsShown() then
		UpdateAllOpenBags()
	end

	if MerchantFrame:IsVisible() and not module.data.allSold then
		for bag = 0, 4 do
			for slot = 1, GetContainerNumSlots(bag) do
				local texture, count, locked = GetContainerItemInfo(bag, slot)
				if texture and not locked then
					local link = GetContainerItemLink(bag, slot)
					if link then
						local _, _, id = string.find(link, "item:(%d+)")
						if id then
							local shouldSell = ShouldSellItem(tonumber(id))
							if shouldSell then
								local price = GetItemPrice(bag, slot)
								if price > 0 then
									VE.print("Selling " .. link .. " for " .. VE.copperToColoredMoneyString(price))
								else
									VE.print("Selling " .. link)
								end
								UseContainerItem(bag, slot)
								return
							end
						end
					end
				end
			end
		end
		
		module.data.allSold = true
	end
end)
