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
		currentOutfitIndex = nil,
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
	UpdateList()
end


local dropdownMenuFrame = nil
local currentOutfitIndex = nil

local function ShowDropdown(button, index)
	currentOutfitIndex = index
	ToggleDropDownMenu(1, nil, dropdownMenuFrame, button, 0, 0)
end

-- UI
local frame = nil
local scrollFrame = nil
local listContent = nil

local function UpdateList()
	if not listContent then return end
	
	if not module.data.buttons then module.data.buttons = {} end
	
	-- Hide and uncheck all known buttons
	for _, btn in ipairs(module.data.buttons) do
		btn:SetChecked(nil)
		btn:Hide()
		if btn.dropdown then btn.dropdown:Hide() end
	end
	
	local height = 0
	for idx, outfit in ipairs(module.data.outfits) do
		local btn = module.data.buttons[idx]
		if not btn then
			local outfitIndex = idx

			btn = CreateFrame("CheckButton", "VE_OutfitItem_" .. outfitIndex, listContent, "UICheckButtonTemplate")
			btn:SetWidth(24)
			btn:SetHeight(24)

			btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			btn.text:SetPoint("LEFT", btn, "RIGHT", 5, 0)
			btn.text:SetJustifyH("LEFT")
			btn.text:SetWidth(110)

			btn.dropdown = CreateFrame("Button", "VE_OutfitDropdown_" .. outfitIndex, btn)
			btn.dropdown:SetWidth(16)
			btn.dropdown:SetHeight(16)
			btn.dropdown:SetPoint("LEFT", btn.text, "RIGHT", 2, 0)
			btn.dropdown:EnableMouse(true)
			btn.dropdown:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
			btn.dropdown:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Highlight")
			btn.dropdown:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
			btn.dropdown:SetScript("OnClick", function()
				ShowDropdown(btn.dropdown, outfitIndex)
			end)
			
			btn:SetScript("OnClick", function()
				local myIndex = this:GetID()
				
				if module.data.selectedIndex == myIndex then
					module.data.selectedIndex = nil
				else
					EquipOutfit(myIndex)
				end
				SaveData()
				UpdateList()
			end)
			module.data.buttons[outfitIndex] = btn
		end
		
		btn:SetID(idx)
		btn:ClearAllPoints()
		btn:SetPoint("TOPLEFT", listContent, "TOPLEFT", 0, -height)
		btn.text:SetText(outfit.name)
		
		if module.data.selectedIndex == idx then
			btn:SetChecked(1)
		else
			btn:SetChecked(nil)
		end
		
		btn:Show()
		btn.dropdown:Show()
		height = height + 20
	end
	
	listContent:SetHeight(height)
end

local function CreateOutfit(name)
	if not name or name == "" then return end
	table.insert(module.data.outfits, {
		name = name,
		gear = GetCurrentGear()
	})
	module.data.selectedIndex = table.getn(module.data.outfits)
	module.data.buttons = {}
	SaveData()
	UpdateList()
end

local function SaveOutfit(index)
	index = index or module.data.selectedIndex
	if not index then
		VE.iprint("Select an outfit first.")
		return
	end
	local outfit = module.data.outfits[index]
	if outfit then
		outfit.gear = GetCurrentGear()
		SaveData()
		VE.print("Outfit '" .. outfit.name .. "' updated with current gear.")
	end
end

local function RenameOutfit(index, newName)
	index = index or module.data.selectedIndex
	if not index or not newName or newName == "" then return end
	local outfit = module.data.outfits[index]
	if outfit then
		outfit.name = newName
		SaveData()
		UpdateList()
	end
end

local function DeleteOutfit(index)
	index = index or module.data.currentOutfitIndex
	if not index then
		VE.iprint("Select an outfit first.")
		return
	end
	table.remove(module.data.outfits, index)
	module.data.selectedIndex = nil
	CloseDropDownMenus()
	SaveData()
	
	if module.data.buttons then
		for _, btn in ipairs(module.data.buttons) do
			btn:Hide()
			if btn.dropdown then btn.dropdown:Hide() end
		end
		wipe(module.data.buttons)
	else
		module.data.buttons = {}
	end
	
	if listContent then
		listContent:SetHeight(10)
	end
	if scrollFrame then
		scrollFrame:SetVerticalScroll(0)
	end
	
	UpdateList()
end

local function CreateUI()
	if frame then return end

	-- Main Frame
	frame = CreateFrame("Frame", "VE_OutfitManagerFrame", PaperDollFrame)
	frame:SetWidth(256)
	frame:SetHeight(350)
	frame:SetPoint("TOPLEFT", PaperDollFrame, "TOPRIGHT", -37, -42)
	frame:SetFrameLevel(PaperDollFrame:GetFrameLevel() - 1)

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\OutfitManager")
	bg:SetTexCoord(0, 1, 0, 350/512)
	
	-- Title
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", frame, "TOP", -5, -7)
	title:SetText("Outfits")
	
	-- Scroll Frame for the list
	scrollFrame = CreateFrame("ScrollFrame", "VE_OutfitManagerScroll", frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -37)
	scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 43)
	scrollFrame:SetClampedToScreen(true)
	scrollFrame:SetFrameLevel(frame:GetFrameLevel() + 1)
	
	listContent = CreateFrame("Frame", "VE_OutfitManagerList", scrollFrame)
	listContent:SetWidth(175)
	listContent:SetHeight(10)
	scrollFrame:SetScrollChild(listContent)
	
	dropdownMenuFrame = CreateFrame("Frame", "VE_OutfitManagerDropdownMenu", frame, "UIDropDownMenuTemplate")
	UIDropDownMenu_Initialize(dropdownMenuFrame, function()
		local index = currentOutfitIndex
		
		local info = {}
		info.text = "Rename"
		info.func = function()
			local outfit = module.data.outfits[index]
			if not outfit then return end
			VE.iprint("Enter new name for outfit: " .. outfit.name)
			module.data.pendingRename = index
		end
		UIDropDownMenu_AddButton(info)
		
		info = {}
		info.text = "Delete"
		info.func = function()
			module.data.currentOutfitIndex = index
			StaticPopup_Show("VE_OUTFIT_DELETE")
		end
		UIDropDownMenu_AddButton(info)
		
		info = {}
		info.text = "Save"
		info.func = function()
			SaveOutfit(index)
		end
		UIDropDownMenu_AddButton(info)
	end, "MENU")
	
	-- New Outfit Button
	local newBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	newBtn:SetWidth(80)
	newBtn:SetHeight(22)
	newBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 13)
	newBtn:SetText("New Outfit")
	newBtn:SetScript("OnClick", function()
		StaticPopup_Show("VE_OUTFIT_NEW")
	end)
	
	-- Popups
	StaticPopupDialogs["VE_OUTFIT_DELETE"] = {
		text = "Are you sure you want to delete this outfit?",
	button1 = "Yes",
	button2 = "No",
		OnAccept = function()
			DeleteOutfit(module.data.currentOutfitIndex)
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
			CreateOutfit(editBox:GetText())
		end,
		EditBoxOnEnterPressed = function()
			CreateOutfit(this:GetText())
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
			RenameOutfit(editBox:GetText())
		end,
		EditBoxOnEnterPressed = function()
			RenameOutfit(this:GetText())
			this:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}

	UpdateList()
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
