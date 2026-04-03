local module = VE.registerModule({
	identifier = "QuestItemTooltip",
	meta = {
		label = "Quest Tooltips",
		description = "Shows quest progress in unit and item tooltips.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		color = { r = 1, g = 0.82, b = 0 },
	},
	data = {
		activeObjectives = {},
		activeIDs = {},
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function cleanObjectiveName(str)
	if not str then return "" end
	str = string.lower(str)
	-- Remove common prefixes
	str = string.gsub(str, "^killing ", "")
	str = string.gsub(str, "^collect ", "")
	str = string.gsub(str, "^gather ", "")
	-- Remove common objective suffixes
	str = string.gsub(str, " slain$", "")
	str = string.gsub(str, " killed$", "")
	str = string.gsub(str, " defeated$", "")
	str = string.gsub(str, " destroyed$", "")
	return VE.trim(str)
end

local function refreshActiveObjectives()
	if not QuestZoneData or not QuestZoneData.quests then return end
	module.data.activeObjectives = {}
	module.data.activeIDs = {}
	local numEntries = GetNumQuestLogEntries()

	for i = 1, numEntries do
		local title, level, _, isHeader = GetQuestLogTitle(i)
		if title and not isHeader and level and level > 0 then
			-- Map to database for ID lookups
			local questID = nil
			if GetQuestLink then
				local link = GetQuestLink(i)
				if link then
					local _, _, qid = string.find(link, "|Hquest:(%d+):")
					questID = tonumber(qid)
				end
			end
			
			if not questID then
				local matches = VE.findQuestIDsByTitle(title, level)
				if matches then questID = matches[1] end
			end

			if questID and QuestZoneData.quests[questID] then
				local qData = QuestZoneData.quests[questID]
				if qData.objU then
					for _, uID in ipairs(qData.objU) do
						module.data.activeIDs[uID] = module.data.activeIDs[uID] or {}
						table.insert(module.data.activeIDs[uID], { title = title, level = level })
					end
				end
				if qData.objO then
					for _, oID in ipairs(qData.objO) do
						module.data.activeIDs[oID] = module.data.activeIDs[oID] or {}
						table.insert(module.data.activeIDs[oID], { title = title, level = level })
					end
				end
			end

			local numObjectives = GetNumQuestLeaderBoards(i)
			for n = 1, numObjectives do
				local text, _, finished = GetQuestLogLeaderBoard(n, i)
				if text and not finished then
					-- Standard "Name: 0/10" format
					local _, _, name, current, total = string.find(text, "(.-):%s*(%d+)%/(%d+)")
					if name then
						local key = cleanObjectiveName(name)
						module.data.activeObjectives[key] = module.data.activeObjectives[key] or {}
						table.insert(module.data.activeObjectives[key], {
							title = title,
							level = level,
							current = current,
							total = total,
							text = text
						})
					else
						-- Non-standard format, try to match the whole text or parts
						local key = cleanObjectiveName(text)
						module.data.activeObjectives[key] = module.data.activeObjectives[key] or {}
						table.insert(module.data.activeObjectives[key], {
							title = title,
							level = level,
							text = text
						})
					end
				end
			end
		end
	end
end

local function onTooltipSetUnit(unit)
	unit = unit or "mouseover"
	local exists, guid = UnitExists(unit)
	if not exists then return end

	local name = UnitName(unit)
	if not name then return end
	local lowerName = string.lower(name)

	local shownQuests = {}
	local matched = false

	-- 1. Try ID matching (SuperWoW)
	if guid and string.len(guid) > 12 then
		local unitID = tonumber(string.sub(guid, 7, 12), 16)
		if unitID and module.data.activeIDs[unitID] then
			for _, obj in ipairs(module.data.activeIDs[unitID]) do
				local questKey = obj.level .. obj.title
				if not shownQuests[questKey] then
					GameTooltip:AddLine(string.format("[%d] %s", obj.level, obj.title), module.config.color.r, module.config.color.g, module.config.color.b)
					shownQuests[questKey] = true
					matched = true
				end
			end
		end
	end

	-- 2. Try Name matching (Fallback/General)
	local objectives = module.data.activeObjectives[lowerName]

	if not objectives then
		-- Try fuzzy matching
		for objKey, objList in pairs(module.data.activeObjectives) do
			if string.find(objKey, lowerName) or string.find(lowerName, objKey) then
				objectives = objList
				break
			end
		end
	end

	if objectives then
		for _, obj in ipairs(objectives) do
			local questKey = obj.level .. obj.title
			if not shownQuests[questKey] then
				if obj.current and obj.total then
					GameTooltip:AddDoubleLine(
						string.format("[%d] %s", obj.level, obj.title),
						string.format("%s/%s", obj.current, obj.total),
						module.config.color.r, module.config.color.g, module.config.color.b,
						1, 1, 1
					)
				else
					GameTooltip:AddLine(string.format("[%d] %s", obj.level, obj.title), module.config.color.r, module.config.color.g, module.config.color.b)
					GameTooltip:AddLine("  " .. obj.text, 1, 1, 1)
				end
				shownQuests[questKey] = true
				matched = true
			end
		end
	end

	if matched then
		GameTooltip:Show()
	end
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("QUEST_LOG_UPDATE")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		-- Delay refresh to ensure quest log is ready
		module.plug.refreshTime = GetTime() + 2
		module.plug:SetScript("OnUpdate", function()
			if GetTime() >= this.refreshTime then
				refreshActiveObjectives()
				this:SetScript("OnUpdate", nil)
			end
		end)
	elseif event == "QUEST_LOG_UPDATE" then
		refreshActiveObjectives()
	end
end)

-- Hook tooltips
local _SetUnit = GameTooltip.SetUnit
GameTooltip.SetUnit = function(self, unit)
	_SetUnit(self, unit)
	if VE.isModuleEnabled(module.identifier) then
		onTooltipSetUnit(unit)
	end
end

local originalOnTooltipSetUnit = GameTooltip:GetScript("OnTooltipSetUnit")
GameTooltip:SetScript("OnTooltipSetUnit", function()
	if originalOnTooltipSetUnit then
		originalOnTooltipSetUnit()
	end
	if VE.isModuleEnabled(module.identifier) then
		onTooltipSetUnit("mouseover")
	end
end)

SLASH_QUESTTOOLTIP1 = "/qtt"
SlashCmdList["QUESTTOOLTIP"] = function(msg)
	VE.print("QuestItemTooltip: Debug Info")
	if not QuestZoneData then
		VE.print("  QuestZoneData is NIL!")
	elseif not QuestZoneData.quests then
		VE.print("  QuestZoneData.quests is NIL!")
	else
		VE.print("  QuestZoneData is loaded.")
	end
	
	local textCount = 0
	for k, v in pairs(module.data.activeObjectives) do
		textCount = textCount + 1
		VE.print("  Text Obj: " .. k)
	end
	local idCount = 0
	for k, v in pairs(module.data.activeIDs) do
		idCount = idCount + 1
	end
	VE.print(string.format("  Total: %d text, %d IDs", textCount, idCount))
end
