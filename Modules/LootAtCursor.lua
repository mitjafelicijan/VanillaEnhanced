local module = VE.registerModule({
	identifier = "LootAtCursor",
	meta = {
		label = "Loot window at cursor",
		description = "Positions the loot window directly under your mouse cursor when opened.",
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
module.plug:RegisterEvent("LOOT_OPENED")
module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	local x, y = GetCursorPosition()
	local scale = LootFrame:GetEffectiveScale()
	x = x / scale
	y = y / scale

	LootFrame:ClearAllPoints()

	for i = 1, LOOTFRAME_NUMBUTTONS do
		local button = getglobal("LootButton"..i)
		if button:IsVisible() then
			x = x - 42
			y = y + 56 + (40 * i)
			LootFrame:SetPoint("TOPLEFT", "UIParent", "BOTTOMLEFT", x, y)
			return
		end
	end

	if LootFrameDownButton:IsVisible() then
		x = x - 158
		y = y + 223
	else
		if GetNumLootItems() == 0 then
			HideUIPanel(LootFrame)
			return
		end
		x = x - 173
		y = y + 25
	end
	LootFrame:SetPoint("TOPLEFT", "UIParent", "BOTTOMLEFT", x, y)
end)
