local module = VE.registerModule({
	identifier = "CombatCursor",
	meta = {
		label = "Combat Cursor",
		description = "Enhances cursor visibility in combat by adding a background texture, making it easier to track during gameplay.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		cursorSize = 64,
		cursorColor = {
			r = 1,0,
			g = 0.0,
			b = 1.0,
		},
	},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

SLASH_COMBATCURSOR1 = "/cursor"
SLASH_COMBATCURSOR2 = "/cc"
SlashCmdList["COMBATCURSOR"] = function()
	if VE.isModuleEnabled(module.identifier) then
		VE.disableModule(module.identifier)
	else
		VE.enableModule(module.identifier)
	end
	ConsoleExec("reloadui")
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" and not module.plug.cursor then
		local uiScale = UIParent:GetEffectiveScale()
		module.plug.cursor = CreateFrame("Frame", nil, UIParent)
		module.plug.cursor:SetPoint("Center", UIParent, "BottomLeft", 0, 0)
		module.plug.cursor:SetWidth(module.config.cursorSize * uiScale)
		module.plug.cursor:SetHeight(module.config.cursorSize * uiScale)
		module.plug.cursor:SetFrameStrata("BACKGROUND")
		module.plug.cursor:SetFrameLevel(0)
		module.plug.cursor.tex = module.plug.cursor:CreateTexture(nil, "BACKGROUND")
		module.plug.cursor.tex:SetAllPoints(module.plug.cursor)
		module.plug.cursor.tex:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\CombatCursor-Background")
		module.plug.cursor.tex:SetVertexColor(
			module.config.cursorColor.r,
			module.config.cursorColor.g,
			module.config.cursorColor.b
		)

		module.plug:SetScript("OnUpdate", function()
			if module.plug.cursor then
				local x, y = GetCursorPosition()
				x = x / uiScale
				y = y / uiScale

				module.plug.cursor:ClearAllPoints()
				module.plug.cursor:SetPoint("Center", UIParent, "BottomLeft", x, y)
			end
		end)
	end
end)

