local module = VE.registerModule({
	identifier = "UnitFrameHealPrediction",
	meta = {
		label = "Unit Frame Heal Prediction",
		description = "Adds heal prediction to the standard player and target frames.",
	},
	plug = nil,
	superWoWRequired = true,
	config = {
		spellEffectiveness = {
			["Healing Touch"] = { [1] = 37, [2] = 88, [3] = 195, [4] = 363, [5] = 572, [6] = 742, [7] = 936, [8] = 1199, [9] = 1516, [10] = 1890, [11] = 2267 },
			["Regrowth"] = { [1] = 84, [2] = 164, [3] = 240, [4] = 318, [5] = 405, [6] = 511, [7] = 646, [8] = 809, [9] = 1003 },
			["Lesser Heal"] = { [1] = 46, [2] = 71, [3] = 135 },
			["Heal"] = { [1] = 295, [2] = 429, [3] = 566, [4] = 605 },
			["Greater Heal"] = { [1] = 764, [2] = 977, [3] = 1222, [4] = 1528, [5] = 1671 },
			["Flash Heal"] = { [1] = 193, [2] = 258, [3] = 278, [4] = 340, [5] = 440, [6] = 548, [7] = 690 },
			["Prayer of Healing"] = { [1] = 301, [2] = 378, [3] = 559, [4] = 798, [5] = 88 },
			["Holy Light"] = { [1] = 39, [2] = 76, [3] = 159, [4] = 310, [5] = 491, [6] = 698, [7] = 945, [8] = 1246, [9] = 1590 },
			["Flash of Light"] = { [1] = 62, [2] = 96, [3] = 145, [4] = 197, [5] = 267, [6] = 343, [7] = 428 },
			["Healing Wave"] = { [1] = 34, [2] = 64, [3] = 129, [4] = 268, [5] = 376, [6] = 536, [7] = 740, [8] = 1017, [9] = 1367, [10] = 1620 },
			["Lesser Healing Wave"] = { [1] = 162, [2] = 247, [3] = 227, [4] = 458, [5] = 631, [6] = 832 },
			["Chain Heal"] = { [1] = 320, [2] = 405, [3] = 551 },
		},
	},
	data = {
		activeHeals = {}, -- [targetGUID] = { [casterGUID] = amount }
		activeCasts = {}, -- [casterGUID] = targetGUID
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function GetTotalIncomingHeals(unitGUID)
	if not unitGUID or not module.data.activeHeals[unitGUID] then return 0 end
	local total = 0
	for _, amount in pairs(module.data.activeHeals[unitGUID]) do
		total = total + amount
	end
	return total
end

local function UpdatePredictionBar(unit)
	if not unit or not UnitExists(unit) then return end
	local framePrefix = "Player"
	if unit == "target" then framePrefix = "Target" end

	local predictionBar = getglobal(framePrefix .. "FrameHealthBarPrediction")
	if not predictionBar then return end

	if UnitIsDeadOrGhost(unit) then
		predictionBar:SetValue(0)
		return
	end

	local _, unitGUID = UnitExists(unit)
	local incomingHeal = GetTotalIncomingHeals(unitGUID)

	local health = UnitHealth(unit)
	local maxHealth = UnitHealthMax(unit)

	predictionBar:SetMinMaxValues(0, maxHealth)
	if incomingHeal > 0 then
		predictionBar:SetValue(health + incomingHeal)
	else
		predictionBar:SetValue(0)
	end
end

local function CreatePredictionBars()
	-- Player Frame
	if not getglobal("PlayerFrameHealthBarPrediction") then
		local predictionBar = CreateFrame("StatusBar", "PlayerFrameHealthBarPrediction", PlayerFrame)
		predictionBar:SetAllPoints(PlayerFrameHealthBar)
		predictionBar:SetStatusBarTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-HealthFill")
		predictionBar:SetStatusBarColor(0, 1, 0, 0.5)
		predictionBar:SetFrameLevel(PlayerFrameHealthBar:GetFrameLevel() - 1)
		predictionBar:SetMinMaxValues(0, 1)
		predictionBar:SetValue(0)
	end

	-- Target Frame
	if not getglobal("TargetFrameHealthBarPrediction") then
		local predictionBar = CreateFrame("StatusBar", "TargetFrameHealthBarPrediction", TargetFrame)
		predictionBar:SetAllPoints(TargetFrameHealthBar)
		predictionBar:SetStatusBarTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\RaidFrame-HealthFill")
		predictionBar:SetStatusBarColor(0, 1, 0, 0.5)
		predictionBar:SetFrameLevel(TargetFrameHealthBar:GetFrameLevel() - 1)
		predictionBar:SetMinMaxValues(0, 1)
		predictionBar:SetValue(0)
	end
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("UNIT_CASTEVENT")
module.plug:RegisterEvent("PLAYER_TARGET_CHANGED")
module.plug:RegisterEvent("UNIT_HEALTH")
module.plug:RegisterEvent("UNIT_MAXHEALTH")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		CreatePredictionBars()
		UpdatePredictionBar("player")
		UpdatePredictionBar("target")
	end

	if event == "PLAYER_TARGET_CHANGED" then
		UpdatePredictionBar("target")
	end

	if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
		if arg1 == "player" or arg1 == "target" then
			UpdatePredictionBar(arg1)
		end
	end

	if event == "UNIT_CASTEVENT" then
		local casterGUID = arg1
		local targetGUID = arg2
		local eventType = arg3   -- ("START", "CAST", "FAIL", "CHANNEL", "MAINHAND", "OFFHAND") 
		local spellID = arg4

		if eventType == "START" then
			local spellName, spellRank = VE.GetSpellInfoByID(spellID)
			if spellName and module.config.spellEffectiveness[spellName] then
				local rankNumber = 1
				if spellRank then
					local _, _, rank = string.find(spellRank, "(%d+)")
					rankNumber = tonumber(rank) or 1
				end

				local amount = module.config.spellEffectiveness[spellName][rankNumber] or 0
				if amount > 0 then
					if not module.data.activeHeals[targetGUID] then
						module.data.activeHeals[targetGUID] = {}
					end
					module.data.activeHeals[targetGUID][casterGUID] = amount
					module.data.activeCasts[casterGUID] = targetGUID

					-- Update frames if target matches
					local _, playerGUID = UnitExists("player")
					local _, targetGUID_unit = UnitExists("target")
					if targetGUID == playerGUID then UpdatePredictionBar("player") end
					if targetGUID == targetGUID_unit then UpdatePredictionBar("target") end
				end
			end
		end

		if eventType == "CAST" or eventType == "FAIL" then
			local tGUID = module.data.activeCasts[casterGUID]
			if tGUID then
				if module.data.activeHeals[tGUID] then
					module.data.activeHeals[tGUID][casterGUID] = nil

					-- Cleanup empty table
					local hasCasters = false
					for _ in pairs(module.data.activeHeals[tGUID]) do hasCasters = true; break end
					if not hasCasters then module.data.activeHeals[tGUID] = nil end
				end
				module.data.activeCasts[casterGUID] = nil

				-- Update frames if target matches
				local _, playerGUID = UnitExists("player")
				local _, targetGUID_unit = UnitExists("target")
				if tGUID == playerGUID then UpdatePredictionBar("player") end
				if tGUID == targetGUID_unit then UpdatePredictionBar("target") end
			end
		end
	end
end)
