local module = VE.registerModule({
	identifier = "QuestTracker",
	meta = {
		label = "Quest Tracker",
		description = "Shows quest objective areas and completed turn-ins on the world map.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		turnin = {
			texture = "Interface\\AddOns\\VanillaEnhanced\\Assets\\QuestTracker-Complete",
			size = 18,
		},
		objective = {
			texture = "Interface\\AddOns\\VanillaEnhanced\\Assets\\QuestTracker-Objective",
			size = 64,
		},
	},
	data = {
		hooked = false,
		zoneCache = {},
		questMatchCache = {},
		mapDataReady = false,
		mapIDsByZoneName = {},
		areaFrames = {},
		turninFrames = {},
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

local function normalizeKey(value)
	if not value then return nil end
	return string.lower(value)
end

local function getZoneNames(continentID)
	if continentID <= 0 then return nil end
	if not module.data.zoneCache[continentID] then
		module.data.zoneCache[continentID] = { GetMapZones(continentID) }
	end
	return module.data.zoneCache[continentID]
end

local function ensureMapData()
	if module.data.mapDataReady then return end
	if not QuestZoneData or not QuestZoneData.maps then return end

	for mapID, zoneName in pairs(QuestZoneData.maps) do
		local zoneKey = normalizeKey(zoneName)
		if zoneKey then
			module.data.mapIDsByZoneName[zoneKey] = module.data.mapIDsByZoneName[zoneKey] or {}
			table.insert(module.data.mapIDsByZoneName[zoneKey], mapID)
		end
	end

	module.data.mapDataReady = true
end

local function findQuestIDsByTitle(title, level)
	if not QuestZoneData or not QuestZoneData.quests then return nil end

	local titleKey = normalizeKey(title)
	if not titleKey then return nil end

	local cacheKey = level and string.format("%s|%d", titleKey, level) or titleKey
	local cached = module.data.questMatchCache[cacheKey]
	if cached ~= nil then
		return cached or nil
	end

	local matches = {}

	for questID, questData in pairs(QuestZoneData.quests) do
		if normalizeKey(questData.title) == titleKey and (not level or questData.lvl == level) then
			matches[VE.count(matches) + 1] = questID
		end
	end

	if level and not matches[1] then
		for questID, questData in pairs(QuestZoneData.quests) do
			if normalizeKey(questData.title) == titleKey then
				matches[VE.count(matches) + 1] = questID
			end
		end
	end

	module.data.questMatchCache[cacheKey] = matches[1] and matches or false
	return matches[1] and matches or nil
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

	return findQuestIDsByTitle(title, level)
end

local function getCurrentMapIDs()
	local currentContinent = GetCurrentMapContinent()
	local currentZone = GetCurrentMapZone()
	if currentContinent <= 0 or currentZone <= 0 then return nil end

	local zoneNames = getZoneNames(currentContinent)
	local currentZoneName = zoneNames and zoneNames[currentZone]
	if not currentZoneName then return nil end

	return module.data.mapIDsByZoneName[normalizeKey(currentZoneName)]
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
									areas[VE.count(areas) + 1] = {
										questID = questID,
										title = title,
										level = level,
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
									turnins[VE.count(turnins) + 1] = marker
									markersByLocation[markerKey] = marker
								end

								marker.quests[VE.count(marker.quests) + 1] = {
									questID = questID,
									title = title,
									level = level,
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
			WorldMapTooltip:AddLine("Objective area", 1, 1, 1)
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

local function refreshQuestAreas()
	for _, area in ipairs(module.data.areaFrames) do
		area:Hide()
	end

	for _, marker in ipairs(module.data.turninFrames) do
		marker:Hide()
	end

	if not VE.isModuleEnabled(module.identifier) then return end
	if not WorldMapFrame:IsVisible() then return end

	ensureMapData()

	local mapIDs = getCurrentMapIDs()
	if not mapIDs then return end

	local areas = collectQuestAreas(mapIDs)
	local turnins = collectQuestTurnins(mapIDs)
	local areaIndex = 1
	local turninIndex = 1

	for _, areaData in ipairs(areas) do
		areaIndex = drawQuestArea(areaIndex, areaData)
	end

	for _, turninData in ipairs(turnins) do
		turninIndex = drawQuestTurnin(turninIndex, turninData)
	end
end

local function hookWorldMapUpdate()
	if module.data.hooked then return end

	local originalWorldMapFrameUpdate = WorldMapFrame_Update
	WorldMapFrame_Update = function()
		if originalWorldMapFrameUpdate then
			originalWorldMapFrameUpdate()
		end

		refreshQuestAreas()
	end

	module.data.hooked = true
end

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		ensureMapData()
		hookWorldMapUpdate()
		refreshQuestAreas()
	elseif event == "QUEST_LOG_UPDATE" then
		refreshQuestAreas()
	end
end)
