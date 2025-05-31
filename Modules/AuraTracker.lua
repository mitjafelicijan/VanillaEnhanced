local module = VE.registerModule({
	identifier = "AuraTracker",
	meta = {
		label = "Aura Tracker",
		description = "Tracks missing or existing auras set to a player in the middle of the screen.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		offsetPercentage = 70,
		offsetPosition = "bottom", -- [top, bottom]
		maxAuras = 10,
		auraPadding = 4,
		auraSize = 36,
	},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function ParseUserAuras()
	local auras = VE.split(module.data.auras, ",")
	local valid = {}

	for _, aura in pairs(auras) do
		aura = VE.trim(aura)
		if strlen(aura) > 0 then
			local spellName = VE.trim(aura)
			local spellInclusion = true

			if strsub(aura, 1, 1) == "!" then
				spellName = VE.trim(strsub(aura, 2, strlen(aura)))
				spellInclusion = false
			end

			table.insert(valid, {
				name = spellName,
				inclusion = spellInclusion
			})
		end
	end

	return valid
end

local function GetValidAuras()
	local shownAuras = {}
	local userAuras = ParseUserAuras()

	-- Attach textures to auras.
	for _, aura in pairs(userAuras) do
		local spells = VE.GetSpellInfoByName(aura.name)
		if VE.count(spells) > 0 then
			aura.texture = spells[next(spells)].icon
		end
	end

	-- Remove auras that dont need to be displayed.
	for _, aura in pairs(userAuras) do
		for i = 0, 15 do
			local _, _, id, _ = UnitBuff("player", i)
		end
	end

	for _, aura in pairs(userAuras) do
		local found = false

		for i = 0, 15 do
			local texture, _, _, _ = UnitBuff("player", i)
			if texture then
				if aura.texture == texture then
					found = true
				end
			end
		end

		if aura.inclusion == found then
			table.insert(shownAuras, aura)
		end
	end

	return shownAuras
end

local function GenerateEmptyFrames()
	local half = GetScreenHeight() / 2
	local offset = half - ((half / 100) * module.config.offsetPercentage)
	if module.config.offsetPosition == "bottom" then offset = -offset end

	module.plug.frame = CreateFrame("Frame", "AuraTracker", UIParent)
	module.plug.frame:SetWidth((module.config.maxAuras * module.config.auraSize) + ((module.config.maxAuras - 1) * module.config.auraPadding))
	module.plug.frame:SetHeight(module.config.auraSize + module.config.auraPadding)
	module.plug.frame:SetPoint("Center", UIParent, "Center", 0, offset)
	module.plug.frame:SetFrameStrata("BACKGROUND")

	module.plug.frame.auras = {}
	for i = 1, module.config.maxAuras do
		local aura = CreateFrame("Frame", "AuraTrackerAura" .. i, module.plug.frame)
		aura:SetWidth(module.config.auraSize)
		aura:SetHeight(module.config.auraSize)
		aura:SetPoint("Left", module.plug.frame, "Left", ((i - 1) * module.config.auraSize) + ((i - 1) * module.config.auraPadding), 0)
		aura.texture = aura:CreateTexture(nil)
		aura.texture:SetAllPoints(aura)
		table.insert(module.plug.frame.auras, aura)
	end

	module.plug:Hide()
end

local function UpdateAuraFrames()
	local auras = GetValidAuras()
	local activeAuraCount = VE.count(auras)

	if activeAuraCount == 0 then
		module.plug.frame:Hide()
		return
	end

	-- Clear all auras.
	for idx = 1, module.config.maxAuras do
		module.plug.frame.auras[idx].texture:SetTexture(nil)
	end

	-- Set active auras.
	for idx, aura in pairs(auras) do
		module.plug.frame.auras[idx].texture:SetTexture(aura.texture)
	end

	-- Set bar position based on number of active auras.
	do
		local offset = (module.config.maxAuras * module.config.auraSize) - (VE.count(auras) * module.config.auraSize)
		local totalWidth = activeAuraCount * module.config.auraSize
		if activeAuraCount > 1 then
			totalWidth = totalWidth + ((activeAuraCount - 1) * module.config.auraPadding)
		end
		module.plug.frame:SetWidth(totalWidth)
	end

	module.plug.frame:Show()
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("PLAYER_AURAS_CHANGED")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	if not VanillaEnhancedData[module.identifier .. "UserAuars"] then return end

	if event == "PLAYER_ENTERING_WORLD" then
		module.data.auras = VanillaEnhancedData[module.identifier .. "UserAuars"]
		GenerateEmptyFrames()
		ParseUserAuras()
	end

	if event == "PLAYER_AURAS_CHANGED" then
		UpdateAuraFrames()
	end
end)
