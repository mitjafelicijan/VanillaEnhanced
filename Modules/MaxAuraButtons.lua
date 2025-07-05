local module = VE.registerModule({
	identifier = "MaxAuraButtons",
	meta = {
		label = "Max Aura Buttons",
		description = "Increases the maximum visible auras, supporting up to 32 buffs and 16 debuffs at once.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		buffCount = 32,
		debuffCount = 16,
		perRow = 16,
		auraSize = 28,
		auraSpacing = 3,
	},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function FormatTime(seconds)
	if seconds <= 0 then
		return ""
	elseif seconds < 60 then
		return string.format("%ds", seconds)
	elseif seconds < 3600 then
		return string.format("%dm", seconds/60)
	else
		return string.format("%dhr", seconds/3600)
	end
end

local function CreatePlayerBuffFrames()
	module.plug.buffs = CreateFrame("Frame", "PlayerBuffFrame", UIParent)
	module.plug.buffs:SetWidth(10)
	module.plug.buffs:SetHeight(10)
	module.plug.buffs:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -Minimap:GetWidth() - 50, -10)

	for i = 0, (module.config.buffCount - 1) do
		local col = math.mod(i, module.config.perRow)
		local row = math.floor(i / module.config.perRow)
		local xOffset = -col * (module.config.auraSize + module.config.auraSpacing)
		local yOffset = -row * (module.config.auraSize + module.config.auraSpacing + 10)

		local button = CreateFrame("Button", "PlayerBuff" .. tostring(i), module.plug.buffs)
		button:RegisterForClicks("RightButtonUp")
		button:SetPoint("TOPRIGHT", module.plug.buffs, "TOPRIGHT", xOffset, yOffset)
		button:SetWidth(module.config.auraSize)
		button:SetHeight(module.config.auraSize)

		button.id = i
		button.lastUpdate = 0

		button.texture = button:CreateTexture("PlayerBuff" .. tostring(i) .. "Texture", "ARTWORK")
		button.texture:SetTexture(0, 0, 1, 1.0)
		button.texture:SetAllPoints()

		button.timeLeft = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		button.timeLeft:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
		button.timeLeft:SetPoint("CENTER", button, "BOTTOM", 0, -6)
		button.timeLeft:SetDrawLayer("OVERLAY", 2)
		button.timeLeft:Hide()

		button.stack = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
		button.stack:SetTextColor(1, 1, 1)
		button.stack:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
		button.stack:SetDrawLayer("OVERLAY", 2)
		button.stack:Hide()

		button:SetScript("OnEnter", function()
			GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
			GameTooltip:SetPlayerBuff(this.id)
			GameTooltip:Show()
		end)

		button:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		button:SetScript("OnClick", function()
			CancelPlayerBuff(this.id)
		end)

		button:SetScript("OnUpdate", function()
			this.lastUpdate = this.lastUpdate + arg1
			if this.lastUpdate >= 1 then
				local timeLeft = GetPlayerBuffTimeLeft(this.id)
				if timeLeft > 0 then
					this.timeLeft:SetText(SecondsToTimeAbbrev(timeLeft))
					this.timeLeft:Show()
				else
					this.timeLeft:Hide()
				end
				this.lastUpdate = 0
			end
		end)

		button:Hide()
	end
end

local function UpdatePlayerBuffs()
	for i = 0, (module.config.buffCount - 1) do
		local id, cancelled = GetPlayerBuff(i, "HELPFUL|PASSIVE");
		local button = getglobal("PlayerBuff" .. tostring(i))

		if(id > -1) then
			local texture = GetPlayerBuffTexture(id)
			local stackCount = GetPlayerBuffApplications(id) or 0
			button.texture:SetTexture(texture)
			button:Show()
			button.id = id

			if stackCount > 1 then
				button.stack:SetText(stackCount)
				button.stack:Show()
			else
				button.stack:SetText("")
				button.stack:Hide()
			end


		else
			button:Hide()
			button.stack:Hide()
		end
	end
end

local function CreatePlayerDebuffFrames()
	module.plug.debuffs = CreateFrame("Frame", "PlayerDebuffFrame", UIParent)
	module.plug.debuffs:SetWidth(10)
	module.plug.debuffs:SetHeight(10)
	module.plug.debuffs:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -Minimap:GetWidth() - 50, -95)

	for i = 0, ((module.config.buffCount / 2) - 1) do
		local col = math.mod(i, module.config.perRow)
		local row = math.floor(i / module.config.perRow)
		local xOffset = -col * (module.config.auraSize + module.config.auraSpacing)
		local yOffset = -row * (module.config.auraSize + module.config.auraSpacing)

		local button = CreateFrame("Button", "PlayerDebuff" .. tostring(i), module.plug.debuffs)
		button:RegisterForClicks("RightButtonUp")
		button:SetPoint("TOPRIGHT", module.plug.debuffs, "TOPRIGHT", xOffset, yOffset)
		button:SetWidth(module.config.auraSize)
		button:SetHeight(module.config.auraSize)

		button.id = i
		button.lastUpdate = 0

		button.texture = button:CreateTexture("PlayerDebuff" .. tostring(i) .. "Texture", "ARTWORK")
		button.texture:SetTexture(0, 0, 1, 1.0)
		button.texture:SetAllPoints()

		button.timeLeft = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		button.timeLeft:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
		button.timeLeft:SetPoint("CENTER", button, "BOTTOM", 0, -6)
		button.timeLeft:SetDrawLayer("OVERLAY", 2)
		button.timeLeft:Hide()

		button.stack = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
		button.stack:SetTextColor(1, 1, 1)
		button.stack:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
		button.stack:SetDrawLayer("OVERLAY", 2)
		button.stack:SetText("")
		button.stack:Hide()

		button:SetScript("OnEnter", function()
			GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
			GameTooltip:SetPlayerBuff(this.id)
			GameTooltip:Show()
		end)

		button:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		button:SetScript("OnClick", function()
			CancelPlayerBuff(this.id)
		end)

		button:SetScript("OnUpdate", function()
			this.lastUpdate = this.lastUpdate + arg1
			if this.lastUpdate >= 1 then
				local timeLeft = GetPlayerBuffTimeLeft(this.id)
				if timeLeft > 0 then
					this.timeLeft:SetText(SecondsToTimeAbbrev(timeLeft))
					this.timeLeft:Show()
				else
					this.timeLeft:Hide()
				end
				this.lastUpdate = 0
			end
		end)

		button:Hide()
	end
