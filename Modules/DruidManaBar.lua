local module = VE.registerModule({
	identifier = "DruidManaBar",
	meta = {
		label = "Druid Mana Bar",
		description = "Shows your mana bar while in any shapeshift form, allowing you to track your mana pool during combat.",
	},
	plug = nil,
	superWoWRequired = true,
	config = {},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function DisplayIfCorrectForm()
	if not module.plug.manabar then return end
	local power = UnitPowerType("player")
	if power == 0 or power == 2 then
		module.plug.manabar:Hide() -- Human or Aquatic form.
	else
		module.plug.manabar:Show() -- Bear or Cat form.
	end
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("UNIT_DISPLAYPOWER")
module.plug:RegisterEvent("UNIT_MANA")
module.plug:RegisterEvent("UNIT_MAXMANA")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	local _, playerClass = UnitClass("player")
	if playerClass ~= "DRUID" then return end

	if event == "PLAYER_ENTERING_WORLD" then
		if module.plug.manabar then
			DisplayIfCorrectForm()
			return
		end

		module.plug.manabar = CreateFrame("Frame", nil, PlayerFrame)
		module.plug.manabar:SetPoint("Left", PlayerFrame, "Bottom", -10, 24)
		module.plug.manabar:SetWidth(123)
		module.plug.manabar:SetHeight(15)
		module.plug.manabar:SetFrameLevel(0)

		local _, maxMana = UnitManaMax("player")
		local _, currentMana = UnitMana("player")

		module.plug.manabar.bg = module.plug.manabar:CreateTexture(nil, "BORDER")
		module.plug.manabar.bg:SetPoint("Center", module.plug.manabar, "Center", 0, 0)
		module.plug.manabar.bg:SetWidth(module.plug.manabar:GetWidth() - 5)
		module.plug.manabar.bg:SetHeight(module.plug.manabar:GetHeight() - 5)
		module.plug.manabar.bg:SetTexture(0, 0, 0, 0.5)

		module.plug.manabar.container = CreateFrame("Frame", nil, module.plug.manabar)
		module.plug.manabar.container:SetAllPoints(module.plug.manabar)
		module.plug.manabar.container:SetFrameLevel(1)

		module.plug.manabar.power = CreateFrame("StatusBar", nil, module.plug.manabar.container, "TextStatusBar")
		module.plug.manabar.power:SetPoint("Center", module.plug.manabar.container, "Center", 0, 0)
		module.plug.manabar.power:SetWidth(module.plug.manabar:GetWidth() - 5)
		module.plug.manabar.power:SetHeight(module.plug.manabar:GetHeight() - 5)
		module.plug.manabar.power:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		module.plug.manabar.power:SetStatusBarColor(0.0, 0.7, 1.0, 1.0)
		module.plug.manabar.power:SetMinMaxValues(0, maxMana)
		module.plug.manabar.power:SetValue(currentMana)
		module.plug.manabar.power:SetFrameLevel(2)

		module.plug.manabar.border = CreateFrame("Frame", nil, module.plug.manabar)
		module.plug.manabar.border:SetAllPoints(module.plug.manabar)
		module.plug.manabar.border:SetFrameLevel(3)

		module.plug.manabar.tex = module.plug.manabar.border:CreateTexture(nil, "BORDER")
		module.plug.manabar.tex:SetAllPoints(module.plug.manabar.border)
		module.plug.manabar.tex:SetTexture("Interface\\Tooltips\\UI-StatusBar-Border")

		module.plug.manabar.text = MainMenuBarBackpackButton:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
		module.plug.manabar.text:SetTextColor(1, 1, 1)
		module.plug.manabar.text:SetPoint("CENTER", module.plug.manabar, "Center", 0, 0)
		module.plug.manabar.text:SetDrawLayer("OVERLAY", 2)
		module.plug.manabar.text:Hide()
		
		PlayerFrame:SetScript("OnEnter", function()
			if not module.plug.manabar:IsVisible() then return end
			local _, maxMana = UnitManaMax("player")
			local _, currentMana = UnitMana("player")
			module.plug.manabar.text:SetText(string.format("Mana %s / %s", currentMana, maxMana))
			module.plug.manabar.text:Show()
		end)

		PlayerFrame:SetScript("OnLeave", function()
			module.plug.manabar.text:Hide()
		end)

		-- Initially display if in correct form.
		DisplayIfCorrectForm()
	else
		if event == "UNIT_DISPLAYPOWER" then
			DisplayIfCorrectForm()
		end

		local _, maxMana = UnitManaMax("player")
		local _, currentMana = UnitMana("player")
		if module.plug.manabar and module.plug.manabar.power then
			module.plug.manabar.power:SetMinMaxValues(0, maxMana)
			module.plug.manabar.power:SetValue(currentMana)
		end
	end
end)
