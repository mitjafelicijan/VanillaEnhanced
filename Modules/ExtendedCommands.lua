local module = VE.registerModule({
	identifier = "ExtendedCommands",
	meta = {
		label = "Extended Commands",
		description = "Adds a set of classic-style macros, expanding the available commands to more closely resemble the original WoW Classic client.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function CurrentDruidForm()
	local inForm = nil
	for i = 1, GetNumShapeshiftForms() do
		_, _, active, _ = GetShapeshiftFormInfo(i)
		if active ~= nil then
			inForm = i
		end
	end
	return inForm
end

local function GoIntoDruidFormId(formId)
	local form = CurrentDruidForm()
	if form ~= nil and form ~= formId then
		CastShapeshiftForm(form)
	end
	_, _, active, _ = GetShapeshiftFormInfo(formId)
	if active == nil then
		CastShapeshiftForm(formId)
	end
end

local function MouseoverUnit()
	local unit = "mouseover"

	if not UnitExists(unit) then
		local frame = GetMouseFocus()
		local fparent = frame:GetParent()

		if frame.label and frame.id then unit = frame.label .. frame.id
		elseif frame.unit then unit = frame.unit
		elseif fparent and fparent.unit then unit = fparent.unit
		elseif UnitExists("target") then unit = "target"
		elseif GetCVar("autoSelfCast") == "1" then unit = "player"
		else unit = nil end
	end

	return unit
end

-- FIXME: Check why cheetah and pack don't work properly.
local function GetCurrentAspect()
	local _, class = UnitClass("player")
	if class ~= "HUNTER" then return nil end

	for i = 1, 16 do
		local buff = UnitBuff("player", i)
		if buff then
			if buff == "Interface\\Icons\\Ability_Mount_JungleTiger" then
				return "Cheetah"
			elseif buff == "Interface\\Icons\\Ability_Mount_WhiteTiger" then
				return "Pack"
			elseif buff == "Interface\\Icons\\Ability_Hunter_AspectOfTheMonkey" then
				return "Monkey"
			elseif buff == "Interface\\Icons\\Spell_Nature_RavenForm" then
				return "Hawk"
			elseif buff == "Interface\\Icons\\Spell_Nature_ProtectionformNature" then
				return "Wild"
			elseif buff == "Interface\\Icons\\Ability_Mount_PinkTiger" then
				return "Beast"
			end
		end
	end

	return nil
end

local function ChangeToAspect(aspect)
	local currentAspect = GetCurrentAspect()
	if currentAspect ~= aspect then
		CastSpellByName("Aspect of the " .. aspect)
	end
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("VARIABLES_LOADED")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	SLASH_TweeksReload1 = "/reloadui"
	SLASH_TweeksReload2 = "/reload"
	SLASH_TweeksReload3 = "/rl"
	SlashCmdList["TweeksReload"] = function()
		ConsoleExec("reloadui")
	end

	SLASH_CANCELFORM1 = "/cancelform"
	SlashCmdList["CANCELFORM"] = function()
		-- Druid forms.
		for i = 1, GetNumShapeshiftForms() do
			_, _, active, _ = GetShapeshiftFormInfo(i)
			if active ~= nil then
				CastShapeshiftForm(i)
			end
		end

		-- Priest Shadowform aura.
		for i = 1, 15 do
			buffTexture = GetPlayerBuffTexture(i)
			if buffTexture ~= nil then
				startPos, endPos = string.find(buffTexture, "Spell_Shadow_Shadowform")
				if startPos ~= nil and endPos ~= nil then CancelPlayerBuff(i) end
			end
		end
	end

	SLASH_BEARFORM1 = "/bearform"
	SlashCmdList["BEARFORM"] = function()
		GoIntoDruidFormId(1)
	end

	SLASH_AQUATICFORM1 = "/aquaticform"
	SlashCmdList["AQUATICFORM"] = function()
		GoIntoDruidFormId(2)
	end

	SLASH_CATFORM1 = "/catform"
	SlashCmdList["CATFORM"] = function()
		GoIntoDruidFormId(3)
	end

	SLASH_TRAVELFORM1 = "/travelform"
	SlashCmdList["TRAVELFORM"] = function()
		GoIntoDruidFormId(4)
	end

	SLASH_ASPECTMONKEY1 = "/aspectofmonkey"
	SlashCmdList["ASPECTMONKEY"] = function()
		ChangeToAspect("Monkey")
	end

	SLASH_ASPECTHAWK1 = "/aspectofhawk"
	SlashCmdList["ASPECTHAWK"] = function()
		ChangeToAspect("Hawk")
	end

	SLASH_ASPECTWILD1 = "/aspectofwild"
	SlashCmdList["ASPECTWILD"] = function()
		ChangeToAspect("Wild")
	end

	SLASH_ASPECTBEAST1 = "/aspectofbeast"
	SlashCmdList["ASPECTBEAST"] = function()
		ChangeToAspect("Beast")
	end

	SLASH_ASPECTCHEETAH1 = "/aspectofcheetah"
	SlashCmdList["ASPECTCHEETAH"] = function()
		ChangeToAspect("Cheetah")
	end

	SLASH_ASPECTPACK1 = "/aspectofpack"
	SlashCmdList["ASPECTPACK"] = function()
		ChangeToAspect("Pack")
	end

	SLASH_DISMOUNT1 = "/dismount"
	SlashCmdList["DISMOUNT"] = function()
		for i = 0, 15 do
			buffTexture = GetPlayerBuffTexture(i)
			if buffTexture ~= nil then
				local startPos, endPos = nil, nil
				-- Normal mounts.
				startPos, endPos = string.find(buffTexture, "Ability_Mount_")
				if startPos ~= nil and endPos ~= nil then CancelPlayerBuff(i) end
				-- Turtle mounts.
				startPos, endPos = string.find(buffTexture, "inv_pet_speedy")
				if startPos ~= nil and endPos ~= nil then CancelPlayerBuff(i) end
				-- Warlock mounts.
				startPos, endPos = string.find(buffTexture, "Spell_Nature_Swiftness")
				if startPos ~= nil and endPos ~= nil then CancelPlayerBuff(i) end
				-- Ghostwolf form.
				startPos, endPos = string.find(buffTexture, "Spell_Nature_SpiritWolf")
				if startPos ~= nil and endPos ~= nil then CancelPlayerBuff(i) end
			end
		end
	end

	SLASH_USE1 = "/use"
	SlashCmdList["USE"] = function(msg, editbox)
		for bagID = 0, NUM_BAG_SLOTS do
			for slotIndex = 1, GetContainerNumSlots(bagID) do
				local name = GetContainerItemLink(bagID, slotIndex)
				if name and string.find(name, msg) then
					UseContainerItem(bagID, slotIndex)
				end
			end
		end
	end

	SLASH_STCAST1 = "/mcast"
	SlashCmdList["STCAST"] = function(msg, editbox)
		local spell = msg or nil
		local unit = MouseoverUnit()
		local restoreHostileTarget = false

		-- Target hostile. Will need to revert back to it.
		if UnitCanAttack("player", "target") then
			restoreHostileTarget = true
		end

		TargetUnit(unit)
		SpellTargetUnit(unit)
		CastSpellByName(spell)

		-- Restoring back to the hostile target.
		if restoreHostileTarget then
			TargetLastEnemy()
		end
	end

	SLASH_CLEARTARGET1 = "/cleartarget"
	SlashCmdList["CLEARTARGET"] = function()
		ClearTarget()
	end
end)
