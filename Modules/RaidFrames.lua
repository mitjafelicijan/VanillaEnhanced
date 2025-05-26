-- https://github.com/refaim/Turtle-WoW-UI-Source/blob/c7543cafa6fb2aed6458f62f18af97203317a892/Interface/FrameXML/UnitFrame.lua#L58

local module = VE.registerModule({
	identifier = "RaidFrames",
	meta = {
		label = "Compact Raid and Party Frames",
		description = "Compact Raid and Party frames, similar to the default raid frames seen in 2010 cataclysm and 2019 Classic and later.",
	},
	plug = {
		party = nil,
		raid = nil,
	},
	superWoWRequired = true,
	config = {
		hasBorder = true,
		numRows = 2,
		rowPadding = 24,
		defaultPosition = {
			party = { x = 20, y = -180 },
			raid = { x = 20, y = -180 },
		},
		-- TODO: Clean position vs defaultPosition mess.
		position = {
			party = { x = 20, y = -180 },
			raid = { x = 20, y = -180 },
		},
		buffFrame = {
			icon = { size = 13, spacing = 0.3 }
		},
		debuffFrame = {
			icon = { size = 14, spacing = -4 }
		},
		unitFrame = {
			width = 85,
			height = 40,
			healthHeight = 34,
			powerHeight = 6,
		},
		rangeSpell = "Flash Heal",
		hots = {
			"Interface\\Icons\\Spell_Nature_ResistNature",   -- Druid: Regrowth
			"Interface\\Icons\\Spell_Nature_Rejuvenation",   -- Druid: Rejuvenation
			"Interface\\Icons\\Spell_Nature_Tranquility",    -- Druid: Tranquility
			"Interface\\Icons\\Spell_Holy_Renew",            -- Priest: Renew
			"Interface\\Icons\\Spell_Holy_PowerWordShield",  -- Priest: Power Word: Shield
			"Interface\\Icons\\INV_Spear_04",                -- Shaman: Healing Stream Totem
			"Interface\\Icons\\Spell_Holy_Heal",             -- Bandage / Icon gets replaced
		},
	},
	data = {
		party = {},
		raid = {},
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

local function RaidMemeberGroup(playerName)
	local group = 0
	for i = 1, GetNumRaidMembers() do
		local name, _, subgroup = GetRaidRosterInfo(i)
		if name == playerName then
			group = subgroup
			break
		end
	end
	return group
end

local function ValidUnits()
	local payload = {
		players = {},
		pets = {},
	}

	if IsParty() then
		-- Add yourself to the roster if in party.
		table.insert(payload.players, "player")

		for i = 1, MAX_PARTY_MEMBERS do
			local unit =  "party" .. i
			if UnitExists(unit) then
				table.insert(payload.players, unit)
			end

			local pet = "partypet" .. i
			if UnitExists(pet) then
				table.insert(payload.pets, pet)
			end
		end
	end

	if IsRaid() then
		for i = 1, MAX_RAID_MEMBERS do
			local unit =  "raid" .. i
			if UnitExists(unit) then
				table.insert(payload.players, unit)
			end

			local pet = "raidpet" .. i
			if UnitExists(pet) then
				table.insert(payload.pets, pet)
			end
		end
	end

	return payload
end

local function UnitAuras(unit)
	local payload = {
		buffs = {},
		debuffs = {},
		hots = {},
	}

	-- Buffs
	for j = 1, 16 do
		local texture, applications = UnitBuff(unit, j)
		if texture then
			table.insert(payload.buffs, {
				texture = texture,
				applications = applications,
			})
		else break end
	end

	-- Debuffs
	for j = 1, 16 do
		local texture, applications, dispelType = UnitDebuff("player", j, 1)
		if texture then
			-- "Magic", "Curse", "Poison", "Disease"
			texture = string.format("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-Debuff%s", dispelType)
			table.insert(payload.debuffs, {
				texture = texture,
				applications = applications,
				dispelType = dispelType,
			})
		else break end
	end

	-- HOTs.
	for i = table.getn(payload.buffs), 1, -1 do
		local buff = payload.buffs[i]
		for _, hot in module.config.hots do
			if buff.texture == hot then

				-- Replacing with bandage icon.
				if buff.texture == "Interface\\Icons\\Spell_Holy_Heal" then
					buff.texture = "Interface\\Icons\\INV_Misc_Bandage_08"
				end

				table.insert(payload.hots, {
					texture = buff.texture,
					applications = buff.applications,
				})
			end
		end
	end

	return payload.buffs, payload.debuffs, payload.hots
end

local function UnitState(unit)
	-- if not UnitExists(unit) then return nil end

	local payload = {
		id = 0,
		name = nil,
		alias = nil,
		class = nil,
		health = { current = 0, max = 0, percentage = 0 },
		power = { current = 0, max = 0, percentage = 0, name = "unknown" },
		buffs = {},
		debuffs = {},
		hots = {},
		group = 0,
		inRange = -1,
		isOnline = 0,
		isDead = 0,
		rank = 0, -- 0 normal, 1 assist, 2 lead
		lead = 0,
		focused = 0,
	}

	payload.alias = unit
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

	payload.group = RaidMemeberGroup(payload.name)
	payload.class = UnitClass(unit)

	if UnitIsConnected(unit) then payload.isOnline = 1 end

	-- Checks if unit is party or raid lead.
	if UnitIsPartyLeader(unit) then payload.lead = 1 end

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

	-- Checks if unit is in range.
	payload.inRange = (CheckInteractDistance(unit, 4))

	-- Attaches unit auras.
	payload.buffs, payload.debuffs, payload.hots = UnitAuras(unit)

	return payload
end

local function UnitFrame(frameName, parent, unitAlias, memberIndex, groupHasBorder)
	local borderPadding = groupHasBorder and 8 or 0

	local healthColor = VE.config.ClassColors["Warrior"]
	local powerColor = VE.config.PowerColors["Rage"]

	local frame = CreateFrame("Button", frameName, parent)
	frame.unit = unitAlias
	frame.data = nil
	frame.lastUpdate = 0
	frame:SetID(0)
	frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	frame:SetPoint("TopLeft", parent, "TopLeft", 4, -module.config.unitFrame.height * (memberIndex-1) - 4)
	frame:SetWidth(module.config.unitFrame.width)
	frame:SetHeight(module.config.unitFrame.height)
	frame:EnableMouse(true)
	frame:SetFrameLevel(1)

	frame:SetScript("OnEnter", function()
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
		GameTooltip:SetUnit(this.unit)
		GameTooltip:Show()
	end)

	frame:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	frame:SetScript("OnClick", function()
		if arg1 == "LeftButton" then
			TargetUnit(frame.unit)
		end

		-- TODO: Add context menus for right click.
		-- if arg1 == "RightButton" then
		-- 	ToggleDropDownMenu(1, nil, getglobal('PartyMemberFrame2DropDown'), nil, 100, 25)
		-- end
	end)

	frame:SetScript("OnUpdate", function()
		this.lastUpdate = (this.lastUpdate or 0) + arg1
		if this.lastUpdate >= 0.5 then
			if CheckInteractDistance(frame.unit, 4) then
				frame.health:SetAlpha(1.0)
				frame.power:SetAlpha(1.0)
			else
				frame.health:SetAlpha(0.5)
				frame.power:SetAlpha(0.5)
			end
			this.lastUpdate = this.lastUpdate - 0.5
		end
	end)

	-- Button background.
	frame.bg = frame:CreateTexture(nil, "BACKGROUND")
	frame.bg:SetAllPoints(frame)
	frame.bg:SetTexture(0, 0, 0, 0.8)

	-- Health bar Predict.
	-- frame.healthPredict = CreateFrame("StatusBar", frameName .. "HealthPredictBar", frame, "TextStatusBar")
	-- frame.healthPredict:SetPoint("TopLeft", frame, "TopLeft", 0, 0)
	-- frame.healthPredict:EnableMouse(false)
	-- frame.healthPredict:SetWidth(module.config.unitFrame.width)
	-- frame.healthPredict:SetHeight(module.config.unitFrame.healthHeight)
	-- frame.healthPredict:SetStatusBarTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-HealthFill")
	-- frame.healthPredict:SetStatusBarColor(0, 1, 0)
	-- frame.healthPredict:SetMinMaxValues(0, 100)
	-- frame.healthPredict:SetValue(100)
	-- frame.healthPredict:SetFrameLevel(1)
	
	-- Health bar.
	frame.health = CreateFrame("StatusBar", frameName .. "HealthBar", frame, "TextStatusBar")
	frame.health:SetPoint("TopLeft", frame, "TopLeft", 0, 0)
	frame.health:EnableMouse(false)
	frame.health:SetWidth(module.config.unitFrame.width)
	frame.health:SetHeight(module.config.unitFrame.healthHeight)
	frame.health:SetStatusBarTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-HealthFill")
	frame.health:SetStatusBarColor(healthColor.r, healthColor.g, healthColor.b)
	frame.health:SetFrameLevel(2)
	frame.health.unit = unitAlias
	frame.health:RegisterEvent("UNIT_HEALTH")
	frame.health:RegisterEvent("UNIT_MAXHEALTH")
	frame.health:SetScript("OnEvent", function()
		if arg1 == this.unit then
			local state = UnitState(this.unit)
			if state and state.class then
				local healthColor = VE.config.ClassColors[state.class]
				if not healthColor then return end
				this:SetStatusBarColor(healthColor.r, healthColor.g, healthColor.b)
				this:SetMinMaxValues(0, state.health.max)
				this:SetValue(state.health.current)
				if state.isDead == 1 then frame.dead:Show() else frame.dead:Hide() end
			end
		end
	end)
	
	-- Power bar.
	frame.power = CreateFrame("StatusBar", frameName .. "PowerBar", frame, "TextStatusBar")
	frame.power:SetPoint("TopLeft", frame, "TopLeft", 0, -module.config.unitFrame.healthHeight)
	frame.power:EnableMouse(false)
	frame.power:SetWidth(module.config.unitFrame.width)
	frame.power:SetHeight(module.config.unitFrame.powerHeight)
	frame.power:SetStatusBarTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-PowerFill")
	frame.power:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b, 1.0)
	frame.power.unit = unitAlias
	frame.power:RegisterEvent("UNIT_MANA")
	frame.power:RegisterEvent("UNIT_RAGE")
	frame.power:RegisterEvent("UNIT_FOCUS")
	frame.power:RegisterEvent("UNIT_ENERGY")
	frame.power:RegisterEvent("UNIT_HAPPINESS")
	frame.power:RegisterEvent("UNIT_MAXMANA")
	frame.power:RegisterEvent("UNIT_MAXRAGE")
	frame.power:RegisterEvent("UNIT_MAXFOCUS")
	frame.power:RegisterEvent("UNIT_MAXENERGY")
	frame.power:RegisterEvent("UNIT_MAXHAPPINESS")
	frame.power:RegisterEvent("UNIT_DISPLAYPOWER")
	frame.power:SetScript("OnEvent", function()
		if arg1 == this.unit then
			local state = UnitState(this.unit)
			if state and state.power.name then
				local powerColor = VE.config.PowerColors[state.power.name]
				if not powerColor then return end
				this:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)
				this:SetMinMaxValues(0, state.power.max)
				this:SetValue(state.power.current)
			end
		end
	end)

	-- Unit name.
	frame.name = frame.health:CreateFontString(nil, "HIGH", "GameFontHighlightSmall")
	frame.name:SetPoint("TopLeft", frame.health, "TopLeft", 16, -3)
	frame.name:SetText(unitAlias)

	-- Unit leader
	frame.lead = frame.health:CreateTexture(nil, "OVERLAY")
	frame.lead:SetPoint("TopLeft", frame.health, "TopLeft", 3, -2)
	frame.lead:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-Leader")
	frame.lead:SetWidth(12)
	frame.lead:SetHeight(12)
	frame.lead:Hide()

	-- Unit Assistant
	frame.assistant = frame.health:CreateTexture(nil, "OVERLAY")
	frame.assistant:SetPoint("TopLeft", frame.health, "TopLeft", 3, -2)
	frame.assistant:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-Assistant")
	frame.assistant:SetWidth(12)
	frame.assistant:SetHeight(12)
	frame.assistant:Hide()

	-- Buff.buffs.
	frame.buffs = CreateFrame("StatusBar", frameName .. "AuraBuffFrame", frame.health)
	frame.buffs:SetAllPoints(frame.health)
	frame.buffs.unit = unitAlias
	frame.buffs.list = {}

	local offset = 0
	for i = 1, 5 do
		local aura = frame.buffs:CreateTexture(frameName .. "BuffAura" .. tostring(i), "ARTWORK")
		aura:SetTexture("Interface\\Icons\\INV_Spear_04")
		aura:SetWidth(module.config.buffFrame.icon.size)
		aura:SetHeight(module.config.buffFrame.icon.size)
		if i > 1 then
			offset = offset + (module.config.buffFrame.icon.size) + module.config.buffFrame.icon.spacing
		end
		aura:SetPoint("BottomLeft", frame.buffs, "BottomLeft", 2 + offset, 2)
		aura:Hide()

		table.insert(frame.buffs.list, aura)
	end

	frame.buffs:RegisterEvent("UNIT_AURA")
	frame.buffs:SetScript("OnEvent", function()
		if not frame.data then return end
		if UnitName(arg1) == frame.data.name then
			local state = frame.data
			if state then
				for _, aura in pairs(this.list) do aura:Hide() end
				state.buffs, state.debuffs, state.hots = UnitAuras(this.unit)
				if state.hots then
					for i, hot in pairs(state.hots) do
						local aura = this.list[i]
						aura:SetTexture(hot.texture)
						aura:Show()
					end
				end
			end
		end
	end)

	-- -- Dispellable debuffs.
	frame.debuffs = CreateFrame("StatusBar", frameName .. "AuraDebuffFrame", frame.health)
	frame.debuffs:SetAllPoints(frame.health)
	frame.debuffs.unit = unitAlias
	frame.debuffs.list = {}

	local offset = 0
	for i = 1, 5 do
		local aura = frame.debuffs:CreateTexture(frameName .. "DebuffAura" .. tostring(i), "ARTWORK")
		aura:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-DebuffMagic")
		aura:SetWidth(module.config.debuffFrame.icon.size)
		aura:SetHeight(module.config.debuffFrame.icon.size)
		if i > 1 then
			offset = offset + (module.config.debuffFrame.icon.size) + module.config.debuffFrame.icon.spacing
		end
		aura:SetPoint("BottomRight", frame.debuffs, "BottomRight", -2 - offset, 2)
		aura:Hide()

		table.insert(frame.debuffs.list, aura)
	end

	frame.debuffs:RegisterEvent("UNIT_AURA")
	frame.debuffs:SetScript("OnEvent", function()
		if not frame.data then return end
		if UnitName(arg1) == frame.data.name then
			local state = frame.data
			if state then
				for _, aura in pairs(this.list) do aura:Hide() end
				state.buffs, state.debuffs, state.hots = UnitAuras(this.unit)
				if state.debuffs then
					for i, debuff in pairs(state.debuffs) do
						local aura = this.list[i]
						aura:SetTexture(debuff.texture)
						aura:Show()
					end
				end
			end
		end
	end)

	-- Disconnect.
	frame.disconnect = CreateFrame("Frame", nil, frame)
	frame.disconnect:SetPoint("Center", frame, "Center", 0, -7)
	frame.disconnect:SetWidth(32)
	frame.disconnect:SetHeight(32)
	frame.disconnect:SetFrameLevel(10)
	frame.disconnect.tex = frame.disconnect:CreateTexture(nil, "OVERLAY")
	frame.disconnect.tex:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-Disconnect")
	frame.disconnect.tex:SetAllPoints(frame.disconnect)
	frame.disconnect:Hide()

	-- Focus unit border.
	frame.focused = CreateFrame("Frame", nil, frame)
	frame.focused:SetAllPoints(frame)
	frame.focused:SetFrameLevel(10)
	frame.focused.tex = frame.focused:CreateTexture(nil, "OVERLAY")
	frame.focused.tex:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-Highlight")
	frame.focused.tex:SetAllPoints(frame.focused)
	frame.focused:Hide()

	-- Unit dead label.
	frame.dead = frame.health:CreateFontString(nil, "HIGH", "GameFontHighlightSmall")
	frame.dead:SetPoint("Center", frame, "Center", 0, -5)
	frame.dead:SetText("DEAD")
	frame.dead:Hide()

	return frame
end

local function GroupFrame(parent, groupIndex, groupPrefix, hasBorder)
	local borderPadding = hasBorder and 6 or 1
	local rowOffset = groupIndex
	local numColumns = (8 / module.config.numRows)
	local x, y = 0, 0

	if rowOffset > numColumns then
		y = - ((module.config.unitFrame.height * 5) + module.config.rowPadding)
		rowOffset = rowOffset - numColumns
	end

	x = ((rowOffset-1) * (module.config.unitFrame.width + borderPadding))

	local group = CreateFrame("Frame", "GroupFrame" .. tostring(groupIndex), parent)
	group:SetPoint("TopLeft", parent, "TopLeft", x, y)
	group:SetWidth(module.config.unitFrame.width + 8)
	group:SetHeight((module.config.unitFrame.height * 5) + 8)
	group:EnableMouse(false)
	group:SetFrameLevel(3)

	if hasBorder then
		group:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 16,
		})
	end

	group.name = group:CreateFontString(nil, "HIGH", "GameFontNormalSmall")
	group.name:SetPoint("Center", group, "Top", 0, 6)

	if groupPrefix == "party" then
		group.name:SetText("Party")
	else
		group.name:SetText("Group " .. tostring(groupIndex))
	end

	local groupName = "GroupFrame" .. tostring(groupIndex)
	if groupPrefix == "party" then groupName = "PartyFrame" end

	for idx = 1, 5 do
		local frameName = groupName .. "MemberFrame" .. tostring(idx)
		local unitAlias = groupPrefix .. tostring(((groupIndex - 1) * 5) + idx)
		UnitFrame(frameName, group, unitAlias, idx, hasBorder)
	end
