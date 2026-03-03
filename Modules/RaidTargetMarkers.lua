local module = VE.registerModule({
	identifier = "RaidTargetMarkers",
	meta = {
		label = "Raid Target Markers",
		description = "Creates a frame at the center of the screen with raid target markers buttons.",
	},
	plug = nil,
	superWoWRequired = true,
	config = {
		buttonSize = 24,
		padding = 4,
	},
	data = {},
})

VE.enableModule(module.identifier)

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local markerNames = { "Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull" }

local function InGroupOrRaid()
	return GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
end

local function CreateMarkerFrame()
	local size = module.config.buttonSize
	local padding = module.config.padding
	local numButtons = 8
	local width = (size + padding) * numButtons + padding
	local height = size + (padding * 2)

	local frame = CreateFrame("Frame", "RaidTargetMarkersFrame", UIParent)
	frame:SetWidth(width)
	frame:SetHeight(height)
	frame:SetPoint("CENTER", 0, -80)
	frame:SetFrameStrata("HIGH")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function() this:StartMoving() end)
	frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

	for i = 1, 8 do
		local index = 9 - i
		local btn = CreateFrame("Button", nil, frame)
		btn:SetWidth(size)
		btn:SetHeight(size)
		btn:SetPoint("LEFT", frame, "LEFT", padding + (i - 1) * (size + padding), 0)

		local tex = btn:CreateTexture(nil, "ARTWORK")
		tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
		tex:SetAllPoints()

		local left = mod(index - 1, 4) * 0.25
		local right = left + 0.25
		local top = floor((index - 1) / 4) * 0.25
		local bottom = top + 0.25
		tex:SetTexCoord(left, right, top, bottom)

		btn:SetScript("OnClick", function()
			-- Index 1-8. If solo and using SuperWoW, use local flag (3rd arg).
			local isSolo = not InGroupOrRaid()
			SetRaidTarget("target", index, isSolo and 1 or nil)
			VE.print("Clicked marker: " .. markerNames[index])
		end)
	end

	frame:Show()
	return frame
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" and not module.plug.frame then
		module.plug.frame = CreateMarkerFrame()
	end
end)
