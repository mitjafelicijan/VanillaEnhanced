local module = VE.registerModule({
	identifier = "HunterTargetDistance",
	meta = {
		label = "Hunter Target Distance",
		description = "Shows a colored bar indicating your hunter target's distance and dead zone.",
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

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" and not module.indicator then
		module.indicator = CreateFrame("Frame", nil, UIParent)
		module.indicator:SetWidth(84)
		module.indicator:SetHeight(18)
		module.indicator:SetPoint("CENTER", UIParent, "CENTER", 0, -150)

		module.indicator:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			tileSize = 8,
			edgeSize = 8,
			insets = { left = 2, right = 2, top = 2, bottom = 2 }
		})
		module.indicator:SetBackdropColor(0, 0, 0, 0.5)
		module.indicator:SetBackdropBorderColor(1, 1, 1, 1)

		module.indicator.texture = module.indicator:CreateTexture(nil, "BACKGROUND")
		module.indicator.texture:SetPoint("TOPLEFT", module.indicator, "TOPLEFT", 2, -2)
		module.indicator.texture:SetPoint("BOTTOMRIGHT", module.indicator, "BOTTOMRIGHT", -2, 2)
		module.indicator.texture:SetTexture(1, 0, 0, 1) -- red

		module.indicator.text = module.indicator:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		module.indicator.text:SetPoint("CENTER", module.indicator, "CENTER", 0, 1)
		module.indicator.text:SetJustifyH("CENTER")
	end
end)

module.plug:SetScript("OnUpdate", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	if not module.indicator then return end

	if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
		local inMelee = CheckInteractDistance("target", 3)
		local rangedCheck = IsSpellInRange("Arcane Shot", "target")

		if inMelee then
			module.indicator.texture:SetTexture(0, 0, 0.6, 1)
			module.indicator.text:SetText("Melee")
		elseif rangedCheck == 1 then
			module.indicator.texture:SetTexture(0, 0.6, 0, 1)
			module.indicator.text:SetText("Ranged")
		elseif rangedCheck == 0 then
			module.indicator.texture:SetTexture(0.6, 0, 0, 1)
			module.indicator.text:SetText("Out of range")
		else
			module.indicator.texture:SetTexture(0.6, 0.6, 0, 1)
			module.indicator.text:SetText("Deadzone")
		end
		module.indicator:Show()
	else
		module.indicator:Hide()
	end
end)