end

local function CreatePartyFrames(parent)
	parent.party = CreateFrame("Frame", nil, UIParent)
	parent.party:SetPoint("TopLeft", UIParent, "TopLeft", module.config.position.party.x, module.config.position.party.y)
	parent.party:SetWidth(module.config.unitFrame.width + (10 * 1))
	parent.party:SetHeight(module.config.unitFrame.height * 5 + 10)
	parent.party:SetFrameStrata("LOW")
	parent.party:SetMovable(true)

	parent.party.move = CreateFrame("Frame", nil, parent.party)
	parent.party.move:SetAllPoints(parent.party)
	parent.party.move:SetFrameStrata("HIGH")
	parent.party.move:EnableMouse(false)
	parent.party.move:SetClampedToScreen(true)
	parent.party.move.tex = parent.party.move:CreateTexture(nil, "BACKGROUND")
	parent.party.move.tex:SetAllPoints(parent.party.move)
	parent.party.move.tex:SetTexture(0, 0, 0, 0.8)
	parent.party.move.text = parent.party.move:CreateFontString(nil, "HIGH", "GameFontNormal")
	parent.party.move.text:SetPoint("Center", parent.party.move, "Center", 0, -30)
	parent.party.move.text:SetText("Move")

	parent.party.move:SetScript("OnMouseDown", function()
		parent.party:StartMoving()
	end)

	parent.party.move:SetScript("OnMouseUp", function()
		local _, _, _, x, y = module.plug.party:GetPoint()
		module.config.position.party.x = x
		module.config.position.party.y = y
		VanillaEnhancedData.position = module.config.position
		parent.party:StopMovingOrSizing()
	end)

	GroupFrame(parent.party, 1, "party", module.config.hasBorder)

	parent.party.move:Hide()
	parent.party:Hide()
