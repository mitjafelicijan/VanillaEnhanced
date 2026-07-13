local module = VE.registerModule({
	identifier = "WorldMap",
	meta = {
		label = "Windowed World Map",
		description = "Opens the World Map as a movable window instead of fullscreen.",
	},
	plug = nil,
	superWoWRequired = false,
})

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

local function ApplyWindowedLayout()
	UIPanelWindows["WorldMapFrame"].area = "center"

	local alreadyInSpecial = nil
	for _, name in ipairs(UISpecialFrames) do
		if name == "WorldMapFrame" then alreadyInSpecial = true; break end
	end
	if not alreadyInSpecial then
		tinsert(UISpecialFrames, "WorldMapFrame")
	end

	WorldMapFrame:SetScale(0.7)

	WorldMapFrame:SetParent(UIParent)
	WorldMapFrame:EnableKeyboard(false)
	WorldMapFrame:SetHeight(688)
	WorldMapFrame:SetWidth(1002)
	WorldMapFrame:SetFrameLevel(0)

	WorldMapFrame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	WorldMapFrame:SetBackdropColor(0, 0, 0, 0.8)

	WorldMapFrame:SetMovable(true)
	WorldMapFrame:RegisterForDrag("LeftButton")
	WorldMapFrame:SetScript("OnDragStart", function() WorldMapFrame:StartMoving() end)
	WorldMapFrame:SetScript("OnDragStop", function() WorldMapFrame:StopMovingOrSizing() end)
	WorldMapFrame:SetClampedToScreen(true)

	WorldMapPositioningGuide:ClearAllPoints()
	WorldMapPositioningGuide:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 0, 0)
	WorldMapPositioningGuide:SetPoint("BOTTOMRIGHT", WorldMapFrame, "BOTTOMRIGHT", 0, 0)

	WorldMapDetailFrame:SetScale(1.0)
	WorldMapDetailFrame:SetPoint("TOPLEFT", 0, -20)

	WorldMapButton:SetScale(1.0)

	WorldMapTooltip:SetFrameStrata("TOOLTIP")

	if WorldMapFrameTitle then
		WorldMapFrameTitle:ClearAllPoints()
		WorldMapFrameTitle:SetPoint("TOP", WorldMapFrame, 0, -3)
		if WorldMapFrameTitle.EnableMouse then
			WorldMapFrameTitle:EnableMouse(false)
		end
	end

	BlackoutWorld:Hide()

	for i = 1, 14 do
		local texture = getglobal("WorldMapFrameTexture" .. i)
		if texture then
			texture:Hide()
			texture:SetAlpha(0)
		end
	end

	WorldMapContinentDropDown:SetAlpha(0)
	if WorldMapContinentDropDownButton then
		WorldMapContinentDropDownButton:EnableMouse(0)
	end
	WorldMapZoneDropDown:SetAlpha(0)
	if WorldMapZoneDropDownButton then
		WorldMapZoneDropDownButton:EnableMouse(0)
	end
	WorldMapZoomOutButton:Hide()
	if WorldMapMagnifyingGlassButton then
		WorldMapMagnifyingGlassButton:Hide()
	end
	if WorldMapFrameMinimizeButton then
		WorldMapFrameMinimizeButton:Hide()
	end
	if WorldMapFrameMaximizeButton then
		WorldMapFrameMaximizeButton:Hide()
	end

	if WorldMapFrameCloseButton then
		WorldMapFrameCloseButton:ClearAllPoints()
		WorldMapFrameCloseButton:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", 15, 44)
		WorldMapFrameCloseButton:SetFrameLevel(110)
	end

	-- Create a drag region at the top of the frame since the map content steals clicks.
	if not WorldMapFrame.dragRegion then
		WorldMapFrame.dragRegion = CreateFrame("Button", nil, WorldMapFrame)
		WorldMapFrame.dragRegion:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 0, 0)
		WorldMapFrame.dragRegion:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", 0, 0)
		WorldMapFrame.dragRegion:SetHeight(44)
		WorldMapFrame.dragRegion:SetFrameStrata("HIGH")
		WorldMapFrame.dragRegion:SetFrameLevel(100)
		WorldMapFrame.dragRegion:EnableMouse(true)
		WorldMapFrame.dragRegion:RegisterForDrag("LeftButton")
		WorldMapFrame.dragRegion:SetScript("OnDragStart", function() this:GetParent():StartMoving() end)
		WorldMapFrame.dragRegion:SetScript("OnDragStop", function() 
			this:GetParent():StopMovingOrSizing() 
			
			if not VanillaEnhancedData[module.identifier] then
				VanillaEnhancedData[module.identifier] = {}
			end
			local point, relativeTo, relativePoint, xOfs, yOfs = this:GetParent():GetPoint()
			VanillaEnhancedData[module.identifier].point = point
			VanillaEnhancedData[module.identifier].relativePoint = relativePoint
			VanillaEnhancedData[module.identifier].xOfs = xOfs
			VanillaEnhancedData[module.identifier].yOfs = yOfs
		end)
	end

	WorldMapFrame:ClearAllPoints()
	local pos = VanillaEnhancedData[module.identifier]
	if pos and pos.xOfs and pos.yOfs then
		WorldMapFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
	else
		WorldMapFrame:SetPoint("CENTER", UIParent, 0, 20)
	end
end

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		local origToggleWorldMap = ToggleWorldMap
		ToggleWorldMap = function()
			if not WorldMapFrame:IsVisible() then
				UIPanelWindows["WorldMapFrame"].area = "center"
				origToggleWorldMap()
			else
				origToggleWorldMap()
			end
		end

		local origOnShow = WorldMapFrame:GetScript("OnShow")
		WorldMapFrame:SetScript("OnShow", function()
			if origOnShow then
				origOnShow()
			end
			ApplyWindowedLayout()
		end)

		local origWorldMapFrameUpdate = WorldMapFrame_Update
		WorldMapFrame_Update = function()
			if origWorldMapFrameUpdate then
				origWorldMapFrameUpdate()
			end

			if VE.isModuleEnabled(module.identifier) then
				for i = 1, 14 do
					local texture = getglobal("WorldMapFrameTexture" .. i)
					if texture then
						texture:Hide()
						texture:SetAlpha(0)
					end
				end

				WorldMapContinentDropDown:SetAlpha(0)
				WorldMapZoneDropDown:SetAlpha(0)
				WorldMapZoomOutButton:Hide()
				if WorldMapMagnifyingGlassButton then
					WorldMapMagnifyingGlassButton:Hide()
				end

				if WorldMapFrameCloseButton then
					WorldMapFrameCloseButton:ClearAllPoints()
					WorldMapFrameCloseButton:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", 15, 44)
					WorldMapFrameCloseButton:SetFrameLevel(110)
				end
			end
		end
	end
end)
