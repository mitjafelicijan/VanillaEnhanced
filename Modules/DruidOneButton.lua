local module = VE.registerModule({
	identifier = "DruidOneButton",
	meta = {
		label = "Druid One Button Rotation",
		description = "Tries to to a good job with cat form rotation.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		applySpells = {
			tigersFury = true,
			faerieFire = true,
		},
		powerShift = {
			energyThreshold = 10,
		},
		buffs = {
			["Tiger's Fury"] = "Interface\\Icons\\Ability_Mount_JungleTiger",
			["Faerie Fire"] = "Interface\\Icons\\Spell_Nature_FaerieFire",
			["Rip"] = "Interface\\Icons\\Ability_GhoulFrenzy",
			["Rake"] = "Interface\\Icons\\Ability_Druid_DisemBowel",
		},
		spellTimeout = {
			rake = 8.10,
			fff = 1.60,
		},
		idols = {
			["Idol of Savagery"] = "Interface\\Icons\\INV_QirajIdol_War",
		},
	},
	data = {
		queue = {
			rake = 0,
			fff = 0,
		},
	},
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

local function idolEquiped(idol)
	local slot = 18
	local trinketLink = GetInventoryItemLink("player", slot)
	local texture = GetInventoryItemTexture("player", slot)
	return (texture == module.config.idols[idol])
end

local function rotation(arg)
	if not UnitExists("target") then return end

	local currentEnergy, currentMana = UnitMana("player")
	local maxEnergy, maxMana = UnitManaMax("player")
	local powerType = UnitPowerType("player") -- 3 is cat	

	if arg == "powershift" then
		-- If not in cat form then switch back to cat.
		if powerType ~= 3 then
			CastShapeshiftForm(3)
			return
		else
			-- If energy falls to N or below cancel druid forms.
			if currentEnergy <= module.config.powerShift.energyThreshold then
				cancelDruidForm()
				return
			end
		end
	end

	-- Cast Rake when the old one expires.
	do
		local now = GetTime()
		local lastCast = module.data.queue.rake
		local elapsed = now - lastCast
		local timeout = module.config.spellTimeout.rake

		-- Add 10% of the timeout if Idol of Savagery equiped.
		if idolEquiped("Idol of Savagery") then
			timeout = math.ceil(timeout + (timeout * 0.10))
		end

		if elapsed >= timeout then
			module.data.queue.rake = now
			CastSpellByName("Rake")
		end
	end

	-- Check if Fearie Fire (Feral) is applied, and if not, apply it the highest rank.
	do
		local now = GetTime()
		local lastCast = module.data.queue.fff
		local elapsed = now - lastCast
		if elapsed >= module.config.spellTimeout.fff then
			module.data.queue.fff = now
			local highestFFF = 0
			for i = 1,200 do
				local spellName = GetSpellName(i, "spell")
				if spellName == "Faerie Fire (Feral)" then
					highestFFF = i
				end
			end
			CastSpell(highestFFF, "spell")
		end
	end

	-- Apply Tiger's Fury if missing.
	if module.config.applySpells.tigersFury and not unitHasBuff("player", module.config.buffs["Tiger's Fury"]) then
		CastSpellByName("Tiger's Fury")
	end

	-- Execute the rest of rotation.
	local points = GetComboPoints()
	if points == 5 then
		if unitHasDebuff("target", module.config.buffs["Rip"]) then
			CastSpellByName("Ferocious Bite")
		else
			CastSpellByName("Rip")
		end
	else
		CastSpellByName("Shred")
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