end

local function CreateRaidFrames(parent)
	parent.raid = CreateFrame("Frame", nil, UIParent)
	parent.raid:SetPoint("TopLeft", UIParent, "TopLeft", module.config.position.raid.x, module.config.position.raid.y)
	parent.raid:SetWidth((module.config.unitFrame.width * 8 + (10 * 5)) / module.config.numRows)
	parent.raid:SetHeight((module.config.unitFrame.height * 5 + (8 * module.config.numRows)) * module.config.numRows)
	parent.raid:SetFrameStrata("LOW")
	parent.raid:SetMovable(true)
	parent.raid:EnableMouse(false)
	parent.raid:SetClampedToScreen(true)

	parent.raid.move = CreateFrame("Frame", nil, parent.raid)
	parent.raid.move:SetAllPoints(parent.raid)
	parent.raid.move:SetFrameStrata("HIGH")
	parent.raid.move:EnableMouse(false)
	parent.raid.move:SetClampedToScreen(true)
	parent.raid.move.tex = parent.raid.move:CreateTexture(nil, "BACKGROUND")
	parent.raid.move.tex:SetAllPoints(parent.raid.move)
	parent.raid.move.tex:SetTexture(0, 0, 0, 0.8)
	parent.raid.move.text = parent.raid.move:CreateFontString(nil, "HIGH", "GameFontNormal")
	parent.raid.move.text:SetPoint("Center", parent.raid.move, "Center", 0, -30)
	parent.raid.move.text:SetText("Move")

	parent.raid.move:SetScript("OnMouseDown", function()
		parent.raid:StartMoving()
	end)

	parent.raid.move:SetScript("OnMouseUp", function()
		local _, _, _, x, y = module.plug.raid:GetPoint()
		module.config.position.raid.x = x
		module.config.position.raid.y = y
		VanillaEnhancedData.position = module.config.position
		parent.raid:StopMovingOrSizing()
	end)

	for idx = 1, 8 do
		GroupFrame(parent.raid, idx, "raid", module.config.hasBorder)
	end

	parent.raid.move:Hide()
	parent.raid:Hide()
