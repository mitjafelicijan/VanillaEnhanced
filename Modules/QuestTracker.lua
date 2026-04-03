-- Faction IDs: 1=Alliance, 2=Horde, 3=Neutral
-- Class IDs: 0=All, 1=Warrior, 2=Paladin, 3=Hunter, 4=Rogue, 5=Priest, 6=Shaman, 7=Mage, 8=Warlock, 9=Druid
-- Event IDs: 0=None, 1=Active
-- PvP IDs: 0=None, 1=Active
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
		available = {
			texture = "Interface\\AddOns\\VanillaEnhanced\\Assets\\QuestTracker-Available",
			size = 18,
		},
		objective = {
			texture = "Interface\\AddOns\\VanillaEnhanced\\Assets\\QuestTracker-Objective",
			size = 64,
		},
		showTrivial = false,
		showEvents = false,
		showPvP = false,
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
	},
	data = {
		hooked = false,
		zoneCache = {},
		questMatchCache = {},
		mapDataReady = false,
		mapIDsByZoneName = {},
		questsByMap = {},
		areaFrames = {},
		turninFrames = {},
		availableFrames = {},
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

	for questID, questData in pairs(QuestZoneData.quests) do
		if questData.available and questData.available.maps then
			for mapID, startData in pairs(questData.available.maps) do
				module.data.questsByMap[mapID] = module.data.questsByMap[mapID] or {}
				table.insert(module.data.questsByMap[mapID], {
					questID = questID,
					title = questData.title,
					level = questData.lvl,
					minLevel = questData.min,
					faction = questData.faction,
					classID = questData.class,
					isEvent = questData.isEvent,
					isPvP = questData.isPvP,
					objective = questData.objText,
					x = startData.x,
					y = startData.y,
				})
			end
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
									turnins[VE.count(turnins) + 1] = marker
									markersByLocation[markerKey] = marker
								end

								marker.quests[VE.count(marker.quests) + 1] = {
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
			activeQuests[normalizeKey(title)] = true
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
				-- Filter by level range.
				local withinLevelRange = (q.level >= minLevel and q.level <= maxLevel)

				-- Filter out active, completed, and under-leveled quests.
				if withinLevelRange and not activeQuests[normalizeKey(q.title)] and not completedQuests[q.questID] and playerLevel >= (q.minLevel or 0) then
					-- Filter by faction (1: Alliance, 2: Horde, 3: Neutral).
					local eligible = (q.faction == 3 or q.faction == factionID)

					-- Filter by class (0: All, 1-9: Specific class).
					if eligible and q.classID and q.classID > 0 then
						if q.classID ~= playerClassID then
							eligible = false
						end
					end

					-- Filter by event status.
					if eligible and q.isEvent == 1 and not module.config.showEvents then
						eligible = false
					end

					-- Filter by PvP status.
					if eligible and q.isPvP == 1 and not module.config.showPvP then
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
							markers[VE.count(markers) + 1] = marker
							markersByLocation[markerKey] = marker
						end

					marker.quests[VE.count(marker.quests) + 1] = {
						questID = q.questID,
						title = q.title,
						level = q.level,
						objective = q.objective,
					}
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
	for _, area in ipairs(module.data.areaFrames) do
		area:Hide()
	end

	for _, marker in ipairs(module.data.turninFrames) do
		marker:Hide()
	end

	for _, marker in ipairs(module.data.availableFrames) do
		marker:Hide()
	end

	if not VE.isModuleEnabled(module.identifier) then return end
	if not WorldMapFrame:IsVisible() then return end

	ensureMapData()

	local mapIDs = getCurrentMapIDs()
	if not mapIDs then return end

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

		ensureMapData()
		hookWorldMapUpdate()
		module.refreshQuestAreas()
	elseif event == "QUEST_LOG_UPDATE" then
		module.refreshQuestAreas()
	elseif event == "QUEST_COMPLETE" then
		-- Remember which quest is being completed.
		local title = GetTitleText()
		if title then
			module.data.lastCompletingQuest = normalizeKey(title)
		end
	elseif event == "QUEST_FINISHED" then
		-- Confirm completion and record it.
		if module.data.lastCompletingQuest then
			local title = module.data.lastCompletingQuest
			module.data.lastCompletingQuest = nil

			-- Look for quest ID by title and mark it as completed in our history.
			local matches = findQuestIDsByTitle(title)
			if matches then
				if not VanillaEnhancedData.completedQuests then
					VanillaEnhancedData.completedQuests = {}
				end
				for _, questID in ipairs(matches) do
					VanillaEnhancedData.completedQuests[questID] = true
				end
			end
		end
		module.refreshQuestAreas()
	end
end)
