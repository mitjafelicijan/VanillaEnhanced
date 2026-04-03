-- Faction IDs: 1=Alliance, 2=Horde, 3=Neutral
-- Class IDs: 0=All, 1=Warrior, 2=Paladin, 3=Hunter, 4=Rogue, 5=Priest, 6=Shaman, 7=Mage, 8=Warlock, 9=Druid
-- Event IDs: 0=None, 1=Active
-- PvP IDs: 0=None, 1=Active
local module = VE.registerModule({
	identifier = "QuestTracker",
	meta = {
		label = "Quest Tracker",
		description = "Shows quest objective areas and completed turn-ins on the world map, and quest progress in tooltips.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		turnin = {
			texture = "Interface\\AddOns\\VanillaEnhanced\\Assets\\QuestTracker-Complete",
			size = 18,
		},
		available = {
			texture = "Interface\\AddOns\\VanillaEnhanced\\Assets\\QuestTracker-Available",
			size = 18,
		},
		objective = {
			texture = "Interface\\AddOns\\VanillaEnhanced\\Assets\\QuestTracker-Objective",
			size = 26,
		},
		showTrivial = false,
		showEvents = false,
		showPvP = false,
		showTooltips = true,
		tooltipColor = { r = 1, g = 0.82, b = 0 },
	},
	options = {
		{
			identifier = "QuestTrackerShowTrivial",
			meta = {
				label = "Show trivial quests",
				description = "Show quests that are more than 9 levels below your current level (grey quests).",
			},
			callback = function(checked)
				local m = VE.getModule("QuestTracker")
				if m then
					m.config.showTrivial = checked
					m.refreshQuestAreas()
				end
			end,
		},
		{
			identifier = "QuestTrackerShowEvents",
			meta = {
				label = "Show event quests",
				description = "Show quests related to festivals and world events.",
			},
			callback = function(checked)
				local m = VE.getModule("QuestTracker")
				if m then
					m.config.showEvents = checked
					m.refreshQuestAreas()
				end
			end,
		},
		{
			identifier = "QuestTrackerShowPvP",
			meta = {
				label = "Show PvP quests",
				description = "Show quests related to battlegrounds and PvP objectives.",
			},
			callback = function(checked)
				local m = VE.getModule("QuestTracker")
				if m then
					m.config.showPvP = checked
					m.refreshQuestAreas()
				end
			end,
		},
		{
			identifier = "QuestTrackerShowTooltips",
			meta = {
				label = "Show quest tooltips",
				description = "Shows quest progress in unit and item tooltips.",
			},
			callback = function(checked)
				local m = VE.getModule("QuestTracker")
				if m then
					m.config.showTooltips = checked
				end
			end,
		},
	},
	data = {
		hooked = false,
		zoneCache = {},
		questMatchCache = {},
		mapDataReady = false,
		mapDataStarted = false,
		mapDataCurrentKey = nil,
		mapIDsByZoneName = {},
		questsByMap = {},
		questsByTitle = {},
		areaFrames = {},
		turninFrames = {},
		availableFrames = {},
		activeObjectives = {},
		activeIDs = {},
		isUpdating = false,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("QUEST_LOG_UPDATE")
module.plug:RegisterEvent("QUEST_FINISHED")
module.plug:RegisterEvent("QUEST_COMPLETE")

-- Helper: Tooltip name cleaning
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

local function getZoneNames(continentID)
	if continentID <= 0 then return nil end
	if not module.data.zoneCache[continentID] then
		module.data.zoneCache[continentID] = { GetMapZones(continentID) }
	end
	return module.data.zoneCache[continentID]
end

local function findQuestIDsInModule(title, level)
	local titleKey = VE.normalizeKey(title)
	if not titleKey or not module.data.questsByTitle[titleKey] then return nil end

	local matches = {}
	for _, questID in ipairs(module.data.questsByTitle[titleKey]) do
		local questData = QuestZoneData.quests[questID]
		if not level or (questData and questData.lvl == level) then
			table.insert(matches, questID)
		end
	end

	return table.getn(matches) > 0 and matches or nil
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
				local matches = findQuestIDsInModule(title, level)
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
					-- Standard "Name: 0/10" format or custom text
					local _, _, name = string.find(text, "(.-):%s*(%d+)%/(%d+)")
					name = cleanObjectiveName(name or text)
					if name and name ~= "" then
						module.data.activeObjectives[name] = module.data.activeObjectives[name] or {}
						table.insert(module.data.activeObjectives[name], {
							title = title,
							level = level,
						})
					end
				end
			end
		end
	end
end

local function onTooltipSetUnit(unit)
	if not module.config.showTooltips then return end
	unit = unit or "mouseover"
	local exists, guid = UnitExists(unit)
	if not exists then return end

	local name = UnitName(unit)
	if not name then return end
	local lowerName = string.lower(name)

	local shownQuests = {}
	local matched = false

	local function addQuestLine(level, title)
		if not matched then
			GameTooltip:AddLine(" ") -- Separator
			matched = true
		end
		GameTooltip:AddLine(string.format("[%d] %s", level, title), module.config.tooltipColor.r, module.config.tooltipColor.g, module.config.tooltipColor.b)
	end

	-- 1. Try ID matching (SuperWoW)
	if guid and string.len(guid) > 12 then
		local unitID = tonumber(string.sub(guid, 7, 12), 16)
		if unitID and module.data.activeIDs[unitID] then
			for _, obj in ipairs(module.data.activeIDs[unitID]) do
				local questKey = obj.level .. obj.title
				if not shownQuests[questKey] then
					addQuestLine(obj.level, obj.title)
					shownQuests[questKey] = true
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
				addQuestLine(obj.level, obj.title)
				shownQuests[questKey] = true
			end
		end
	end

	if matched then
		GameTooltip:Show()
	end
end

local function ensureMapData()
	if module.data.mapDataReady or module.data.mapDataStarted then return end
	if not QuestZoneData or not QuestZoneData.maps then return end

	module.data.mapDataStarted = true

	-- Process maps instantly (they are few)
	for mapID, zoneName in pairs(QuestZoneData.maps) do
		local zoneKey = VE.normalizeKey(zoneName)
		if zoneKey then
			module.data.mapIDsByZoneName[zoneKey] = module.data.mapIDsByZoneName[zoneKey] or {}
			table.insert(module.data.mapIDsByZoneName[zoneKey], mapID)
		end
	end

	-- Start the incremental quest processor
	local processor = CreateFrame("Frame")
	processor.count = 0
	processor:SetScript("OnUpdate", function()
		if not QuestZoneData or not QuestZoneData.quests then
			this:SetScript("OnUpdate", nil)
			return
		end

		local processed = 0
		local chunk = 100 -- Process 100 quests per frame
		
		while processed < chunk do
			local k, v = next(QuestZoneData.quests, module.data.mapDataCurrentKey)
			if not k then
				-- We're done
				module.data.mapDataReady = true
				module.refreshQuestAreas()
				this:SetScript("OnUpdate", nil)
				return
			end
			
			module.data.mapDataCurrentKey = k
			processed = processed + 1
			
			-- Process quest data
			local questID = k
			local questData = v
			local titleKey = VE.normalizeKey(questData.title)
			if titleKey then
				module.data.questsByTitle[titleKey] = module.data.questsByTitle[titleKey] or {}
				table.insert(module.data.questsByTitle[titleKey], questID)
			end

			if questData.available and questData.available.maps then
				for mapID, startData in pairs(questData.available.maps) do
					module.data.questsByMap[mapID] = module.data.questsByMap[mapID] or {}
					table.insert(module.data.questsByMap[mapID], {
						questID = questID,
						x = startData.x,
						y = startData.y,
					})
				end
			end
		end
	end)
end

local function getQuestIDFromLink(questLogIndex)
	if not GetQuestLink then return nil end

	local questLink = GetQuestLink(questLogIndex)
	if not questLink then return nil end

	local _, _, questID = string.find(questLink, "|Hquest:(%d+):")
	return questID and tonumber(questID) or nil
end

local function getQuestCandidates(title, level, questLogIndex)
	local questID = getQuestIDFromLink(questLogIndex)
	if questID and QuestZoneData and QuestZoneData.quests and QuestZoneData.quests[questID] then
		return { questID }
	end

	return findQuestIDsInModule(title, level)
end

local function getCurrentMapIDs()
	local currentContinent = GetCurrentMapContinent()
	local currentZone = GetCurrentMapZone()
	if currentContinent <= 0 or currentZone <= 0 then return nil end

	local zoneNames = getZoneNames(currentContinent)
	local currentZoneName = zoneNames and zoneNames[currentZone]
	if not currentZoneName then return nil end

	return module.data.mapIDsByZoneName[VE.normalizeKey(currentZoneName)]
end

local function collectQuestAreas(mapIDs)
	if not mapIDs or not mapIDs[1] or not QuestZoneData or not QuestZoneData.quests then
		return {}
	end

	local areas = {}
	local seenAreas = {}
	local numEntries = GetNumQuestLogEntries()

	for questLogIndex = 1, numEntries do
		local title, level, _, isHeader, _, complete = GetQuestLogTitle(questLogIndex)
		if title and not isHeader and level and level > 0 and not complete then
			local candidateIDs = getQuestCandidates(title, level, questLogIndex)
			if candidateIDs then
				for _, questID in ipairs(candidateIDs) do
					local questData = QuestZoneData.quests[questID]
					local objectiveMaps = questData and questData.objective and questData.objective.maps
					if objectiveMaps then
						for _, mapID in ipairs(mapIDs) do
							local areaData = objectiveMaps[mapID]
							if areaData then
								local areaKey = string.format(
									"%s|%s|%s|%s|%s|%s",
									questID,
									mapID,
									areaData.x,
									areaData.y,
									areaData.width,
									areaData.height
								)

								if not seenAreas[areaKey] then
									areas[table.getn(areas) + 1] = {
										questID = questID,
										title = title,
										level = level,
										objective = questData.objText,
										count = areaData.count,
										x = areaData.x,
										y = areaData.y,
										width = areaData.width,
										height = areaData.height,
									}
									seenAreas[areaKey] = true
								end
							end
						end
					end
				end
			end
		end
	end

	return areas
end

local function isQuestReadyForTurnin(complete)
	return complete and complete ~= -1
end

local function collectQuestTurnins(mapIDs)
	if not mapIDs or not mapIDs[1] or not QuestZoneData or not QuestZoneData.quests then
		return {}
	end

	local turnins = {}
	local markersByLocation = {}
	local numEntries = GetNumQuestLogEntries()

	for questLogIndex = 1, numEntries do
		local title, level, _, isHeader, _, complete = GetQuestLogTitle(questLogIndex)
		if title and not isHeader and level and level > 0 and isQuestReadyForTurnin(complete) then
			local candidateIDs = getQuestCandidates(title, level, questLogIndex)
			if candidateIDs then
				for _, questID in ipairs(candidateIDs) do
					local questData = QuestZoneData.quests[questID]
					local turninMaps = questData and questData.turnin and questData.turnin.maps
					if turninMaps then
						for _, mapID in ipairs(mapIDs) do
							local turninData = turninMaps[mapID]
							if turninData then
								local markerKey = string.format("%s|%s|%s", mapID, turninData.x, turninData.y)
								local marker = markersByLocation[markerKey]

								if not marker then
									marker = {
										x = turninData.x,
										y = turninData.y,
										quests = {},
									}
									turnins[table.getn(turnins) + 1] = marker
									markersByLocation[markerKey] = marker
								end

								marker.quests[table.getn(marker.quests) + 1] = {
									questID = questID,
									title = title,
									level = level,
									objective = questData.objText,
								}
							end
						end
					end
				end
			end
		end
	end

	return turnins
end

local function collectAvailableQuests(mapIDs)
	if not mapIDs or not mapIDs[1] then return {} end

	local activeQuests = {}
	local numEntries = GetNumQuestLogEntries()
	for i = 1, numEntries do
		local title, level, _, isHeader = GetQuestLogTitle(i)
		if title and not isHeader then
			activeQuests[VE.normalizeKey(title)] = true
		end
	end

	-- Try to get completed quests from multiple sources.
	local completedQuests = {}
	if type(GetQuestsCompleted) == "function" then
		local temp = GetQuestsCompleted() or {}
		if temp[1] and type(temp[1]) == "number" then
			for _, id in ipairs(temp) do completedQuests[id] = true end
		else
			completedQuests = temp
		end
	elseif type(GetCompletedQuests) == "function" then
		local temp = GetCompletedQuests() or {}
		if temp[1] and type(temp[1]) == "number" then
			for _, id in ipairs(temp) do completedQuests[id] = true end
		else
			completedQuests = temp
		end
	elseif pfQuest_history then
		completedQuests = pfQuest_history
	end

	-- Check VanillaEnhanced's own tracking.
	if not VanillaEnhancedData.completedQuests then
		VanillaEnhancedData.completedQuests = {}
	end
	for id, _ in pairs(VanillaEnhancedData.completedQuests) do
		completedQuests[id] = true
	end

	local playerLevel = UnitLevel("player")
	local playerFaction = UnitFactionGroup("player")
	local factionID = (playerFaction == "Alliance" and 1 or 2)

	local _, playerClass = UnitClass("player")
	local playerClassID = 0
	if playerClass == "WARRIOR" then playerClassID = 1
	elseif playerClass == "PALADIN" then playerClassID = 2
	elseif playerClass == "HUNTER" then playerClassID = 3
	elseif playerClass == "ROGUE" then playerClassID = 4
	elseif playerClass == "PRIEST" then playerClassID = 5
	elseif playerClass == "SHAMAN" then playerClassID = 6
	elseif playerClass == "MAGE" then playerClassID = 7
	elseif playerClass == "WARLOCK" then playerClassID = 8
	elseif playerClass == "DRUID" then playerClassID = 9
	end

	local minLevel = module.config.showTrivial and 0 or (playerLevel - 9)
	local maxLevel = playerLevel + 4

	local markers = {}
	local markersByLocation = {}

	for _, mapID in ipairs(mapIDs) do
		local quests = module.data.questsByMap[mapID]
		if quests then
			for _, q in ipairs(quests) do
				local qData = QuestZoneData.quests[q.questID]
				if qData then
					local qTitle = qData.title
					local qLevel = qData.lvl
					local qMinLevel = qData.min or 0
					local qFaction = qData.faction
					local qClassID = qData.class
					local qIsEvent = qData.isEvent
					local qIsPvP = qData.isPvP
					local qObjective = qData.objText

					-- Filter by level range.
					local withinLevelRange = (qLevel >= minLevel and qLevel <= maxLevel)

					-- Filter out active, completed, and under-leveled quests.
					if withinLevelRange and not activeQuests[VE.normalizeKey(qTitle)] and not completedQuests[q.questID] and playerLevel >= qMinLevel then
						-- Filter by faction (1: Alliance, 2: Horde, 3: Neutral).
						local eligible = (qFaction == 3 or qFaction == factionID)

						-- Filter by class (0: All, 1-9: Specific class).
						if eligible and qClassID and qClassID > 0 then
							if qClassID ~= playerClassID then
								eligible = false
							end
						end

						-- Filter by event status.
						if eligible and qIsEvent == 1 and not module.config.showEvents then
							eligible = false
						end

						-- Filter by PvP status.
						if eligible and qIsPvP == 1 and not module.config.showPvP then
							eligible = false
						end

						if eligible then
							local markerKey = string.format("%s|%s|%s", mapID, q.x, q.y)
							local marker = markersByLocation[markerKey]

							if not marker then
								marker = {
									x = q.x,
									y = q.y,
									quests = {},
								}
								markers[table.getn(markers) + 1] = marker
								markersByLocation[markerKey] = marker
							end

							table.insert(marker.quests, {
								questID = q.questID,
								title = qTitle,
								level = qLevel,
								objective = qObjective,
							})
						end
					end
				end
			end
		end
	end

	return markers
end

local function getOrCreateAreaFrame(index)
	if not module.data.areaFrames[index] then
		local area = CreateFrame("Button", "VE_QuestTrackerArea" .. index, WorldMapButton)
		area:SetFrameLevel(WorldMapButton:GetFrameLevel() + 2)

		area.texture = area:CreateTexture(nil, "ARTWORK")
		area.texture:SetAllPoints(area)
		area.texture:SetTexture(module.config.objective.texture)

		area:SetScript("OnEnter", function()
			WorldMapTooltip:SetOwner(this, "ANCHOR_RIGHT")
			WorldMapTooltip:AddLine(string.format("[%d] %s", this.questLevel, this.questTitle), 1, 0.82, 0)
			if this.questObjective and this.questObjective ~= "" then
				WorldMapTooltip:AddLine(this.questObjective, 1, 1, 1, 1)
			else
				WorldMapTooltip:AddLine("Objective area", 1, 1, 1)
			end
			if this.objectiveCount and this.objectiveCount > 0 then
				WorldMapTooltip:AddLine(string.format("Known spawns/objectives: %d", this.objectiveCount), 0.9, 0.9, 0.9)
			end
			WorldMapTooltip:Show()
		end)

		area:SetScript("OnLeave", function()
			WorldMapTooltip:Hide()
		end)

		module.data.areaFrames[index] = area
	end

	return module.data.areaFrames[index]
end

local function getOrCreateTurninFrame(index)
	if not module.data.turninFrames[index] then
		local marker = CreateFrame("Button", "VE_QuestTrackerTurnin" .. index, WorldMapButton)
		marker:SetWidth(module.config.turnin.size)
		marker:SetHeight(module.config.turnin.size)
		marker:SetFrameLevel(WorldMapButton:GetFrameLevel() + 6)

		marker.texture = marker:CreateTexture(nil, "OVERLAY")
		marker.texture:SetAllPoints(marker)
		marker.texture:SetTexture(module.config.turnin.texture)

		marker:SetScript("OnEnter", function()
			WorldMapTooltip:SetOwner(this, "ANCHOR_RIGHT")
			if this.quests and this.quests[1] then
				if this.quests[2] then
					WorldMapTooltip:AddLine("Quest turn-ins", 1, 0.82, 0)
					for _, questData in ipairs(this.quests) do
						WorldMapTooltip:AddLine(string.format("[%d] %s", questData.level, questData.title), 1, 1, 1)
					end
				else
					WorldMapTooltip:AddLine(string.format("[%d] %s", this.quests[1].level, this.quests[1].title), 1, 0.82, 0)
					if this.quests[1].objective and this.quests[1].objective ~= "" then
						WorldMapTooltip:AddLine(this.quests[1].objective, 1, 1, 1, 1)
					end
				end
				WorldMapTooltip:AddLine("Completed quest ready to turn in", 0.9, 0.9, 0.9)
			end
			WorldMapTooltip:Show()
		end)

		marker:SetScript("OnLeave", function()
			WorldMapTooltip:Hide()
		end)

		module.data.turninFrames[index] = marker
	end

	return module.data.turninFrames[index]
end

local function getOrCreateAvailableFrame(index)
	if not module.data.availableFrames[index] then
		local marker = CreateFrame("Button", "VE_QuestTrackerAvailable" .. index, WorldMapButton)
		marker:SetWidth(module.config.available.size)
		marker:SetHeight(module.config.available.size)
		marker:SetFrameLevel(WorldMapButton:GetFrameLevel() + 5)

		marker.texture = marker:CreateTexture(nil, "OVERLAY")
		marker.texture:SetAllPoints(marker)
		marker.texture:SetTexture(module.config.available.texture)

		marker:SetScript("OnEnter", function()
			WorldMapTooltip:SetOwner(this, "ANCHOR_RIGHT")
			if this.quests and this.quests[1] then
				if this.quests[2] then
					WorldMapTooltip:AddLine("Available quests", 1, 0.82, 0)
					for _, questData in ipairs(this.quests) do
						WorldMapTooltip:AddLine(string.format("[%d] %s", questData.level, questData.title), 1, 1, 1)
					end
				else
					WorldMapTooltip:AddLine(string.format("[%d] %s", this.quests[1].level, this.quests[1].title), 1, 0.82, 0)
					if this.quests[1].objective and this.quests[1].objective ~= "" then
						WorldMapTooltip:AddLine(this.quests[1].objective, 1, 1, 1, 1)
					end
				end
				WorldMapTooltip:AddLine("Available quest givers", 0.9, 0.9, 0.9)
				WorldMapTooltip:AddLine("<Shift+Click to mark as completed>", 0.5, 0.5, 0.5)
			end
			WorldMapTooltip:Show()
		end)

		marker:SetScript("OnLeave", function()
			WorldMapTooltip:Hide()
		end)

		marker:SetScript("OnClick", function()
			if IsShiftKeyDown() and this.quests then
				if not VanillaEnhancedData.completedQuests then
					VanillaEnhancedData.completedQuests = {}
				end
				for _, questData in ipairs(this.quests) do
					VanillaEnhancedData.completedQuests[questData.questID] = true
				end
				module.refreshQuestAreas()
			end
		end)

		module.data.availableFrames[index] = marker
	end

	return module.data.availableFrames[index]
end

local function drawQuestArea(index, areaData)
	local area = getOrCreateAreaFrame(index)
	local mapWidth = WorldMapDetailFrame:GetWidth()
	local mapHeight = WorldMapDetailFrame:GetHeight()

	area:ClearAllPoints()
	area:SetWidth(module.config.objective.size)
	area:SetHeight(module.config.objective.size)
	area:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", mapWidth * (areaData.x / 100), -mapHeight * (areaData.y / 100))

	area.questTitle = areaData.title
	area.questLevel = areaData.level
	area.questObjective = areaData.objective
	area.objectiveCount = areaData.count

	area:Show()
	return index + 1
end

local function drawQuestTurnin(index, turninData)
	local marker = getOrCreateTurninFrame(index)
	local mapWidth = WorldMapDetailFrame:GetWidth()
	local mapHeight = WorldMapDetailFrame:GetHeight()

	marker:ClearAllPoints()
	marker:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", mapWidth * (turninData.x / 100), -mapHeight * (turninData.y / 100))
	marker.quests = turninData.quests
	marker:Show()

	return index + 1
end

local function drawAvailableQuest(index, availableData)
	local marker = getOrCreateAvailableFrame(index)
	local mapWidth = WorldMapDetailFrame:GetWidth()
	local mapHeight = WorldMapDetailFrame:GetHeight()

	marker:ClearAllPoints()
	marker:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", mapWidth * (availableData.x / 100), -mapHeight * (availableData.y / 100))
	marker.quests = availableData.quests
	marker:Show()

	return index + 1
end

module.refreshQuestAreas = function()
	if module.data.isUpdating then return end
	module.data.isUpdating = true

	for _, area in ipairs(module.data.areaFrames) do
		area:Hide()
	end

	for _, marker in ipairs(module.data.turninFrames) do
		marker:Hide()
	end

	for _, marker in ipairs(module.data.availableFrames) do
		marker:Hide()
	end

	if not VE.isModuleEnabled(module.identifier) then 
		module.data.isUpdating = false
		return 
	end
	
	if not WorldMapFrame:IsVisible() then 
		module.data.isUpdating = false
		return 
	end

	ensureMapData()

	local mapIDs = getCurrentMapIDs()
	if not mapIDs then 
		module.data.isUpdating = false
		return 
	end

	local areas = collectQuestAreas(mapIDs)
	local turnins = collectQuestTurnins(mapIDs)
	local available = collectAvailableQuests(mapIDs)
	local areaIndex = 1
	local turninIndex = 1
	local availableIndex = 1

	for _, areaData in ipairs(areas) do
		areaIndex = drawQuestArea(areaIndex, areaData)
	end

	for _, turninData in ipairs(turnins) do
		turninIndex = drawQuestTurnin(turninIndex, turninData)
	end

	for _, availableData in ipairs(available) do
		availableIndex = drawAvailableQuest(availableIndex, availableData)
	end

	module.data.isUpdating = false
end

local function hookWorldMapUpdate()
	if module.data.hooked then return end

	local originalWorldMapFrameUpdate = WorldMapFrame_Update
	WorldMapFrame_Update = function()
		if originalWorldMapFrameUpdate then
			originalWorldMapFrameUpdate()
		end

		module.refreshQuestAreas()
	end

	module.data.hooked = true
end

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		-- Sync options with config.
		module.config.showTrivial = VE.isOptionEnabled("QuestTrackerShowTrivial")
		module.config.showEvents = VE.isOptionEnabled("QuestTrackerShowEvents")
		module.config.showPvP = VE.isOptionEnabled("QuestTrackerShowPvP")
		module.config.showTooltips = VE.isOptionEnabled("QuestTrackerShowTooltips")

		hookWorldMapUpdate()
		
		-- Start map data processing and initial cache refresh after a delay
		module.plug.refreshTime = GetTime() + 3
		module.plug:SetScript("OnUpdate", function()
			if GetTime() >= this.refreshTime then
				ensureMapData()
				refreshActiveObjectives()
				module.refreshQuestAreas()
				this:SetScript("OnUpdate", nil)
			end
		end)
	elseif event == "QUEST_LOG_UPDATE" then
		refreshActiveObjectives()
		module.refreshQuestAreas()
	elseif event == "QUEST_COMPLETE" then
		-- Remember which quest is being completed.
		local title = GetTitleText()
		if title then
			module.data.lastCompletingQuest = VE.normalizeKey(title)
		end
	elseif event == "QUEST_FINISHED" then
		-- Confirm completion and record it.
		if module.data.lastCompletingQuest then
			local title = module.data.lastCompletingQuest
			module.data.lastCompletingQuest = nil

			-- Look for quest ID by title and mark it as completed in our history.
			local matches = findQuestIDsInModule(title)
			if matches then
				if not VanillaEnhancedData.completedQuests then
					VanillaEnhancedData.completedQuests = {}
				end
				for _, questID in ipairs(matches) do
					VanillaEnhancedData.completedQuests[questID] = true
				end
			end
		end
		refreshActiveObjectives()
		module.refreshQuestAreas()
	end
end)

-- Hook tooltips
local function setupHooks()
	-- 1. Hook SetUnit method
	local _SetUnit = GameTooltip.SetUnit
	GameTooltip.SetUnit = function(self, unit)
		_SetUnit(self, unit)
		if VE.isModuleEnabled(module.identifier) then
			onTooltipSetUnit(unit)
		end
	end

	-- 2. Hook OnShow script as fallback (confirmed working in 1.12)
	local _OnShow = GameTooltip:GetScript("OnShow")
	GameTooltip:SetScript("OnShow", function()
		if _OnShow then _OnShow() end
		if VE.isModuleEnabled(module.identifier) and UnitExists("mouseover") then
			onTooltipSetUnit("mouseover")
		end
	end)
end

setupHooks()
