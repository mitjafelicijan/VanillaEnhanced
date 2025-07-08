local module = VE.registerModule({
	identifier = "MaintainHunterAspects",
	meta = {
		label = "Maintain Hunter Aspects",
		description = "Maintain your chosen Hunter Aspects without toggling out of them (spammable).",
	},
	plug = nil,
	superWoWRequired = false,
	config = {},
	data = {
		actionTooltip = nil,
		aspects = {
			["Interface\\Icons\\Spell_Nature_RavenForm"]            = "Aspect of the Hawk",
			["Interface\\Icons\\Ability_Hunter_AspectOfTheMonkey"]  = "Aspect of the Monkey",
			["Interface\\Icons\\Ability_Mount_JungleTiger"]         = "Aspect of the Cheetah",
			["Interface\\Icons\\Ability_Mount_WhiteTiger"]          = "Aspect of the Pack",
			["Interface\\Icons\\Ability_Mount_PinkTiger"]           = "Aspect of the Beast",
			["Interface\\Icons\\Spell_Nature_ProtectionformNature"] = "Aspect of the Wild",
			["Interface\\Icons\\Ability_Mount_WhiteDireWolf"]       = "Aspect of the Wolf",
		},
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function GetCurrentAspect()
	local _, class = UnitClass("player")
	if class ~= "HUNTER" then return nil end

	for i = 0, 31 do
		local buff = UnitBuff("player", i)
		if buff and module.data.aspects[buff] then
			return module.data.aspects[buff]
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
		local currentAspect = GetCurrentAspect()

		if spellName ~= currentAspect then
			Original_UseAction(slot, checkCursor, onSelf)
		end
	end
end)
