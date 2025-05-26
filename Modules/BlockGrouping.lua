local module = VE.registerModule({
	identifier = "BlockGrouping",
	meta = {
		label = "Block Grouping",
		description = "Prevent incoming group invitations from other players. Stops automatic prompts for joining groups.",
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

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	DeclineGroup()
	StaticPopup_Hide("PARTY_INVITE")
end)