end

local function UpdatePlayerDebuffs()
	for i = 0, ((module.config.buffCount/2) - 1) do
		local id, cancelled = GetPlayerBuff(i, "HARMFUL");
		local button = getglobal("PlayerDebuff" .. tostring(i))

		if(id > -1) then
			local timeLeft = GetPlayerBuffTimeLeft(id)
			local texture = GetPlayerBuffTexture(id)
			local stackCount = GetPlayerBuffApplications(id) or 0

			button.texture:SetTexture(texture)
			button.id = id
			button:Show()

			if stackCount > 1 then
				button.stack:SetText(stackCount)
				button.stack:Show()
			else
				button.stack:SetText("")
				button.stack:Hide()
			end
		else
			button:Hide()
			button.stack:Hide()
		end
	end
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("PLAYER_AURAS_CHANGED")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	BuffFrame:Hide()

	if event == "PLAYER_ENTERING_WORLD" then
		CreatePlayerBuffFrames()
		CreatePlayerDebuffFrames()

		local BuffFrame_Enchant_OnUpdate_Original = BuffFrame_Enchant_OnUpdate
		function BuffFrame_Enchant_OnUpdate(elapsed)
			BuffFrame_Enchant_OnUpdate_Original(elapsed)
			TemporaryEnchantFrame:ClearAllPoints()
			TemporaryEnchantFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -Minimap:GetWidth() - 50, -140)
			TempEnchant1:SetScale(module.config.auraSize / 30)
			TempEnchant2:SetScale(module.config.auraSize / 30)
		end

		this:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end

	if event == "PLAYER_AURAS_CHANGED" then
		UpdatePlayerBuffs()
		UpdatePlayerDebuffs()
	end
end)
