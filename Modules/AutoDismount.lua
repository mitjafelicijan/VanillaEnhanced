local module = VE.registerModule({
	identifier = "AutoDismount",
	meta = {
		label = "Automatic Dismount",
		description = "Automatically dismounts if shapeshifting etc. occurs (depends on Extended Commands).",
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
module.plug:RegisterEvent("UI_ERROR_MESSAGE")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if arg1 == "You are mounted" then
		SlashCmdList["DISMOUNT"]()
	end
end)
