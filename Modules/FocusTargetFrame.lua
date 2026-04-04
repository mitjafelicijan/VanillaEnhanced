local module = VE.registerModule({
	identifier = "FocusTargetFrame",
	meta = {
		label = "FocusTargetFrame",
		description = "Adds a focus target frame using SuperWoW GUID capabilities.",
	},
	plug = nil,
	superWoWRequired = true,
	config = {},
	data = {
		focusGUID = nil,
		focusName = nil,
		focusLevel = nil,
		focusClass = nil,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

-- Main Container
module.plug = CreateFrame("Frame", "VE_FocusFrame", UIParent)
module.plug:SetPoint("CENTER", UIParent, "CENTER", 250, 100)
module.plug:SetWidth(256)
module.plug:SetHeight(130)
module.plug:Hide()
module.plug:SetMovable(true)
module.plug:EnableMouse(true)
module.plug:RegisterForDrag("LeftButton")
module.plug:SetScript("OnDragStart", function() this:StartMoving() end)
module.plug:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
module.plug:SetScript("OnMouseDown", function()
	if arg1 == "LeftButton" then
		if module.data.focusGUID then
			TargetUnit(module.data.focusGUID)
		end
	elseif arg1 == "RightButton" then
		module.data.focusGUID = nil
		module.plug:Hide()
		VE.print("Focus cleared.")
	end
end)

-- Level 1: Background and Portrait
module.plug.portrait = module.plug:CreateTexture(nil, "BACKGROUND")
module.plug.portrait:SetWidth(64)
module.plug.portrait:SetHeight(64)
module.plug.portrait:SetPoint("TOPRIGHT", -42, -12)

-- Level 2: Status Bars
module.plug.healthBar = CreateFrame("StatusBar", nil, module.plug)
module.plug.healthBar:SetFrameLevel(module.plug:GetFrameLevel() + 1)
module.plug.healthBar:SetWidth(119)
module.plug.healthBar:SetHeight(30) -- Matches BigPlayerFrame style
module.plug.healthBar:SetPoint("TOPRIGHT", -106, -22)
module.plug.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

module.plug.manaBar = CreateFrame("StatusBar", nil, module.plug)
module.plug.manaBar:SetFrameLevel(module.plug:GetFrameLevel() + 1)
module.plug.manaBar:SetWidth(119)
module.plug.manaBar:SetHeight(12)
module.plug.manaBar:SetPoint("TOPRIGHT", -106, -52)
module.plug.manaBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

-- Level 3: Overlay (Texture and Text)
module.plug.overlay = CreateFrame("Frame", nil, module.plug)
module.plug.overlay:SetAllPoints(module.plug)
module.plug.overlay:SetFrameLevel(module.plug:GetFrameLevel() + 2)

module.plug.texture = module.plug.overlay:CreateTexture(nil, "ARTWORK")
module.plug.texture:SetAllPoints(module.plug.overlay)
module.plug.texture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-TargetingFrame")

module.plug.name = module.plug.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
module.plug.name:SetPoint("TOPLEFT", 34, -28)
module.plug.name:SetJustifyH("LEFT")
module.plug.name:SetWidth(100)
module.plug.name:SetHeight(10)

module.plug.level = module.plug.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
module.plug.level:SetPoint("TOPLEFT", 196, -62)

-- Target of Focus Frame (Small frame)
module.plug.targetOfFocus = CreateFrame("Button", "VE_TargetOfFocusFrame", module.plug)
module.plug.targetOfFocus:SetWidth(126)
module.plug.targetOfFocus:SetHeight(64)
module.plug.targetOfFocus:SetPoint("TOPLEFT", module.plug, "BOTTOMRIGHT", -138, 64)
module.plug.targetOfFocus:Hide()

module.plug.targetOfFocus.portrait = module.plug.targetOfFocus:CreateTexture(nil, "BACKGROUND")
module.plug.targetOfFocus.portrait:SetWidth(35)
module.plug.targetOfFocus.portrait:SetHeight(35)
module.plug.targetOfFocus.portrait:SetPoint("TOPLEFT", 5, -5)

module.plug.targetOfFocus.healthBar = CreateFrame("StatusBar", nil, module.plug.targetOfFocus)
module.plug.targetOfFocus.healthBar:SetFrameLevel(module.plug.targetOfFocus:GetFrameLevel() + 1)
module.plug.targetOfFocus.healthBar:SetWidth(46)
module.plug.targetOfFocus.healthBar:SetHeight(7)
module.plug.targetOfFocus.healthBar:SetPoint("TOPLEFT", 44, -15)
module.plug.targetOfFocus.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

module.plug.targetOfFocus.manaBar = CreateFrame("StatusBar", nil, module.plug.targetOfFocus)
module.plug.targetOfFocus.manaBar:SetFrameLevel(module.plug.targetOfFocus:GetFrameLevel() + 1)
module.plug.targetOfFocus.manaBar:SetWidth(46)
module.plug.targetOfFocus.manaBar:SetHeight(7)
module.plug.targetOfFocus.manaBar:SetPoint("TOPLEFT", 44, -23)
module.plug.targetOfFocus.manaBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

-- Target of Focus Overlay (Texture and Name)
module.plug.targetOfFocus.overlay = CreateFrame("Frame", nil, module.plug.targetOfFocus)
module.plug.targetOfFocus.overlay:SetAllPoints(module.plug.targetOfFocus)
module.plug.targetOfFocus.overlay:SetFrameLevel(module.plug.targetOfFocus:GetFrameLevel() + 2)

module.plug.targetOfFocus.texture = module.plug.targetOfFocus.overlay:CreateTexture(nil, "ARTWORK")
module.plug.targetOfFocus.texture:SetAllPoints(module.plug.targetOfFocus.overlay)
module.plug.targetOfFocus.texture:SetTexture("Interface\\TargetingFrame\\UI-TargetofTargetFrame")

module.plug.targetOfFocus.name = module.plug.targetOfFocus.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
module.plug.targetOfFocus.name:SetPoint("BOTTOMLEFT", 42, 5)
module.plug.targetOfFocus.name:SetJustifyH("LEFT")
module.plug.targetOfFocus.name:SetWidth(45)

module.plug.targetOfFocus:SetScript("OnClick", function()
	local guid = module.data.focusGUID
	if guid then
		local exists, targetOfFocusGUID = UnitExists(guid .. "target")
		if targetOfFocusGUID then
			TargetUnit(targetOfFocusGUID)
		end
	end
end)

local function UpdateFocusClassification()
	if not module.data.focusGUID then return end
	local classification = UnitClassification(module.data.focusGUID)
	if classification == "worldboss" or classification == "elite" or classification == "rareelite" then
		module.plug.texture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-TargetingFrame-Elite")
	elseif classification == "rare" then
		module.plug.texture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-TargetingFrame-Rare")
	else
		module.plug.texture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-TargetingFrame")
	end
end

local function UpdateFocusBars()
	local guid = module.data.focusGUID
	if not guid or not UnitExists(guid) then return end

	local health = UnitHealth(guid)
	local healthMax = UnitHealthMax(guid)
	module.plug.healthBar:SetMinMaxValues(0, healthMax)
	module.plug.healthBar:SetValue(health)

	local mana = UnitMana(guid)
	local manaMax = UnitManaMax(guid)
	module.plug.manaBar:SetMinMaxValues(0, manaMax)
	module.plug.manaBar:SetValue(mana)

	-- Power colors
	local powerType = UnitPowerType(guid)
	if powerType == 0 then -- Mana
		module.plug.manaBar:SetStatusBarColor(VE.config.PowerColors.Mana.r, VE.config.PowerColors.Mana.g, VE.config.PowerColors.Mana.b)
	elseif powerType == 1 then -- Rage
		module.plug.manaBar:SetStatusBarColor(VE.config.PowerColors.Rage.r, VE.config.PowerColors.Rage.g, VE.config.PowerColors.Rage.b)
	elseif powerType == 3 then -- Energy
		module.plug.manaBar:SetStatusBarColor(VE.config.PowerColors.Energy.r, VE.config.PowerColors.Energy.g, VE.config.PowerColors.Energy.b)
	end

	-- Class colors
	if VE.isModuleEnabled("BigPlayerFrame") and VE.isOptionEnabled("BigPlayerFrameClassColors") then
		local class = module.data.focusClass
		local color = VE.config.ClassColors[class]
		if color then
			module.plug.healthBar:SetStatusBarColor(color.r, color.g, color.b)
		else
			module.plug.healthBar:SetStatusBarColor(0, 1, 0)
		end
	else
		module.plug.healthBar:SetStatusBarColor(0, 1, 0)
	end
end

local function UpdateTargetOfFocus()
	local guid = module.data.focusGUID
	if not guid then
		module.plug.targetOfFocus:Hide()
		return
	end

	local exists, targetGUID = UnitExists(guid .. "target")
	if not exists then
		module.plug.targetOfFocus:Hide()
		return
	end

	module.plug.targetOfFocus.name:SetText(UnitName(guid .. "target"))
	SetPortraitTexture(module.plug.targetOfFocus.portrait, guid .. "target")
	
	local health = UnitHealth(guid .. "target")
	local healthMax = UnitHealthMax(guid .. "target")
	module.plug.targetOfFocus.healthBar:SetMinMaxValues(0, healthMax)
	module.plug.targetOfFocus.healthBar:SetValue(health)

	local mana = UnitMana(guid .. "target")
	local manaMax = UnitManaMax(guid .. "target")
	module.plug.targetOfFocus.manaBar:SetMinMaxValues(0, manaMax)
	module.plug.targetOfFocus.manaBar:SetValue(mana)

	module.plug.targetOfFocus:Show()
end

local function UpdateFocusFrame()
	local guid = module.data.focusGUID
	if not guid or not UnitExists(guid) then
		module.plug:Hide()
		return
	end

	module.plug.name:SetText(module.data.focusName or "Unknown")
	module.plug.level:SetText(module.data.focusLevel or "??")
	SetPortraitTexture(module.plug.portrait, guid)
	
	UpdateFocusClassification()
	UpdateFocusBars()
	UpdateTargetOfFocus()
	module.plug:Show()
end

module.plug:SetScript("OnUpdate", function()
	if not module.data.focusGUID then return end
	
	this.elapsed = (this.elapsed or 0) + arg1
	if this.elapsed < 0.1 then return end
	this.elapsed = 0

	if not UnitExists(module.data.focusGUID) then
		module.plug:Hide()
		module.data.focusGUID = nil
		return
	end
	
	UpdateFocusBars()
	UpdateTargetOfFocus()
end)

module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		SLASH_VE_FOCUS1 = "/focus"
		SLASH_VE_FOCUS2 = "/focustarget"
		SlashCmdList["VE_FOCUS"] = function()
			local exists, guid = UnitExists("target")
			if guid then
				module.data.focusGUID = guid
				module.data.focusName = UnitName("target")
				module.data.focusLevel = UnitLevel("target")
				local _, class = UnitClass("target")
				module.data.focusClass = class
				UpdateFocusFrame()
			else
				module.data.focusGUID = nil
				module.plug:Hide()
			end
		end

		SLASH_VE_CLEARFOCUS1 = "/clearfocus"
		SlashCmdList["VE_CLEARFOCUS"] = function()
			module.data.focusGUID = nil
			module.plug:Hide()
		end

		UpdateFocusFrame()
	end
end)
