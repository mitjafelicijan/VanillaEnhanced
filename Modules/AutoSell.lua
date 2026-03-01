local module = VE.registerModule({
	identifier = "AutoSell",
	meta = {
		label = "Automatically Sell Poor Items",
		description = "Automatically sells poor items upon interacting with a merchant.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("MERCHANT_SHOW")
module.plug:RegisterEvent("MERCHANT_CLOSED")
module.plug:Hide()

local timeSinceLastUpdate = 0
local updateInterval = 0.2

module.plug:SetScript("OnEvent", function()
	if event == "MERCHANT_SHOW" then
		if not VE.isModuleEnabled(module.identifier) then return end

		-- Always open all bags.
		OpenAllBags()

		module.plug:Show()
	elseif event == "MERCHANT_CLOSED" then
		module.plug:Hide()
	end
end)

module.plug:SetScript("OnUpdate", function()
	timeSinceLastUpdate = timeSinceLastUpdate + arg1
	if timeSinceLastUpdate < updateInterval then return end
	timeSinceLastUpdate = 0

	if IsShiftKeyDown() then return end

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
							DEFAULT_CHAT_FRAME:AddMessage("Selling " .. link)
							UseContainerItem(bag, slot)
							return
						end
					end
				end
			end
		end
	end
end)
