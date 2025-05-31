local module = VE.registerModule({
	identifier = "MiniPowerFrame",
	meta = {
		label = "Mini Power Frame",
		description = "Adds additional power player frame with power bar (energy, rage, mana and debuffs).",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		backgroundAlpha = 0.8,
		show = {
			[0] = false,  -- mana
			[1] = true,   -- rage
			[3] = true,   -- energy
		},
	},
	data = {
		-- frames
		miniPlayerFrame = nil,
		powerBar = nil,
		playerDebuffs = nil,

		-- general vars
		playerClass = nil,
		playerPower = nil,

		-- temporary vars
		aura = nil,
		texture = nil,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function UpdateComboPoints()
	module.data.comboPointCount = GetComboPoints()

	-- Reset all points
	for i = 1, 5 do
		getglobal(string.format("%sComboPoints%sHighlight", this:GetName(), i)):Hide()
	end

	if module.data.comboPointCount == 0 then
		module.data.comboPoints:Hide()
		return
	end

	for i = 1, module.data.comboPointCount do
		getglobal(string.format("%sComboPoints%sHighlight", this:GetName(), i)):Show()
	end

	if not module.data.comboPoints:IsShown() then
		module.data.comboPoints:Show()
	end
end

local function ToggleComboPoints()
	if (module.data.playerClass == "Druid" or module.data.playerClass == "Rogue") then
		UpdateComboPoints()
		return
	end

	module.data.comboPoints:Hide()
end

local function SwitchPowerBarColor()
	module.data.playerPower = UnitPowerType("player")

	if module.data.playerPower == 0 then
		module.data.powerBar:SetStatusBarColor(VE.config.PowerColors.Mana.r, VE.config.PowerColors.Mana.g, VE.config.PowerColors.Mana.b)
	end

	if module.data.playerPower == 1 then
		module.data.powerBar:SetStatusBarColor(VE.config.PowerColors.Rage.r, VE.config.PowerColors.Rage.g, VE.config.PowerColors.Rage.b)
	end

	if module.data.playerPower == 3 then
		module.data.powerBar:SetStatusBarColor(VE.config.PowerColors.Energy.r, VE.config.PowerColors.Energy.g, VE.config.PowerColors.Energy.b)
	end
end

local function UpdatePlayerDebuffs()
	if not UnitExists("player") then
		module.data.playerDebuffs:Hide()
		return
	end

	local texture = nil
	local activeBuffs = 0
	for i = 1, 4 do
		module.data.aura = getglobal(string.format("%sPlayerDebuffs%sTexture", this:GetName(), i))
		texture, _, _ = UnitDebuff("player", i)
		if texture then
			activeBuffs = activeBuffs + 1
			module.data.aura:SetTexture(texture)
			module.data.aura:Show()
		else
			module.data.aura:Hide()
		end
	end

	local xOffset = 0
	if activeBuffs > 0 then
		xOffset = (4 - activeBuffs) * (24 / 2) + (activeBuffs * 0.3)
	end

	module.data.playerDebuffs:ClearAllPoints()
	module.data.playerDebuffs:SetPoint("Center", module.data.miniPowerFrame, "Center", xOffset, -22)
	module.data.playerDebuffs:Show()
end

local function ToggleMiniPowerFrame()
	if module.config.show[UnitPowerType("player")] then
		this:Show()
	else
		this:Hide()
	end
end

function MiniPowerFrame_OnLoad()
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	this:RegisterEvent("UNIT_MANA")
	this:RegisterEvent("UNIT_RAGE")
	this:RegisterEvent("UNIT_ENERGY")
	this:RegisterEvent("UNIT_DISPLAYPOWER")
	this:RegisterEvent("UNIT_AURA")
	this:RegisterEvent("PLAYER_COMBO_POINTS")
	this:RegisterEvent("PLAYER_TARGET_CHANGED")

	module.data.playerClass = UnitClass("player")
	module.data.powerBar = getglobal(this:GetName() .. "PowerStatusBar")
	module.data.playerDebuffs = getglobal(this:GetName() .. "PlayerDebuffs")
	module.data.comboPoints = getglobal(this:GetName() .. "ComboPoints")
	module.data.miniPowerFrame = getglobal(this:GetName())

	-- Set background.
	VE.dframe(module.data.powerBar, 0, 0, 0, module.config.backgroundAlpha)

	SwitchPowerBarColor()
	UpdatePlayerDebuffs()
	ToggleComboPoints()
	ToggleMiniPowerFrame()
end

function MiniPowerFrame_OnEvent()
	if not VE.isModuleEnabled(module.identifier) then
		this:UnregisterAllEvents()
		return
	end

	if event == "PLAYER_ENTERING_WORLD" then
		ToggleMiniPowerFrame()
	end

	if event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" then
		module.data.powerBar:SetMinMaxValues(0, UnitManaMax("player"))
		module.data.powerBar:SetValue(UnitMana("player"))
	end

	if event == "UNIT_DISPLAYPOWER" then
		SwitchPowerBarColor()
		ToggleMiniPowerFrame()
	end

	if event == "PLAYER_COMBO_POINTS" or event == "PLAYER_TARGET_CHANGED" then
		ToggleComboPoints()
	end

	if event == "UNIT_AURA" then
		if arg1 == "player" then
			UpdatePlayerDebuffs()
		end
	end
end
