local module = VE.registerModule({
	identifier = "CompactFrames",
	meta = {
		label = "Compact Raid and Party Frames",
		description = "Compact Raid and Party frames, similar to the default raid frames seen in 2010 cataclysm and 2019 Classic and later.",
	},
	plug = nil,
	superWoWRequired = true,
	config = {
		debug = false,    -- Enable this to show frames / for debugging.
		spellEffectiveness = {
			["Healing Touch"] = { [1] = 37, [2] = 88, [3] = 195, [4] = 363, [5] = 572, [6] = 742, [7] = 936, [8] = 1199, [9] = 1516, [10] = 1890, [11] = 2267 },
			["Regrowth"] = { [1] = 84, [2] = 164, [3] = 240, [4] = 318, [5] = 405, [6] = 511, [7] = 646, [8] = 809, [9] = 1003 },
			["Lesser Heal"] = { [1] = 46, [2] = 71, [3] = 135 },
			["Heal"] = { [1] = 295, [2] = 429, [3] = 566, [4] = 605 },
			["Greater Heal"] = { [1] = 764, [2] = 977, [3] = 1222, [4] = 1528, [5] = 1671 },
			["Flash Heal"] = { [1] = 193, [2] = 258, [3] = 278, [4] = 340, [5] = 440, [6] = 548, [7] = 690 },
			["Prayer of Healing"] = { [1] = 301, [2] = 378, [3] = 559, [4] = 798, [5] = 88 },
			["Holy Light"] = { [1] = 39, [2] = 76, [3] = 159, [4] = 310, [5] = 491, [6] = 698, [7] = 945, [8] = 1246, [9] = 1590 },
			["Flash of Light"] = { [1] = 62, [2] = 96, [3] = 145, [4] = 197, [5] = 267, [6] = 343, [7] = 428 },
			["Healing Wave"] = { [1] = 34, [2] = 64, [3] = 129, [4] = 268, [5] = 376, [6] = 536, [7] = 740, [8] = 1017, [9] = 1367, [10] = 1620 },
			["Lesser Healing Wave"] = { [1] = 162, [2] = 247, [3] = 227, [4] = 458, [5] = 631, [6] = 832 },
			["Chain Heal"] = { [1] = 320, [2] = 405, [3] = 551 },
		},
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
		activeMembers = {},
		healPredictionCache = {},
	},
	options = {
		{
			identifier = "CompactFramesShowPets",
			meta = {
				label = "Show Pets",
				description = "Show pet unit frames.",
			},
			superWoWRequired = false,
		},
		{
			identifier = "CompactFramesShowFocusFrames",
			meta = {
				label = "Show Focus Frames",
				description = "Show up to three focus unit frames like tanks etc.",
			},
			superWoWRequired = false,
		},
	},
})

local print = VE.print
local iprint = VE.iprint
local dprint = VE.dprint

-- Set up default value of no Auras displayed on unit frames.
if not VanillaEnhancedOptions["CompactFramesAuras"] then
	VanillaEnhancedOptions["CompactFramesAuras"] = 0
end

local function IsRaid()
	if GetNumRaidMembers() > 0 then return true end
	return false
end

local function IsParty()
	if GetNumPartyMembers() > 0 and GetNumRaidMembers() == 0 then return true end
	return false
end

local function GetMemberGroup(playerName)
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

local function UnitAuras(unit)
	local payload = {
		buffs = {},
		debuffs = {},
		hots = {},
		dispell = {
			Magic = 0,
			Curse = 0,
			Poison = 0,
			Disease = 0,
		},
	}

	-- Buffs
	for j = 1, 32 do
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
		local texture, applications, dispelType = UnitDebuff(unit, j, 1)
		if texture then
			-- "Magic", "Curse", "Poison", "Disease"
			texture = string.format("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-Debuff%s", dispelType)
			table.insert(payload.debuffs, {
				texture = texture,
				applications = applications,
				dispelType = dispelType,
			})

			payload.dispell[dispelType] = payload.dispell[dispelType] + 1
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

	return payload.buffs, payload.debuffs, payload.hots, payload.dispell
