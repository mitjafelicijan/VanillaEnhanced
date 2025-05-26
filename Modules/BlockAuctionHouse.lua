local module = VE.registerModule({
	identifier = "BlockAuctionHouse",
	meta = {
		label = "Block Auction House",
		description = "Disable access to the Auction House UI. Prevents players from opening the Auction House window.",
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
module.plug:RegisterEvent("AUCTION_HOUSE_SHOW")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	CloseAuctionHouse()
	CloseAllBags()
end)
