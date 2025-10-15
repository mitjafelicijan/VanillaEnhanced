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
			energyThreshold = 20,    -- when energy goes below this value shapeshift
			minManaThreshold = 40,   -- never dip below this (in percentage)
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

local function rotation(filler, finisher, powershift)
	if not UnitExists("target") then return end

	local currentEnergy, currentMana = UnitMana("player")
	local maxEnergy, maxMana = UnitManaMax("player")
	local manaPercent = (currentMana / maxMana) * 100
	local powerType = UnitPowerType("player") -- 3 is cat	

	if powershift then
		if currentEnergy <= module.config.powerShift.energyThreshold and manaPercent > module.config.powerShift.minManaThreshold then
			CastSpellByName("Reshift")
		end
	end

	-- Cast Rake when the old one expires.
	if IsSpellInRange("Rake", "target") == 1 then
		local now = GetTime()
		local elapsed = now - module.data.queue.rake
		local timeout = module.config.spellTimeout.rake

		-- Reduce timeout of Rake by 10% if Idol of Savagery equiped.
		if idolEquiped("Idol of Savagery") then
			timeout = math.ceil(timeout + (timeout * 0.10))
		end

		if module.data.queue.rake == 0 or elapsed >= timeout then
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
	-- Check's if mele in range at all.
	if IsSpellInRange("Claw", "target") == 1 then
		local points = GetComboPoints()
		if points == 5 then
			if unitHasDebuff("target", module.config.buffs["Rip"]) then
				CastSpellByName(finisher)
			else
				CastSpellByName("Rip")
			end
		else
			CastSpellByName(filler)
		end
	end
end

module.frame = CreateFrame("Frame", module.identifier, UIParent)
module.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
module.frame:RegisterEvent("PLAYER_ENTER_COMBAT")
module.frame:RegisterEvent("PLAYER_LEAVE_COMBAT")
module.frame:RegisterEvent("PLAYER_TARGET_CHANGED")

module.frame:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	if not UnitClass("player") == "Druid" then return end

	if event == "PLAYER_ENTERING_WORLD" then
		SLASH_DruidOneButton1 = "/dob"
		SlashCmdList["DruidOneButton"] = function(arg)
			local args = VE.split(arg, ",")
			local filler = VE.trim(args[1])
			local finisher = VE.trim(args[2])
			local powershift = false

			if args[3] and args[3] == "powershift" then
				powershift = true
			end

			rotation(filler, finisher, powershift)
		end
	end

	if event == "PLAYER_ENTER_COMBAT" or
		event == "PLAYER_LEAVE_COMBAT" or
		event == "PLAYER_TARGET_CHANGED" then
		module.data.queue.rake = 0
	end
end)
