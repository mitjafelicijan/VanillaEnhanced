local module = VE.registerModule({
	identifier = "RaidTargetMarkers",
	meta = {
		label = "Raid Target Markers",
		description = "Easily target raid markers. Uses SuperWoW for direct 'mark1-8' targeting.",
	},
	plug = nil,
	superWoWRequired = true,
	config = {
		buttonSize = 24,
		padding = 6,
		updateInterval = 0.2,
	},
	data = {
		buttons = {},
	},
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
	frame:SetPoint("CENTER", 0, -80)
	frame:SetFrameStrata("HIGH")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function() this:StartMoving() end)
	frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

	for index = 1, 8 do
		local btn = CreateFrame("Button", nil, frame)
		btn:SetWidth(size)
		btn:SetHeight(size)
		btn.index = index

		local tex = btn:CreateTexture(nil, "ARTWORK")
		tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
		tex:SetAllPoints()
		btn.tex = tex

		local left = mod(index - 1, 4) * 0.25
		local right = left + 0.25
		local top = floor((index - 1) / 4) * 0.25
		local bottom = top + 0.25
		tex:SetTexCoord(left, right, top, bottom)

		btn:SetScript("OnClick", function()
			local unit = "mark" .. this.index
			-- Target the marked unit
			if UnitExists(unit) then
				TargetUnit(unit)
				VE.print(string.format("Targeted %s: %s", markerNames[this.index], UnitName(unit)))
			else
				VE.print(string.format("No unit found with %s marker.", markerNames[this.index]))
			end
		end)

		btn:SetScript("OnEnter", function()
			local unit = "mark" .. this.index
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:ClearLines()
			
			local exists, guid = UnitExists(unit)
			if exists then
				local name = UnitName(unit)
				local level = UnitLevel(unit)
				if level == -1 then level = "??" end
				local classification = UnitClassification(unit)
				local type = UnitCreatureType(unit) or ""
				local health = floor((UnitHealth(unit) / UnitHealthMax(unit)) * 100)
				
				local classStr = ""
				if classification == "worldboss" or classification == "elite" or classification == "rareelite" then
					classStr = " (Elite)"
				end

				-- Header: Marker Name and Health
				GameTooltip:AddDoubleLine(markerNames[this.index], string.format("Health: %d%%", health), 1, 1, 1, 1, 1, 1)
				
				-- Line 1: Name with Class/Reaction coloring
				local r, g, b = 1, 0.82, 0
				if UnitIsPlayer(unit) then
					local _, class = UnitClass(unit)
					if class then
						local classKey = string.upper(string.sub(class, 1, 1)) .. string.lower(string.sub(class, 2))
						if VE.config.ClassColors[classKey] then
							r, g, b = VE.config.ClassColors[classKey].r, VE.config.ClassColors[classKey].g, VE.config.ClassColors[classKey].b
						end
					end
				else
					if UnitIsFriend("player", unit) then
						r, g, b = 0.1, 1, 0.1
					elseif UnitCanAttack("player", unit) then
						r, g, b = 1, 0.1, 0.1
					else
						r, g, b = 1, 1, 0.1
					end
				end
				GameTooltip:AddLine(name, r, g, b)
				
				-- Line 2: Level / Type
				GameTooltip:AddLine(string.format("Level %s %s%s", level, type, classStr), 0.8, 0.8, 0.8)

				-- Line 3: Target of Target (Aggro)
				local target = guid .. "target"
				if UnitExists(target) then
					local targetName = UnitName(target)
					GameTooltip:AddLine("Target: " .. targetName)
				end
			else
				GameTooltip:AddLine(markerNames[this.index], 1, 1, 1)
				GameTooltip:AddLine("<No target>", 0.5, 0.5, 0.5)
			end
			GameTooltip:Show()
		end)

		btn:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		module.data.buttons[index] = btn
	end

	frame.timeSinceLastUpdate = 0
	frame:SetScript("OnUpdate", function()
		if not arg1 then return end
		this.timeSinceLastUpdate = this.timeSinceLastUpdate + arg1
		if this.timeSinceLastUpdate >= module.config.updateInterval then
			this.timeSinceLastUpdate = 0
			
			local visibleCount = 0
			-- Reverse order: Skull (8) to Star (1)
			for i = 1, 8 do
				local idx = 9 - i
				local btn = module.data.buttons[idx]
				local unit = "mark" .. idx
				if UnitExists(unit) and not UnitIsDead(unit) then
					visibleCount = visibleCount + 1
					btn:ClearAllPoints()
					btn:SetPoint("LEFT", this, "LEFT", padding + (visibleCount - 1) * (size + padding), 0)
					btn:Show()
				else
					btn:Hide()
				end
			end
			
			if visibleCount > 0 then
				this:SetWidth((size + padding) * visibleCount + padding)
			else
				this:SetWidth(1)
			end
		end
	end)

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

		VE.executeWithDelay(2, ScanMarkers)
	end
end)

-- Slash Commands
SLASH_SCANMARKS1 = "/scanmarks"
SLASH_SCANMARKS2 = "/sm"
SlashCmdList["SCANMARKS"] = function(msg)
	ScanMarkers()
end
