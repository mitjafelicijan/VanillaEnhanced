local module = VE.registerModule({
	identifier = "TargetCastingBar",
	meta = {
		label = "Target Casting Bar",
		description = "Shows cast progress on the target frame. Displays duration and cast time of spells used by your current target.",
	},
	plug = nil,
	superWoWRequired = true,
	config = {
		width = 200,
		height = 20,
		offset = 10,
	},
	data = {
		ticker = nil,
		position = {
			x = 4,
			y = 0,
		},
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function StartCasting(milliseconds)
	if not module.plug.castbar then return end

	local seconds = milliseconds / 1000
	local endTime = GetTime() + seconds
	local totalTime = seconds

	module.data.ticker = CreateFrame("Frame")
	module.data.ticker:SetScript("OnUpdate", function()
		local remaining = endTime - GetTime()

		if remaining <= 0 then
			module.data.ticker:SetScript("OnUpdate", nil)
			module.plug.castbar.progress:SetValue(0)
			module.plug.castbar:Hide()
			return
		end

		local percentRemaining = (remaining / totalTime) * 100
		module.plug.castbar.progress:SetValue(percentRemaining)
	end)
end

local function UpdateCastingBarPosition()
	local aura = nil
	local numBuffs = 0
	local numDebuffs = 0

	for i = 1, MAX_TARGET_BUFFS do
		aura = getglobal(string.format("TargetFrameBuff%s", i))
		if aura and aura:IsShown() then
			numBuffs = numBuffs + 1
			aura = nil
		end
	end

	for i = 1, MAX_TARGET_DEBUFFS do
		aura = getglobal(string.format("TargetFrameDebuff%s", i))
		if aura and aura:IsShown() then
			numDebuffs = numDebuffs + 1
			aura = nil
		end
	end

	-- 5 auras per row for buffs and debuffs.
	numBuffs = math.ceil(numBuffs / 5)
	numDebuffs = math.ceil(numDebuffs / 5)

	local totOffset = 0
	if TargetofTargetFrame:IsVisible() then
		totOffset = 34
	end

	-- We have no buffs and no debuffs.
	if numBuffs == 0 and numDebuffs == 0 then
		module.data.position.y = - totOffset
	end

	-- We have buffs and no debuffs.
	if numBuffs > 0 and numDebuffs == 0 then
		module.data.position.y = module.config.offset - (numBuffs * 20) - totOffset
	end

	-- We have no buffs and do have debuffs.
	if numBuffs == 0 and numDebuffs > 0 then
		module.data.position.y = module.config.offset - (numBuffs * 20) - 44
	end

	-- We have buffs and debuffs.
	if numBuffs > 0 and numDebuffs > 0 then
		module.data.position.y = module.config.offset - (numBuffs * 20) - (numDebuffs * 24)
	end

	module.plug.castbar:SetPoint("BottomLeft", TargetFrame, "BottomLeft", module.data.position.x, module.data.position.y)
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("UNIT_CASTEVENT")
module.plug:RegisterEvent("UNIT_AURA")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" and not module.plug.castbar then
		module.plug.castbar = CreateFrame("StatusBar", "TargetCastBar", TargetFrame)
		module.plug.castbar:SetPoint("BottomLeft", TargetFrame, "BottomLeft", module.data.position.x, module.config.offset)
		module.plug.castbar:SetWidth(130)
		module.plug.castbar:SetHeight(15)
		module.plug.castbar:SetFrameLevel(0)

		module.plug.castbar.bg = module.plug.castbar:CreateTexture(nil, "BORDER")
		module.plug.castbar.bg:SetPoint("Center", module.plug.castbar, "Center", 0, 0)
		module.plug.castbar.bg:SetWidth(module.plug.castbar:GetWidth() - 5)
		module.plug.castbar.bg:SetHeight(module.plug.castbar:GetHeight() - 5)
		module.plug.castbar.bg:SetTexture(0, 0, 0, 0.5)

		module.plug.castbar.progress = CreateFrame("StatusBar", nil, module.plug.castbar, "TextStatusBar")
		module.plug.castbar.progress:SetPoint("Center", module.plug.castbar, "Center", 0, 0)
		module.plug.castbar.progress:SetWidth(module.plug.castbar:GetWidth() - 5)
		module.plug.castbar.progress:SetHeight(module.plug.castbar:GetHeight() - 5)
		module.plug.castbar.progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		module.plug.castbar.progress:SetStatusBarColor(1.0, 1.0, 0.0, 1.0)
		module.plug.castbar.progress:SetMinMaxValues(0, 100)
		module.plug.castbar.progress:SetValue(30)

		module.plug.castbar.border = CreateFrame("Frame", nil, module.plug.castbar)
		module.plug.castbar.border:SetAllPoints(module.plug.castbar)
		module.plug.castbar.border:SetFrameLevel(3)

		module.plug.castbar.border = module.plug.castbar.border:CreateTexture(nil, "BORDER")
		module.plug.castbar.border:SetAllPoints(module.plug.castbar)
		module.plug.castbar.border:SetTexture("Interface\\Tooltips\\UI-StatusBar-Border")

		module.plug.castbar.text = module.plug.castbar:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		module.plug.castbar.text:SetText("Spell name")
		module.plug.castbar.text:SetPoint("Top", 0, -14)

		module.plug.castbar.icon = module.plug.castbar.progress:CreateTexture(nil, "ARTWORK")
		module.plug.castbar.icon:SetWidth(16)
		module.plug.castbar.icon:SetHeight(16)
		module.plug.castbar.icon:SetPoint("Right", module.plug.castbar.progress, "Right", 21, 0)
		module.plug.castbar.icon:SetDrawLayer("ARTWORK")

		module.plug.castbar:Hide()
	end

	if event == "UNIT_AURA" then
		if arg1 == "target" then
			if module.plug.castbar:IsShown() then
				UpdateCastingBarPosition()
			end
		end
	end

	if event == "UNIT_CASTEVENT" then
		if not module.plug.castbar then return end
		
		local casterGUID = arg1
		local targetGUID = arg2
		local eventType = arg3   -- ("START", "CAST", "FAIL", "CHANNEL", "MAINHAND", "OFFHAND") 
		local spellID = arg4
		local castDuration = arg5

		local selectedTargetExists, selectedTagetGUID = UnitExists("target")
		if casterGUID == selectedTagetGUID then
			local castName, castRank, castTexture = SpellInfo(spellID)

			if eventType == "START" then
				if castDuration > 0 then
					StartCasting(castDuration)
					module.plug.castbar.text:SetText(castName)
					module.plug.castbar.icon:SetTexture(castTexture)
					UpdateCastingBarPosition()
					module.plug.castbar:Show()
				end
			end

			if eventType == "FAIL" then
				module.plug.castbar:Hide()
				if module.data.ticker then
					module.data.ticker:SetScript("OnUpdate", nil)
				end
			end
		end
	end
end)
