local module = VE.registerModule({
	identifier = "CharacterStats",
	meta = {
		label = "Improved Character Stats",
		description = "Replaces the default character stats with a more detailed view including Hit, Crit, and Spell Power.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		DropdownLeft = "PLAYERSTAT_BASE_STATS",
		DropdownRight = "PLAYERSTAT_MELEE_COMBAT",
	},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

-- ============================================================================
-- CONSTANTS & PATTERNS
-- ============================================================================
local PATTERNS = {
	HIT = "Improves your chance to hit by (%d)%%",
	SPELL_HIT = "Improves your chance to hit with spells by (%d)%%",
	CRIT = "Improves your chance to get a critical strike by (%d)%%",
	SPELL_CRIT = "Improves your chance to get a critical strike with spells by (%d)%%",
	
	-- Spell Power patterns
	SPELL_DMG = "Increases damage and healing done by magical spells and effects by up to (%d+)", -- Generic
	SPELL_DMG_SHADOW = "Increases damage done by Shadow spells and effects by up to (%d+)",
	SPELL_DMG_FIRE = "Increases damage done by Fire spells and effects by up to (%d+)",
	SPELL_DMG_FROST = "Increases damage done by Frost spells and effects by up to (%d+)",
	SPELL_DMG_ARCANE = "Increases damage done by Arcane spells and effects by up to (%d+)",
	SPELL_DMG_NATURE = "Increases damage done by Nature spells and effects by up to (%d+)",
	SPELL_DMG_HOLY = "Increases damage done by Holy spells and effects by up to (%d+)",
	
	HEALING = "Increases healing done by spells and effects by up to (%d+)",
	MANA_REGEN = "Restores (%d+) mana per 5 sec",
	SPELLBOOK_CRIT = "([%d.]+)%% chance to crit",
	
	-- Haste
	HASTE_SPELL = "Increases your casting speed by (%d+)%%",
	HASTE_BOTH = "Increases your attack and casting speed by (%d+)%%",
	
	-- Talents (Generic)
	TALENT_SPELL_CRIT = "Increases your spell damage and critical srike chance by (%d+)%%", -- Arcane Instability
	TALENT_REGEN_CAST = "Allows (%d+)%% of your Mana regeneration to continue while casting",
}

-- ============================================================================
-- HELPER FUNCTIONS & STATE
-- ============================================================================
local BCS_Tooltip = CreateFrame("GameTooltip", "VE_BCS_Tooltip", nil, "GameTooltipTemplate")
BCS_Tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local Cache = {
	hit = 0,
	spell_hit = 0,
	crit = 0,
	spell_crit = 0,
	spell_power = 0,
	generic_spell_power = 0,
	healing_power = 0,
	mp5 = 0,
	casting_regen = 0,
	spell_haste = 0,
	talent_spell_crit = 0
}

-- Track active set bonuses to avoid double counting
local SetBonuses = {}

local function ScanAuras()
	local buffGeneric = 0
	local buffHealing = 0
	local buffSchool = { shadow=0, fire=0, frost=0, arcane=0, nature=0, holy=0 }
	
	for i = 0, 31 do
		local index = GetPlayerBuff(i, "HELPFUL")
		if index > -1 then
			BCS_Tooltip:SetPlayerBuff(index)
			for line = 1, BCS_Tooltip:NumLines() do
				local text = _G["VE_BCS_TooltipTextLeft" .. line]:GetText()
				if text then
					local _, _, value
					
					-- Generic Spell Power
					_, _, value = string.find(text, "Magical damage dealt is increased by up to (%d+)")
					if value then buffGeneric = buffGeneric + tonumber(value) end
					
					_, _, value = string.find(text, "Increases damage and healing done by magical spells and effects by up to (%d+)")
					if value then buffGeneric = buffGeneric + tonumber(value) end
					
					_, _, value = string.find(text, "Spell damage is increased by up to (%d+)")
					if value then buffGeneric = buffGeneric + tonumber(value) end
					
					_, _, value = string.find(text, "Spell damage increased by up to (%d+)")
					if value then buffGeneric = buffGeneric + tonumber(value) end
					
					-- School Specific
					_, _, value = string.find(text, "Increases damage done by Shadow spells and effects by up to (%d+)")
					if value then buffSchool.shadow = buffSchool.shadow + tonumber(value) end
					
					_, _, value = string.find(text, "Increases damage done by Fire spells and effects by up to (%d+)")
					if value then buffSchool.fire = buffSchool.fire + tonumber(value) end
					
					_, _, value = string.find(text, "Increases damage done by Frost spells and effects by up to (%d+)")
					if value then buffSchool.frost = buffSchool.frost + tonumber(value) end
					
					-- Crit
					_, _, value = string.find(text, "Chance for a critical hit with a spell increased by (%d+)%%")
					if value then Cache.spell_crit = Cache.spell_crit + tonumber(value) end
					
					-- Haste
					_, _, value = string.find(text, "spell casting speed by (%d+)%%")
					if value then Cache.spell_haste = Cache.spell_haste + tonumber(value) end
				end
			end
		end
	end
	
	-- Calculate Max School Buff
	local maxBuffSchool = 0
	if buffSchool.shadow > maxBuffSchool then maxBuffSchool = buffSchool.shadow end
	if buffSchool.fire > maxBuffSchool then maxBuffSchool = buffSchool.fire end
	if buffSchool.frost > maxBuffSchool then maxBuffSchool = buffSchool.frost end
	if buffSchool.arcane > maxBuffSchool then maxBuffSchool = buffSchool.arcane end
	if buffSchool.nature > maxBuffSchool then maxBuffSchool = buffSchool.nature end
	if buffSchool.holy > maxBuffSchool then maxBuffSchool = buffSchool.holy end
	
	-- Update Caches
	-- Cache.spell_power currently has [Gear Generic + Gear MaxSchool]
	-- We add [Buff Generic + Buff MaxSchool]
	Cache.spell_power = Cache.spell_power + buffGeneric + maxBuffSchool
	
	-- Cache.generic_spell_power currently has [Gear Generic]
	-- We add [Buff Generic]
	Cache.generic_spell_power = Cache.generic_spell_power + buffGeneric
	
	-- Cache.healing_power currently has [Gear Healing Only]
	-- We add [Buff Healing Only (if any, separate from generic)]
	-- Note: buffGeneric applies to healing too usually (Damage AND Healing).
	-- My Healing Display logic is: Generic + HealingOnly.
	-- So we update generic (done above) and healing only (buffHealing).
	Cache.healing_power = Cache.healing_power + buffHealing
end

function module.UpdateStats()
	if not module.frame then return end
	ScanGear()
	ScanTalents()
	ScanAuras()
	UpdatePaperdollStats("LEFT", module.config.DropdownLeft)
	UpdatePaperdollStats("RIGHT", module.config.DropdownRight)
end

local function ScanTalents()
	Cache.casting_regen = 0
	Cache.talent_spell_crit = 0
	
	for tab = 1, GetNumTalentTabs() do
		for talent = 1, GetNumTalents(tab) do
			local name, icon, tier, column, rank, maxRank = GetTalentInfo(tab, talent)
			if rank > 0 then
				BCS_Tooltip:ClearLines()
				BCS_Tooltip:SetTalent(tab, talent)
				for line = 1, BCS_Tooltip:NumLines() do
					local text = _G["VE_BCS_TooltipTextLeft" .. line]:GetText()
					if text then
						-- Regen while casting
						local _, _, value = string.find(text, PATTERNS.TALENT_REGEN_CAST)
						if value then
							Cache.casting_regen = Cache.casting_regen + tonumber(value)
						end
						
						-- Generic Spell Crit (Arcane Instability)
						_, _, value = string.find(text, PATTERNS.TALENT_SPELL_CRIT)
						if value then
							Cache.talent_spell_crit = Cache.talent_spell_crit + tonumber(value)
						end
						
						-- Class Specific Handling
						local _, class = UnitClass("player")
						if class == "WARLOCK" then
							-- Devastation: Increases the critical strike chance of your Destruction spells by X%
							-- Note: Exclude "Increases critical strike damage bonus" (Ruin)
							local s, e, val = string.find(text, "Destruction spells by (%d+)%%")
							if val and not string.find(text, "damage bonus") then
								Cache.talent_spell_crit = Cache.talent_spell_crit + tonumber(val)
							end
						elseif class == "MAGE" then
							-- Critical Mass (Fire) - We might want to keep this separate if we had school specific tabs, but for summary we can't just add it.
							-- Keeping generic for now.
						elseif class == "PALADIN" then
							-- Holy Power
							local s, e, val = string.find(text, "Holy Light and Flash of Light by (%d+)%%")
							if val then
								Cache.talent_spell_crit = Cache.talent_spell_crit + tonumber(val)
							end
						end
					end
				end
			end
		end
	end
end

local function ScanGear()
	Cache.hit = 0
	Cache.spell_hit = 0
	Cache.crit = 0
	Cache.spell_crit = 0
	Cache.spell_power = 0
	Cache.healing_power = 0
	Cache.mp5 = 0
	Cache.spell_haste = 0
	
	-- Reset Set Bonuses
	SetBonuses = {}

	for slot = 1, 19 do
		if BCS_Tooltip:SetInventoryItem("player", slot) then
			for line = 1, BCS_Tooltip:NumLines() do
				local text = _G["VE_BCS_TooltipTextLeft" .. line]:GetText()
				if text then
					local _, _, value
					
					-- Check for Set Bonus
					local isSetBonus = string.find(text, "^Set: ")
					local setName = nil
					
					if isSetBonus then
						-- Find the set name from previous lines if needed, but for now we just rely on the text being unique enough
						-- If we found "Set: ...", we check if we already counted this specific line for this set
						-- This is a simplification. To do it perfectly we need to find the "Set Name (x/y)" header.
						-- But typically, "Set: Increases..." is identical across items of the same set.
						if SetBonuses[text] then
							-- Skip this line, we already counted it for this set
							-- Note: This assumes different sets won't have identical bonus text strings.
							-- In Vanilla, this is mostly true (e.g. "Set: Increases damage and healing by up to 23" vs "up to 18")
						else
							SetBonuses[text] = true
							-- Proceed to match
						end
					else
						-- Proceed to match normally for Equip/Use/Stats
					end
					
					-- If it's a set bonus we've already seen, skip matching
					if not (isSetBonus and SetBonuses[text] == nil) then
						-- Continue (double negation means: if it IS a set bonus AND we HAVE seen it, skip)
						-- Wait, logic is: if isSetBonus and SetBonuses[text] then SKIP end.
						-- But I already set SetBonuses[text] = true above.
						-- Correct logic:
					end
					
					local skip = false
					if isSetBonus then
						-- We already marked it as seen. If it was ALREADY in the table before this loop iteration, skip.
						-- But wait, I need to know if I *just* added it or if it was there.
						-- Let's refactor the check.
					end
				end
			end
		end
	end
	
	-- Re-run with clean logic
	SetBonuses = {}
	
	-- Temp tables to calculate highest school damage
	local schoolDamage = {
		shadow = 0,
		fire = 0,
		frost = 0,
		arcane = 0,
		nature = 0,
		holy = 0
	}

	for slot = 1, 19 do
		if BCS_Tooltip:SetInventoryItem("player", slot) then
			-- Identify Set Name if possible
			local currentSet = nil
			
			for line = 1, BCS_Tooltip:NumLines() do
				local text = _G["VE_BCS_TooltipTextLeft" .. line]:GetText()
				if text then
					-- Check for Set Header "Name (x/y)"
					local s, e, name = string.find(text, "(.+) %(%d/%d%)")
					if name then currentSet = name end
					
					-- Check if line is a set bonus (Active or Inactive)
					-- Note: GetText() includes color codes (e.g., |cff808080 for inactive).
					-- We must check for "Set:" anywhere in the line to handle color prefixes.
					local isSetLine = string.find(text, "Set: ")
					
					-- Heuristic: If the line contains the Grey color code, it is likely an inactive set bonus.
					-- Inactive bonuses should be IGNORED.
					-- Standard Grey: |cff808080.
					local lowerText = string.lower(text)
					local isInactive = string.find(lowerText, "cff808080") or string.find(lowerText, "cff7f7f7f")
					
					local shouldScan = true
					
					if isSetLine then
						if isInactive then
							shouldScan = false
						else
							-- Deduplicate active set bonuses
							-- Use set name if available to distinguish between identical bonuses from different sets
							local key = text
							if currentSet then key = currentSet .. text end
							
							if SetBonuses[key] then
								shouldScan = false
							else
								SetBonuses[key] = true
							end
						end
					end
					
					-- Filter out "Use:" and "Chance on hit:" lines
					if string.find(text, "^Use:") or string.find(text, "^Chance on hit:") then
						shouldScan = false
					end
					
					if shouldScan then
						local _, _, value
						
						-- Hit
						_, _, value = string.find(text, PATTERNS.HIT)
						if value then Cache.hit = Cache.hit + tonumber(value) end
						
						-- Spell Hit
						_, _, value = string.find(text, PATTERNS.SPELL_HIT)
						if value then Cache.spell_hit = Cache.spell_hit + tonumber(value) end

						-- Crit
						_, _, value = string.find(text, PATTERNS.CRIT)
						if value then Cache.crit = Cache.crit + tonumber(value) end
						
						-- Spell Crit
						_, _, value = string.find(text, PATTERNS.SPELL_CRIT)
						if value then Cache.spell_crit = Cache.spell_crit + tonumber(value) end

						-- Spell Power (Generic Damage & Healing)
						-- Priority: Check standard full text first
						local foundSpellDmg = false
						_, _, value = string.find(text, PATTERNS.SPELL_DMG)
						if value then 
							Cache.spell_power = Cache.spell_power + tonumber(value) 
							foundSpellDmg = true
						end
						
						-- Enchants / Short formats (Spell Damage +30)
						-- Only check if we didn't find the long format (prevent double counting if line matches both somehow)
						if not foundSpellDmg then
							_, _, value = string.find(text, "^Spell Damage %+(%d+)$")
							if value then Cache.spell_power = Cache.spell_power + tonumber(value) end
							_, _, value = string.find(text, "^Spell Damage increased by (%d+)$")
							if value then Cache.spell_power = Cache.spell_power + tonumber(value) end
						end
						
						-- School Specific Damage
						_, _, value = string.find(text, PATTERNS.SPELL_DMG_SHADOW)
						if value then schoolDamage.shadow = schoolDamage.shadow + tonumber(value) end
						_, _, value = string.find(text, "^%+(%d+) Shadow Damage$")
						if value then schoolDamage.shadow = schoolDamage.shadow + tonumber(value) end
						
						_, _, value = string.find(text, PATTERNS.SPELL_DMG_FIRE)
						if value then schoolDamage.fire = schoolDamage.fire + tonumber(value) end
						_, _, value = string.find(text, "^%+(%d+) Fire Damage$")
						if value then schoolDamage.fire = schoolDamage.fire + tonumber(value) end
						
						_, _, value = string.find(text, PATTERNS.SPELL_DMG_FROST)
						if value then schoolDamage.frost = schoolDamage.frost + tonumber(value) end
						_, _, value = string.find(text, "^%+(%d+) Frost Damage$")
						if value then schoolDamage.frost = schoolDamage.frost + tonumber(value) end
						
						_, _, value = string.find(text, PATTERNS.SPELL_DMG_ARCANE)
						if value then schoolDamage.arcane = schoolDamage.arcane + tonumber(value) end
						_, _, value = string.find(text, "^%+(%d+) Arcane Damage$")
						if value then schoolDamage.arcane = schoolDamage.arcane + tonumber(value) end
						
						_, _, value = string.find(text, PATTERNS.SPELL_DMG_NATURE)
						if value then schoolDamage.nature = schoolDamage.nature + tonumber(value) end
						_, _, value = string.find(text, "^%+(%d+) Nature Damage$")
						if value then schoolDamage.nature = schoolDamage.nature + tonumber(value) end
						
						_, _, value = string.find(text, PATTERNS.SPELL_DMG_HOLY)
						if value then schoolDamage.holy = schoolDamage.holy + tonumber(value) end
						_, _, value = string.find(text, "^%+(%d+) Holy Damage$")
						if value then schoolDamage.holy = schoolDamage.holy + tonumber(value) end

						-- Healing Power (Healing Only)
						_, _, value = string.find(text, PATTERNS.HEALING)
						if value then Cache.healing_power = Cache.healing_power + tonumber(value) end
						
						-- Enchant: "Healing Spells +30"
						_, _, value = string.find(text, "^Healing Spells %+(%d+)$")
						if value then Cache.healing_power = Cache.healing_power + tonumber(value) end
						-- Jewelcrafting/Enchant: "Healing +20"
						_, _, value = string.find(text, "^Healing %+(%d+)$")
						if value then Cache.healing_power = Cache.healing_power + tonumber(value) end

						-- Mana Regen
						_, _, value = string.find(text, PATTERNS.MANA_REGEN)
						if value then Cache.mp5 = Cache.mp5 + tonumber(value) end
						_, _, value = string.find(text, "^Mana Regen %+(%d+)$")
						if value then Cache.mp5 = Cache.mp5 + tonumber(value) end
						
						-- Haste
						_, _, value = string.find(text, PATTERNS.HASTE_SPELL)
						if value then Cache.spell_haste = Cache.spell_haste + tonumber(value) end
						_, _, value = string.find(text, PATTERNS.HASTE_BOTH)
						if value then Cache.spell_haste = Cache.spell_haste + tonumber(value) end
					end
				end
			end
		end
	end
	
	-- Add Highest School Damage to Generic Spell Power for display
	local maxSchool = 0
	if schoolDamage.shadow > maxSchool then maxSchool = schoolDamage.shadow end
	if schoolDamage.fire > maxSchool then maxSchool = schoolDamage.fire end
	if schoolDamage.frost > maxSchool then maxSchool = schoolDamage.frost end
	if schoolDamage.arcane > maxSchool then maxSchool = schoolDamage.arcane end
	if schoolDamage.nature > maxSchool then maxSchool = schoolDamage.nature end
	if schoolDamage.holy > maxSchool then maxSchool = schoolDamage.holy end
	
	-- NOTE: Generic Spell Power (Cache.spell_power) adds to ALL schools.
	-- But for the "Spell Power" display row, typically users want to see their MAIN school power.
	-- So we add the highest specific school bonus to the generic total.
	-- Healing Power does NOT benefit from School Specific damage.
	
	-- Store the "Base" generic power for Healing calculation
	Cache.generic_spell_power = Cache.spell_power
	
	-- Update the display Cache.spell_power to include the highest school
	Cache.spell_power = Cache.spell_power + maxSchool
	
	-- Base Spell Crit from Intellect (Formula from BCS)
	local _, intellect = UnitStat("player", 4)
	local level = UnitLevel("player")
	local _, class = UnitClass("player")
	local baseSpellCrit = 0
	
	if class == "MAGE" then baseSpellCrit = 3.7 + intellect / (14.77 + .65 * level)
	elseif class == "WARLOCK" then baseSpellCrit = 3.18 + intellect / (11.30 + .82 * level)
	elseif class == "PRIEST" then baseSpellCrit = 2.97 + intellect / (10.03 + .82 * level)
	elseif class == "DRUID" then baseSpellCrit = 3.33 + intellect / (12.41 + .79 * level)
	elseif class == "SHAMAN" then baseSpellCrit = 3.54 + intellect / (11.51 + .8 * level)
	elseif class == "PALADIN" then baseSpellCrit = 3.7 + intellect / (14.77 + .65 * level)
	end
	
	Cache.spell_crit = Cache.spell_crit + baseSpellCrit
end

local function GetCritChance()
	-- Fallback scanner for Melee Crit if needed, or could use formula
	for i = 1, 200 do
		BCS_Tooltip:SetSpell(i, "spell")
		for line = 1, BCS_Tooltip:NumLines() do
			local text = _G["VE_BCS_TooltipTextLeft" .. line]:GetText()
			if text then
				local _, _, value = string.find(text, PATTERNS.SPELLBOOK_CRIT)
				if value then return tonumber(value) end
			end
		end
	end
	return 0
end

local function GetManaRegen()
	local _, spirit = UnitStat("player", 5)
	local _, class = UnitClass("player")
	local base = 0

	if class == "DRUID" then base = (spirit / 5 + 15)
	elseif class == "HUNTER" then base = (spirit / 5 + 15)
	elseif class == "MAGE" then base = (spirit / 4 + 12.5)
	elseif class == "PALADIN" then base = (spirit / 5 + 15)
	elseif class == "PRIEST" then base = (spirit / 4 + 12.5)
	elseif class == "SHAMAN" then base = (spirit / 5 + 17)
	elseif class == "WARLOCK" then base = (spirit / 5 + 15)
	end
	
	-- MP5 from gear is always active
	local mp5_regen = Cache.mp5 * 0.4 -- Convert 5sec to 2sec tick
	
	-- Casting regen
	local casting_regen = (base * (Cache.casting_regen / 100)) + mp5_regen
	
	-- Normal regen
	local normal_regen = base + mp5_regen
	
	return math.floor(normal_regen), math.floor(casting_regen)
end

local function GetAttackPower()
	local base, pos, neg = UnitAttackPower("player")
	return base + pos + neg
end

local function GetRangedAttackPower()
	local base, pos, neg = UnitRangedAttackPower("player")
	return base + pos + neg
end

-- ============================================================================
-- UI CREATION
-- ============================================================================
local statRows = { left = {}, right = {} }
local dropdowns = {}

local function CreateStatRow(parent, id, align)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetWidth(104)
	frame:SetHeight(13)
	
	local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
	label:SetPoint("LEFT", frame, "LEFT")
	frame.label = label
	
	local text = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	text:SetPoint("RIGHT", frame, "RIGHT")
	frame.text = text
	
	frame:SetScript("OnEnter", function()
		if frame.tooltip then
			GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
			GameTooltip:SetText(frame.tooltip, 1, 1, 1)
			if frame.tooltipSub then
				GameTooltip:AddLine(frame.tooltipSub, 1, 0.82, 0)
			end
			GameTooltip:Show()
		end
	end)
	frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
	
	return frame
end

local function InitUI()
	if module.frame then return end

	local frame = CreateFrame("Frame", "VE_CharacterStatsFrame", PaperDollFrame)
	frame:SetWidth(230)
	frame:SetHeight(78)
	frame:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 67, -291)
	module.frame = frame

	-- Textures
	local leftTop = frame:CreateTexture(nil, "BORDER")
	leftTop:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-StatBackground")
	leftTop:SetWidth(115); leftTop:SetHeight(16)
	leftTop:SetPoint("TOPLEFT", frame, "TOPLEFT")
	leftTop:SetTexCoord(0, 0.8984375, 0, 0.125)

	local leftMid = frame:CreateTexture(nil, "BORDER")
	leftMid:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-StatBackground")
	leftMid:SetWidth(115); leftMid:SetHeight(53)
	leftMid:SetPoint("TOPLEFT", leftTop, "BOTTOMLEFT")
	leftMid:SetTexCoord(0, 0.8984375, 0.125, 0.1953125)

	local leftBot = frame:CreateTexture(nil, "BORDER")
	leftBot:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-StatBackground")
	leftBot:SetWidth(115); leftBot:SetHeight(16)
	leftBot:SetPoint("TOPLEFT", leftMid, "BOTTOMLEFT")
	leftBot:SetTexCoord(0, 0.8984375, 0.484375, 0.609375)

	local rightTop = frame:CreateTexture(nil, "BORDER")
	rightTop:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-StatBackground")
	rightTop:SetWidth(115); rightTop:SetHeight(16)
	rightTop:SetPoint("TOPLEFT", leftTop, "TOPRIGHT")
	rightTop:SetTexCoord(0, 0.8984375, 0, 0.125)

	local rightMid = frame:CreateTexture(nil, "BORDER")
	rightMid:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-StatBackground")
	rightMid:SetWidth(115); rightMid:SetHeight(53)
	rightMid:SetPoint("TOPLEFT", rightTop, "BOTTOMLEFT")
	rightMid:SetTexCoord(0, 0.8984375, 0.125, 0.1953125)

	local rightBot = frame:CreateTexture(nil, "BORDER")
	rightBot:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-StatBackground")
	rightBot:SetWidth(115); rightBot:SetHeight(16)
	rightBot:SetPoint("TOPLEFT", rightMid, "BOTTOMLEFT")
	rightBot:SetTexCoord(0, 0.8984375, 0.484375, 0.609375)

	-- Rows
	for i = 1, 6 do
		statRows.left[i] = CreateStatRow(frame, i, "LEFT")
		if i == 1 then statRows.left[i]:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -3)
		else statRows.left[i]:SetPoint("TOPLEFT", statRows.left[i-1], "BOTTOMLEFT") end

		statRows.right[i] = CreateStatRow(frame, i, "RIGHT")
		if i == 1 then statRows.right[i]:SetPoint("TOPLEFT", rightTop, "TOPLEFT", 6, -3)
		else statRows.right[i]:SetPoint("TOPLEFT", statRows.right[i-1], "BOTTOMLEFT") end
	end

	-- Dropdowns
	dropdowns.left = CreateFrame("Frame", "VE_StatLeftDropDown", frame, "UIDropDownMenuTemplate")
	dropdowns.left:SetPoint("BOTTOMLEFT", leftTop, "TOPLEFT", -17, -8)
	UIDropDownMenu_SetWidth(99, dropdowns.left)
	UIDropDownMenu_JustifyText("LEFT", dropdowns.left)

	dropdowns.right = CreateFrame("Frame", "VE_StatRightDropDown", frame, "UIDropDownMenuTemplate")
	dropdowns.right:SetPoint("BOTTOMLEFT", rightTop, "TOPLEFT", -17, -8)
	UIDropDownMenu_SetWidth(99, dropdowns.right)
	UIDropDownMenu_JustifyText("LEFT", dropdowns.right)

	local function OnClick()
		UIDropDownMenu_SetSelectedValue(this.owner, this.value)
		if this.owner == dropdowns.left then
			module.config.DropdownLeft = this.value
		else
			module.config.DropdownRight = this.value
		end
		module.UpdateStats()
	end

	local function AddStatOption(text, value, selectedValue, owner)
		local info = {}
		info.text = text
		info.value = value
		info.func = OnClick
		info.owner = owner
		info.checked = (value == selectedValue)
		UIDropDownMenu_AddButton(info)
	end

	local function InitDropdownLeft()
		local selected = module.config.DropdownLeft
		local owner = dropdowns.left
		AddStatOption("Base Stats", "PLAYERSTAT_BASE_STATS", selected, owner)
		AddStatOption("Melee", "PLAYERSTAT_MELEE_COMBAT", selected, owner)
		AddStatOption("Ranged", "PLAYERSTAT_RANGED_COMBAT", selected, owner)
		AddStatOption("Spell", "PLAYERSTAT_SPELL_COMBAT", selected, owner)
		AddStatOption("Defenses", "PLAYERSTAT_DEFENSES", selected, owner)
	end

	local function InitDropdownRight()
		local selected = module.config.DropdownRight
		local owner = dropdowns.right
		AddStatOption("Base Stats", "PLAYERSTAT_BASE_STATS", selected, owner)
		AddStatOption("Melee", "PLAYERSTAT_MELEE_COMBAT", selected, owner)
		AddStatOption("Ranged", "PLAYERSTAT_RANGED_COMBAT", selected, owner)
		AddStatOption("Spell", "PLAYERSTAT_SPELL_COMBAT", selected, owner)
		AddStatOption("Defenses", "PLAYERSTAT_DEFENSES", selected, owner)
	end

	UIDropDownMenu_Initialize(dropdowns.left, InitDropdownLeft)
	UIDropDownMenu_SetSelectedValue(dropdowns.left, module.config.DropdownLeft)

	UIDropDownMenu_Initialize(dropdowns.right, InitDropdownRight)
	UIDropDownMenu_SetSelectedValue(dropdowns.right, module.config.DropdownRight)
