-- https://github.com/tilare/ModernMapMarkers

local module = VE.registerModule({
	identifier = "MapMarkers",
	meta = {
		label = "Map Markers",
		description = "...",
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
module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	-- Code goes below here
	VE.print("Map markers loaded")
end)
