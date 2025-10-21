local module = VE.registerModule({
	identifier = "MaintainDruidForms",
	meta = {
		label = "Maintain Druid Forms",
		description = "Maintain your chosen Druid Forms without toggling out of them (spammable).",
	},
	plug = nil,
	superWoWRequired = false,
	config = {},
	data = {
		actionTooltip = nil,
		forms = {
			["Interface\\Icons\\Ability_Racial_BearForm"] = "Bear Form",
			-- ["Interface\\Icons\\Ability_Racial_BearForm"] = "Dire Bear Form",
			["Interface\\Icons\\Ability_Druid_AquaticForm"] = "Aquatic Form",
			["Interface\\Icons\\Ability_Druid_CatForm"] = "Cat Form",
			["Interface\\Icons\\Ability_Druid_TravelForm"] = "Travel Form",
		},
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function GetCurrentDruidForm()
	local _, class = UnitClass("player")
	if class ~= "DRUID" then return nil end

	for i = 0, 31 do
		local buff = UnitBuff("player", i)
		if buff and module.data.forms[buff] then
			return module.data.forms[buff]
		end
	end

	return nil
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("VARIABLES_LOADED")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	module.data.actionTooltip = CreateFrame("GameTooltip", module.identifier.."ActionTooltip", UIParent, "GameTooltipTemplate")
	module.data.actionTooltip:SetOwner(UIParent, "ANCHOR_NONE")

	local Original_UseAction = UseAction
	function UseAction(slot, checkCursor, onSelf)
		module.data.actionTooltip:ClearLines()
		module.data.actionTooltip:SetAction(slot)

		local spellName = getglobal(module.identifier.."ActionTooltipTextLeft1"):GetText()
		local currentForm = GetCurrentDruidForm()

		-- We remove Dire from spellName.
		if spellName then
			if string.sub(spellName, 1, string.len("Dire")) == "Dire" then
				spellName = string.sub(spellName, string.len("Dire") + 2)
			end
		end

		if spellName ~= currentForm then
			Original_UseAction(slot, checkCursor, onSelf)
		end
	end
end)
