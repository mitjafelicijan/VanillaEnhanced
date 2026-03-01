local module = VE.registerModule({
	identifier = "MapMarkers",
	meta = {
		label = "Map Markers",
		description = "Adds markers for dungeons, raids, transport, and world bosses to the World Map.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {},
	data = {
		markers = {},
		zoneMarkers = {},
		zoneCache = {},
		dataBuilt = false,
		hooked = false,
		textureMap = {
			DUNGEON   = "Interface\\AddOns\\VanillaEnhanced\\Assets\\dungeon",
			RAID      = "Interface\\AddOns\\VanillaEnhanced\\Assets\\raid",
			BOAT      = "Interface\\AddOns\\VanillaEnhanced\\Assets\\boat",
			ZEPPELIN  = "Interface\\AddOns\\VanillaEnhanced\\Assets\\zepp",
			TRAM      = "Interface\\AddOns\\VanillaEnhanced\\Assets\\tram",
			WORLDBOSS = "Interface\\AddOns\\VanillaEnhanced\\Assets\\worldboss",
		}
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local CONTINENT_NAMES = {
	[1] = "Kalimdor",
	[2] = "Eastern Kingdoms"
}

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

local function drawMarker(markerIndex, data, x, y)
	local marker = getOrCreateMarker(markerIndex)
	if not marker then return markerIndex end

	-- Sizing
	if data.type == "DUNGEON" or data.type == "RAID" or data.type == "WORLDBOSS" then
		marker:SetWidth(32)
		marker:SetHeight(32)
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
				if (data.type == "BOAT" or data.type == "ZEPPELIN" or data.type == "TRAM") then
					if data.description ~= "Neutral" and data.description ~= playerFaction then
						showMarker = false
					end
				end

				if showMarker then
					markerIndex = drawMarker(markerIndex, data, data.x, data.y)
				end
			end
		end

	elseif currentZone == 0 and VE_ZoneGeometry then
		-- Continent View
		local continentName = CONTINENT_NAMES[currentContinent]
		local contGeo = VE_ZoneGeometry[continentName]
		local continentMarkers = module.data.zoneMarkers[currentContinent]

		if contGeo and continentMarkers then
			for zoneName, zonePoints in pairs(continentMarkers) do
				local zoneGeo = VE_ZoneGeometry[zoneName]
				if zoneGeo then
					for _, data in ipairs(zonePoints) do
						local showMarker = true
						if (data.type == "BOAT" or data.type == "ZEPPELIN" or data.type == "TRAM") then
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

							markerIndex = drawMarker(markerIndex, data, cx, cy)
						end
					end
				end
			end
		end
	end
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		cacheZones()
		buildData()

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
