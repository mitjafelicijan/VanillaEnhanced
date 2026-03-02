local module = VE.registerModule({
	identifier = "MapMarkers",
	meta = {
		label = "World Map Markers",
		description = "Adds markers for dungeons, raids, transport, and world bosses to the World Map.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		filters = {
			FLIGHT    = true,
			DUNGEON   = true,
			RAID      = true,
			WORLDBOSS = true,
			TRANSPORT = true,
		}
	},
	data = {
		markers = {},
		zoneMarkers = {},
		zoneCache = {},
		dataBuilt = false,
		hooked = false,
		dropdownCreated = false,
		textureMap = {
			DUNGEON   = "Interface\\AddOns\\VanillaEnhanced\\Assets\\dungeon",
			RAID      = "Interface\\AddOns\\VanillaEnhanced\\Assets\\raid",
			BOAT      = "Interface\\AddOns\\VanillaEnhanced\\Assets\\boat",
			ZEPPELIN  = "Interface\\AddOns\\VanillaEnhanced\\Assets\\zepp",
			TRAM      = "Interface\\AddOns\\VanillaEnhanced\\Assets\\tram",
			WORLDBOSS = "Interface\\AddOns\\VanillaEnhanced\\Assets\\worldboss",
			FLIGHT    = "Interface\\AddOns\\VanillaEnhanced\\Assets\\flight",
		},
		continentNames = {
			[1] = "Kalimdor",
			[2] = "Eastern Kingdoms"
		}
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

-- Helper Functions
local function cacheZones()
	module.data.zoneCache[1] = { GetMapZones(1) } -- Kalimdor
	module.data.zoneCache[2] = { GetMapZones(2) } -- Eastern Kingdoms
end

local function buildData()
	if module.data.dataBuilt then return end
	if not ModernMapMarkers_Points then return end

	module.data.zoneMarkers = {}
	local index = 1

	for contID, zones in pairs(ModernMapMarkers_Points) do
		module.data.zoneMarkers[contID] = module.data.zoneMarkers[contID] or {}

		for zoneName, zonePoints in pairs(zones) do
			module.data.zoneMarkers[contID][zoneName] = {}

			for _, m in ipairs(zonePoints) do
				local typeUpper = string.upper(m.type or "UNKNOWN")
				if typeUpper == "ZEPP" then typeUpper = "ZEPPELIN" end

				local markerData = {
					continent   = contID,
					zoneName    = zoneName,
					x           = m.x,
					y           = m.y,
					name        = m.name,
					type        = typeUpper,
					description = m.info,
					atlasID     = m.atlas,
					id          = index
				}

				table.insert(module.data.zoneMarkers[contID][zoneName], markerData)
				index = index + 1
			end
		end
	end
	

	-- Process Flight Data
	if VE_FlightData then
		-- Build reverse zone cache for continent lookup
		local zoneToContinent = {}
		if module.data.zoneCache then
			for cID, zList in pairs(module.data.zoneCache) do
				if zList then
					for _, zName in pairs(zList) do
						zoneToContinent[zName] = cID
					end
				end
			end
		end

		for zoneName, markers in pairs(VE_FlightData) do
			local contID = zoneToContinent[zoneName]
			if contID then
				module.data.zoneMarkers[contID] = module.data.zoneMarkers[contID] or {}
				module.data.zoneMarkers[contID][zoneName] = module.data.zoneMarkers[contID][zoneName] or {}

				for _, m in ipairs(markers) do
					local markerData = {
						continent   = contID,
						zoneName    = zoneName,
						x           = m.x,
						y           = m.y,
						name        = m.name,
						type        = m.type,
						description = m.info,
						atlasID     = nil,
						id          = index
					}
					table.insert(module.data.zoneMarkers[contID][zoneName], markerData)
					index = index + 1
				end
			end
		end
	end

	module.data.dataBuilt = true
end

local function onMarkerClick(marker)
	if marker.atlasID then
		if AtlasTW and AtlasTWOptions then
			-- Map Addon Continent (1=Kal, 2=EK) to Atlas ID (1=EK, 2=Kal)
			if marker.continent == 1 then
				AtlasTWOptions.AtlasType = 2
			else
				AtlasTWOptions.AtlasType = 1
			end

			AtlasTWOptions.AtlasZone = marker.atlasID

			if AtlasTWFrame and not AtlasTWFrame:IsVisible() then
				AtlasTW.ToggleAtlas()
			else
				AtlasTW.Refresh()
			end
		end
	end
end

local function getOrCreateMarker(index)
	if not module.data.markers[index] then
		local marker = CreateFrame("Button", "MapMarkersIcon"..index, WorldMapButton)
		marker:SetWidth(24)
		marker:SetHeight(24)
		marker:SetFrameLevel(WorldMapButton:GetFrameLevel() + 5)

		local tex = marker:CreateTexture(nil, "OVERLAY")
		tex:SetAllPoints(marker)
		marker.texture = tex

		marker:SetScript("OnClick", function() onMarkerClick(this) end)

		marker:SetScript("OnEnter", function()
			WorldMapTooltip:SetOwner(this, "ANCHOR_RIGHT")
			WorldMapTooltip:AddLine(this.name, 1, 0.82, 0)

			if this.description then
				if this.markerType == "DUNGEON" or this.markerType == "RAID" or this.markerType == "WORLDBOSS" then
					WorldMapTooltip:AddLine("Level: " .. this.description, 1, 1, 1, 1)
				elseif this.description == "Alliance" then
					WorldMapTooltip:AddLine(this.description, 0.0, 0.47, 1.0, 1)
				elseif this.description == "Horde" then
					WorldMapTooltip:AddLine(this.description, 1.0, 0.0, 0.0, 1)
				else
					WorldMapTooltip:AddLine(this.description, 1, 1, 1, 1)
				end
			end
			WorldMapTooltip:Show()
		end)

		marker:SetScript("OnLeave", function() WorldMapTooltip:Hide() end)

		module.data.markers[index] = marker
	end
	return module.data.markers[index]
end

local function drawMarker(markerIndex, data, x, y, isContinent)
	local marker = getOrCreateMarker(markerIndex)
	if not marker then return markerIndex end

	-- Sizing
	if data.type == "DUNGEON" or data.type == "RAID" or data.type == "WORLDBOSS" then
		marker:SetWidth(32)
		marker:SetHeight(32)
	elseif data.type == "FLIGHT" then
		marker:SetWidth(16)
		marker:SetHeight(16)
	elseif isContinent and (data.type == "BOAT" or data.type == "ZEPPELIN") then
		marker:SetWidth(16)
		marker:SetHeight(16)
	else
		marker:SetWidth(24)
		marker:SetHeight(24)
	end

	-- Position
	local width  = WorldMapDetailFrame:GetWidth()
	local height = WorldMapDetailFrame:GetHeight()
	marker:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", x * width, -y * height)

	-- Texture
	local tex = module.data.textureMap[data.type] or "Interface\\Minimap\\POIIcons"
	if marker.lastTexture ~= tex then
		marker.texture:SetTexture(tex)
		marker.lastTexture = tex
	end

	-- Metadata
	marker.name        = data.name
	marker.description = data.description
	marker.markerType  = data.type
	marker.atlasID     = data.atlasID
	marker.continent   = data.continent
	marker.zoneName    = data.zoneName

	marker:Show()
	return markerIndex + 1
end

local function refreshMarkers()
	for _, marker in ipairs(module.data.markers) do marker:Hide() end
	if not WorldMapFrame:IsVisible() then return end
	if not VE.isModuleEnabled(module.identifier) then return end

	buildData()

	local currentContinent = GetCurrentMapContinent()
	local currentZone      = GetCurrentMapZone()

	if currentContinent == 0 then return end

	local playerFaction = UnitFactionGroup("player")
	local markerIndex = 1

	if currentZone > 0 then
		-- Zone View
		local zoneNames = module.data.zoneCache[currentContinent]
		local currentZoneName = zoneNames and zoneNames[currentZone]
		if not currentZoneName then return end

		local currentZoneMarkers = module.data.zoneMarkers[currentContinent] and module.data.zoneMarkers[currentContinent][currentZoneName]

		if currentZoneMarkers then
			for _, data in ipairs(currentZoneMarkers) do
				local showMarker = true

				-- Type Filter
				local mType = data.type
				if mType == "FLIGHT" and not module.config.filters.FLIGHT then
					showMarker = false
				elseif (mType == "DUNGEON" or mType == "RAID") and not module.config.filters.DUNGEON then
					showMarker = false
				elseif mType == "WORLDBOSS" and not module.config.filters.WORLDBOSS then
					showMarker = false
				elseif (mType == "BOAT" or mType == "ZEPPELIN" or mType == "TRAM") and not module.config.filters.TRANSPORT then
					showMarker = false
				end

				if showMarker and (mType == "BOAT" or mType == "ZEPPELIN" or mType == "TRAM") then
					if data.description ~= "Neutral" and data.description ~= playerFaction then
						showMarker = false
					end
				end

				if showMarker then
					markerIndex = drawMarker(markerIndex, data, data.x, data.y, false)
				end
			end
		end

	elseif currentZone == 0 and VE_ZoneGeometry then
		-- Continent View
		local continentName = module.data.continentNames[currentContinent]
		local contGeo = VE_ZoneGeometry[continentName]
		local continentMarkers = module.data.zoneMarkers[currentContinent]

		if contGeo and continentMarkers then
			for zoneName, zonePoints in pairs(continentMarkers) do
				local zoneGeo = VE_ZoneGeometry[zoneName]
				if zoneGeo then
					for _, data in ipairs(zonePoints) do
						local showMarker = true

						-- Type Filter
						local mType = data.type
						if mType == "FLIGHT" and not module.config.filters.FLIGHT then
							showMarker = false
						elseif (mType == "DUNGEON" or mType == "RAID") and not module.config.filters.DUNGEON then
							showMarker = false
						elseif mType == "WORLDBOSS" and not module.config.filters.WORLDBOSS then
							showMarker = false
						elseif (mType == "BOAT" or mType == "ZEPPELIN" or mType == "TRAM") and not module.config.filters.TRANSPORT then
							showMarker = false
						end

						if showMarker and (mType == "BOAT" or mType == "ZEPPELIN" or mType == "TRAM") then
							if data.description ~= "Neutral" and data.description ~= playerFaction then
								showMarker = false
							end
						end

						if showMarker then
							-- Translate Coordinates
							-- Zone -> World
							local wx = (data.x - zoneGeo.offset_x) / zoneGeo.scale_x
							local wy = (data.y - zoneGeo.offset_y) / zoneGeo.scale_y

							-- World -> Continent
							local cx = contGeo.offset_x + contGeo.scale_x * wx
							local cy = contGeo.offset_y + contGeo.scale_y * wy

							markerIndex = drawMarker(markerIndex, data, cx, cy, true)
						end
					end
				end
			end
		end
	end
end

local function saveFilters()
	VanillaEnhancedData[module.identifier] = module.config.filters
end

local function createDropdown()
	if module.data.dropdownCreated then return end

	-- Parented to WorldMapButton and set high frame level to ensure clickability
	local filterBtn = CreateFrame("Button", "VE_MapMarkerFilterButton", WorldMapButton, "UIPanelButtonTemplate")
	filterBtn:SetWidth(100)
	filterBtn:SetHeight(24)
	filterBtn:SetText("Map Filters")
	filterBtn:SetFrameLevel(WorldMapButton:GetFrameLevel() + 10)

	if IsAddOnLoaded("pfQuest") then
		filterBtn:SetPoint("TOPRIGHT", WorldMapButton, "TOPRIGHT", -16, -40)
	else
		filterBtn:SetPoint("TOPRIGHT", WorldMapButton, "TOPRIGHT", -16, -12)
	end

	local menuFrame = CreateFrame("Frame", "VE_MapMarkerFilterMenu", filterBtn, "UIDropDownMenuTemplate")

	UIDropDownMenu_Initialize(menuFrame, function()
		local info = {}
		info.keepShownOnClick = 1
		info.isNotRadio = 1

		info.text = "Flight Paths"
		info.checked = module.config.filters.FLIGHT
		info.func = function()
			module.config.filters.FLIGHT = not module.config.filters.FLIGHT
			saveFilters()
			refreshMarkers()
		end
		UIDropDownMenu_AddButton(info)

		info.text = "Dungeons & Raids"
		info.checked = module.config.filters.DUNGEON
		info.func = function() 
			module.config.filters.DUNGEON = not module.config.filters.DUNGEON
			module.config.filters.RAID = module.config.filters.DUNGEON
			saveFilters()
			refreshMarkers()
		end
		UIDropDownMenu_AddButton(info)

		info.text = "World Bosses"
		info.checked = module.config.filters.WORLDBOSS
		info.func = function()
			module.config.filters.WORLDBOSS = not module.config.filters.WORLDBOSS
			saveFilters()
			refreshMarkers()
		end
		UIDropDownMenu_AddButton(info)

		info.text = "Transports"
		info.checked = module.config.filters.TRANSPORT
		info.func = function()
			module.config.filters.TRANSPORT = not module.config.filters.TRANSPORT
			saveFilters()
			refreshMarkers()
		end
		UIDropDownMenu_AddButton(info)
	end, "MENU")

	filterBtn:SetScript("OnClick", function()
		ToggleDropDownMenu(1, nil, menuFrame, "VE_MapMarkerFilterButton", 0, 0)
	end)

	module.data.dropdownCreated = true
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		-- Load saved filters
		if VanillaEnhancedData[module.identifier] then
			for k, v in pairs(VanillaEnhancedData[module.identifier]) do
				module.config.filters[k] = v
			end
		end

		cacheZones()
		buildData()
		createDropdown()

		-- Hook WorldMapFrame_Update
		if not module.data.hooked then
			local original_WorldMapFrame_Update = WorldMapFrame_Update
			WorldMapFrame_Update = function()
				if original_WorldMapFrame_Update then
					original_WorldMapFrame_Update()
				end
				refreshMarkers()
			end
			module.data.hooked = true
		end

		-- Initial refresh
		refreshMarkers()
	end
end)