end

local function GetValidUnits()
	local payload = {
		party = {
			members = {},
			pets = {},
		},
		raid = {
			members = {},
			pets = {},
		},
	}

	if IsParty() then
		-- Add yourself to the roster if in party.
		table.insert(payload.party.members, "player")

		for i = 1, MAX_PARTY_MEMBERS do
			local unit =  "party" .. i
			if UnitExists(unit) then
				table.insert(payload.party.members, unit)
			end

			local pet = "partypet" .. i
			if UnitExists(pet) then
				table.insert(payload.party.pets, pet)
			end
		end
	end

	if IsRaid() then
		for i = 1, MAX_RAID_MEMBERS do
			local unit =  "raid" .. i
			if UnitExists(unit) then
				table.insert(payload.raid.members, unit)
			end

			local pet = "raidpet" .. i
			if UnitExists(pet) then
				table.insert(payload.raid.pets, pet)
			end
		end
	end

	return payload
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

	payload.group = GetMemberGroup(payload.name)
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
	payload.buffs, payload.debuffs, payload.hots, payload.dispell = UnitAuras(unit)

	return payload
end

local function HideNativeFrames()
	PartyMemberBackground:Hide()
	PartyMemberFrame1:Hide()
	PartyMemberFrame2:Hide()
	PartyMemberFrame3:Hide()
	PartyMemberFrame4:Hide()
end

local function GetMemberFrameName(memberName)
	for g = 1, 8 do
		for m = 1, 5 do
			local frame = getglobal(string.format("GroupFrame%sMemberFrame%s", g, m))
			if frame:IsVisible() then
				local name = getglobal(frame:GetName()).info.name
				if name and name == memberName then
					return frame:GetName()
				end
			end
		end
	end
	return nil
end

local function IsUnitInPartyOrRaid(name)
	local groups = { "party", "raid" }
	for _, group in pairs(groups) do
		for _, unit in pairs(module.data.activeMembers[group].members) do
			local unitInfo = GetUnitInfo(unit)
			if unitInfo then
				if name == unitInfo.name then
					return true
				end
			end
		end
	end
	return false
end

local function UpdateHealPrediction(casterGUID, targetGUID, eventType, spellID, spellDuration)
	-- eventType: ("START", "CAST", "FAIL", "CHANNEL", "MAINHAND", "OFFHAND")
	local casterName = UnitName(casterGUID) or nil
	local targetName = UnitName(targetGUID) or nil

	if not IsUnitInPartyOrRaid(casterName) then return end

	if eventType == "START" then
		local spellName, spellRank, spellIcon, spellCost = VE.GetSpellInfoByID(spellID)
		if spellRank then
			local rankNumber = string.gsub(spellRank, ".*(%d+).*", "%1") or 0

			if module.config.spellEffectiveness[spellName] then
				local spellEffectiveness = module.config.spellEffectiveness[spellName][tonumber(rankNumber)]
				local targetFrameName = GetMemberFrameName(targetName)
				if targetFrameName and spellEffectiveness then
					local unitInfo = GetUnitInfo(targetGUID)
					local healthBarPrediction = getglobal(string.format("%sHealthBarPrediction", targetFrameName))
					healthBarPrediction:SetStatusBarColor(0.0, 1.0, 0.0)
					healthBarPrediction:SetMinMaxValues(0, unitInfo.health.max)
					healthBarPrediction:SetValue(unitInfo.health.current + spellEffectiveness)
					healthBarPrediction.spellEffectiveness = spellEffectiveness

					table.insert(module.data.healPredictionCache, {
						casterGUID = casterGUID,
						targetGUID = targetGUID,
						targetFrameName = targetFrameName,
					})
				end
			end
		end
	end

	if eventType == "FAIL" or eventType == "CAST" then
		for key, cast in pairs(module.data.healPredictionCache) do
			if casterGUID == cast.casterGUID then
				local healthBarPrediction = getglobal(string.format("%sHealthBarPrediction", cast.targetFrameName))
				healthBarPrediction:SetValue(0)
				healthBarPrediction.spellEffectiveness = nil
				module.data.healPredictionCache[key] = nil
			end
		end
	end
