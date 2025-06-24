local module = VE.registerModule({
	identifier = "CompactActionBars",
	meta = {
		label = "Compact Action Bars",
		description = "Stacks action bars vertically for a compact, clean layout and hides some of the UI elements.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {},
	data = {
		bars = {
			pivot = nil,
			spacing = 6,
			size = { width = 0, height = 0 },
			main = nil,
			left = nil,
			right = nil,
			bags = nil,
			shapeshift = nil,
			pet = nil,
			bonus = nil,
			exp = nil,
			rep = nil,
		},
		microButtonScale = 0.7,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local print = VE.print
local dprint = VE.dprint
local iprint = VE.iprint

local function Initialize()
	module.data.bars.size.width = MultiBarBottomLeft:GetWidth()
	module.data.bars.size.height = MultiBarBottomLeft:GetHeight()

	module.data.bars.pivot = CreateFrame("Frame", "CompactActionBars", UIParent)
	module.data.bars.pivot:SetWidth(module.data.bars.size.width)
	module.data.bars.pivot:SetHeight((module.data.bars.size.height * 3) + (module.data.bars.spacing * 5))
	module.data.bars.pivot:SetPoint("Center", UIParent, "Bottom", 0, (module.data.bars.size.height * 2))

	module.data.bars.right = CreateFrame("Frame", "CompactActionBarsRight", module.data.bars.pivot)
	module.data.bars.right:SetWidth(module.data.bars.size.width)
	module.data.bars.right:SetHeight(module.data.bars.size.height)
	module.data.bars.right:SetPoint("TopLeft", module.data.bars.pivot, "TopLeft", 0, 0)

	module.data.bars.left = CreateFrame("Frame", "CompactActionBarsLeft", module.data.bars.right)
	module.data.bars.left:SetWidth(module.data.bars.size.width)
	module.data.bars.left:SetHeight(module.data.bars.size.height)
	module.data.bars.left:SetPoint("TopLeft", module.data.bars.right, "TopLeft", 0, -module.data.bars.size.height - module.data.bars.spacing + 2)

	module.data.bars.main = CreateFrame("Frame", "CompactActionBarsMain", module.data.bars.left)
	module.data.bars.main:SetWidth(module.data.bars.size.width)
	module.data.bars.main:SetHeight(module.data.bars.size.height)
	module.data.bars.main:SetPoint("TopLeft", module.data.bars.left, "TopLeft", 0, -module.data.bars.size.height - module.data.bars.spacing + 2)

	module.data.bars.bonus = CreateFrame("Frame", "CompactActionBarsBonus", module.data.bars.left)
	module.data.bars.bonus:SetWidth(module.data.bars.size.width)
	module.data.bars.bonus:SetHeight(module.data.bars.size.height)
	module.data.bars.bonus:SetPoint("TopLeft", module.data.bars.left, "TopLeft", 0, -module.data.bars.size.height - module.data.bars.spacing + 2)

	module.data.bars.shapeshift = CreateFrame("Frame", "CompactActionBarsShapeshift", module.data.bars.right)
	module.data.bars.shapeshift:SetWidth(module.data.bars.size.width)
	module.data.bars.shapeshift:SetHeight(module.data.bars.size.height)
	module.data.bars.shapeshift:SetPoint("BottomLeft", module.data.bars.right, "BottomLeft", -1, module.data.bars.size.height + module.data.bars.spacing + 6)

	module.data.bars.pet = CreateFrame("Frame", "CompactActionBarsPet", module.data.bars.right)
	module.data.bars.pet:SetWidth(module.data.bars.size.width)
	module.data.bars.pet:SetHeight(module.data.bars.size.height)
	module.data.bars.pet:SetPoint("BottomLeft", module.data.bars.right, "BottomLeft", 0, module.data.bars.size.height + module.data.bars.spacing + 6)

	module.data.bars.exp = CreateFrame("Frame", "ExperienceBar", module.data.bars.pivot)
	module.data.bars.exp:SetWidth(module.data.bars.size.width / 2)
	module.data.bars.exp:SetHeight(20)
	module.data.bars.exp:SetPoint("TopLeft", module.data.bars.right, "TopLeft", -2, -126)
	module.data.bars.exp.tex = module.data.bars.exp:CreateTexture("ExperienceBarNormal", "OVERLAY")
	module.data.bars.exp.tex:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder")
	module.data.bars.exp.tex:SetAllPoints(module.data.bars.exp)
	module.data.bars.exp.tex:SetDrawLayer("OVERLAY", 7)

	module.data.bars.rep = CreateFrame("Frame", "ReputationBar", module.data.bars.pivot)
	module.data.bars.rep:SetWidth(module.data.bars.size.width / 2)
	module.data.bars.rep:SetHeight(20)
	module.data.bars.rep:SetPoint("TopRight", module.data.bars.right, "TopRight", -2, -126)
	module.data.bars.rep.tex = module.data.bars.rep:CreateTexture("ReputationBarNormal", "OVERLAY")
	module.data.bars.rep.tex:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder")
	module.data.bars.rep.tex:SetAllPoints(module.data.bars.rep)
	module.data.bars.rep.tex:SetDrawLayer("OVERLAY", 7)
end

local function RepositionMultiBarMain()
	for i = 1, 12 do
		local button = getglobal("ActionButton"..i)
		if button then
			button:ClearAllPoints()

			if i == 1 then
				button:SetPoint("BOTTOMLEFT", module.data.bars.main, "BOTTOMLEFT", 0, 0)
			else
				local prevButton = getglobal("ActionButton"..(i-1))
				button:SetPoint("LEFT", prevButton, "RIGHT", module.data.bars.spacing, 0)
			end
		end
	end

	if ActionBarUpButton and ActionBarDownButton then
		ActionBarUpButton:SetParent(module.data.bars.main)
		ActionBarDownButton:SetParent(module.data.bars.main)
		ActionBarUpButton:ClearAllPoints()
		ActionBarUpButton:SetPoint("BOTTOMRIGHT", ActionButton12, "TOPRIGHT", 30, -25)
		ActionBarDownButton:ClearAllPoints()
		ActionBarDownButton:SetPoint("TOP", ActionBarUpButton, "BOTTOM", 0, 11)
	end

	-- Move main menu bar out of the viewport.
	MainMenuBar:ClearAllPoints()
	MainMenuBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, -100)
end

local function HideMultiBarMain()
	-- Dirty hack to position it out of viewport.
	module.data.bars.main:SetPoint("TopLeft", module.data.bars.left, "TopLeft", 0, -500)
end

local function ShowMultiBarMain()
	module.data.bars.main:SetPoint("TopLeft", module.data.bars.left, "TopLeft", 0, -module.data.bars.size.height - module.data.bars.spacing + 2)
end

local function RepositionMultiBarBottomLeft()
	for i = 1, 12 do
		local button = getglobal("MultiBarBottomLeftButton"..i)
		if button then
			button:ClearAllPoints()
			button:SetFrameStrata("LOW")

			if i == 1 then
				button:SetPoint("BOTTOMLEFT", module.data.bars.left, "BOTTOMLEFT", 0, 0)
			else
				local prevButton = getglobal("MultiBarBottomLeftButton"..(i-1))
				button:SetPoint("LEFT", prevButton, "RIGHT", module.data.bars.spacing, 0)
			end
		end
	end
end

local function RepositionMultiBarBottomRight()
	for i = 1, 12 do
		local button = getglobal("MultiBarBottomRightButton"..i)
		if button then
			button:ClearAllPoints()
			button:SetFrameStrata("LOW")

			if i == 1 then
				button:SetPoint("BOTTOMLEFT", module.data.bars.right, "BOTTOMLEFT", 0, 0)
			else
				local prevButton = getglobal("MultiBarBottomRightButton"..(i-1))
				button:SetPoint("LEFT", prevButton, "RIGHT", module.data.bars.spacing, 0)
			end
		end
	end
end

local function RepositionShapeshiftBar()
	for i = 1, 12 do
		local button = getglobal("ShapeshiftButton"..i)
		if button then
			button:ClearAllPoints()
			button:SetFrameStrata("LOW")

			if i == 1 then
				button:SetPoint("BOTTOMLEFT", module.data.bars.shapeshift, "BOTTOMLEFT", 0, 0)
			else
				local prevButton = getglobal("ShapeshiftButton"..(i-1))
				button:SetPoint("LEFT", prevButton, "RIGHT", module.data.bars.spacing - 2, 0)
			end
		end
	end
end

local function RepositionPetBar()
	for i = 1, 12 do
		local button = getglobal("PetActionButton"..i)
		if button then
			button:ClearAllPoints()
			button:SetFrameStrata("LOW")

			if i == 1 then
				button:SetPoint("BOTTOMLEFT", module.data.bars.pet, "BOTTOMLEFT", 0, 0)
			else
				local prevButton = getglobal("PetActionButton"..(i-1))
				button:SetPoint("LEFT", prevButton, "RIGHT", module.data.bars.spacing - 2, 0)
			end
		end
	end
end

local function RepositionBonusBar()
	for i = 1, 12 do
		local button = getglobal("BonusActionButton"..i)
		if button then
			button:ClearAllPoints()
			button:SetFrameStrata("LOW")

			if i == 1 then
				button:SetPoint("BOTTOMLEFT", module.data.bars.bonus, "BOTTOMLEFT", 0, 0)
			else
				local prevButton = getglobal("BonusActionButton"..(i-1))
				button:SetPoint("LEFT", prevButton, "RIGHT", module.data.bars.spacing, 0)
			end
		end
	end
end

local function RepositionBags()
	if MainMenuBarBackpackButton then
		MainMenuBarBackpackButton:ClearAllPoints()
		MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -6, 6)

		for i = 0, 3 do
			local bag = getglobal("CharacterBag"..i.."Slot")
			if bag then
				bag:ClearAllPoints()
				bag:SetPoint("RIGHT", getglobal(i == 0 and "MainMenuBarBackpackButton" or "CharacterBag"..(i-1).."Slot"), "LEFT", -4, 0)
			end
		end

		if getglobal("MainMenuBarBackpackButtonPortrait") then
			MainMenuBarBackpackButtonPortrait:Hide()
		end
	end
end

local function HideOtherUI()
	-- Hide the micro button Performance.
	if getglobal("MainMenuBarPerformanceBar") then
		MainMenuBarPerformanceBar:Hide()
	end

	if MainMenuExpBar then
		if MainMenuExpBarLeftCap then MainMenuExpBarLeftCap:Hide() end
		if MainMenuExpBarRightCap then MainMenuExpBarRightCap:Hide() end
	end

	local mainBarTextures = {
		"MainMenuBarTexture0",
		"MainMenuBarTexture1",
		"MainMenuBarTexture2",
		"MainMenuBarTexture3",
		"MainMenuBarTexture4",
		"MainMenuBarPageNumber",
		"MainMenuBarMaxLevelBar",
		"MainMenuBarPerformanceBarFrameButton",
		"BonusActionBarTexture0",
		"BonusActionBarTexture1",
	}

	for _, textureName in pairs(mainBarTextures) do
		local texture = getglobal(textureName)
		if texture then
			texture:Hide()
			texture.Show = function() end -- Prevent other addons from showing it
		end
	end

	if MainMenuBarLeftEndCap then MainMenuBarLeftEndCap:Hide() end
	if MainMenuBarRightEndCap then MainMenuBarRightEndCap:Hide() end
end

local function RepositionExperienceBar()
	MainMenuXPBarTexture0:Hide()
	MainMenuXPBarTexture1:Hide()
	MainMenuXPBarTexture2:Hide()
	MainMenuXPBarTexture3:Hide()

	if UnitLevel("player") == 60 then
		module.data.bars.exp:Hide()
		return
	end

	MainMenuExpBar:SetWidth((module.data.bars.size.width / 2) - 10)
	MainMenuExpBar:SetHeight(10)
	MainMenuExpBar:ClearAllPoints()
	MainMenuExpBar:SetPoint("Center", module.data.bars.exp, "Center", 0, 0)
	MainMenuExpBar:SetParent(module.data.bars.exp)
	MainMenuExpBar:SetFrameStrata("MEDIUM")
	MainMenuExpBar:SetFrameLevel(module.data.bars.exp:GetFrameLevel())

	MainMenuBarExpText:SetPoint("Center", MainMenuExpBar, "Center", 0, 10)
	
	local Original_MainMenuExpBar_Update = MainMenuExpBar_Update
	MainMenuExpBar_Update = function()
		Original_MainMenuExpBar_Update()
	end
end

local function RepositionReputationBar()
	ReputationWatchBar:Hide()
	ReputationWatchBar:SetWidth((module.data.bars.size.width / 2) - 10)
	ReputationWatchBar:SetHeight(10)
	ReputationWatchStatusBar:SetAllPoints()

	local Original_ReputationWatchBar_Update = ReputationWatchBar_Update
	ReputationWatchBar:SetScript("OnEvent", function()
		Original_ReputationWatchBar_Update()
		
		ReputationWatchBar:Hide()
		module.data.bars.rep:Hide()
		
		if not GetWatchedFactionInfo() then return end

		module.data.bars.rep:Show()

		ReputationWatchBar:Show()
		ReputationWatchBar:ClearAllPoints()
		ReputationWatchBar:SetPoint("CENTER", module.data.bars.rep, "CENTER", 0, 0)
		ReputationWatchBar:SetParent(module.data.bars.rep)

		ReputationWatchBarTexture0:Hide()
		ReputationWatchBarTexture1:Hide()
		ReputationWatchBarTexture2:Hide()
		ReputationWatchBarTexture3:Hide()

		ReputationXPBarTexture0:Hide()
		ReputationXPBarTexture1:Hide()
		ReputationXPBarTexture2:Hide()
	end)
end

local function RepositionMicroMenu()
    local microButtons = {
        "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
        "QuestLogMicroButton", "SocialsMicroButton", "WorldMapMicroButton",
        "MainMenuMicroButton", "HelpMicroButton",
    }

	local length = table.getn(microButtons)
	local reversedMicroButtons = {}
	for i = 1, length do
		reversedMicroButtons[i] = microButtons[length - i + 1]
	end

	for i, buttonName in pairs(reversedMicroButtons) do
		local button = getglobal(buttonName)
		if button then
			button:SetScale(module.data.microButtonScale)
			button:ClearAllPoints()
			button:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -8 - (button:GetWidth() * i) + button:GetWidth(), 65)
			button.Show = function() end
		end
	end
end
module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("UPDATE_BONUS_ACTIONBAR")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" and not module.data.bars.pivot then
		Initialize()
		RepositionMultiBarMain()
		RepositionMultiBarBottomLeft()
		RepositionMultiBarBottomRight()
		RepositionShapeshiftBar()
		RepositionPetBar()
		RepositionBonusBar()
		RepositionBags()
		RepositionExperienceBar()
		RepositionReputationBar()
		RepositionMicroMenu()
		HideOtherUI()
	end

	if event == "UPDATE_BONUS_ACTIONBAR" then
		if GetBonusBarOffset() > 0 then
			HideMultiBarMain()
		else
			ShowMultiBarMain()
		end
	end
end)