end

local function UpdateUnitFrame(frameName, unit)
	local frame = getglobal(frameName)
	if frame and unit and type(unit) == "table" then
		frame.data = unit
		frame.unit = unit.alias
		frame.health.unit = unit.alias
		frame.power.unit = unit.alias
		frame.buffs.unit = unit.alias
		frame.debuffs.unit = unit.alias
		frame:SetID(unit.id)

		if unit.isOnline == 0 then
			frame.disconnect:Show()
		else
			frame.disconnect:Hide()
		end

		if string.len(unit.name) > 9 then
			frame.name:SetText(string.format("%s...", string.sub(unit.name, 1, 8)))
		else
			frame.name:SetText(unit.name)
		end

		local healthColor = VE.config.ClassColors[unit.class]
		local powerColor = VE.config.PowerColors[unit.power.name]

		if unit.isOnline == 0 then
			healthColor = VE.config.BlackColor
			powerColor = VE.config.BlackColor
		end

		if healthColor then
			frame.health:SetStatusBarColor(healthColor.r, healthColor.g, healthColor.b)
			frame.health:SetMinMaxValues(0, unit.health.max)
			frame.health:SetValue(unit.health.current)
		end

		if powerColor then
			frame.power:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)
			frame.power:SetMinMaxValues(0, unit.power.max)
			frame.power:SetValue(unit.power.current)
		end

		if IsParty() then
			if unit.lead > 0 then frame.lead:Show() else frame.lead:Hide() end
		end

		if IsRaid() then
			if unit.rank == 2 then frame.lead:Show() else frame.lead:Hide() end
			if unit.rank == 1 then frame.assistant:Show() else frame.assistant:Hide() end
		end

		if unit.isDead == 1 then
			frame.dead:Show()
		else
			frame.dead:Hide()
		end

		frame:Show()
	end
