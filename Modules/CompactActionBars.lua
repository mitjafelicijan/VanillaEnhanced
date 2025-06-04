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
		}
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
	module.data.bars.pivot:SetHeight((module.data.bars.size.height * 3) + (module.data.bars.spacing * 2))
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
	local microButtons = {
		"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
		"QuestLogMicroButton", "SocialsMicroButton", "WorldMapMicroButton",
		"MainMenuMicroButton", "HelpMicroButton"
	}

	for _, buttonName in pairs(microButtons) do
		local button = getglobal(buttonName)
		if button then
			button:Hide()
			button.Show = function() end
		end
	end

	-- Hide the micro button background
	if getglobal("MainMenuBarPerformanceBar") then
		MainMenuBarPerformanceBar:Hide()
	end

	if MainMenuExpBar then
		MainMenuExpBar:Hide()
		MainMenuExpBar.Show = function() end
		if MainMenuExpBarLeftCap then MainMenuExpBarLeftCap:Hide() end
		if MainMenuExpBarRightCap then MainMenuExpBarRightCap:Hide() end
	end

	ReputationWatchBar:SetScript("OnEvent", function()
		this:SetParent(UIParent)
		this:Hide()
	end)

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
