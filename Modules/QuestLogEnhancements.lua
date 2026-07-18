local module = VE.registerModule({
	identifier = "QuestLogEnhancements",
	meta = {
		label = "Quest Log Enhancements",
		description = "Displays quest levels in the tooltip when hovering over quests in the quest log.",
	},
	plug = nil,
	superWoWRequired = false,
})

local function GetOrCreateLevelString(parent)
	local name = parent:GetName() .. "VELevel"
	local fs = getglobal(name)
	if not fs then
		fs = parent:CreateFontString(name, "OVERLAY", "GameFontNormalSmall")
		fs:SetPoint("LEFT", parent, "LEFT", 4, 0)
	end
	return fs
end

local function UpdateQuestLog()
	if not VE.isModuleEnabled(module.identifier) then
		-- Hide levels if module is disabled
		for i = 1, QUESTS_DISPLAYED do
			local button = getglobal("QuestLogTitle" .. i)
			if button then
				local fs = getglobal(button:GetName() .. "VELevel")
				if fs then fs:Hide() end
			end
		end
		return
	end

	local numEntries, _ = GetNumQuestLogEntries()
	local questIndex, questLogTitle, level, isHeader
	local button, levelFS

	for i = 1, QUESTS_DISPLAYED, 1 do
		button = getglobal("QuestLogTitle"..i)
		if button then
			levelFS = GetOrCreateLevelString(button)
			levelFS:Hide()
		end
	end
end

local function OnQuestLogTitleEnter()
	if not VE.isModuleEnabled(module.identifier) then return end

	local questIndex = this:GetID() + FauxScrollFrame_GetOffset(QuestLogListScrollFrame)
	local numEntries, _ = GetNumQuestLogEntries()

	if questIndex <= numEntries then
		local questLogTitle, level, _, isHeader = GetQuestLogTitle(questIndex)
		if questLogTitle and not isHeader then
			local color = GetDifficultyColor(level)
			if not color then color = { r = 1, g = 1, b = 1 } end

			if not GameTooltip:IsVisible() then
				GameTooltip_SetDefaultAnchor(GameTooltip, this)
				GameTooltip:SetText(questLogTitle)
			end

			GameTooltip:AddDoubleLine("Quest Level:", string.format("[%d]", level), 1, 1, 1, color.r, color.g, color.b)
			GameTooltip:Show()
		end
	end
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:SetScript("OnEvent", function()
	if event == "PLAYER_ENTERING_WORLD" then
		VE.hooksecurefunc("QuestLog_Update", UpdateQuestLog, true)
		VE.hooksecurefunc("QuestLogTitleButton_OnEnter", OnQuestLogTitleEnter, true)
		module.plug:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end)
