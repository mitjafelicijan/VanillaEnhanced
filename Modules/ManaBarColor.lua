local module = VE.registerModule({
	identifier = "ManaBarColor",
	meta = {
		label = "Lighter Mana Bar Color",
		description = "Adjusts the default mana bar color to a lighter shade of blue for better visibility.",
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
module.plug:RegisterEvent("VARIABLES_LOADED")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	-- Changes global color variable.
	ManaBarColor[0] = {
		r = VE.config.PowerColors.Mana.r,
		g = VE.config.PowerColors.Mana.g,
		b = VE.config.PowerColors.Mana.b,
		prefix = TEXT(MANA),
	}
end)
