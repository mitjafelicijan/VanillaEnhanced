local module = VE.registerModule({
	identifier = "AutoRoll",
	meta = {
		label = "Auto Roll",
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

module.frame = CreateFrame("Frame", module.identifier, UIParent)
module.frame:RegisterEvent("PLAYER_LOGIN")
module.frame:EnableKeyboard(true)

module.frame:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	SetAutoloot(0)
end)

module.frame:SetScript("OnUpdate", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	-- Code goes here...
end)
