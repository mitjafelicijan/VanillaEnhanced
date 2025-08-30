local module = VE.registerModule({
	identifier = "TargetChangeStopAttack",
	meta = {
		label = "Stop Attack on Target Change",
		description = "Stops auto attack when player target changes.",
	},
	plug = nil,
	superWoWRequired = true,
	config = {},
	data = {
		previousTarget = nil,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_TARGET_CHANGED")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	local exists, guid = UnitExists("target")

	if module.data.previousTarget == nil then
		module.data.previousTarget = guid
	end

	if module.data.previousTarget ~= guid then
		module.data.previousTarget = guid
		ClearTarget()
		TargetLastTarget()
	end
end)
