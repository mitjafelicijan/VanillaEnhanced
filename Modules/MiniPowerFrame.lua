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
		module.data.targetDebuffs:Hide()
		return
	end

	local texture = nil
	for i = 1, 4 do
		module.data.aura = getglobal(string.format("%sPlayerDebuffs%sTexture", this:GetName(), i))
		texture, _, _ = UnitDebuff("player", i)
		if texture then
			module.data.aura:SetTexture(texture)
			module.data.aura:Show()
		else
			module.data.aura:Hide()
		end
	end

	module.data.targetDebuffs:Show()
end

local function UpdatePlayerBars()
	module.data.powerBar:SetMinMaxValues(0, UnitManaMax("player"))
	module.data.powerBar:SetValue(UnitMana("player"))
end

function MiniPowerFrame_OnLoad()
	this:RegisterEvent("UNIT_MANA")
	this:RegisterEvent("UNIT_RAGE")
	this:RegisterEvent("UNIT_ENERGY")
	this:RegisterEvent("UNIT_DISPLAYPOWER")
	this:RegisterEvent("UNIT_AURA")

	module.data.playerClass = UnitClass("player")
	module.data.powerBar = getglobal(this:GetName() .. "PowerStatusBar")
	module.data.targetDebuffs = getglobal(this:GetName() .. "PlayerDebuffs")
	module.data.miniPowerFrame = getglobal(this:GetName())

	-- Set background.
	VE.dframe(module.data.powerBar, 0, 0, 0, module.config.backgroundAlpha)
	
	SwitchPowerBarColor()
	UpdatePlayerDebuffs()
end

function MiniPowerFrame_OnEvent()
	if not VE.isModuleEnabled(module.identifier) then
		this:UnregisterAllEvents()
		return
	end

	if event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" then
		module.data.powerBar:SetMinMaxValues(0, UnitManaMax("player"))
		module.data.powerBar:SetValue(UnitMana("player"))
	end

	if event == "UNIT_DISPLAYPOWER" then
		SwitchPowerBarColor()
	end

	if event == "UNIT_AURA" then
		if arg1 == "player" then
			UpdatePlayerDebuffs()
		end
	end
end
