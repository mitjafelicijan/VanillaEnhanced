local module = VE.registerModule({
	identifier = "AutoCancelForm",
	meta = {
		label = "Automatic Cancel Form",
		description = "Automatically cancels shapeshift form if spell cannot be cast.",
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
	if not UnitClass("player") == "Druid" then return end

	if arg1 == "You are in shapeshift form" or
		arg1 == "Can't speak while shapeshifted." or
		arg1 == "You can't do that while shapeshifted." then
		local inForm = nil
		for i = 1, GetNumShapeshiftForms() do
			_, _, active, _ = GetShapeshiftFormInfo(i)
			if active ~= nil then
				inForm = i
			end
		end
		CastShapeshiftForm(inForm)
	end
end)
