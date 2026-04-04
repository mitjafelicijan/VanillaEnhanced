local module = VE.registerModule({
	identifier = "FocusTargetFrame",
	meta = {
		label = "FocusTargetFrame",
		description = "...",
	},
	plug = nil,
	superWoWRequired = true,
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

	-- Code goes here.
end)