end

-- ============================================================================
-- UPDATE LOGIC
-- ============================================================================
local function UpdatePaperdollStats(side, category)
	local rows = (side == "LEFT") and statRows.left or statRows.right
	for i = 1, 6 do
		rows[i].label:SetText("")
		rows[i].text:SetText("")
		rows[i].tooltip = nil
		rows[i].tooltipSub = nil
		rows[i]:Show()
	end

	if category == "PLAYERSTAT_BASE_STATS" then
		for i = 1, 5 do
			local stat, eff, pos, neg = UnitStat("player", i)
			rows[i].label:SetText(_G["SPELL_STAT"..(i-1).."_NAME"]..":")
			local color = (neg < 0 and "|cffff2020") or (pos > 0 and "|cff20ff20") or "|cffffffff"
			rows[i].text:SetText(color .. eff .. "|r")
			rows[i].tooltip = _G["SPELL_STAT"..(i-1).."_NAME"]
			rows[i].tooltipSub = "Base: " .. stat .. "\nBonus: " .. (pos+neg)
		end
		local _, eff = UnitArmor("player")
		rows[6].label:SetText(ARMOR..":")
		rows[6].text:SetText(eff)
		
	elseif category == "PLAYERSTAT_MELEE_COMBAT" then
		local min, max = UnitDamage("player")
		rows[1].label:SetText("Damage:")
		rows[1].text:SetText(math.floor(min).."-"..math.ceil(max))
		
		local speed = UnitAttackSpeed("player")
		rows[2].label:SetText("Speed:")
		rows[2].text:SetText(string.format("%.2f", speed))
		
		rows[3].label:SetText("Power:")
		rows[3].text:SetText(GetAttackPower())
		
		rows[4].label:SetText("Hit Rating:")
		rows[4].text:SetText(Cache.hit .. "%")
		
		rows[5].label:SetText("Crit Chance:")
		rows[5].text:SetText(string.format("%.2f%%", GetCritChance() + Cache.crit))
		
		local mh = UnitAttackBothHands("player")
		rows[6].label:SetText("Skill:")
		rows[6].text:SetText(mh)

	elseif category == "PLAYERSTAT_RANGED_COMBAT" then
		if not UnitHasRelicSlot("player") and GetInventoryItemLink("player", 18) then
			local speed = UnitRangedDamage("player")
			rows[1].label:SetText("Speed:")
			rows[1].text:SetText(string.format("%.2f", speed))
			rows[2].label:SetText("Power:")
			rows[2].text:SetText(GetRangedAttackPower())
			rows[3].label:SetText("Hit Rating:")
			rows[3].text:SetText(Cache.hit .. "%")
			rows[4].label:SetText("Crit Chance:")
			rows[4].text:SetText(string.format("%.2f%%", Cache.crit)) 
			rows[5].label:SetText("Skill:")
			local base, mod = UnitRangedAttack("player")
			rows[5].text:SetText(base + mod)
		else
			rows[1].label:SetText("Ranged:")
			rows[1].text:SetText("N/A")
		end
		
	elseif category == "PLAYERSTAT_SPELL_COMBAT" then
		-- 1. Spell Power
		rows[1].label:SetText("Spell Power:")
		-- Spell Power displayed in GREEN if it includes buffs or school specific damage, otherwise white
		local text = Cache.spell_power
		if Cache.spell_power > 0 then
			text = "|cff20ff20" .. text .. "|r"
		end
		rows[1].text:SetText(text)
		rows[1].tooltip = "Spell Power"
		rows[1].tooltipSub = "Increases damage done by spells and effects."
		
		-- 2. Hit Rating
		rows[2].label:SetText("Hit Rating:")
		rows[2].text:SetText(Cache.spell_hit .. "%")
		
		-- 3. Crit Chance
		rows[3].label:SetText("Crit Chance:")
		local totalCrit = Cache.spell_crit + Cache.talent_spell_crit
		rows[3].text:SetText(string.format("%.2f%%", totalCrit))
		
		-- 4. Healing
		rows[4].label:SetText("Healing:")
		-- Healing = Generic Power + Healing Only (School specific power does not apply)
		local healVal = Cache.generic_spell_power + Cache.healing_power
		text = healVal
		if healVal > 0 then
			text = "|cff20ff20" .. text .. "|r"
		end
		rows[4].text:SetText(text)
		
		-- 5. Mana Regen
		rows[5].label:SetText("Mana Regen:")
		local normal, casting = GetManaRegen()
		rows[5].text:SetText(string.format("%d (%d)", normal, casting))
		rows[5].tooltip = "Mana Regen"
		rows[5].tooltipSub = string.format("Normal: %d per tick\nCasting: %d per tick", normal, casting)
		
		-- 6. Haste
		rows[6].label:SetText("Haste:")
		rows[6].text:SetText(Cache.spell_haste .. "%")

	elseif category == "PLAYERSTAT_DEFENSES" then
		local _, eff = UnitArmor("player")
		rows[1].label:SetText("Armor:")
		rows[1].text:SetText(eff)
		local baseDef, modDef = UnitDefense("player")
		rows[2].label:SetText("Defense:")
		rows[2].text:SetText(baseDef + modDef)
		rows[3].label:SetText("Dodge:")
		rows[3].text:SetText(string.format("%.2f%%", GetDodgeChance()))
		rows[4].label:SetText("Parry:")
		rows[4].text:SetText(string.format("%.2f%%", GetParryChance()))
		rows[5].label:SetText("Block:")
		rows[5].text:SetText(string.format("%.2f%%", GetBlockChance()))
	end
end

function module.UpdateStats()
	if not module.frame then return end
	ScanGear()
	ScanTalents()
	UpdatePaperdollStats("LEFT", module.config.DropdownLeft)
	UpdatePaperdollStats("RIGHT", module.config.DropdownRight)
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("UNIT_INVENTORY_CHANGED")
module.plug:RegisterEvent("CHARACTER_POINTS_CHANGED")
module.plug:RegisterEvent("PLAYER_AURAS_CHANGED")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	if event == "PLAYER_ENTERING_WORLD" then
		InitUI()
		if CharacterAttributesFrame then CharacterAttributesFrame:Hide() end
		PaperDollFrame:SetScript("OnShow", function()
			module.UpdateStats()
			CharacterAttributesFrame:Hide()
		end)
	end
	if module.frame and module.frame:IsVisible() then module.UpdateStats() end
end)
