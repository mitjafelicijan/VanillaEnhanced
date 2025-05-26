local module = VE.registerModule({
	identifier = "LastMessageOnly",
	meta = {
		label = "Last Message Only",
		description = "Shows only last message on the screen instead of default three.",
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

	local originalUIErrorsFrame_OnEvent = UIErrorsFrame_OnEvent
	function UIErrorsFrame_OnEvent(event, message)
		UIErrorsFrame:Clear()
		originalUIErrorsFrame_OnEvent(event, message)
	end
end)
