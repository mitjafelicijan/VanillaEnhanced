local module = VE.registerModule({
	identifier = "OutfitManager",
	meta = {
		label = "Outfit Manager",
		description = "Manage and swap gear sets.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {},
	data = {
		outfits = {},
		selectedIndex = nil,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local INV_SLOTS = {
	{ name = "HeadSlot", slot = 1 },
	{ name = "NeckSlot", slot = 2 },
	{ name = "ShoulderSlot", slot = 3 },
	{ name = "ShirtSlot", slot = 4 },
	{ name = "ChestSlot", slot = 5 },
	{ name = "WaistSlot", slot = 6 },
	{ name = "LegsSlot", slot = 7 },
	{ name = "FeetSlot", slot = 8 },
	{ name = "WristSlot", slot = 9 },
	{ name = "HandsSlot", slot = 10 },
	{ name = "Finger0Slot", slot = 11 },
	{ name = "Finger1Slot", slot = 12 },
	{ name = "Trinket0Slot", slot = 13 },
	{ name = "Trinket1Slot", slot = 14 },
	{ name = "BackSlot", slot = 15 },
	{ name = "MainHandSlot", slot = 16 },
	{ name = "SecondaryHandSlot", slot = 17 },
	{ name = "RangedSlot", slot = 18 },
	{ name = "TabardSlot", slot = 19 },
}

local function SaveData()
	if not VanillaEnhancedData[module.identifier] then
		VanillaEnhancedData[module.identifier] = {}
	end
	VanillaEnhancedData[module.identifier].outfits = module.data.outfits
	VanillaEnhancedData[module.identifier].selectedIndex = module.data.selectedIndex
end

local function LoadData()
	if VanillaEnhancedData[module.identifier] then
		if VanillaEnhancedData[module.identifier].outfits then
			module.data.outfits = VanillaEnhancedData[module.identifier].outfits
		end
		if VanillaEnhancedData[module.identifier].selectedIndex then
			module.data.selectedIndex = VanillaEnhancedData[module.identifier].selectedIndex
		end
	end
end

local function GetCurrentGear()
	local gear = {}
	for _, info in ipairs(INV_SLOTS) do
		local link = GetInventoryItemLink("player", info.slot)
		if link then
			gear[info.slot] = link
		end
	end
	return gear
end

local function FindItemLocation(targetLink)
	-- Check Bags 0-4
	for bag = 0, 4 do
		local numSlots = GetContainerNumSlots(bag)
		if numSlots and numSlots > 0 then
			for slot = 1, numSlots do
				local link = GetContainerItemLink(bag, slot)
				if link == targetLink then
					return bag, slot
				end
			end
		end
	end
	
	-- Check Bank if open
	if BankFrame and BankFrame:IsVisible() then
		-- Main Bank
		local numBankSlots = GetContainerNumSlots(-1)
		if numBankSlots and numBankSlots > 0 then
			for slot = 1, numBankSlots do
				local link = GetContainerItemLink(-1, slot)
				if link == targetLink then
					return -1, slot
				end
			end
		end

		-- Bank Bags 5-10
		for bag = 5, 10 do
			local numSlots = GetContainerNumSlots(bag)
			if numSlots and numSlots > 0 then
				for slot = 1, numSlots do
					local link = GetContainerItemLink(bag, slot)
					if link == targetLink then
						return bag, slot
					end
				end
			end
		end
	end
	
	return nil, nil
end

local function EquipOutfit(index)
	local outfit = module.data.outfits[index]
	if not outfit then return end
	
	VE.print("Equipping outfit: " .. outfit.name)
	for _, info in ipairs(INV_SLOTS) do
		local desiredLink = outfit.gear[info.slot]
		if desiredLink then
			VE.print(" - " .. desiredLink)
		end
	end

	for _, info in ipairs(INV_SLOTS) do
		local desiredLink = outfit.gear[info.slot]
		local currentLink = GetInventoryItemLink("player", info.slot)
		
		if desiredLink ~= currentLink then
			if desiredLink then
				local bag, slot = FindItemLocation(desiredLink)
				if bag and slot then
					PickupContainerItem(bag, slot)
					PickupInventoryItem(info.slot)
					-- Put the old item back into the bag if it was swapped
					if CursorHasItem() then
						PickupContainerItem(bag, slot)
					end
				else
					VE.iprint("Item not found: " .. desiredLink)
				end
			end
		end
	end
	module.data.selectedIndex = index
	SaveData()
	module.UpdateList()
end

function module.CreateOutfit(name)
	if not name or name == "" then return end
	table.insert(module.data.outfits, {
		name = name,
		gear = GetCurrentGear()
	})
	module.data.selectedIndex = table.getn(module.data.outfits)
	SaveData()
	module.UpdateList()
end

function module.SaveOutfit()
	if not module.data.selectedIndex then
		VE.iprint("Select an outfit first.")
		return
	end
	local outfit = module.data.outfits[module.data.selectedIndex]
	if outfit then
		outfit.gear = GetCurrentGear()
		SaveData()
		VE.print("Outfit '" .. outfit.name .. "' updated with current gear.")
	end
end

function module.RenameOutfit(newName)
	if not module.data.selectedIndex or not newName or newName == "" then return end
	local outfit = module.data.outfits[module.data.selectedIndex]
	if outfit then
		outfit.name = newName
		SaveData()
		module.UpdateList()
	end
end

function module.DeleteOutfit()
	if not module.data.selectedIndex then
		VE.iprint("Select an outfit first.")
		return
	end
	table.remove(module.data.outfits, module.data.selectedIndex)
	module.data.selectedIndex = nil
	SaveData()
	module.UpdateList()
end

-- UI
local frame = nil
local scrollFrame = nil
local listContent = nil

function module.UpdateList()
	if not listContent then return end
	
	if not module.data.buttons then module.data.buttons = {} end
	
	-- Hide and uncheck all known buttons
	for _, btn in ipairs(module.data.buttons) do
		btn:SetChecked(nil)
		btn:Hide()
	end
	
	local height = 0
	for idx, outfit in ipairs(module.data.outfits) do
		local btn = module.data.buttons[idx]
		if not btn then
			btn = CreateFrame("CheckButton", "VE_OutfitItem_" .. idx, listContent, "UICheckButtonTemplate")
			btn:SetWidth(24)
			btn:SetHeight(24)
			
			btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			btn.text:SetPoint("LEFT", btn, "RIGHT", 5, 0)
			btn.text:SetJustifyH("LEFT")
			btn.text:SetWidth(130)
			
			btn:SetScript("OnClick", function()
				-- In Vanilla, 'this' refers to the button clicked.
				-- We need to know which index this button represents.
				-- Since we map buttons 1:1 to indices, we can store the index on the button.
				local myIndex = this:GetID()
				
				if module.data.selectedIndex == myIndex then
					-- Toggle off if clicking the same one
					module.data.selectedIndex = nil
				else
					EquipOutfit(myIndex)
				end
				SaveData()
				module.UpdateList()
			end)
			module.data.buttons[idx] = btn
		end
		
		btn:SetID(idx) -- Ensure the button knows its current index
		btn:ClearAllPoints()
		btn:SetPoint("TOPLEFT", listContent, "TOPLEFT", 5, -height)
		btn.text:SetText(outfit.name)
		
		-- Set the checked state correctly
		if module.data.selectedIndex == idx then
			btn:SetChecked(1)
		else
			btn:SetChecked(nil)
		end
		
		btn:Show()
		height = height + 24
	end
	
	listContent:SetHeight(height)
end

local function CreateUI()
	if frame then return end

	-- Main Frame
	frame = CreateFrame("Frame", "VE_OutfitManagerFrame", PaperDollFrame)
	frame:SetWidth(200)
	frame:SetHeight(320)
	-- Positioned next to the character paperdoll, slightly overlapping the edge for a docked look
	frame:SetPoint("TOPLEFT", PaperDollFrame, "TOPRIGHT", -32, -12)
	
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 }
	})
	
	-- Title
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", frame, "TOP", 0, -15)
	title:SetText("Outfit Manager")
	
	-- Scroll Frame for the list
	scrollFrame = CreateFrame("ScrollFrame", "VE_OutfitManagerScroll", frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -40)
	scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 75)
	
	listContent = CreateFrame("Frame", "VE_OutfitManagerList", scrollFrame)
	listContent:SetWidth(150)
	listContent:SetHeight(10)
	scrollFrame:SetScrollChild(listContent)
	
	-- Control Buttons
	local saveBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	saveBtn:SetWidth(80)
	saveBtn:SetHeight(22)
	saveBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 40)
	saveBtn:SetText("Save")
	saveBtn:SetScript("OnClick", function()
		module.SaveOutfit()
	end)
	
	local renameBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	renameBtn:SetWidth(80)
	renameBtn:SetHeight(22)
	renameBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 40)
	renameBtn:SetText("Rename")
	renameBtn:SetScript("OnClick", function()
		if module.data.selectedIndex then
			local outfit = module.data.outfits[module.data.selectedIndex]
			local dialog = StaticPopup_Show("VE_OUTFIT_RENAME")
			if dialog and outfit then
				local editBox = getglobal(dialog:GetName().."EditBox")
				editBox:SetText(outfit.name)
				editBox:HighlightText()
			end
		else
			VE.iprint("Select an outfit first.")
		end
	end)
	
	local newBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	newBtn:SetWidth(80)
	newBtn:SetHeight(22)
	newBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 15)
	newBtn:SetText("New Outfit")
	newBtn:SetScript("OnClick", function()
		StaticPopup_Show("VE_OUTFIT_NEW")
	end)
	
	local deleteBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	deleteBtn:SetWidth(80)
	deleteBtn:SetHeight(22)
	deleteBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 15)
	deleteBtn:SetText("Delete")
	deleteBtn:SetScript("OnClick", function()
		if module.data.selectedIndex then
			StaticPopup_Show("VE_OUTFIT_DELETE")
		else
			VE.iprint("Select an outfit first.")
		end
	end)
	
	-- Popups
	StaticPopupDialogs["VE_OUTFIT_DELETE"] = {
		text = "Are you sure you want to delete this outfit?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function()
			module.DeleteOutfit()
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}

	StaticPopupDialogs["VE_OUTFIT_NEW"] = {
		text = "Enter name for new outfit:",
		button1 = "Accept",
		button2 = "Cancel",
		hasEditBox = 1,
		maxLetters = 32,
		OnAccept = function()
			local editBox = getglobal(this:GetParent():GetName().."EditBox")
			module.CreateOutfit(editBox:GetText())
		end,
		EditBoxOnEnterPressed = function()
			module.CreateOutfit(this:GetText())
			this:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}

	StaticPopupDialogs["VE_OUTFIT_RENAME"] = {
		text = "Enter new name:",
		button1 = "Accept",
		button2 = "Cancel",
		hasEditBox = 1,
		maxLetters = 32,
		OnAccept = function()
			local editBox = getglobal(this:GetParent():GetName().."EditBox")
			module.RenameOutfit(editBox:GetText())
		end,
		EditBoxOnEnterPressed = function()
			module.RenameOutfit(this:GetText())
			this:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}

	module.UpdateList()
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	
	if event == "PLAYER_ENTERING_WORLD" then
		LoadData()
		CreateUI()
	end
end)
