local module = VE.registerModule({
	identifier = "NameplateComboPoints",
	meta = {
		label = "Nameplate Combo Points",
		description = "Displays your combo points on the nameplate for quick reference during combat.",
	},
	plug = nil,
	superWoWRequired = true,
	config = {
		comboSize = {
			width = 12,
			height = 16,
		},
	},
	data = {
		initialized = 0,
		parentCount = 0,
		nameplates = {},
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function IsNameplateFrame(frame)
	local overlayRegion = frame:GetRegions()
	if not overlayRegion or overlayRegion:GetObjectType() ~= "Texture" or overlayRegion:GetTexture() ~= "Interface\\Tooltips\\Nameplate-Border" then
		return false
	end
	return true
end

local function GetTargetNameplate()
	local exists, targetGUID = UnitExists("target")
	if not exists then return nil end

	for _, nameplate in pairs(module.data.nameplates) do
		if nameplate:GetName(1) == targetGUID then 
			return nameplate
		end
	end

	return nil
end

local function AttachComboPointsToNameplate()
	local nameplate = GetTargetNameplate()
	if nameplate then
		module.plug.comboPoints:ClearAllPoints()
		module.plug.comboPoints:SetParent(nameplate)
		module.plug.comboPoints:SetPoint("Center", nameplate, "Bottom", 0, -5)
		module.plug.comboPoints:SetAlpha(1)
	end
end

local function DetachComboPointsFromNameplate()
	module.plug.comboPoints:ClearAllPoints()
	module.plug.comboPoints:SetParent(nil)
end

local function ClearComboPoints()
	for i = 1, 5 do
		getglobal("ComboPointsFramePoint" .. tostring(i)):Hide()
	end
end

local function HideComboPoints()
	module.plug.comboPoints:Hide()
end

local function ShowComboFrame()
	module.plug.comboPoints:Show()
end

local function UpdateComboPoints()
	local count = GetComboPoints()
	if count == 0 then
		ClearComboPoints()
		DetachComboPointsFromNameplate()
		HideComboPoints()
		return
	end
	
	for i = 1, count do
		getglobal("ComboPointsFramePoint" .. tostring(i)):Show()
	end
	
	AttachComboPointsToNameplate()
	ShowComboFrame()
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_COMBO_POINTS")
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" and not module.plug.comboPoints then
		local parent = UIParent
		local uiScale = UIParent:GetScale()

		module.plug.comboPoints = CreateFrame("Frame", "ComboPointsFrame", parent)
		module.plug.comboPoints:SetWidth((module.config.comboSize.width * uiScale) * 6.5)
		module.plug.comboPoints:SetHeight(module.config.comboSize.height * uiScale * 5)
		module.plug.comboPoints:Hide()

		module.plug.comboPoints.bg = CreateFrame("Frame", nil, module.plug.comboPoints)
		module.plug.comboPoints.bg:SetAllPoints(module.plug.comboPoints)
		for i = 1, 5 do
			local offset = (i-1) * ((module.config.comboSize.width * uiScale) + 2) + 3
			local bg = module.plug.comboPoints.bg:CreateTexture(nil, "BACKGROUND")
			bg:SetPoint("Left", module.plug.comboPoints.bg, "Left", offset, 0)
			bg:SetWidth(module.config.comboSize.width * uiScale)
			bg:SetHeight(module.config.comboSize.height * uiScale)
			bg:SetTexture("Interface\\ComboFrame\\ComboPoint");
			bg:SetTexCoord(0, 0.375, 0, 1);
		end

		module.plug.comboPoints.points = CreateFrame("Frame", nil, module.plug.comboPoints)
		module.plug.comboPoints.points:SetAllPoints(module.plug.comboPoints)
		module.plug.comboPoints.points:SetFrameLevel(3)
		for i = 1, 5 do
			local offset = (i-1) * ((module.config.comboSize.width * uiScale) + 2) + 6
			local point = module.plug.comboPoints.points:CreateTexture("ComboPointsFramePoint" .. tostring(i), "BACKGROUND")
			point:SetPoint("Left", module.plug.comboPoints.points, "Left", offset, 0)
			point:SetWidth((module.config.comboSize.width * uiScale) - 6)
			point:SetHeight(module.config.comboSize.height * uiScale)
			point:SetTexture("Interface\\ComboFrame\\ComboPoint");
			point:SetTexCoord(0.375,0.5625,0,1)
		end
	end
	
	if event == "PLAYER_COMBO_POINTS" then
		ClearComboPoints()
		UpdateComboPoints()
	end
end)

module.plug:SetScript("OnUpdate", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	module.data.parentCount = WorldFrame:GetNumChildren()
	if module.data.initialized < module.data.parentCount then
		local frames = {WorldFrame:GetChildren()}
		
		for i = module.data.initialized + 1, module.data.parentCount do
			nameplate = frames[i]
			if IsNameplateFrame(nameplate) then
				table.insert(module.data.nameplates, nameplate)
			end
		end
		
		module.data.initialized = module.data.parentCount
	end
end)