end

local function UpdateMemberFrame(unitInfo, frameName)
	if not unitInfo or type(unitInfo) ~= "table" then return end

	local healthBar = getglobal(string.format("%sHealthBar", frameName))
	local powerBar = getglobal(string.format("%sPowerBar", frameName))
	local nameText = getglobal(string.format("%sNameText", frameName))
	local deadText = getglobal(string.format("%sDeadText", frameName))
	local disconnectIcon = getglobal(string.format("%sDisconnectIcon", frameName))

	getglobal(frameName).info = unitInfo

	if string.len(unitInfo.name) > 9 then
		nameText:SetText(string.format("%s...", string.sub(unitInfo.name, 1, 8)))
	else
		nameText:SetText(unitInfo.name)
	end

	if unitInfo.isDead == 1 then
		this:SetAlpha(1.0)
		deadText:SetText("DEAD")
		deadText:Show()
	else
		deadText:Hide()
	end

	if IsRaid() then
		local leaderIcon = getglobal(string.format("%sLeaderIcon", frameName))
		local assistantIcon = getglobal(string.format("%sAssistantIcon", frameName))
		if unitInfo.rank == 2 then leaderIcon:Show() else leaderIcon:Hide() end
		if unitInfo.rank == 1 then assistantIcon:Show() else assistantIcon:Hide() end
	end

	if IsParty() then
		local leaderIcon = getglobal(string.format("%sLeaderIcon", frameName))
		if unitInfo.lead then leaderIcon:Show() else leaderIcon:Hide() end
	end

	-- In range detection.
	if unitInfo.inRange == 1 then
		this:SetAlpha(1.0)
	else
		this:SetAlpha(0.4)
	end

	if not unitInfo.isOnline then
		healthBar:SetStatusBarColor(0.0, 0.0, 0.0)
		healthBar:SetMinMaxValues(0, 1)
		healthBar:SetValue(1)
		powerBar:SetStatusBarColor(0.2, 0.2, 0.2)
		powerBar:SetMinMaxValues(0, 1)
		powerBar:SetValue(1)
		disconnectIcon:Show()
		this:SetAlpha(1.0)
	else
		local powerColor = VE.config.PowerColors[unitInfo.power.name]
		local healthColor = VE.config.ClassColors[unitInfo.class]
		if powerColor and healthColor then
			healthBar:SetStatusBarColor(healthColor.r, healthColor.g, healthColor.b)
			healthBar:SetMinMaxValues(0, unitInfo.health.max)
			healthBar:SetValue(unitInfo.health.current)
			powerBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)
			powerBar:SetMinMaxValues(0, unitInfo.power.max)
			powerBar:SetValue(unitInfo.power.current)
			disconnectIcon:Hide()

			-- Update heal prediction white health is getting lower.
			local healthBarPrediction = getglobal(string.format("%sHealthBarPrediction", frameName))
			if healthBarPrediction and healthBarPrediction.spellEffectiveness then
				healthBarPrediction:SetValue(unitInfo.health.current + healthBarPrediction.spellEffectiveness)
			end
		end
	end

	-- Update HOTs.
	if VanillaEnhancedOptions["CompactFramesAuras"] and VanillaEnhancedOptions["CompactFramesAuras"] > 0 then
		for i = 1, 5 do
			local _aura = nil
			if VanillaEnhancedOptions["CompactFramesAuras"] == 1 then _aura = unitInfo.buffs[i] end
			if VanillaEnhancedOptions["CompactFramesAuras"] == 2 then _aura = unitInfo.debuffs[i] end
			if VanillaEnhancedOptions["CompactFramesAuras"] == 3 then _aura = unitInfo.hots[i] end

			local auraFrame = getglobal(string.format("%sAura%s", frameName, i))
			if _aura then
				local auraTexture = getglobal(string.format("%sAura%sTexture", frameName, i))
				auraTexture:SetTexture(_aura.texture)
				auraFrame:Show()
			else
				auraFrame:Hide()
			end
		end
	end

	-- Update dispellable debuffs.

	for i = 1, 4 do
		getglobal(string.format("%sDispell%s", frameName, i)):Hide()
	end

	local nextDispellAura = 1
	for idx, dispellType in pairs({ "Magic", "Curse", "Poison", "Disease" }) do
		local dispellValue = unitInfo.dispell[dispellType]

		if dispellValue > 0 then
			local dispellFrame = getglobal(string.format("%sDispell%s", frameName, nextDispellAura))
			local dispellTexture = getglobal(string.format("%sDispell%sTexture", frameName, nextDispellAura))
			dispellTexture:SetTexture(string.format("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-Debuff%s", dispellType))
			dispellFrame:Show()
			nextDispellAura = nextDispellAura + 1
		end	
	end
