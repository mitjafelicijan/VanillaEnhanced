local module = VE.registerModule({
	identifier = "MiniPlayerFrame",
	meta = {
		label = "Mini Player Frame",
		description = "Adds a combat-only player frame that displays combo points and target health.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		backgroundAlpha = 0.8,
	},
	data = {
		-- frames
		miniPlayerFrame = nil,
		healthBar = nil,
		powerBar = nil,
		druidManaBar = nil,
		comboPoints = nil,
		targetDebuffs = nil,
		targetHealthBar = nil,

		-- general vars
		playerClass = nil,
		playerPower = nil,
		comboPointCount = nil,
		druidMaxMana = nil,
		druidCurrentMana = nil,

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

local function ToggleDruidManaBar()
	module.data.playerPower = UnitPowerType("player")

	if module.data.playerClass ~= "Druid" then
		module.data.druidManaBar:GetParent():Hide()
		return
	end

	if module.data.playerPower == 0 or module.data.playerPower == 2 then
		module.data.targetDebuffs:SetPoint("Center", module.data.targetDebuffs:GetParent(), "Center", 0, -30)
		module.data.druidManaBar:GetParent():Hide()
	else
		module.data.targetDebuffs:SetPoint("Center", module.data.targetDebuffs:GetParent(), "Center", 0, -40)
		module.data.druidManaBar:GetParent():Show()
	end
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
	if (module.data.playerClass == "Druid" or module.data.playerClass == "Rogue") and UnitAffectingCombat("player") then
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

local function UpdateTargetDebuffs()
	if not UnitExists("target") then
		module.data.targetDebuffs:Hide()
		return
	end

	local texture = nil
	for i = 1, 12 do
		module.data.aura = getglobal(string.format("%sTargetDebuffs%sTexture", this:GetName(), i))
		texture, _, _ = UnitDebuff("target", i)
		if texture then
			module.data.aura:SetTexture(texture)
			module.data.aura:Show()
		else
			module.data.aura:Hide()
		end
	end

	module.data.targetDebuffs:Show()
end

local function UpdateTargetHealth()
	if not UnitExists("target") or UnitIsDeadOrGhost("target") then
		module.data.targetHealthBar:GetParent():Hide()
		return
	end

	module.data.targetHealthBar:SetMinMaxValues(0, UnitHealthMax("target"))
	module.data.targetHealthBar:SetValue(UnitHealth("target"))
	module.data.targetHealthBar:GetParent():Show()
end

local function UpdatePlayerBars()
	module.data.healthBar:SetMinMaxValues(0, UnitHealthMax("player"))
	module.data.healthBar:SetValue(UnitHealth("player"))
	module.data.powerBar:SetMinMaxValues(0, UnitManaMax("player"))
	module.data.powerBar:SetValue(UnitMana("player"))
end

function MiniPlayerFrame_OnLoad()
	this:RegisterEvent("UNIT_HEALTH")
	this:RegisterEvent("UNIT_MANA")
	this:RegisterEvent("UNIT_RAGE")
	this:RegisterEvent("UNIT_ENERGY")
	this:RegisterEvent("UNIT_DISPLAYPOWER")
	this:RegisterEvent("UNIT_AURA")
	this:RegisterEvent("PLAYER_COMBO_POINTS")
	this:RegisterEvent("PLAYER_TARGET_CHANGED")
	this:RegisterEvent("PLAYER_ENTER_COMBAT")
	this:RegisterEvent("PLAYER_LEAVE_COMBAT")

	module.data.playerClass = UnitClass("player")
	module.data.healthBar = getglobal(this:GetName() .. "HealthStatusBar")
	module.data.powerBar = getglobal(this:GetName() .. "PowerStatusBar")
	module.data.druidManaBar = getglobal(this:GetName() .. "DruidStatusBar")
	module.data.comboPoints = getglobal(this:GetName() .. "ComboPoints")
	module.data.targetDebuffs = getglobal(this:GetName() .. "TargetDebuffs")
	module.data.targetHealthBar = getglobal(this:GetName() .. "TargetHealthStatusBar")
	module.data.miniPlayerFrame = getglobal(this:GetName())

	-- Set background.
	VE.dframe(module.data.healthBar, 0, 0, 0, module.config.backgroundAlpha)
	VE.dframe(module.data.powerBar, 0, 0, 0, module.config.backgroundAlpha)
	VE.dframe(module.data.druidManaBar, 0, 0, 0, module.config.backgroundAlpha)
	VE.dframe(module.data.targetHealthBar, 0, 0, 0, module.config.backgroundAlpha)

	UpdatePlayerBars()
	SwitchPowerBarColor()
	ToggleDruidManaBar()
	ToggleComboPoints()
	UpdateTargetDebuffs()
	UpdateTargetHealth()

	if not UnitAffectingCombat("player") then
		module.data.miniPlayerFrame:Hide()
	end
end

function MiniPlayerFrame_OnEvent()
	if not VE.isModuleEnabled(module.identifier) then
		this:UnregisterAllEvents()
		return
	end

	if UnitAffectingCombat("player") then
		if not module.data.miniPlayerFrame:IsVisible() then module.data.miniPlayerFrame:Show() end
		UpdatePlayerBars()
		ToggleDruidManaBar()
		ToggleComboPoints()
	else
		if module.data.miniPlayerFrame:IsVisible() then module.data.miniPlayerFrame:Hide() end
		return
	end

	if event == "UNIT_HEALTH" then
		if arg1 == "player" then
			module.data.healthBar:SetMinMaxValues(0, UnitHealthMax("player"))
			module.data.healthBar:SetValue(UnitHealth("player"))
		end

		if arg1 == "target" then
			UpdateTargetHealth()
		end
	end

	if event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" then
		module.data.powerBar:SetMinMaxValues(0, UnitManaMax("player"))
		module.data.powerBar:SetValue(UnitMana("player"))

		if module.data.playerClass == "Druid" then
			_, module.data.druidMaxMana = UnitManaMax("player")
			_, module.data.druidCurrentMana = UnitMana("player")
			module.data.druidManaBar:SetMinMaxValues(0, module.data.druidMaxMana)
			module.data.druidManaBar:SetValue(module.data.druidCurrentMana)
		end
	end

	if event == "PLAYER_COMBO_POINTS" or event == "PLAYER_TARGET_CHANGED" then
		ToggleComboPoints()
		UpdateTargetDebuffs()
		UpdateTargetHealth()
	end

	if event == "UNIT_DISPLAYPOWER" then
		SwitchPowerBarColor()
		ToggleDruidManaBar()
		ToggleComboPoints()
	end

	if event == "UNIT_AURA" then
		if arg1 == "target" then
			UpdateTargetHealth()
			UpdateTargetDebuffs()
		end
	end
end
