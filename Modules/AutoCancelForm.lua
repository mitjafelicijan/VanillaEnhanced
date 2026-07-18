local module = VE.registerModule({
	identifier = "AutoCancelForm",
	meta = {
		label = "Automatic Cancel of Forms",
		description = "Automatically cancels shapeshift form if spell cannot be cast (depends on Extended Commands).",
	},
	plug = nil,
	superWoWRequired = false,
	-- https://vanilla-wow-archive.fandom.com/wiki/WoW_Constants/Errors
	config = {
		cancelFormErrors = {
			[SPELL_FAILED_NOT_SHAPESHIFT] = true,
			[ERR_CANT_INTERACT_SHAPESHIFTED] = true,
			[ERR_NOT_WHILE_SHAPESHIFTED] = true,
			[ERR_MOUNT_SHAPESHIFTED] = true,
			[ERR_NO_ITEMS_WHILE_SHAPESHIFTED] = true,
		}
	},
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
	if not UnitClass("player") == "Druid" or not UnitClass("player") == "Shaman" then return end

	if module.config.cancelFormErrors[arg1] then
		SlashCmdList["CANCELFORM"]()
	end
end)