end

local function UpdatePartyGroup()
	if not IsParty() then return end
	module.data.activeMembers = GetValidUnits()

	for i, unit in pairs(module.data.activeMembers.party.members) do
		local unitInfo = GetUnitInfo(unit)
		if unitInfo and type(unitInfo) == "table" then
			local frameName = string.format("GroupFrame1MemberFrame%s", i)
			getglobal(frameName).unit = unit
			UpdateMemberFrame(unitInfo, frameName)
			getglobal(frameName):Show()
		end
	end

	-- Toggle active members.
	for i = 1, 5 do
		local frame = getglobal(string.format("GroupFrame1MemberFrame%s", i))
		if module.data.activeMembers.party.members[i] then
			frame:Show()
		else
			frame.info = nil
			frame:Hide()
		end
	end

	-- Hide all other groups.
	for i = 2, 8 do
		getglobal(string.format("GroupFrame%s", i)):Hide()
	end
end

local function UpdateRaidGroups()
	if not IsRaid() then return end
	module.data.activeMembers = GetValidUnits()

	local groupPositions = { 0, 0, 0, 0, 0, 0, 0, 0 }
	for i, unit in pairs(module.data.activeMembers.raid.members) do
		local unitInfo = GetUnitInfo(unit)
		if unitInfo and type(unitInfo) == "table" then
			if unitInfo.group > 0 then
				groupPositions[unitInfo.group] = groupPositions[unitInfo.group] + 1
				local frameName = string.format("GroupFrame%sMemberFrame%s", unitInfo.group, groupPositions[unitInfo.group])
				getglobal(frameName).unit = unit
				UpdateMemberFrame(unitInfo, frameName)
				getglobal(frameName):Show()
			end
		end
	end

	-- Hide all other frames in all groups.
	for i, val in pairs(groupPositions) do
		if val > 0 then
			for j = val + 1, 5 do
				getglobal(string.format("GroupFrame%sMemberFrame%s", i, j)):Hide()
			end
			getglobal(string.format("GroupFrame%s", i)):Show()
		else
			getglobal(string.format("GroupFrame%s", i)):Hide()
			getglobal(string.format("GroupFrame%s", i)).info = nil
		end
	end
end

local function ResetHighlightedFrames()
	for i = 1, 8 do
		for j = 1, 5 do
			getglobal(string.format("GroupFrame%sMemberFrame%sHighlight", i, j)):Hide()
		end
	end
end

local function HighlightUnitFrameByMemberName(name)
	for i = 1, 8 do
		for j = 1, 5 do
			local frame = getglobal(string.format("GroupFrame%sMemberFrame%s", i, j))
			if frame:IsVisible() then
				local unitInfo = GetUnitInfo(frame.unit)
				if unitInfo and unitInfo.name == name then
					getglobal(string.format("%sHighlight", frame:GetName())):Show()
				end
			end
		end
	end
end

function GroupFrame_OnLoad()
end

