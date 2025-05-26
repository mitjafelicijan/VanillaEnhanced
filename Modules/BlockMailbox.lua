local module = VE.registerModule({
	identifier = "BlockMailbox",
	meta = {
		label = "Block Mailbox",
		description = "Disable access to the mailbox UI, preventing the player from opening or interacting with it.",
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
module.plug:RegisterEvent("MAIL_SHOW")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	CloseMail()
	CloseAllBags()
end)
