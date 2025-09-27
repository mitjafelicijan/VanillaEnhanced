local module = VE.registerModule({
	identifier = "DruidOneButton",
	meta = {
		label = "Druid One Button Rotation",
		description = "Tries to to a good job with cat form rotation.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		debug = false,
		applySpells = {
			tigersFury = true,
			faerieFire = true,
		},
		powerShift = {
			energyThreshold = 5,
		},
		buffs = {
			["Tiger's Fury"] = "Interface\\Icons\\Ability_Mount_JungleTiger",
			["Faerie Fire"] = "Interface\\Icons\\Spell_Nature_FaerieFire",
			["Rip"] = "Interface\\Icons\\Ability_GhoulFrenzy",
			["Rake"] = "Interface\\Icons\\Ability_Druid_DisemBowel",
		},
	},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local print = VE.print

local function unitHasBuff(unit, buffTexture)
	for j = 1, 32 do
		local texture, applications = UnitBuff(unit, j)
		if texture then
			if texture == buffTexture then
				return true
			end
		else break end
	end
	return false
end

local function unitHasDebuff(unit, buffTexture)
	for j = 1, 32 do
		local texture, applications = UnitDebuff(unit, j)
		if texture then
			if texture == buffTexture then
				return true
			end
		else break end
	end
	return false
end

local function cancelDruidForm()
	for i = 1, GetNumShapeshiftForms() do
		_, _, active, _ = GetShapeshiftFormInfo(i)
		if active ~= nil then
			CastShapeshiftForm(i)
		end
	end
end

local function rotation(arg)
	if not UnitExists("target") then return end

	local currentEnergy, currentMana = UnitMana("player")
	local maxEnergy, maxMana = UnitManaMax("player")
	local powerType = UnitPowerType("player") -- 3 is cat

	if module.config.debug then
		print(string.format("> mana(%s/%s), energy(%s/%s), power: %s", currentMana, maxMana, currentEnergy, maxEnergy, powerType))
	end

	if arg == "powershift" then
		-- If not in cat form then switch back to cat.
		if powerType ~= 3 then
			CastShapeshiftForm(3)
		else
			-- If energy falls to N or below cancel druid forms.
			if currentEnergy <= module.config.powerShift.energyThreshold then
				cancelDruidForm()
			end
		end
	end

	-- Apply Tiger's Fury if missing.
	if module.config.applySpells.tigersFury and not unitHasBuff("player", module.config.buffs["Tiger's Fury"]) then
		CastSpellByName("Tiger's Fury")
	end

	-- Check if Fearie Fire (Feral) is applied, and if not, apply it.
	if module.config.applySpells.faerieFire and not unitHasDebuff("target", module.config.buffs["Faerie Fire"]) then
		-- FIXME: Stupid hack because CastSpellByName doesn't work for this spell.
		for i = 1,200 do
			local spellName = GetSpellName(i, "spell")
			if spellName == "Faerie Fire (Feral)" then
				CastSpell(i, "spell")
				break
			end
		end
	end

	-- Execute the rest of rotation.
	local points = GetComboPoints()
	if points == 0 then
		CastSpellByName("Rake")
	elseif points == 5 then
		if unitHasDebuff("target", module.config.buffs["Rip"]) then
			CastSpellByName("Ferocious Bite")
		else
			CastSpellByName("Rip")
		end
	else
		-- Backfill Rake if target is missing one.
		if not unitHasDebuff("target", module.config.buffs["Rake"]) then
			CastSpellByName("Rake")
		else
			-- This is the filler spell.
			CastSpellByName("Shred")
		end
	end
end

module.frame = CreateFrame("Frame", module.identifier, UIParent)
module.frame:RegisterEvent("PLAYER_ENTERING_WORLD")

module.frame:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	if not UnitClass("player") == "Druid" then return end

	SLASH_DruidOneButton1 = "/dob"
	SlashCmdList["DruidOneButton"] = function(arg)
		rotation(arg)
	end
end)
