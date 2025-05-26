local module = VE.registerModule({
	identifier = "MaxCameraZoom",
	meta = {
		label = "Max Camera Zoom",
		description = "Increases the maximum zoom out distance of the camera.",
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
module.plug:RegisterEvent("ADDON_LOADED")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then
		SlashCmdList["CONSOLE"]("cameraDistanceMax 15")
		SlashCmdList["CONSOLE"]("cameraDistanceMaxFactor 1.9")
		SlashCmdList["CONSOLE"]("cameraDistanceMoveSpeed 8.33")
		SlashCmdList["CONSOLE"]("cameraDistanceSmoothSpeed 8.33")
	end

	SlashCmdList["CONSOLE"]("cameraDistanceMax 50")
	SlashCmdList["CONSOLE"]("cameraDistanceMaxFactor 5")
	SlashCmdList["CONSOLE"]("cameraDistanceMoveSpeed 50")
	SlashCmdList["CONSOLE"]("cameraDistanceSmoothSpeed 1")
end)
