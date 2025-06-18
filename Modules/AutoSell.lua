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

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	-- Always open all bags.
	OpenAllBags()

	if IsShiftKeyDown() then return end
	for bag = 0,4,1 do
		for slot = 1, GetContainerNumSlots(bag),1 do
			local name = GetContainerItemLink(bag, slot)
			if name and string.find(name, "ff9d9d9d") then
				DEFAULT_CHAT_FRAME:AddMessage("Selling "..name)
				UseContainerItem(bag, slot)
			end
		end
	end
end)
