local module = VE.registerModule({
	identifier = "FocusTargetFrame",
	meta = {
		label = "Focus Target Frame",
		description = "Adds a focus target frame that tracks your current focus's health, mana, and target.",
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

local function UpdateFocusClassification()
	if not module.data.focusGUID then return end
	local classification = UnitClassification(module.data.focusGUID)
	if classification == "worldboss" or classification == "elite" or classification == "rareelite" then
		module.plug.frame.texture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-TargetingFrame-Elite")
	elseif classification == "rare" then
		module.plug.frame.texture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-TargetingFrame-Rare")
	else
		module.plug.frame.texture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-TargetingFrame")
	end
end

local function UpdateFocusBars()
	local guid = module.data.focusGUID
	if not guid or not UnitExists(guid) then return end

	local health = UnitHealth(guid)
	local healthMax = UnitHealthMax(guid)
	module.plug.frame.healthBar:SetMinMaxValues(0, healthMax)
	module.plug.frame.healthBar:SetValue(health)

	local power = UnitMana(guid)
	local powerMax = UnitManaMax(guid)
	module.plug.frame.powerBar:SetMinMaxValues(0, powerMax)
	module.plug.frame.powerBar:SetValue(power)

	-- Power colors
	local powerType = UnitPowerType(guid)
	local powerName = "unknown"
	if powerType == 0 then powerName = "Mana"
	elseif powerType == 1 then powerName = "Rage"
	elseif powerType == 2 then powerName = "Focus"
	elseif powerType == 3 then powerName = "Energy" end

	local powerColor = VE.config.PowerColors[powerName]
	if powerColor then
		module.plug.frame.powerBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)
	end

	-- Class colors
	if VE.isModuleEnabled("BigPlayerFrame") and VE.isOptionEnabled("BigPlayerFrameClassColors") then
		local class = module.data.focusClass
		local color = VE.config.ClassColors[class]
		if color then
			module.plug.frame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
		else
			module.plug.frame.healthBar:SetStatusBarColor(0, 1, 0)
		end
	else
		module.plug.frame.healthBar:SetStatusBarColor(0, 1, 0)
	end
end

local function UpdateTargetOfFocus()
	local guid = module.data.focusGUID
	if not guid then
		module.plug.frame.targetOfFocus:Hide()
		return
	end

	local exists, targetGUID = UnitExists(guid .. "target")
	if not exists then
		module.plug.frame.targetOfFocus:Hide()
		return
	end

	module.plug.frame.targetOfFocus.name:SetText(UnitName(guid .. "target"))
	SetPortraitTexture(module.plug.frame.targetOfFocus.portrait, guid .. "target")

	local health = UnitHealth(guid .. "target")
	local healthMax = UnitHealthMax(guid .. "target")
	module.plug.frame.targetOfFocus.healthBar:SetMinMaxValues(0, healthMax)
	module.plug.frame.targetOfFocus.healthBar:SetValue(health)

	local power = UnitMana(guid .. "target")
	local powerMax = UnitManaMax(guid .. "target")
	module.plug.frame.targetOfFocus.powerBar:SetMinMaxValues(0, powerMax)
	module.plug.frame.targetOfFocus.powerBar:SetValue(power)

	-- Power colors
	local powerType = UnitPowerType(guid .. "target")
	local powerName = "unknown"
	if powerType == 0 then powerName = "Mana"
	elseif powerType == 1 then powerName = "Rage"
	elseif powerType == 2 then powerName = "Focus"
	elseif powerType == 3 then powerName = "Energy" end

	local powerColor = VE.config.PowerColors[powerName]
	if powerColor then
		module.plug.frame.targetOfFocus.powerBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)
	end

	module.plug.frame.targetOfFocus:Show()
end
	
local function UpdateFocusDebuffs()
	local guid = module.data.focusGUID
	if not guid or not UnitExists(guid) then
		if module.plug.frame.debuffs then
			for i = 1, 16 do
				module.plug.frame.debuffs[i]:Hide()
			end
		end
		return
	end

	for i = 1, 16 do
		local button = module.plug.frame.debuffs[i]
		local texture, applications, debuffType = UnitDebuff(guid, i)

		if texture then
			button.texture:SetTexture(texture)
			if applications and applications > 1 then
				button.count:SetText(applications)
				button.count:Show()
			else
				button.count:Hide()
			end

			local color = DebuffTypeColor[debuffType or "none"] or DebuffTypeColor["none"]
			button.border:SetVertexColor(color.r, color.g, color.b)
			button:Show()
		else
			button:Hide()
		end
	end
end

local function UpdateFocusFrame()
	local guid = module.data.focusGUID
	if not guid or not UnitExists(guid) then
		module.plug.frame:Hide()
		return
	end

	module.plug.frame.name:SetText(module.data.focusName or "Unknown")
	module.plug.frame.level:SetText(module.data.focusLevel or "??")
	SetPortraitTexture(module.plug.frame.portrait, guid)

	UpdateFocusClassification()
	UpdateFocusBars()
	UpdateTargetOfFocus()
	UpdateFocusDebuffs()
	module.plug.frame:Show()
end

local function InitializeFocusFrame()
	-- Main Container
	module.plug.frame = CreateFrame("Frame", "VE_FocusFrame", UIParent)
	local pos = VanillaEnhancedData[module.identifier] and VanillaEnhancedData[module.identifier].pos
	if pos then
		module.plug.frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
	else
		module.plug.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	module.plug.frame:SetWidth(256)
	module.plug.frame:SetHeight(130)
	module.plug.frame:Hide()
	module.plug.frame:SetMovable(true)
	module.plug.frame:EnableMouse(true)
	module.plug.frame:RegisterForDrag("LeftButton")
	module.plug.frame:SetScript("OnDragStart", function() this:StartMoving() end)
	module.plug.frame:SetScript("OnDragStop", function()
		this:StopMovingOrSizing()
		local point, _, relativePoint, xOfs, yOfs = this:GetPoint()
		if not VanillaEnhancedData[module.identifier] then
			VanillaEnhancedData[module.identifier] = {}
		end
		VanillaEnhancedData[module.identifier].pos = {
			point = point,
			relativePoint = relativePoint,
			xOfs = xOfs,
			yOfs = yOfs,
		}
	end)
	module.plug.frame:SetScript("OnMouseDown", function()
		if arg1 == "LeftButton" then
			if module.data.focusGUID then
				TargetUnit(module.data.focusGUID)
			end
		elseif arg1 == "RightButton" then
			module.data.focusGUID = nil
			module.plug.frame:Hide()
			VE.print("Focus cleared.")
		end
	end)

	-- Level 1: Background and Portrait
	module.plug.frame.portrait = module.plug.frame:CreateTexture(nil, "BACKGROUND")
	module.plug.frame.portrait:SetWidth(64)
	module.plug.frame.portrait:SetHeight(64)
	module.plug.frame.portrait:SetPoint("TOPRIGHT", -42, -12)

	-- Level 2: Status Bars
	module.plug.frame.healthBar = CreateFrame("StatusBar", nil, module.plug.frame)
	module.plug.frame.healthBar:SetFrameLevel(module.plug.frame:GetFrameLevel() + 1)
	module.plug.frame.healthBar:SetWidth(119)
	module.plug.frame.healthBar:SetHeight(30) -- Matches BigPlayerFrame style
	module.plug.frame.healthBar:SetPoint("TOPRIGHT", -106, -22)
	module.plug.frame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	VE.dframe(module.plug.frame.healthBar, 0, 0, 0, 0.5)

	module.plug.frame.powerBar = CreateFrame("StatusBar", nil, module.plug.frame)
	module.plug.frame.powerBar:SetFrameLevel(module.plug.frame:GetFrameLevel() + 1)
	module.plug.frame.powerBar:SetWidth(119)
	module.plug.frame.powerBar:SetHeight(12)
	module.plug.frame.powerBar:SetPoint("TOPRIGHT", -106, -52)
	module.plug.frame.powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	VE.dframe(module.plug.frame.powerBar, 0, 0, 0, 0.5)

	-- Level 3: Overlay (Texture and Text)
	module.plug.frame.overlay = CreateFrame("Frame", nil, module.plug.frame)
	module.plug.frame.overlay:SetAllPoints(module.plug.frame)
	module.plug.frame.overlay:SetFrameLevel(module.plug.frame:GetFrameLevel() + 2)

	module.plug.frame.texture = module.plug.frame.overlay:CreateTexture(nil, "ARTWORK")
	module.plug.frame.texture:SetAllPoints(module.plug.frame.overlay)
	module.plug.frame.texture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-TargetingFrame")

	module.plug.frame.name = module.plug.frame.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	module.plug.frame.name:SetPoint("TOPLEFT", 34, -28)
	module.plug.frame.name:SetJustifyH("CENTER")
	module.plug.frame.name:SetWidth(100)
	module.plug.frame.name:SetHeight(10)

	module.plug.frame.level = module.plug.frame.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	module.plug.frame.level:SetPoint("TOPLEFT", 196, -62)

	-- Debuffs (4x4 Grid)
	module.plug.frame.debuffs = {}
	local auraSize = 21
	local auraSpacing = 2
	local perRow = 4
	local startX = 30
	local startY = -70

	for i = 1, 16 do
		local row = math.floor((i - 1) / perRow)
		local col = math.mod((i - 1), perRow)

		local button = CreateFrame("Button", "VE_FocusFrame_Debuff" .. i, module.plug.frame)
		button:SetWidth(auraSize)
		button:SetHeight(auraSize)
		button:SetPoint("TOPLEFT", module.plug.frame, "TOPLEFT", startX + (col * (auraSize + auraSpacing)), startY - (row * (auraSize + auraSpacing)))

		button.texture = button:CreateTexture(nil, "ARTWORK")
		button.texture:SetAllPoints()
		button.texture:SetTexture("Interface\\Icons\\Temp")

		button.count = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
		button.count:SetTextColor(1, 1, 1)
		button.count:Hide()

		button.border = button:CreateTexture(nil, "OVERLAY")
		button.border:SetWidth(auraSize + 2)
		button.border:SetHeight(auraSize + 2)
		button.border:SetPoint("CENTER", button, "CENTER", 0, 0)
		button.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
		button.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)

		button.id = i
		button:SetScript("OnEnter", function()
			if module.data.focusGUID then
				GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
				GameTooltip:SetUnitDebuff(module.data.focusGUID, this.id)
			end
		end)
		button:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		module.plug.frame.debuffs[i] = button
	end

	-- Target of Focus Frame (Small frame)
	module.plug.frame.targetOfFocus = CreateFrame("Button", "VE_TargetOfFocusFrame", module.plug.frame)
	module.plug.frame.targetOfFocus:SetWidth(126)
	module.plug.frame.targetOfFocus:SetHeight(64)
	module.plug.frame.targetOfFocus:SetPoint("TOPLEFT", module.plug.frame, "BOTTOMRIGHT", -130, 64)
	module.plug.frame.targetOfFocus:Hide()

	module.plug.frame.targetOfFocus.portrait = module.plug.frame.targetOfFocus:CreateTexture(nil, "BACKGROUND")
	module.plug.frame.targetOfFocus.portrait:SetWidth(35)
	module.plug.frame.targetOfFocus.portrait:SetHeight(35)
	module.plug.frame.targetOfFocus.portrait:SetPoint("TOPLEFT", 5, -5)

	module.plug.frame.targetOfFocus.healthBar = CreateFrame("StatusBar", nil, module.plug.frame.targetOfFocus)
	module.plug.frame.targetOfFocus.healthBar:SetFrameLevel(module.plug.frame.targetOfFocus:GetFrameLevel() + 1)
	module.plug.frame.targetOfFocus.healthBar:SetWidth(46)
	module.plug.frame.targetOfFocus.healthBar:SetHeight(7)
	module.plug.frame.targetOfFocus.healthBar:SetPoint("TOPLEFT", 44, -15)
	module.plug.frame.targetOfFocus.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	module.plug.frame.targetOfFocus.healthBar:SetStatusBarColor(0, 1, 0)
	VE.dframe(module.plug.frame.targetOfFocus.healthBar, 0, 0, 0, 0.5)

	module.plug.frame.targetOfFocus.powerBar = CreateFrame("StatusBar", nil, module.plug.frame.targetOfFocus)
	module.plug.frame.targetOfFocus.powerBar:SetFrameLevel(module.plug.frame.targetOfFocus:GetFrameLevel() + 1)
	module.plug.frame.targetOfFocus.powerBar:SetWidth(46)
	module.plug.frame.targetOfFocus.powerBar:SetHeight(7)
	module.plug.frame.targetOfFocus.powerBar:SetPoint("TOPLEFT", 44, -23)
	module.plug.frame.targetOfFocus.powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	VE.dframe(module.plug.frame.targetOfFocus.powerBar, 0, 0, 0, 0.5)

	-- Target of Focus Overlay (Texture and Name)
	module.plug.frame.targetOfFocus.overlay = CreateFrame("Frame", nil, module.plug.frame.targetOfFocus)
	module.plug.frame.targetOfFocus.overlay:SetAllPoints(module.plug.frame.targetOfFocus)
	module.plug.frame.targetOfFocus.overlay:SetFrameLevel(module.plug.frame.targetOfFocus:GetFrameLevel() + 2)

	module.plug.frame.targetOfFocus.texture = module.plug.frame.targetOfFocus.overlay:CreateTexture(nil, "ARTWORK")
	module.plug.frame.targetOfFocus.texture:SetAllPoints(module.plug.frame.targetOfFocus.overlay)
	module.plug.frame.targetOfFocus.texture:SetTexture("Interface\\TargetingFrame\\UI-TargetofTargetFrame")

	module.plug.frame.targetOfFocus.name = module.plug.frame.targetOfFocus.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	module.plug.frame.targetOfFocus.name:SetPoint("BOTTOMLEFT", 42, 18)
	module.plug.frame.targetOfFocus.name:SetJustifyH("LEFT")
	module.plug.frame.targetOfFocus.name:SetWidth(100)

	module.plug.frame.targetOfFocus:SetScript("OnClick", function()
		local guid = module.data.focusGUID
		if guid then
			local exists, targetOfFocusGUID = UnitExists(guid .. "target")
			if targetOfFocusGUID then
				TargetUnit(targetOfFocusGUID)
			end
		end
	end)
	module.plug.frame:SetScript("OnUpdate", function()
		if not module.data.focusGUID then return end

		this.elapsed = (this.elapsed or 0) + arg1
		if this.elapsed < 0.1 then return end
		this.elapsed = 0

		if not UnitExists(module.data.focusGUID) then
			module.plug.frame:Hide()
			module.data.focusGUID = nil
			return
		end

		UpdateFocusBars()
		UpdateTargetOfFocus()
		UpdateFocusDebuffs()
	end)

end

module.plug = CreateFrame("Frame", module.identifier, UIParent)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		SLASH_VE_FOCUS1 = "/focus"
		SLASH_VE_FOCUS2 = "/focustarget"

		_G["VE_SetFocus"] = function()
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
		SlashCmdList["VE_FOCUS"] = _G["VE_SetFocus"]

		SLASH_VE_CLEARFOCUS1 = "/clearfocus"

		_G["VE_ClearFocus"] = function()
			module.data.focusGUID = nil
			module.plug:Hide()
		end
		SlashCmdList["VE_CLEARFOCUS"] = _G["VE_ClearFocus"]

		InitializeFocusFrame()
		UpdateFocusFrame()
	end
end)
