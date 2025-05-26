local module = VE.registerModule({
	identifier = "HideLuaErrors",
	meta = {
		label = "Hide All Lua Errors",
		description = "Suppresses the display of Lua error messages, keeping your interface clean during gameplay.",
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

	-- Hides all Lua errors
	error = function() return end
	seterrorhandler(error)
end)