function GroupMemberFrame_OnLoad()
	this:RegisterEvent("UNIT_AURA")
	this:RegisterEvent("UNIT_HEALTH")
	this:RegisterEvent("UNIT_MAXHEALTH")
	this:RegisterEvent("UNIT_MANA")
	this:RegisterEvent("UNIT_RAGE")
	this:RegisterEvent("UNIT_FOCUS")
	this:RegisterEvent("UNIT_ENERGY")
	this:RegisterEvent("UNIT_HAPPINESS")
	this:RegisterEvent("UNIT_MAXMANA")
	this:RegisterEvent("UNIT_MAXRAGE")
	this:RegisterEvent("UNIT_MAXFOCUS")
	this:RegisterEvent("UNIT_MAXENERGY")
	this:RegisterEvent("UNIT_MAXHAPPINESS")
	this:RegisterEvent("UNIT_DISPLAYPOWER")

	this:SetScript("OnMouseDown", function()
		if IsControlKeyDown() and IsAltKeyDown() then
			CompactFrames:StartMoving()
		end
	end)

	this:SetScript("OnMouseUp", function()
		if IsControlKeyDown() and IsAltKeyDown() then
			CompactFrames:StopMovingOrSizing()
		end
	end)

	this:SetScript("OnHide", function()
		CompactFrames:StopMovingOrSizing()
	end)

	-- Reset all healing prediction status bars.
	local frame = getglobal(string.format("%sHealthBarPrediction", this:GetName()))
	if frame then
		frame:SetStatusBarColor(0.0, 1.0, 0.0)
		frame:SetMinMaxValues(0, 1)
		frame:SetValue(0)
	end
end

function GroupMemberFrame_OnEvent()
	if not VE.isModuleEnabled(module.identifier) then
		this:UnregisterAllEvents()
		return
	end

	if arg1 == this.unit then
		UpdateMemberFrame(GetUnitInfo(this.unit), this:GetName())
	end
end

function GroupMemberFrame_OnEnter()
	if this.unit then
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
		GameTooltip:SetUnit(this.unit)
		GameTooltip:Show()
	end
end

function GroupMemberFrame_OnLeave()
	GameTooltip:Hide()
end

function GroupMemberFrame_OnClick()
	if not UnitExists(this.unit) then return nil end
	TargetUnit(this.unit)
	ResetHighlightedFrames()
	getglobal(string.format("%sHighlight", this:GetName())):Show()
end

function CompactFrames_OnLoad()
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	this:RegisterEvent("PARTY_MEMBERS_CHANGED")
	this:RegisterEvent("RAID_ROSTER_UPDATE")
	this:RegisterEvent("PARTY_LEADER_CHANGED")
	this:RegisterEvent("PARTY_MEMBER_DISABLE")
	this:RegisterEvent("PLAYER_TARGET_CHANGED")
	this:RegisterEvent("UNIT_CASTEVENT")
	this:RegisterEvent("UPDATE_MASTER_LOOT_LIST")
end

function CompactFrames_OnEvent()
	if not VE.isModuleEnabled(module.identifier) then
		this:UnregisterAllEvents()
		return
	end

	if module.config.debug then
		this:Show()
	else
		if not IsParty() and not IsRaid() then
			this:Hide()
			return
		end

		HideNativeFrames()

		if event == "PLAYER_ENTERING_WORLD" or event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
			if not IsParty() and not IsRaid() then
				this:Hide()
			end

			if IsParty() then
				UpdatePartyGroup()
				this:Show()
			end

			if IsRaid() then
				UpdateRaidGroups()
				this:Show()
			end
		end

		if event == "PLAYER_TARGET_CHANGED" then
			if not IsParty() and not IsRaid() then return end

			ResetHighlightedFrames()

			if UnitExists("target") then
				local targetName = UnitName("target")
				HighlightUnitFrameByMemberName(targetName)
			end
		end

		if event == "UNIT_CASTEVENT" then
			UpdateHealPrediction(arg1, arg2, arg3, arg4, arg5)
		end

		if event == "UPDATE_MASTER_LOOT_LIST" then
			-- https://wowpedia.fandom.com/wiki/API_GetLootMethod
			print(string.format("master looter > arg1: %s, arg2: %s, arg3: %s", arg1, arg2, arg3))
		end
	end
end
