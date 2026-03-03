local module = VE.registerModule({
	identifier = "RaidTargetMarkers",
	meta = {
		label = "Raid Target Markers",
		description = "Easily target or set raid markers. Uses SuperWoW for direct 'mark1-8' targeting.",
	},
	plug = nil,
	superWoWRequired = true,
	config = {
		buttonSize = 32,
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
	return (GetNumPartyMembers() + GetNumRaidMembers()) > 0
end

local function ScanMarkers()
	local found = false
	VE.print("|cff00ff00Scanning for Raid Markers...|r")
	for i = 1, 8 do
		local unit = "mark" .. i
		if UnitExists(unit) then
			local name = UnitName(unit)
			local color = "|cffffff00" -- Default yellow
			VE.print(string.format(" [%s]: %s%s|r", markerNames[i], color, name))
			found = true
		end
	end
	if not found then
		VE.print(" No marked targets found nearby.")
	end
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
	frame:SetPoint("CENTER", 0, -100)
	frame:SetFrameStrata("HIGH")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function() this:StartMoving() end)
	frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

	for i = 1, 8 do
		local index = 9 - i -- Reversed order (Skull to Star)
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
			local unit = "mark" .. index
			if IsShiftKeyDown() then
				-- Set marker on current target
				local isSolo = not InGroupOrRaid()
				SetRaidTarget("target", index, isSolo and 1 or nil)
				VE.print(string.format("Set %s on target.", markerNames[index]))
			else
				-- Target the marked unit
				if UnitExists(unit) then
					TargetUnit(unit)
					VE.print(string.format("Targeted %s: %s", markerNames[index], UnitName(unit)))
				else
					VE.print(string.format("No unit found with %s marker.", markerNames[index]))
				end
			end
		end)

		btn:SetScript("OnEnter", function()
			local unit = "mark" .. index
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:ClearLines()
			GameTooltip:AddLine(markerNames[index], 1, 1, 1)
			if UnitExists(unit) then
				local name = UnitName(unit)
				local health = floor((UnitHealth(unit) / UnitHealthMax(unit)) * 100)
				GameTooltip:AddLine(name, 1, 0.82, 0)
				GameTooltip:AddLine(string.format("Health: %d%%", health), 1, 1, 1)
			else
				GameTooltip:AddLine("<No target>", 0.5, 0.5, 0.5)
			end
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("|cff00ff00Click:|r Target unit", 0.8, 0.8, 0.8)
			GameTooltip:AddLine("|cff00ff00Shift-Click:|r Set marker on target", 0.8, 0.8, 0.8)
			GameTooltip:Show()
		end)

		btn:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	end

	frame:Show()
	return frame
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		if not module.plug.frame then
			module.plug.frame = CreateMarkerFrame()
		end
		-- Wait a bit for units to load before scanning
		VE.executeWithDelay(2, ScanMarkers)
	end
end)

-- Slash Commands
SLASH_SCANMARKS1 = "/scanmarks"
SLASH_SCANMARKS2 = "/sm"
SlashCmdList["SCANMARKS"] = function(msg)
	ScanMarkers()
end
