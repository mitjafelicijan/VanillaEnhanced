local module = VE.registerModule({
	identifier = "LowHealth",
	meta = {
		label = "Low Health Warning",
		description = "Displays a red screen border when health drops below 35%.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		threshold = 0.35,   -- health threshold 33%
		alpha = 0.6,        -- alpha of image
		animDuration = 1.0, -- 1 sec ducation
	},
	data = {
		triggerFadeOut = false,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

module.plug = CreateFrame("Frame", module.identifier, UIParent)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("UNIT_HEALTH")
module.plug:RegisterEvent("PLAYER_DEAD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" and not module.plug.frame then
		module.plug.frame = CreateFrame("Frame", nil, UIParent)
		module.plug.frame:SetFrameStrata("BACKGROUND")
		module.plug.frame:SetAllPoints()

		module.plug.frame.tex = module.plug.frame:CreateTexture(nil, "BACKGROUND")
		module.plug.frame.tex:SetAllPoints()
		module.plug.frame.tex:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\LowHealth-Border")
		module.plug.frame.tex:SetAlpha(0)
	end

	if event == "UNIT_HEALTH" and not UnitIsDeadOrGhost("player") then
		if not module.plug.frame or not module.plug.frame.tex then return end

		local health, maxHealth = UnitHealth("player"), UnitHealthMax("player")
		local healthPercentage = health / maxHealth
		
		if (healthPercentage < module.config.threshold) and (not module.data.triggerFadeOut) then
			UIFrameFadeIn(module.plug.frame.tex, module.config.animDuration, module.plug.frame.tex:GetAlpha(), module.config.alpha)
			module.data.triggerFadeOut = true
		end

		if (healthPercentage > module.config.threshold) and module.data.triggerFadeOut then
			UIFrameFadeOut(module.plug.frame.tex, module.config.animDuration, module.plug.frame.tex:GetAlpha(), 0)
			module.data.triggerFadeOut = false
		end
	end

	if event == "PLAYER_DEAD" and module.plug ~= nil then
		if not module.plug.frame or not module.plug.frame.tex then return end
		module.plug.frame.tex:SetAlpha(0)
	end
end)
