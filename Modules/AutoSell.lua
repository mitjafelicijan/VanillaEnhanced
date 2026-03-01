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
				local isPoor = false

				if link then
					local _, _, id = string.find(link, "item:(%d+)")
					if id then
						local _, _, quality = GetItemInfo(id)
						if quality == 0 then
							isPoor = true
						end
					end
				end

				local iconName = buttonName .. "AutoSellIcon"
				local icon = getglobal(iconName)

				if isPoor then
					if not icon then
						icon = button:CreateTexture(iconName, "OVERLAY")
						icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
						icon:SetWidth(12)
						icon:SetHeight(12)
						icon:SetPoint("TOPRIGHT", -3, -3)
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

if ContainerFrame_Update then
	VE.hooksecurefunc("ContainerFrame_Update", UpdateFrameIcons, true)
end

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

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
							local _, _, quality = GetItemInfo(id)
							if quality == 0 then
								VE.print("Selling " .. link)
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
