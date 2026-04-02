local module = VE.registerModule({
	identifier = "CompactRaidFrames",
	meta = {
		label = "Compact Raid Frames v2",
		description = "",
	},
	plug = nil,
	superWoWRequired = true,
	config = {
		unitFrame = {
			width = 82,
			height = 40,
			powerBarHeight = 8,
		},
		nameFormatters = {
			group = "VanillaEnhancedCompactRaidFramesGroup%d",
			unit = "VanillaEnhancedCompactRaidFramesGroup%dMember%d",
		},
		groupsPerRow = 4,
	},
	data = {
		currentlyHighlightedUnitFrame = nil,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function IsRaid()
	if GetNumRaidMembers() > 0 then return true end
	return false
end

local function IsParty()
	if GetNumPartyMembers() > 0 and GetNumRaidMembers() == 0 then return true end
	return false
end

local function GetUnitInfo(unit)
	if not UnitExists(unit) then return nil end

	local payload = {
		name = nil,
		alias = nil,
		class = nil,
		health = { current = 0, max = 0, percentage = 0 },
		power = { current = 0, max = 0, percentage = 0, name = "unknown" },
		buffs = {},
		debuffs = {},
		hots = {},
		dispell = {},
		group = 0,
		inRange = 0,
		isOnline = nil,
		isDead = 0,
		rank = 0, -- 0 normal, 1 assist, 2 lead
	}

	payload.unit = unit
	payload.name = UnitName(unit)

	payload.health.current = UnitHealth(unit)
	payload.health.max = UnitHealthMax(unit)
	if payload.health.current > 0 then
		payload.health.percentage = math.floor((payload.health.current / payload.health.max) * 100 + 0.5)
	end

	payload.power.current = UnitMana(unit)
	payload.power.max = UnitManaMax(unit)
	if payload.power.current > 0 then
		payload.power.percentage = math.floor((payload.power.current / payload.power.max) * 100 + 0.5)
	end

	local powerType = UnitPowerType(unit)
	if powerType == 0 then
		payload.power.name = "Mana"
	elseif powerType == 1 then
		payload.power.name = "Rage"
	elseif powerType == 2 then
		payload.power.name = "Focus"
	elseif powerType == 3 then
		payload.power.name = "Energy"
	end

	-- payload.group = GetMemberGroup(payload.name)
	payload.class = UnitClass(unit)
	payload.inRange = (CheckInteractDistance(unit, 4))

	if UnitIsConnected(unit) then payload.isOnline = 1 end

	-- Checks if unit is party or raid lead.
	payload.lead = UnitIsPartyLeader(unit)

	-- Checks if unit is raid assist.
	if IsRaid() then
		for i = 1, GetNumRaidMembers() do
			local name, rank = GetRaidRosterInfo(i)
			if name == payload.name then
				payload.rank = rank
				break
			end
		end
	end

	if UnitIsDeadOrGhost(unit) then payload.isDead = 1 else payload.isDead = 0 end

	-- Attaches unit auras.
	-- payload.buffs, payload.debuffs, payload.hots, payload.dispell = UnitAuras(unit)

	return payload
end

local function HighlightUnitFrame(unit)
end

local function CreateUnitFrame(unit, groupIdx, unitIdx, parent)
	local unitFrame = CreateFrame("Button", string.format(module.config.nameFormatters.unit, groupIdx, unitIdx), parent)
	unitFrame:SetWidth(module.config.unitFrame.width)
	unitFrame:SetHeight(module.config.unitFrame.height)
	unitFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((unitIdx - 1) * module.config.unitFrame.height))

	-- Important meta data.
	unitFrame.unit = unit or "player"

	-- Unit selection.
	unitFrame:EnableMouse(true)
	unitFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	unitFrame:SetScript("OnClick", function()
		if module.data.currentlyHighlightedUnitFrame and module.data.currentlyHighlightedUnitFrame.highlight then
			module.data.currentlyHighlightedUnitFrame.highlight:Hide()
		end

		module.data.currentlyHighlightedUnitFrame = this
		this.highlight:Show()
		TargetUnit(this.unit)
	end)

	-- This is a black background of a frame.
	VE.dframe(unitFrame, 0.05, 0.05, 0.05, 1)

	-- Health Bar.
	unitFrame.healthBar = CreateFrame("StatusBar", "$parentHealthBar", unitFrame)
	unitFrame.healthBar:SetWidth(module.config.unitFrame.width)
	unitFrame.healthBar:SetHeight(module.config.unitFrame.height - module.config.unitFrame.powerBarHeight)
	unitFrame.healthBar:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 0, 0)
	unitFrame.healthBar:SetStatusBarTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-HealthFill")
	unitFrame.healthBar:SetFrameLevel(unitFrame:GetFrameLevel() + 1)
	unitFrame.healthBar:Show()

	-- Power Bar.
	unitFrame.powerBar = CreateFrame("StatusBar", "$parentPowerBar", unitFrame)
	unitFrame.powerBar:SetWidth(module.config.unitFrame.width)
	unitFrame.powerBar:SetHeight(module.config.unitFrame.powerBarHeight + 1) -- A bit of padding hotfix
	unitFrame.powerBar:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 0, -(module.config.unitFrame.height - module.config.unitFrame.powerBarHeight))
	unitFrame.powerBar:SetStatusBarTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-PowerFill")
	unitFrame.powerBar:SetFrameLevel(unitFrame:GetFrameLevel() + 1)
	unitFrame.powerBar:Show()

	-- Overlay frame above bars.
	unitFrame.overlay = CreateFrame("Frame", "$parentOverlay", unitFrame)
	unitFrame.overlay:SetAllPoints(unitFrame)
	unitFrame.overlay:SetFrameLevel(unitFrame:GetFrameLevel() + 10)
	unitFrame.overlay:Show()

	-- Border square around unit frame.
	unitFrame.border = unitFrame.overlay:CreateTexture("$parentHighlight", "OVERLAY")
	unitFrame.border:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-UnitBorder")
	unitFrame.border:SetAllPoints(unitFrame.overlay)
	unitFrame.border:SetDrawLayer("OVERLAY", 4)
	unitFrame.border:Show()

	-- Unit name.
	unitFrame.name = unitFrame.overlay:CreateFontString("$parentNameText", "OVERLAY", "GameFontHighlightSmall")
	unitFrame.name:SetPoint("TOPLEFT", unitFrame.overlay, "TOPLEFT", 3, -3)
	unitFrame.name:SetDrawLayer("OVERLAY", 5)
	unitFrame.name:SetText("Player " .. tostring(unitIdx))

	-- Dead label.
	unitFrame.dead = unitFrame.overlay:CreateFontString("$parentNameText", "OVERLAY", "GameFontHighlightSmall")
	unitFrame.dead:SetPoint("CENTER", unitFrame.overlay, "CENTER", 0, -3)
	unitFrame.dead:SetDrawLayer("OVERLAY", 5)
	unitFrame.dead:SetText("Dead")
	unitFrame.dead:Hide()

	-- Highlight square around unit frame.
	unitFrame.highlight = unitFrame.overlay:CreateTexture("$parentHighlight", "OVERLAY")
	unitFrame.highlight:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-Highlight")
	unitFrame.highlight:SetAllPoints(unitFrame.overlay)
	unitFrame.highlight:SetDrawLayer("OVERLAY", 7)
	unitFrame.highlight:SetVertexColor(1, 1, 1, 1)
	unitFrame.highlight:SetBlendMode("BLEND")
	unitFrame.highlight:Hide()

	local unitInfo = GetUnitInfo(unit)
	local powerColor = VE.config.PowerColors[unitInfo.power.name]
	local healthColor = VE.config.ClassColors[unitInfo.class]

	if powerColor and healthColor then
		unitFrame.healthBar:SetStatusBarColor(healthColor.r, healthColor.g, healthColor.b)
		unitFrame.healthBar:SetMinMaxValues(0, unitInfo.health.max)
		unitFrame.healthBar:SetValue(unitInfo.health.current)
		-- unitFrame.healthBar:SetValue(300)

		unitFrame.powerBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)
		unitFrame.powerBar:SetMinMaxValues(0, unitInfo.power.max)
		-- unitFrame.powerBar:SetValue(500)
	end

	table.insert(module.plug.placeholder.groups[groupIdx].units, unitIdx, unitFrame)
	unitFrame:Show()

	-- Register events and hook into events.
