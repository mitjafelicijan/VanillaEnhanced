local module = VE.registerModule({
	identifier = "AuraTracker",
	meta = {
		label = "Aura Tracker",
		description = "Tracks and displays player auras in the center of the screen.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		offset= -140,
		maxAuras = 8,
		columns = 4,
		rows = 2,
		auraPadding = 4,
		auraSize = 32,
	},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function GetAuraSlotData(index)
	if not VanillaEnhancedData["AuraTrackerSlots"] then
		VanillaEnhancedData["AuraTrackerSlots"] = {}
	end

	if not VanillaEnhancedData["AuraTrackerSlots"][index] then
		VanillaEnhancedData["AuraTrackerSlots"][index] = {
			name = "",
			showWhen = "present", -- present, missing
			target = "player", -- player, target
			type = "buff", -- buff, debuff
			showStacks = true,
			showDuration = true,
		}
	end

	return VanillaEnhancedData["AuraTrackerSlots"][index]
end

local function GetAuraStatus(slotData)
	if not slotData.name or slotData.name == "" then return nil end

	local target = slotData.target or "player"

	-- Get target texture for the spell name
	local targetTexture = nil
	local spellName = VE.trim(slotData.name)
	local spells = VE.GetSpellInfoByName(spellName)

	if next(spells) then
		targetTexture = spells[next(spells)].icon
	end

	if not targetTexture then return nil end

	-- Search for the aura
	for i = 1, 32 do
		local texture, count, id, duration, timeLeft
		if slotData.type == "buff" then
			texture, count, id, duration, timeLeft = UnitBuff(target, i)
		else
			texture, count, id, duration, timeLeft = UnitDebuff(target, i)
		end

		if not texture then break end

		if texture == targetTexture then
			return {
				found = true,
				texture = texture,
				count = count,
				duration = duration,
				timeLeft = timeLeft,
				showWhen = slotData.showWhen,
				showStacks = slotData.showStacks,
				showDuration = slotData.showDuration,
			}
		end
	end

	-- Not found
	return {
		found = false,
		texture = targetTexture,
		showWhen = slotData.showWhen,
		showStacks = slotData.showStacks,
		showDuration = slotData.showDuration,
	}
end

local function GenerateEmptyFrames()
	if module.plug.frame then return end

	local totalWidth = (module.config.columns * module.config.auraSize) + ((module.config.columns - 1) * module.config.auraPadding)
	local totalHeight = (module.config.rows * module.config.auraSize) + ((module.config.rows - 1) * module.config.auraPadding)

	module.plug.frame = CreateFrame("Frame", "AuraTracker", UIParent)
	module.plug.frame:SetWidth(totalWidth)
	module.plug.frame:SetHeight(totalHeight)
	module.plug.frame:SetPoint("Center", UIParent, "Center", 0, module.config.offset)
	module.plug.frame:SetFrameStrata("BACKGROUND")

	if VE.config.Debug then
		VE.dframe(module.plug.frame, 1, 0, 0, 1)
	end

	module.plug.frame.auras = {}
	for i = 1, module.config.maxAuras do
		local row = math.floor((i - 1) / module.config.columns)
		local col = mod(i - 1, module.config.columns)

		local aura = CreateFrame("Frame", "AuraTrackerAura" .. i, module.plug.frame)
		aura:SetWidth(module.config.auraSize)
		aura:SetHeight(module.config.auraSize)

		local xOffset = (col * (module.config.auraSize + module.config.auraPadding))
		local yOffset = -(row * (module.config.auraSize + module.config.auraPadding))

		aura:SetPoint("TopLeft", module.plug.frame, "TopLeft", xOffset, yOffset)

		aura.texture = aura:CreateTexture(nil, "BACKGROUND")
		aura.texture:SetAllPoints(aura)

		aura.stacks = aura:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		aura.stacks:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", -2, 2)
		aura.stacks:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
		aura.stacks:SetTextColor(1, 1, 1)

		aura.duration = aura:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		aura.duration:SetPoint("CENTER", aura, "CENTER", 0, 0)
		aura.duration:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
		aura.duration:SetTextColor(1, 1, 0)

		table.insert(module.plug.frame.auras, aura)
	end

	-- module.plug.frame:Hide()
end

local function UpdateAuraFrames()
	if not module.plug.frame then
		GenerateEmptyFrames()
	end
	if not module.plug.frame then return end

	local anyShown = false

	for i = 1, module.config.maxAuras do
		local slotData = GetAuraSlotData(i)
		local status = GetAuraStatus(slotData)
		local frame = module.plug.frame.auras[i]

		local shouldShow = false
		if status then
			if status.showWhen == "present" and status.found then
				shouldShow = true
			elseif status.showWhen == "missing" and not status.found then
				shouldShow = true
			end
		end

		if shouldShow and status.texture then
			frame.texture:SetTexture(status.texture)

			if status.showStacks and status.count and status.count > 1 then
				frame.stacks:SetText(status.count)
				frame.stacks:Show()
			else
				frame.stacks:Hide()
			end

			if status.showDuration and status.timeLeft and status.timeLeft > 0 then
				local val = math.floor(status.timeLeft)
				if val > 60 then
					frame.duration:SetText(math.floor(val/60) .. "m")
				else
					frame.duration:SetText(val)
				end
				frame.duration:Show()
			else
				frame.duration:Hide()
			end

			frame:Show()
			anyShown = true
		else
			frame:Hide()
		end
	end

	if anyShown then
		module.plug.frame:Show()
	else
		module.plug.frame:Hide()
	end
end

-- Migration from old format
local function MigrateData()
	if VanillaEnhancedData["AuraTrackerUserAuars"] and not VanillaEnhancedData["AuraTrackerSlots"] then
		local auras = VE.split(VanillaEnhancedData["AuraTrackerUserAuars"], ",")
		VanillaEnhancedData["AuraTrackerSlots"] = {}
		for i, aura in ipairs(auras) do
			if i > 8 then break end
			aura = VE.trim(aura)
			if strlen(aura) > 0 then
				local spellName = aura
				local showWhen = "present"
				if strsub(aura, 1, 1) == "!" then
					spellName = VE.trim(strsub(aura, 2))
					showWhen = "missing"
				end

				VanillaEnhancedData["AuraTrackerSlots"][i] = {
					name = spellName,
					showWhen = showWhen,
					target = "player",
					type = "buff",
					showStacks = true,
					showDuration = true,
				}
			end
		end
	end
end

SLASH_AURATRACKER1 = "/auratracker"
SLASH_AURATRACKER2 = "/at"
SlashCmdList["AURATRACKER"] = function()
	if VE.isModuleEnabled(module.identifier) then
		VE.disableModule(module.identifier)
	else
		VE.enableModule(module.identifier)
	end
	ConsoleExec("reloadui")
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("PLAYER_AURAS_CHANGED")
module.plug:RegisterEvent("PLAYER_TARGET_CHANGED")
module.plug:RegisterEvent("UNIT_AURA")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		MigrateData()
		GenerateEmptyFrames()
		UpdateAuraFrames()
	end

	if event == "PLAYER_AURAS_CHANGED" or event == "PLAYER_TARGET_CHANGED" or event == "UNIT_AURA" then
		if event == "UNIT_AURA" then
			if arg1 == "player" or arg1 == "target" then
				UpdateAuraFrames()
			end
		else
			UpdateAuraFrames()
		end
	end
end)

-- Timer for smooth duration updates
local lastUpdate = 0
module.plug:SetScript("OnUpdate", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	if not module.plug.frame or not module.plug.frame:IsShown() then return end

	lastUpdate = lastUpdate + arg1
	if lastUpdate > 0.3 then
		UpdateAuraFrames()
		lastUpdate = 0
	end
end)
