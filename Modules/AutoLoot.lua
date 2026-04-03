local module = VE.registerModule({
	identifier = "AutoLoot",
	meta = {
		label = "Auto Loot",
		description = "Auto loots when shift key is pressed.",
	},
	plug = nil,
	superWoWRequired = true,
	config = {},
	data = {
		wasShiftKeyDown = false,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

-- Negate SuperWoW default auto loot.
if SUPERWOW_VERSION then
	SetAutoloot(0)

	module.frame = CreateFrame("Frame", module.identifier, UIParent)
	module.frame:RegisterEvent("PLAYER_LOGIN")
	module.frame:EnableKeyboard(true)

	module.frame:SetScript("OnUpdate", function()
		local a = VE.isModuleEnabled(module.identifier) and 1 or 0
		local b = (a == 0) and 1 or 0
		local isShiftKeyDown = IsShiftKeyDown()

		if isShiftKeyDown and not module.data.wasShiftKeyDown then
			SetAutoloot(b)
		elseif not isShiftKeyDown and module.data.wasShiftKeyDown then
			SetAutoloot(a)
		end

		module.data.wasShiftKeyDown = isShiftKeyDown
	end)
end