end

local function CreateGroupFrame(groupIdx)
	local col = (groupIdx - 1) - math.floor((groupIdx - 1)/module.config.groupsPerRow)*module.config.groupsPerRow
	local row = math.floor((groupIdx - 1)/module.config.groupsPerRow)
	local x = col * module.config.unitFrame.width
	local y = -row * (module.config.unitFrame.height * 5)

	local groupFrame = CreateFrame("Button", string.format(module.config.nameFormatters.group, groupIdx), module.plug.placeholder)
	groupFrame:SetWidth(module.config.unitFrame.width)
	groupFrame:SetHeight(module.config.unitFrame.height * 5)
	groupFrame:SetPoint("TOPLEFT", module.plug.placeholder, "TOPLEFT", x, y)
	groupFrame:SetFrameLevel(10)

	groupFrame.nameText = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	groupFrame.nameText:SetPoint("TOPLEFT", groupFrame, "TOPLEFT", 3, -3)
	groupFrame.nameText:SetText("Group "..tostring(groupIdx))

	-- VE.dframe(groupFrame, 0, 1, 0, 0.5)
	table.insert(module.plug.placeholder.groups, groupIdx, groupFrame)

	groupFrame.units = {}

	for unitIdx = 1, 5 do
		CreateUnitFrame("player", groupIdx, unitIdx, module.plug.placeholder.groups[groupIdx])
	end
end

local function CreateAllFrames()
	module.plug.placeholder = CreateFrame("Button", "VanillaEnhancedCompactRaidFrames", UIParent)
	module.plug.placeholder:SetWidth(module.config.unitFrame.width * 4)      -- columns: 4 groups
	module.plug.placeholder:SetHeight(module.config.unitFrame.height * 10)   -- rows: 2 groups by 5 members
	module.plug.placeholder:SetPoint("TOPLEFT", 10, -200)
	module.plug.placeholder.groups = {}
	-- VE.dframe(module.plug.placeholder, 1, 0, 0, 1)

	for groupIdx = 1, 8 do
		CreateGroupFrame(groupIdx)
	end

	module.plug.placeholder:RegisterEvent("PLAYER_TARGET_CHANGED")
	module.plug.placeholder:SetScript("OnEvent", function()
		if event == "PLAYER_TARGET_CHANGED" then
			VE.print(">>>>> inside")
		end
	end)
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		CreateAllFrames()
	end
end)