end

local function UpdatePartyFrames()
	if not IsParty() then return end

	module.data.party = {}

	-- Add members to the data table.
	local validUnits = ValidUnits()
	for _, unit in ipairs(validUnits.players) do
		local state = UnitState(unit)
		table.insert(module.data.party, state)
	end

	-- Hide all frames in advance.
	for idx = 1, 5 do
		getglobal("PartyFrameMemberFrame" .. tostring(idx)):Hide()
	end

	-- Update the actural unit frames.
	for idx, unit in pairs(module.data.party) do
		local frameName = string.format("PartyFrameMemberFrame%s", idx)
		UpdateUnitFrame(frameName, unit)
	end
end

local function UpdateRaidFrames()
	if not IsRaid() then return end

	module.data.raid = {}

	for i = 1, 8 do
		module.data.raid[i] = {}
	end

	-- Add members to the data table.
	local validUnits = ValidUnits()
	for i, unit in ipairs(validUnits.players) do
		local state = UnitState(unit)
		-- FIXME: This throws error (insert nil).
		if module.data.raid and type(module.data.raid) == "table" and state then
			table.insert(module.data.raid[state.group], state)
		end
	end

	-- Hide all frames in advance.
	for gdx = 1, 8 do
		for idx = 1, 5 do
			local frame = getglobal(string.format("GroupFrame%sMemberFrame%s", gdx, idx))
			if frame then frame:Hide() end
		end
	end

	for gdx = 1, 8 do
		if VE.count(module.data.raid[gdx]) == 0 then
			getglobal(string.format("GroupFrame%s", gdx)):Hide()
		else
			getglobal(string.format("GroupFrame%s", gdx)):Show()
			for idx, unit in pairs(module.data.raid[gdx]) do
				local frameName = string.format("GroupFrame%sMemberFrame%s", unit.group, idx)
				UpdateUnitFrame(frameName, unit)
			end
		end
	end
