local module = VE.registerModule({
	identifier = "SoloSelfFound",
	meta = {
		label = "Solo Self Found",
		description = "Disables grouping and auction house access for the Solo Self Found challenge.",
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
module.plug:RegisterEvent("PARTY_INVITE_REQUEST")
module.plug:RegisterEvent("AUCTION_HOUSE_SHOW")
module.plug:RegisterEvent("TRADE_SHOW")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	VE.print(event)

	if event == "PARTY_INVITE_REQUEST" then
		-- arg1: target name
		DeclineGroup()
		StaticPopup_Hide("PARTY_INVITE")
		SendChatMessage("I am doing a Solo-Self Found Challenge!", "WHISPER", nil, arg1)
	end

	if event == "AUCTION_HOUSE_SHOW" then
		CloseAuctionHouse()
		CloseAllBags()
	end

	if event == "TRADE_SHOW" then
		CancelTrade()
		SendChatMessage("I am doing a Solo Self-Found Challenge!", "SAY")
	end
end)
