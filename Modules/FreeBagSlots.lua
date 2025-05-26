local module = VE.registerModule({
	identifier = "FreeBagSlots",
	meta = {
		label = "Free Bag Slots",
		description = "Shows the number of available slots in your bags, making it easier to manage inventory space.",
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
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("BAG_UPDATE")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if not MainMenuBarBackpackButton then return end

	if not MainMenuBarBackpackButton.text then
		MainMenuBarBackpackButton.text = MainMenuBarBackpackButton:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
		MainMenuBarBackpackButton.text:SetTextColor(1, 1, 1)
		MainMenuBarBackpackButton.text:SetPoint("BOTTOMRIGHT", MainMenuBarBackpackButton, "BOTTOMRIGHT", -3, 3)
		MainMenuBarBackpackButton.text:SetDrawLayer("OVERLAY", 2)
	end

	local totalFree = 0
	local freeSlots = 0

	for i = 0, NUM_BAG_SLOTS do
		freeSlots = 0
		for slot = 1, GetContainerNumSlots(i) do
			local texture = GetContainerItemInfo(i, slot)
			if not (texture) then
				freeSlots = freeSlots + 1
			end
		end
		totalFree = totalFree + freeSlots
	end

	MainMenuBarBackpackButton.freeSlots = totalFree
	MainMenuBarBackpackButton.text:SetText(string.format("%s", totalFree))
end)