end

local function TogglePartyRaidFrames()
	if not IsParty() and not IsRaid() then
		module.plug.party:Hide()
		module.plug.raid:Hide()
		return
	end

	if IsParty() then
		-- FIXME: When game loads from character selection and is party
		--        module.plug.raid:Hide() throws an error.
		module.plug.raid:Hide()
		module.plug.party:Show()
	end

	if IsRaid() then
		module.plug.raid:Show()
		module.plug.party:Hide()
	end
end

local function ToggleSelectedUnitFrame()
	-- Find and toggle selected party unit frame.
	if IsParty() then
		for idx = 1, 5 do
			local frame = getglobal(string.format("PartyFrameMemberFrame%s", idx))
			if frame.data then
				if frame.data.name == UnitName("target") then
					frame.focused:Show()
				else
					frame.focused:Hide()
				end
			end
		end
	end

	-- Find and toggle selected raid unit frame.
	if IsRaid() then
		for gdx = 1, 8 do
			for idx = 1, 5 do
				local frame = getglobal(string.format("GroupFrame%sMemberFrame%s", gdx, idx))
				if frame.data then
					if frame.data.name == UnitName("target") then
						frame.focused:Show()
					else
						frame.focused:Hide()
					end
				end
			end
		end
	end
end

local function ExecuteWithDelay(delay, fn)
	local frame = CreateFrame("Frame")
	frame.timeSinceLastUpdate = 0
	frame:SetScript("OnUpdate", function()
		if not arg1 then return end
		this.timeSinceLastUpdate = this.timeSinceLastUpdate + arg1
		if this.timeSinceLastUpdate >= delay then -- 0.1 seconds = 100ms
			fn()
			this:SetScript("OnUpdate", nil)
		end
	end)
