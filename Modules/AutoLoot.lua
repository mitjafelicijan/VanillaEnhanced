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
end

module.frame = CreateFrame("Frame", module.identifier, UIParent)
module.frame:RegisterEvent("PLAYER_LOGIN")
module.frame:EnableKeyboard(true)

module.frame:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	SetAutoloot(1)
end)

module.frame:SetScript("OnUpdate", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	local isShiftKeyDown = IsShiftKeyDown()
	if isShiftKeyDown and not module.data.wasShiftKeyDown then
		SetAutoloot(0)
	elseif not isShiftKeyDown and module.data.wasShiftKeyDown then
		SetAutoloot(1)
	end

	module.data.wasShiftKeyDown = isShiftKeyDown
end)
