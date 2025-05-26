local module = VE.registerModule({
	identifier = "RestedXPTooltip",
	meta = {
		label = "Rested Experience Tooltip",
		description = "Displays your rested XP as a percentage directly on the XP bar for easier tracking of bonus experience.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {},
	data = {
		attached = false,
		exhaustion = 0,
		currentXP = 0,
		nextLevelXP = 0,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("UPDATE_EXHAUSTION")
module.plug:RegisterEvent("PLAYER_UPDATE_RESTING")
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("PLAYER_LEVEL_UP")
module.plug:RegisterEvent("PLAYER_XP_UPDATE")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if not module.plug.exp then
		module.plug.exp = CreateFrame("Frame", "exp", UIParent)
		module.plug.exp:SetFrameStrata("HIGH")

		module.plug.exp.expstring = module.plug.exp:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
		module.plug.exp.expstring:ClearAllPoints()
		module.plug.exp.expstring:SetPoint("Center", MainMenuExpBar, "Center", 0, 2)
		module.plug.exp.expstring:SetJustifyH("Center")
		module.plug.exp.expstring:SetTextColor(1,1,1)

		MainMenuExpBar:SetScript("OnEnter", function(self)
			local currentXP, nextLevelXP, xpExhaustion = UnitXP("player"), UnitXPMax("player"), GetXPExhaustion() or 0
			local exhaustion = math.floor(xpExhaustion / nextLevelXP * 100) or 0
			local percentage = math.floor((exhaustion / 150) * 100)
			local tooltip = string.format("%s%% rested", percentage)
			if percentage == 0 then tooltip = "no rested" end
			if percentage == 100 then tooltip = "max rested" end

			module.plug.exp.expstring:SetText(string.format("XP %s / %s (%s)", currentXP, nextLevelXP, tooltip))
			module.plug.exp:Show()
		end)

		MainMenuExpBar:SetScript("OnLeave", function(self)
			module.plug.exp:Hide()
		end)

		module.data.attached = true
	end
end)