end

local function HideOriginalPartyFrames()
	if IsParty() or IsRaid() then
		getglobal("PartyMemberBackground"):Hide()
		for i = 1, 4 do
			local partyFrame = getglobal("PartyMemberFrame" .. i)
			if partyFrame then
				partyFrame:Hide()
				partyFrame:SetScript("OnShow", function()
					this:Hide()
				end)
			end
		end
	end
end

do
	SLASH_RF1 = "/rf"
	SLASH_RF2 = "/raidframes"
	SlashCmdList["RF"] = function(msg, editbox)
		if not module.plug.party and not module.plug.raid then return end

		if msg == "unlock" then
			if module.plug.party then
				VE.iprint("Party frames have been unlocked.")
				module.plug.party.move:EnableMouse(true)
				module.plug.party.move:Show()
			end

			if module.plug.raid then
				VE.iprint("Raid frames have been unlocked.")
				module.plug.raid.move:EnableMouse(true)
				module.plug.raid.move:Show()
			end
		end

		if msg == "lock" then
			if module.plug.party and module.plug.raid then
				VE.iprint("Party and Raid frames have been locked.")
				module.plug.raid.move:EnableMouse(false)
				module.plug.raid.move:Hide()
				module.plug.raid:SetUserPlaced(true)
				module.plug.party.move:EnableMouse(false)
				module.plug.party.move:Hide()
				module.plug.party:SetUserPlaced(true)
			end
		end

		if msg == "reset" then
			VanillaEnhancedData.position = module.config.defaultPosition
			ConsoleExec("reloadui")
		end
	end
end

module.plug = CreateFrame("Frame", module.identifier, UIParent)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("PARTY_MEMBERS_CHANGED")
module.plug:RegisterEvent("RAID_ROSTER_UPDATE")
module.plug:RegisterEvent("PARTY_LEADER_CHANGED")
module.plug:RegisterEvent("PARTY_MEMBER_DISABLE")
module.plug:RegisterEvent("PLAYER_TARGET_CHANGED")
--module.plug:RegisterEvent("UNIT_CASTEVENT")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	HideOriginalPartyFrames()

	if event == "PLAYER_ENTERING_WORLD" and not module.plug.party and not module.plug.raid then
		if VanillaEnhancedData.position ~= nil then
			module.config.position = VanillaEnhancedData.position
		end

		CreatePartyFrames(module.plug)
		CreateRaidFrames(module.plug)
		TogglePartyRaidFrames()

		if IsParty() then UpdatePartyFrames() end
		if IsRaid() then UpdateRaidFrames() end

		-- ExecuteWithDelay(2.0, function()
		-- 	CreatePartyFrames(module.plug)
		-- 	CreateRaidFrames(module.plug)
		-- 	TogglePartyRaidFrames()

		-- 	if IsParty() then UpdatePartyFrames() end
		-- 	if IsRaid() then UpdateRaidFrames() end
		-- end)
	end

	-- Fired when the player's party changes.
	if event == "PARTY_MEMBERS_CHANGED" then
		TogglePartyRaidFrames()
		UpdatePartyFrames()
		-- VE.dprint("> PARTY_MEMBERS_CHANGED")
	end

	-- Fired whenever a raid is formed or disbanded, players are leaving or joining a raid.
	if event == "RAID_ROSTER_UPDATE" then
		TogglePartyRaidFrames()
		UpdateRaidFrames()
		-- VE.dprint("> RAID_ROSTER_UPDATE")
	end

	-- Fired when the player's leadership changed. Referred to as buggy.
	if event == "PARTY_LEADER_CHANGED" then
		ExecuteWithDelay(1.5, function()
			TogglePartyRaidFrames()
			UpdatePartyFrames()
			UpdateRaidFrames()
		end)
		-- VE.dprint("> PARTY_LEADER_CHANGED")
	end

	-- Fired when a specific party member is offline or dead.
	if event == "PARTY_MEMBER_DISABLE" then
		ExecuteWithDelay(1.5, function()
			TogglePartyRaidFrames()
			UpdatePartyFrames()
			UpdateRaidFrames()
		end)
		-- VE.dprint("> PARTY_MEMBER_DISABLE")
	end

	-- If player target changed we set a border.
	if event == "PLAYER_TARGET_CHANGED" then
		if not IsParty() and not IsRaid() then return end
		ToggleSelectedUnitFrame()
		-- VE.dprint("> PLAYER_TARGET_CHANGED")
	end

	if event == "UNIT_CASTEVENT" then
		local casterGUID = UnitName(arg1) or "none"
		local targetGUID = UnitName(arg2) or "none"
		local eventType = arg3 -- ("START", "CAST", "FAIL", "CHANNEL", "MAINHAND", "OFFHAND")
		local spellID = arg4
		local spellDuration = arg5

		if spellID then
			local spellName, spellRank, spellIcon, spellCost = VE.GetSpellInfoByID(spellID)

			VE.print(string.format("> (%s, %s): %s [%s:%s] => %s rank %s", 
				tostring(casterGUID), tostring(targetGUID), tostring(eventType), tostring(spellID),
				tostring(spellDuration), tostring(spellName), tostring(spellRank)
			))
		end
		-- VE.dprint("> UNIT_CASTEVENT")
	end
end)
