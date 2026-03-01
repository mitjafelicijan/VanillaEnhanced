local module = VE.registerModule({
	identifier = "AuctionEnhancements",
	meta = {
		label = "Auction Enhancements",
		description = "Adds new post form to the auction house, and a new tab for viewing items in your bags.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		BidMultiplier = 1.5,
		BuyoutMultiplier = 2.5,
	},
	data = {
		AuctionFrameTab_OnClick = nil,
		sniffTooltip = nil,
		tabIndex = 0,
		bagItems = nil,
		selectedRecord = nil,
		stackSize = 1,
		stackCount = 1,
		duration = 1440, -- Default to 72 hours (1440 minutes)
		startPrice = 0,
		buyoutPrice = 0,
		isScanning = false,
		scanPage = 0,
		-- Posting state
		isPosting = false,
		postedCount = 0,
		remainingStacks = 0,
		isWaitingForBag = false,
		lastBagUpdate = 0,
	},
})

local print = VE.print

local function MoneyStringToCopper(text)
	if not text or text == "" then return 0 end
	local _, _, gold = string.find(text, "(%d+)g")
	local _, _, silver = string.find(text, "(%d+)s")
	local _, _, copper = string.find(text, "(%d+)c")

	gold = tonumber(gold) or 0
	silver = tonumber(silver) or 0
	copper = tonumber(copper) or 0

	-- If it's just a number, assume it's copper? Or gold? 
	-- Let's try to match "1g 2s 3c" or just "12345"
	if gold == 0 and silver == 0 and copper == 0 then
		local num = tonumber(text)
		if num then return num end
	end

	return (gold * 100 * 100) + (silver * 100) + copper
end

local function CopperToMoneyString(money)
	local gold = floor(money / 10000)
	local silver = floor(mod(money, 10000) / 100)
	local copper = mod(money, 100)

	if gold > 0 then
		return string.format("%dg %02ds %02dc", gold, silver, copper)
	elseif silver > 0 then
		return string.format("%ds %02dc", silver, copper)
	else
		return string.format("%dc", copper)
	end
end

local function CopperToColoredMoneyString(money)
	local gold = floor(money / 10000)
	local silver = floor(mod(money, 10000) / 100)
	local copper = mod(money, 100)

	if gold > 0 then
		return string.format("%d|cffffd700g|r %02d|cffc7c7cfs|r %02d|cffeda55fc|r", gold, silver, copper)
	elseif silver > 0 then
		return string.format("%d|cffc7c7cfs|r %02d|cffeda55fc|r", silver, copper)
	else
		return string.format("%d|cffeda55fc|r", copper)
	end
end

local function ParseItemLink(itemLink)
	local _, _, itemString = string.find(itemLink, "(item:[^|]+)")
	if not itemString then
		return nil, 0
	end

	local parts = VE.split(itemString, ":")

	local itemID = tonumber(parts[2])
	-- 1.12 item link: item:itemID:enchantID:suffixID:uniqueID
	-- parts: 1:item, 2:itemID, 3:enchantID, 4:suffixID, 5:uniqueID
	local suffixID = tonumber(parts[4]) or 0
	return itemID, suffixID
end

local function InitializePriceSniffer()
	if not VanillaEnhancedData.vendorPrices then
		VanillaEnhancedData.vendorPrices = {}
	end
	if not VanillaEnhancedData.auctionPrices then
		VanillaEnhancedData.auctionPrices = {}
	end

	-- Create a hidden tooltip for price sniffing if not exists
	if not module.data.priceSniffer then
		module.data.priceSniffer = CreateFrame("GameTooltip", "VEPriceSnifferTooltip", UIParent, "GameTooltipTemplate")
		module.data.priceSniffer:SetOwner(UIParent, "ANCHOR_NONE")
		module.data.priceSniffer:SetScript("OnTooltipAddMoney", function()
			if module.data.lastSniffedID and VanillaEnhancedData and VanillaEnhancedData.vendorPrices then
				VanillaEnhancedData.vendorPrices[tostring(module.data.lastSniffedID)] = arg1
			end
		end)
	end
end

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function UpdateUIState()
	local frame = AuctionEnhancementsFormFrame
	if not frame or not frame.initialized then return end

	local isPosting = module.data.isPosting
	local hasSelection = module.data.selectedRecord ~= nil

	if isPosting then
		if AuctionEnhancementsActionsFrameScan then AuctionEnhancementsActionsFrameScan:Disable() end
		-- Post button remains enabled to allow "Stop"
		if AuctionEnhancementsActionsFramePost then AuctionEnhancementsActionsFramePost:Enable() end
	else
		if AuctionEnhancementsActionsFrameScan then 
			if hasSelection then 
				AuctionEnhancementsActionsFrameScan:Enable() 
			else
				AuctionEnhancementsActionsFrameScan:Disable()
			end
		end
		if AuctionEnhancementsActionsFramePost then
			if hasSelection then
				AuctionEnhancementsActionsFramePost:Enable()
			else
				AuctionEnhancementsActionsFramePost:Disable()
			end
		end
	end
end

local function StopPosting(message)
	if message then
		VE.print("|cff00ff00[Auction] " .. message .. "|r")
	end
	module.data.isPosting = false
	module.data.remainingStacks = 0
	module.data.isWaitingForBag = false
	module.data.isWaitingForAuctionSlot = false
	if AuctionEnhancementsActionsFramePost then
		AuctionEnhancementsActionsFramePost:SetText("Post")
		AuctionEnhancementsActionsFramePost:Enable()
	end
	UpdateUIState()
end

local function FindEmptySlot()
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			if not GetContainerItemLink(bag, slot) then
				return bag, slot
			end
		end
	end
	return nil
end

local function FindExactStack(itemID, suffixID, count)
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemLink = GetContainerItemLink(bag, slot)
			if itemLink then
				local id, sfx = ParseItemLink(itemLink)
				if id == itemID and sfx == suffixID then
					local _, stackSize, locked = GetContainerItemInfo(bag, slot)
					if stackSize == count and not locked then
						return bag, slot
					end
				end
			end
		end
	end
	return nil
end

local function FindLargerStack(itemID, suffixID, minCount)
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemLink = GetContainerItemLink(bag, slot)
			if itemLink then
				local id, sfx = ParseItemLink(itemLink)
				if id == itemID and sfx == suffixID then
					local _, stackSize, locked = GetContainerItemInfo(bag, slot)
					if stackSize > minCount and not locked then
						return bag, slot
					end
				end
			end
		end
	end
	return nil
end

local function EnsureAuctionSlotEmpty()
	local name = GetAuctionSellItemInfo()
	if name then
		ClearCursor()
		ClickAuctionSellItemButton()
		ClearCursor()
	end
end

local function PostNext()
	if not module.data.isPosting then return end
	if module.data.remainingStacks <= 0 then
		StopPosting("Finished posting all auctions.")
		return
	end

	local record = module.data.selectedRecord
	if not record then 
		StopPosting("No item selected.")
		return 
	end

	local stackSize = module.data.stackSize
	local startPrice = module.data.startPrice
	local buyoutPrice = module.data.buyoutPrice
	local duration = module.data.duration

	if (startPrice * stackSize) <= 0 then
		StopPosting("Error: Start price must be greater than 0.")
		return
	end

	if buyoutPrice > 0 and buyoutPrice < startPrice then
		StopPosting("Error: Buyout price cannot be less than starting price.")
		return
	end

	-- Ensure cursor is empty before doing anything
	if CursorHasItem() then
		ClearCursor()
		VE.executeWithDelay(0.1, PostNext)
		return
	end

	-- 1. Check if we have items that are currently locked (waiting for split/post)
	for b = 0, 4 do
		for s = 1, GetContainerNumSlots(b) do
			local itemLink = GetContainerItemLink(b, s)
			if itemLink then
				local id, sfx = ParseItemLink(itemLink)
				if id == record.ID and sfx == record.suffixID then
					local _, _, locked = GetContainerItemInfo(b, s)
					if locked then
						-- Wait until items are unlocked
						VE.executeWithDelay(0.1, PostNext)
						return
					end
				end
			end
		end
	end

	-- 2. Try to find an exact stack
	local bag, slot = FindExactStack(record.ID, record.suffixID, stackSize)

	if bag and slot then
		module.data.isWaitingForBag = false

		-- Exact sequence used by standard addons (Aux) to ensure item is placed correctly
		ClearCursor()
		ClickAuctionSellItemButton()
		ClearCursor()
		
		local wasVisible = true
		if AuctionFrameAuctions and not AuctionFrameAuctions:IsVisible() then
			wasVisible = false
			AuctionFrameAuctions:Show()
		end

		PickupContainerItem(bag, slot)
		ClickAuctionSellItemButton()
		ClearCursor()

		if not wasVisible and AuctionFrameAuctions then
			AuctionFrameAuctions:Hide()
		end

		-- Verify item is actually in the slot before starting the auction
		local _, _, count = GetAuctionSellItemInfo()
		if count ~= stackSize then
			-- It failed to drop into the slot! The client might be busy or desyncing.
			-- Clear the cursor just in case the item is stuck on it.
			ClearCursor()
			module.data.postRetries = (module.data.postRetries or 0) + 1
			if module.data.postRetries < 5 then
				VE.executeWithDelay(0.3, PostNext)
				return
			end
			StopPosting("Script Error: Failed to place item in the auction slot. The UI frame might be blocking it.")
			return
		end

		-- Reset retries on successful placement
		module.data.postRetries = 0

		-- Determine native duration code (1=2h/6h, 2=8h/24h, 3=24h/72h depending on patch)
		local durationCode = 3
		if duration == 120 then durationCode = 1 end
		if duration == 480 then durationCode = 2 end
		if duration == 1440 then durationCode = 3 end

		-- Sync native UI variables just in case the client reads them instead of our StartAuction arguments
		if AuctionFrameAuctions then
			AuctionFrameAuctions.duration = durationCode
			if not AuctionFrameAuctions.page then
				AuctionFrameAuctions.page = 0
			end
		end
		if StartPrice then
			MoneyInputFrame_SetCopper(StartPrice, startPrice * stackSize)
		end
		if BuyoutPrice then
			MoneyInputFrame_SetCopper(BuyoutPrice, buyoutPrice * stackSize)
		end

		-- Create the auction immediately!
		StartAuction(startPrice * stackSize, buyoutPrice * stackSize, duration)

		module.data.remainingStacks = module.data.remainingStacks - 1
		module.data.postedCount = module.data.postedCount + 1

		if AuctionEnhancementsActionsFramePost then
			AuctionEnhancementsActionsFramePost:SetText(string.format("Stop (%d)", module.data.remainingStacks))
		end
		
		-- The CHAT_MSG_SYSTEM event (ERR_AUCTION_STARTED) will trigger the next PostNext() call.
		return
	end

	-- 3. No exact stack, try to split a larger one
	local largeBag, largeSlot = FindLargerStack(record.ID, record.suffixID, stackSize)
	if largeBag and largeSlot then
		local emptyBag, emptySlot = FindEmptySlot()
		if emptyBag and emptySlot then
			module.data.isWaitingForBag = true
			module.data.postRetries = 0 -- Reset retries on successful action
			ClearCursor()
			SplitContainerItem(largeBag, largeSlot, stackSize)
			PickupContainerItem(emptyBag, emptySlot)
			
			-- Wait for the split to complete (the items will become locked, then unlocked)
			-- BAG_UPDATE will trigger PostNext once they unlock.
			return
		else
			StopPosting("No empty bag slots to split stacks.")
			return
		end
	end

	-- If we get here, no items were found. It's possible the bag is just desyncing and we need a moment.
	module.data.postRetries = (module.data.postRetries or 0) + 1
	if module.data.postRetries < 5 then
		VE.executeWithDelay(0.3, PostNext)
		return
	end

	StopPosting("Script Error: Could not find any more items in bags. Note: Auto-stacking is not currently supported.")
end

local function PostAuction()
	if module.data.isPosting then
		StopPosting("Posting cancelled.")
		return
	end
	ClearCursor()
	ClickAuctionSellItemButton()
	ClearCursor()

	local record = module.data.selectedRecord
	if not record then return end

	if module.data.stackSize <= 0 or module.data.stackCount <= 0 then return end

	module.data.isPosting = true
	module.data.remainingStacks = module.data.stackCount
	module.data.postedCount = 0

	if AuctionEnhancementsActionsFramePost then
		AuctionEnhancementsActionsFramePost:SetText(string.format("Stop (%d)", module.data.remainingStacks))
	end

	UpdateUIState()
	PostNext()
end

local function ScanBagPrices()
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemLink = GetContainerItemLink(bag, slot)
			if itemLink then
				local itemID = ParseItemLink(itemLink)
				if itemID then
					module.data.lastSniffedID = itemID
					module.data.priceSniffer:ClearLines()
					module.data.priceSniffer:SetBagItem(bag, slot)
				end
			end
		end
	end
end

local function CancelScan()
	module.data.isScanning = false
	module.data.scanPage = 0
	if AuctionEnhancementsActionsFrameScan then
		AuctionEnhancementsActionsFrameScan:SetText("Scan")
		if module.data.selectedRecord then
			AuctionEnhancementsActionsFrameScan:Enable()
		else
			AuctionEnhancementsActionsFrameScan:Disable()
		end
	end
	if AuctionEnhancementsActionsFrameStatusBar then
		AuctionEnhancementsActionsFrameStatusBar:SetMinMaxValues(0, 1)
		AuctionEnhancementsActionsFrameStatusBar:SetValue(0)
	end
end

local function StartScan()
	if not module.data.selectedRecord then return end

	if AuctionEnhancementsActionsFrameScan then
		AuctionEnhancementsActionsFrameScan:SetText("Scanning...")
		AuctionEnhancementsActionsFrameScan:Disable()
	end

	if not CanSendAuctionQuery() then
		VE.executeWithDelay(0.1, StartScan)
		return
	end

	module.data.isScanning = true
	module.data.scanPage = 0
	module.data.scanResults = {}

	-- Add vendor and historical prices to results right away so they stay in the table
	local record = module.data.selectedRecord
	local itemSellPrice = VanillaEnhancedData.vendorPrices and VanillaEnhancedData.vendorPrices[tostring(record.ID)] or 0
	if itemSellPrice > 0 then
		module.data.scanResults["vendor:0"] = { from = "Vendor", price = itemSellPrice, count = "-", duration = 0 }
	end

	local ahPriceKey = string.format("%s:%s", tostring(record.ID), tostring(record.suffixID or 0))
	local ahPrice = VanillaEnhancedData.auctionPrices and VanillaEnhancedData.auctionPrices[ahPriceKey] or 0
	if ahPrice > 0 then
		module.data.scanResults["hist:0"] = { from = "Auction", price = ahPrice, count = "Hist.", duration = 0 }
	end

	if AuctionEnhancementsActionsFrameStatusBar then
		AuctionEnhancementsActionsFrameStatusBar:SetMinMaxValues(0, 1)
		AuctionEnhancementsActionsFrameStatusBar:SetValue(0)
	end

	-- Query by name. We'll filter by ID and suffixID in the update event.
	QueryAuctionItems(module.data.selectedRecord.name, 0, 0, 0, 0, 0, module.data.scanPage, 0, 0)
end

local function SelectItem(record)
	local frame = AuctionEnhancementsFormFrame
	if not frame or not frame.initialized then return end

	-- Only cancel scan if we are clearing selection or switching to a different item
	local isDifferent = not record or not module.data.selectedRecord or record.ID ~= module.data.selectedRecord.ID or record.suffixID ~= module.data.selectedRecord.suffixID
	if isDifferent then
		CancelScan()
		module.data.scanResults = nil
		if AuctionEnhancementsListingsFrame.list then
			AuctionEnhancementsListingsFrame.list.records = {}
			AuctionEnhancementsListingsFrame.list:Render()
		end
	end

	if not record then
		module.data.selectedRecord = nil
		module.data.selectionInitDone = false

		if frame.itemIcon then frame.itemIcon:SetTexture(nil) end
		if frame.itemName then 
			frame.itemName:SetText("No item selected")
			frame.itemName:SetTextColor(0.5, 0.5, 0.5)
		end

		UpdateUIState()
		return
	end

	module.data.selectedRecord = record
	frame:Show()
	if AuctionEnhancementsListingsFrame then AuctionEnhancementsListingsFrame:Show() end
	if AuctionEnhancementsActionsFrame then AuctionEnhancementsActionsFrame:Show() end

	UpdateUIState()

	if isDifferent then
		module.data.selectionInitDone = false
	end

	-- Get all item info into a table to handle index shifts (minLevel presence)
	local info = { GetItemInfo(record.itemLink or record.ID) }
	if not info[1] then
		info = { GetItemInfo(record.ID) }
	end

	local itemName = info[1]
	if not itemName then return end -- Wait for GET_ITEM_INFO_RECEIVED

	-- Detect stack size index. 
	-- If index 8 is a number, it's the stackCount (minLevel is present).
	-- If index 8 is a string/nil and index 7 is a number, index 7 is the stackCount (minLevel is absent).
	local itemMaxStack = 1
	if type(info[8]) == "number" then
		itemMaxStack = info[8]
	elseif type(info[7]) == "number" then
		itemMaxStack = info[7]
	end

	local itemQuality = info[3]
	local itemTexture = info[10] or info[9] -- Texture is usually 10 or 9

	if frame.itemIcon then frame.itemIcon:SetTexture(record.texture or itemTexture) end
	if frame.itemName then 
		frame.itemName:SetText(record.name or itemName)
		local color = ITEM_QUALITY_COLORS[record.quality or itemQuality or 1]
		frame.itemName:SetTextColor(color.r, color.g, color.b)
	end

	local totalOwned = tonumber(record.count) or 1
	itemMaxStack = tonumber(itemMaxStack) or 1

	if not module.data.selectionInitDone then
		module.data.selectionInitDone = true
		module.data.stackSize = math.min(itemMaxStack, totalOwned)
		module.data.stackCount = math.max(1, math.floor(totalOwned / module.data.stackSize))

		-- Prices
		local initialRecords = {}
		local itemSellPrice = VanillaEnhancedData.vendorPrices and VanillaEnhancedData.vendorPrices[tostring(record.ID)] or 0
		local ahPriceKey = string.format("%s:%s", tostring(record.ID), tostring(record.suffixID or 0))
		local ahPrice = VanillaEnhancedData.auctionPrices and VanillaEnhancedData.auctionPrices[ahPriceKey] or 0

		if itemSellPrice > 0 then
			table.insert(initialRecords, { from = "Vendor", price = itemSellPrice, count = "-", duration = 0 })
		end
		if ahPrice > 0 then
			table.insert(initialRecords, { from = "Auction", price = ahPrice, count = "Hist.", duration = 0 })
		end

		if ahPrice > 0 then
			-- If we have scan results, use the lowest price found as both start and buyout, with no multiplier
			module.data.startPrice = ahPrice
			module.data.buyoutPrice = ahPrice
		elseif itemSellPrice > 0 then
			-- Fallback to vendor prices with multipliers
			module.data.startPrice = math.floor(itemSellPrice * module.config.BidMultiplier)
			module.data.buyoutPrice = math.floor(itemSellPrice * module.config.BuyoutMultiplier)
		else
			module.data.startPrice = 0
			module.data.buyoutPrice = 0
		end

		if AuctionEnhancementsListingsFrame.list and not module.data.isScanning then
			AuctionEnhancementsListingsFrame.list.records = initialRecords
			AuctionEnhancementsListingsFrame.list:Render()
		end
	else
		-- Refresh limits for existing selection
		module.data.stackSize = math.max(1, math.min(module.data.stackSize, totalOwned, itemMaxStack))
		module.data.stackCount = math.max(1, math.min(module.data.stackCount, math.floor(totalOwned / module.data.stackSize)))
	end

	-- Update UI components
	if frame.stackSizeSlider and frame.stackSizeSlider.slider then
		local min, max = 1, math.max(1, math.min(itemMaxStack, totalOwned))
		frame.stackSizeSlider.slider:SetMinMaxValues(min, max)
		frame.stackSizeSlider.slider:SetValue(module.data.stackSize)
		if frame.stackSizeSlider.low then frame.stackSizeSlider.low:SetText(min) end
		if frame.stackSizeSlider.high then frame.stackSizeSlider.high:SetText(max) end
		if frame.stackSizeSlider.text then frame.stackSizeSlider.text:SetText(module.data.stackSize) end
	end

	if frame.stackCountSlider and frame.stackCountSlider.slider then
		local min, max = 1, math.max(1, math.floor(totalOwned / module.data.stackSize))
		frame.stackCountSlider.slider:SetMinMaxValues(min, max)
		frame.stackCountSlider.slider:SetValue(module.data.stackCount)
		if frame.stackCountSlider.low then frame.stackCountSlider.low:SetText(1) end
		if frame.stackCountSlider.high then frame.stackCountSlider.high:SetText(max) end
		if frame.stackCountSlider.text then frame.stackCountSlider.text:SetText(module.data.stackCount) end
	end

	if frame.startPriceInput and frame.startPriceInput.editbox then
		frame.startPriceInput.editbox:SetText(CopperToMoneyString(module.data.startPrice))
	end
	if frame.buyoutPriceInput and frame.buyoutPriceInput.editbox then
		frame.buyoutPriceInput.editbox:SetText(CopperToMoneyString(module.data.buyoutPrice))
	end

	if frame.UpdateTotal then
		frame.UpdateTotal()
	end
end

local function CreateAuctionHouseForm()
	local frame = AuctionEnhancementsFormFrame
	if frame.initialized then return end

	frame.itemIcon = frame:CreateTexture(nil, "ARTWORK")
	frame.itemIcon:SetWidth(38)
	frame.itemIcon:SetHeight(38)
	frame.itemIcon:SetPoint("TOPLEFT", 10, -12)

	frame.itemName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.itemName:SetPoint("LEFT", frame.itemIcon, "RIGHT", 10, 0)
	frame.itemName:SetText("No item selected")

	-- Stack Size
	frame.stackSizeSlider = VE.elements.Slider(frame, 270, -12, 160, "Stack Size", nil, nil, 1, 20, 1, 1, function(val)
		module.data.stackSize = math.max(1, math.floor(val))
		if module.data.selectedRecord and frame.stackCountSlider and frame.stackCountSlider.slider then
			local totalOwned = tonumber(module.data.selectedRecord.count) or 0
			local maxStacks = math.max(1, math.floor(totalOwned / module.data.stackSize))

			-- Only reset to 1 if current count is now invalid
			local currentStackCount = module.data.stackCount or 1
			if currentStackCount > maxStacks then
				currentStackCount = 1
			end

			frame.stackCountSlider.slider:SetMinMaxValues(1, maxStacks)
			frame.stackCountSlider.slider:SetValue(currentStackCount)
			module.data.stackCount = currentStackCount

			if frame.stackCountSlider.low then frame.stackCountSlider.low:SetText(1) end
			if frame.stackCountSlider.high then frame.stackCountSlider.high:SetText(maxStacks) end
		end
		if frame.UpdateTotal then frame.UpdateTotal() end
		if AuctionEnhancementsListingsFrame.list then AuctionEnhancementsListingsFrame.list:Render() end
	end)

	-- Stack Count
	frame.stackCountSlider = VE.elements.Slider(frame, 270, -65, 160, "Stack Count", nil, nil, 1, 1, 1, 1, function(val)
		module.data.stackCount = floor(val)
		if frame.UpdateTotal then frame.UpdateTotal() end
		if AuctionEnhancementsListingsFrame.list then AuctionEnhancementsListingsFrame.list:Render() end
	end)

	-- Duration
	local durations = {
		{ key = 120, text = "6 Hours" },
		{ key = 480, text = "24 Hours" },
		{ key = 1440, text = "72 Hours" },
	}
	frame.durationDropDown = VE.elements.DropDown(frame, 10, -55, 100, "Duration", 1440, durations, function(key)
		module.data.duration = key
	end)

	-- Starting Price
	frame.startPriceInput = VE.elements.InputArea(frame, 450, -22, 150, 25, "Starting Price (per item)", nil, nil, "0c", 20, function(text)
		module.data.startPrice = MoneyStringToCopper(text)
		if frame.UpdateTotal then frame.UpdateTotal() end
	end)
	frame.startPriceInput.label = frame.startPriceInput:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.startPriceInput.label:SetPoint("BOTTOMLEFT", frame.startPriceInput, "TOPLEFT", 5, 2)
	frame.startPriceInput.label:SetText("Starting Price (per item)")

	-- Buyout Price
	frame.buyoutPriceInput = VE.elements.InputArea(frame, 450, -76, 150, 25, "Buyout Price (per item)", nil, nil, "0c", 20, function(text)
		module.data.buyoutPrice = MoneyStringToCopper(text)
		if frame.UpdateTotal then frame.UpdateTotal() end
	end)
	frame.buyoutPriceInput.label = frame.buyoutPriceInput:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.buyoutPriceInput.label:SetPoint("BOTTOMLEFT", frame.buyoutPriceInput, "TOPLEFT", 5, 2)
	frame.buyoutPriceInput.label:SetText("Buyout Price (per item)")


	-- Show current total bid/buyout
	frame.totalBidText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.totalBidText:SetPoint("LEFT", frame.durationDropDown, "RIGHT", -5, 10)
	frame.totalBidText:SetText("Total Bid: 0c")

	frame.totalBuyoutText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.totalBuyoutText:SetPoint("TOPLEFT", frame.totalBidText, "BOTTOMLEFT", 0, -2)
	frame.totalBuyoutText:SetText("Total Buyout: 0c")

	frame.UpdateTotal = function()
		local totalStart = (module.data.startPrice or 0) * (module.data.stackSize or 1) * (module.data.stackCount or 1)
		local totalBuyout = (module.data.buyoutPrice or 0) * (module.data.stackSize or 1) * (module.data.stackCount or 1)
		frame.totalBidText:SetText(string.format("Total Bid: %s", CopperToColoredMoneyString(totalStart)))
		frame.totalBuyoutText:SetText(string.format("Total Buyout: %s", CopperToColoredMoneyString(totalBuyout)))
	end

	if AuctionEnhancementsActionsFrameScan then
		AuctionEnhancementsActionsFrameScan:SetScript("OnClick", function()
			StartScan()
		end)
	end

	-- Use the Post button from the Listings frame (from XML)
	if AuctionEnhancementsActionsFramePost then
		AuctionEnhancementsActionsFramePost:SetScript("OnClick", function()
			PostAuction()
		end)
	end

	frame.initialized = true
end

local function CheckIfItemIsSellable(bag, slot)
	local isSoulbound = false
	local isQuestItem = false
	local isUnique = false

	module.data.sniffTooltip:ClearLines()
	module.data.sniffTooltip:SetBagItem(bag, slot)

	for i = 1, module.data.sniffTooltip:NumLines() do
		local line = getglobal(module.data.sniffTooltip:GetName() .. "TextLeft" .. i)
		local text = line and line:GetText() or ""

		if text == ITEM_SOULBOUND then
			isSoulbound = true
		elseif text == ITEM_BIND_QUEST then
			isQuestItem = true
		elseif string.find(text, ITEM_UNIQUE) then
			isUnique = true
		end
	end

	return isSoulbound, isQuestItem, isUnique
end

local function GetBagItemsGrouped()
	local records = {}
	local recordMap = {}

	for bag = 0, NUM_BAG_SLOTS do
		local numSlots = GetContainerNumSlots(bag)

		for slot = 1, numSlots do
			local texture, itemCount, locked, quality, readable = GetContainerItemInfo(bag, slot)
			local itemLink = GetContainerItemLink(bag, slot)

			if itemCount and itemCount > 0 and itemLink then
				local _, _, name = string.find(itemLink, "|h%[(.-)%]|h|r")
				local itemID, suffixID = ParseItemLink(itemLink)
				local isSoulbound, isQuestItem, isUnique = CheckIfItemIsSellable(bag, slot)

				if itemID and not isSoulbound and not isQuestItem then
					local key = string.format("%s:%s", tostring(itemID), tostring(suffixID or 0))
					local record = recordMap[key]
					if not record then
						record = {
							ID = itemID,
							suffixID = suffixID or 0,
							itemLink = itemLink,
							count = itemCount,
							texture = texture,
							name = name,
							quality = quality or 1,
							bag = bag,
							slot = slot,
						}
						recordMap[key] = record
						table.insert(records, record)
					else
						record.count = record.count + itemCount
					end
				end
			end
		end
	end

	table.sort(records, function(a, b)
		local aQuality = a.quality or 1
		local bQuality = b.quality or 1
		if aQuality ~= bQuality then
			return aQuality > bQuality
		end
		return (a.name or "") < (b.name or "")
	end)

	return records
end

local BAG_ITEMS_ROW_HEIGHT = 36
local BAG_ITEMS_VISIBLE_ROWS = 9
local LISTINGS_ROW_HEIGHT = 20
local LISTINGS_VISIBLE_ROWS = 11

local DURATION_LABELS = {
	[1] = "< 30m",
	[2] = "30m-2h",
	[3] = "2h-12h",
	[4] = "> 12h",
}

local function CreateListingsList()
	local frame = AuctionEnhancementsListingsFrame
	if frame.list then return end

	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -6)
	content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 0)

	-- Add a subtle background to the content area
	content.bg = content:CreateTexture(nil, "BACKGROUND")
	content.bg:SetAllPoints(content)
	content.bg:SetTexture(0, 0, 0, 0.3)

	-- Header Background Row
	content.headerBg = content:CreateTexture(nil, "BACKGROUND", nil, 1)
	content.headerBg:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
	content.headerBg:SetPoint("TOPRIGHT", content, "TOPRIGHT", -15, 0)
	content.headerBg:SetHeight(LISTINGS_ROW_HEIGHT)
	content.headerBg:SetTexture(1, 1, 1, 0.1)

	-- Headers
	frame.fromHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.fromHeader:SetPoint("LEFT", content.headerBg, "LEFT", 10, 0)
	frame.fromHeader:SetText("From")

	frame.countHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.countHeader:SetPoint("LEFT", content.headerBg, "LEFT", 85, 0)
	frame.countHeader:SetText("Available")

	frame.durHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.durHeader:SetPoint("LEFT", content.headerBg, "LEFT", 175, 0)
	frame.durHeader:SetText("Duration")

	frame.priceHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.priceHeader:SetPoint("LEFT", content.headerBg, "LEFT", 265, 0)
	frame.priceHeader:SetWidth(90)
	frame.priceHeader:SetJustifyH("RIGHT")
	frame.priceHeader:SetText("Unit Price")

	frame.profitHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.profitHeader:SetPoint("LEFT", content.headerBg, "LEFT", 340, 0)
	frame.profitHeader:SetWidth(130)
	frame.profitHeader:SetJustifyH("RIGHT")
	frame.profitHeader:SetText("Profit")

	frame.pctHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.pctHeader:SetPoint("LEFT", content.headerBg, "LEFT", 480, 0)
	frame.pctHeader:SetWidth(80)
	frame.pctHeader:SetJustifyH("RIGHT")
	frame.pctHeader:SetText("Market %")

	local scrollFrame = CreateFrame("ScrollFrame", "AuctionEnhancementsListingsScrollFrame", frame, "FauxScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
	scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -12, 0)
	scrollFrame:SetScript("OnVerticalScroll", function()
		FauxScrollFrame_OnVerticalScroll(LISTINGS_ROW_HEIGHT, function()
			if frame.list then frame.list:Render() end
		end)
	end)

	local rows = {}
	for i = 1, LISTINGS_VISIBLE_ROWS do
		local row = CreateFrame("Button", nil, content)
		row:SetHeight(LISTINGS_ROW_HEIGHT)
		row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(i * LISTINGS_ROW_HEIGHT))
		row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -15, -(i * LISTINGS_ROW_HEIGHT))
		row:SetFrameLevel(content:GetFrameLevel() + 1)

		row.from = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.from:SetPoint("LEFT", 10, 0)
		row.from:SetJustifyH("LEFT")

		row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.count:SetPoint("LEFT", 85, 0)
		row.count:SetJustifyH("LEFT")

		row.dur = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.dur:SetPoint("LEFT", 175, 0)
		row.dur:SetJustifyH("LEFT")

		row.price = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.price:SetPoint("LEFT", 265, 0)
		row.price:SetWidth(90)
		row.price:SetJustifyH("RIGHT")

		row.profit = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.profit:SetPoint("LEFT", 340, 0)
		row.profit:SetWidth(130)
		row.profit:SetJustifyH("RIGHT")

		row.pct = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.pct:SetPoint("LEFT", 480, 0)
		row.pct:SetWidth(80)
		row.pct:SetJustifyH("RIGHT")

		row.bg = row:CreateTexture(nil, "BACKGROUND")
		row.bg:SetAllPoints(row)
		row.bg:Hide()

		row.highlight = row:CreateTexture(nil, "BACKGROUND", nil, 1)
		row.highlight:SetAllPoints(row)
		row.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		row.highlight:SetTexCoord(0.1, 0.8, 0, 1)
		row.highlight:Hide()

		row:SetScript("OnEnter", function() row.highlight:Show() end)
		row:SetScript("OnLeave", function() row.highlight:Hide() end)
		row:SetScript("OnClick", function()
			if row.priceValue then
				module.data.startPrice = row.priceValue
				module.data.buyoutPrice = row.priceValue
				if AuctionEnhancementsFormFrame.startPriceInput and AuctionEnhancementsFormFrame.startPriceInput.editbox then
					AuctionEnhancementsFormFrame.startPriceInput.editbox:SetText(CopperToMoneyString(module.data.startPrice))
				end
				if AuctionEnhancementsFormFrame.buyoutPriceInput and AuctionEnhancementsFormFrame.buyoutPriceInput.editbox then
					AuctionEnhancementsFormFrame.buyoutPriceInput.editbox:SetText(CopperToMoneyString(module.data.buyoutPrice))
				end
				if AuctionEnhancementsFormFrame.UpdateTotal then
					AuctionEnhancementsFormFrame.UpdateTotal()
				end
			end
		end)

		rows[i] = row
	end

	-- Initialize Status Bar
	if AuctionEnhancementsActionsFrameStatusBar then
		AuctionEnhancementsActionsFrameStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		AuctionEnhancementsActionsFrameStatusBar:SetStatusBarColor(1, 1, 0)
		AuctionEnhancementsActionsFrameStatusBar:SetMinMaxValues(0, 1)
		AuctionEnhancementsActionsFrameStatusBar:SetValue(0)
	end

	frame.list = {
		content = content,
		scrollFrame = scrollFrame,
		rows = rows,
		records = {},
		Render = function(self)
			FauxScrollFrame_Update(self.scrollFrame, table.getn(self.records), LISTINGS_VISIBLE_ROWS, LISTINGS_ROW_HEIGHT)
			local offset = FauxScrollFrame_GetOffset(self.scrollFrame)

			local minPrice = 0
			for _, rec in ipairs(self.records) do
				if rec.from == "Auction" and (minPrice == 0 or rec.price < minPrice) then
					minPrice = rec.price
				end
			end

			for i = 1, LISTINGS_VISIBLE_ROWS do
				local row = self.rows[i]
				local record = self.records[i + offset]
				if record then
					row.from:SetText(record.from or "")
					row.count:SetText(record.count)
					row.dur:SetText(DURATION_LABELS[record.duration] or "-")
					row.price:SetText(CopperToColoredMoneyString(record.price))

					local profit = record.price * (module.data.stackSize or 1) * (module.data.stackCount or 1)
					row.profit:SetText(CopperToColoredMoneyString(profit))

					local pctText = "-"
					if minPrice > 0 and record.from ~= "Vendor" then
						pctText = string.format("%.1f%%", record.price / minPrice * 100)
					end
					row.pct:SetText(pctText)
					row.priceValue = record.price

					if record.from == "Vendor" or record.count == "Hist." then
						row.bg:SetTexture(0, 1, 0, 0.1)
						row.bg:Show()
					else
						row.bg:Hide()
					end

					row:Show()
				else
					row:Hide()
				end
			end
		end,
	}
end

local function CreateBagItemsList()
	local frame = AuctionEnhancementsBagItemsFrame
	if frame.list then
		return
	end

	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -28)
	content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 104)

	local scrollFrame = CreateFrame("ScrollFrame", "AuctionEnhancementsBagItemsScrollFrame", frame, "FauxScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
	scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, 99)
	scrollFrame:SetScript("OnVerticalScroll", function()
		FauxScrollFrame_OnVerticalScroll(BAG_ITEMS_ROW_HEIGHT, function()
			if frame.list then
				frame.list:Render()
			end
		end)
	end)

	local rows = {}
	for i = 1, BAG_ITEMS_VISIBLE_ROWS do
		local row = CreateFrame("Button", nil, content)
		row:SetHeight(BAG_ITEMS_ROW_HEIGHT)
		row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((i - 1) * BAG_ITEMS_ROW_HEIGHT))
		row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -((i - 1) * BAG_ITEMS_ROW_HEIGHT))
		row:EnableMouse(true)

		row.itemIcon = row:CreateTexture(nil, "ARTWORK")
		row.itemIcon:SetWidth(32)
		row.itemIcon:SetHeight(32)
		row.itemIcon:SetPoint("LEFT", row, "LEFT", 2, 0)

		row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		row.name:SetPoint("LEFT", row.itemIcon, "RIGHT", 4, 0)
		row.name:SetPoint("RIGHT", row, "RIGHT", -28, 0)
		row.name:SetJustifyH("LEFT")

		row.count = row:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
		row.count:SetPoint("BOTTOMRIGHT", row.itemIcon, "BOTTOMRIGHT", -2, 2)
		row.count:SetJustifyH("RIGHT")
		row.count:SetTextColor(1, 1, 1)

		row.highlight = row:CreateTexture(nil, "BACKGROUND")
		row.highlight:SetAllPoints(row)
		row.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		row.highlight:SetTexCoord(0.1, 0.8, 0, 1)
		row.highlight:Hide()

		row:SetScript("OnClick", function()
			if row.record then
				SelectItem(row.record)
			end
		end)

		row:SetScript("OnEnter", function()
			row.highlight:Show()
			GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
			if row.bag and row.slot then
				GameTooltip:SetBagItem(row.bag, row.slot)
			elseif row.itemLink then
				GameTooltip:SetHyperlink(row.itemLink)
			end
		end)
		row:SetScript("OnLeave", function()
			row.highlight:Hide()
			GameTooltip:Hide()
		end)

		rows[i] = row
	end

	frame.list = {
		content = content,
		scrollFrame = scrollFrame,
		rows = rows,
		records = {},
		Render = function(self)
			FauxScrollFrame_Update(self.scrollFrame, table.getn(self.records), BAG_ITEMS_VISIBLE_ROWS, BAG_ITEMS_ROW_HEIGHT)
			local offset = FauxScrollFrame_GetOffset(self.scrollFrame)
			for i = 1, BAG_ITEMS_VISIBLE_ROWS do
				local row = self.rows[i]
				local record = self.records[i + offset]
				if record then
					row.itemIcon:SetTexture(record.texture)
					row.name:SetText(record.name or "")
					local color = ITEM_QUALITY_COLORS[record.quality or 1] or ITEM_QUALITY_COLORS[1]
					row.name:SetTextColor(color.r, color.g, color.b)
					if record.count and record.count > 1 then
						row.count:SetText(record.count)
					else
						row.count:SetText("")
					end
					row.record = record
					row.itemLink = record.itemLink
					row.bag = record.bag
					row.slot = record.slot
					row:Show()
				else
					row.record = nil
					row.itemLink = nil
					row.bag = nil
					row.slot = nil
					row:Hide()
				end
			end
		end,
	}
end

local function AddAuctionHousePostButton()
	module.data.tabIndex = AuctionFrame.numTabs + 1
	local nextFrameName = "AuctionFrameTab" .. module.data.tabIndex
	local prevFrameName = "AuctionFrameTab" .. AuctionFrame.numTabs

	local frame = CreateFrame("Button", nextFrameName, AuctionFrame, "AuctionTabTemplate");
	frame:SetID(module.data.tabIndex);
	frame:SetText("Post");
	frame:SetPoint("LEFT", getglobal(prevFrameName), "RIGHT", -8, 0);
	frame:Show();

	setglobal(nextFrameName, frame);

	PanelTemplates_SetNumTabs(AuctionFrame, module.data.tabIndex);
	PanelTemplates_EnableTab(AuctionFrame, module.data.tabIndex);
end

local function AddAuctionHouseBagItemsFrame()
	AuctionEnhancementsBagItemsFrame:ClearAllPoints()
	AuctionEnhancementsBagItemsFrame:SetParent(AuctionFrame)
	AuctionEnhancementsBagItemsFrame:SetPoint("TopLeft", AuctionFrame, "TopLeft", 20, -50)
end

local function AddAuctionHouseListingsFrame()
	AuctionEnhancementsListingsFrame:ClearAllPoints()
	AuctionEnhancementsListingsFrame:SetParent(AuctionFrame)
	AuctionEnhancementsListingsFrame:SetPoint("TopLeft", AuctionFrame, "TopLeft", 210, -160)
	CreateListingsList()
end

local function AddAuctionHouseActionsFrame()
	AuctionEnhancementsActionsFrame:ClearAllPoints()
	AuctionEnhancementsActionsFrame:SetParent(AuctionFrame)
	AuctionEnhancementsActionsFrame:SetPoint("BottomRight", AuctionFrame, "BottomRight", -12, 37)
end

local function AddAuctionHouseFormFrame()
	AuctionEnhancementsFormFrame:ClearAllPoints()
	AuctionEnhancementsFormFrame:SetParent(AuctionFrame)
	AuctionEnhancementsFormFrame:SetPoint("TopLeft", AuctionFrame, "TopLeft", 210, -45)
	CreateAuctionHouseForm()
end

function AuctionEnhancements_OnLoad()
	this:RegisterEvent("ADDON_LOADED")
	this:RegisterEvent("AUCTION_HOUSE_SHOW")
	this:RegisterEvent("AUCTION_HOUSE_CLOSED")
	this:RegisterEvent("BAG_UPDATE")
	this:RegisterEvent("BAG_UPDATE_DELAYED")
	this:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	this:RegisterEvent("MERCHANT_SHOW")
	this:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
	this:RegisterEvent("CHAT_MSG_SYSTEM")
	this:RegisterEvent("UI_ERROR_MESSAGE")
end

local function RefreshBagItemsList()
	if not AuctionEnhancementsBagItemsFrame or not AuctionEnhancementsBagItemsFrame.list then
		return
	end

	local records = GetBagItemsGrouped()
	AuctionEnhancementsBagItemsFrame.list.records = records
	AuctionEnhancementsBagItemsFrame.list:Render()

	-- Check if we need to update the selected record's count
	if module.data.selectedRecord then
		local found = false
		for _, record in ipairs(records) do
			if record.ID == module.data.selectedRecord.ID and record.suffixID == module.data.selectedRecord.suffixID then
				SelectItem(record)
				found = true
				break
			end
		end
		if not found then
			SelectItem(nil)
		end
	end
end

function AuctionEnhancements_OnEvent()
	if not VE.isModuleEnabled(module.identifier) then
		this:UnregisterAllEvents()
		return
	end

	if event == "ADDON_LOADED" then
		if string.lower(arg1) == "vanillaenhanced" then
			InitializePriceSniffer()
		end

		if (string.lower(arg1) == "blizzard_auctionui") then
			AddAuctionHousePostButton()
			AddAuctionHouseBagItemsFrame()
			AddAuctionHouseListingsFrame()
			AddAuctionHouseActionsFrame()
			AddAuctionHouseFormFrame()
			CreateBagItemsList()

			-- Hijack native tab onclick event.
			module.data.AuctionFrameTab_OnClick = AuctionFrameTab_OnClick
			function AuctionFrameTab_OnClick(index)
				if not index then index = this:GetID() end
				module.data.AuctionFrameTab_OnClick(index)

				-- Add this frame to the list to handle.
				if index == module.data.tabIndex then
					PanelTemplates_SetTab(AuctionFrame, module.data.tabIndex);
					AuctionFrameAuctions:Hide();
					AuctionFrameBrowse:Hide();
					AuctionFrameBid:Hide();

					AuctionFrameTopLeft:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\AuctionEnhancements-TopLeft")
					AuctionFrameTop:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\AuctionEnhancements-Top")
					AuctionFrameTopRight:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\AuctionEnhancements-TopRight")
					AuctionFrameBotLeft:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\AuctionEnhancements-BotLeft")
					AuctionFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Bot")
					AuctionFrameBotRight:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\AuctionEnhancements-BotRight")

					AuctionEnhancementsBagItemsFrame:Show()
					AuctionEnhancementsActionsFrame:Show()

					-- Adds needed background to progress bar.
					VE.dframe(AuctionEnhancementsActionsFrameStatusBar, 0, 0, 0, 1) 

					OpenAllBags(true)
					RefreshBagItemsList()
					UpdateUIState()
				else
					AuctionEnhancementsBagItemsFrame:Hide()
					AuctionEnhancementsListingsFrame:Hide()
					AuctionEnhancementsActionsFrame:Hide()
					AuctionEnhancementsFormFrame:Hide()
				end
			end
		end

		-- Create a tooltip for sniffing soulbound, quest and unique items.
		if not module.data.sniffTooltip then
			module.data.sniffTooltip = CreateFrame("GameTooltip", "AuctionSniffTooltip", UIParent, "GameTooltipTemplate")
			module.data.sniffTooltip:SetOwner(UIParent, "ANCHOR_NONE")
		end
	end

	if event == "CHAT_MSG_SYSTEM" then
		if arg1 == ERR_AUCTION_STARTED and module.data.isPosting then
			-- Wait a short delay before trying to post the next one to allow the server to fully process
			-- the consumed item, avoiding the ERR_ITEM_NOT_FOUND "ghost item" desync issue.
			VE.executeWithDelay(0.4, PostNext)
		end
	end

	if event == "UI_ERROR_MESSAGE" then
		if module.data.isPosting then
			if arg1 == ERR_ITEM_NOT_FOUND or arg1 == "Item not found." then
				-- This is a desync ghost item. Just wait a moment and try again.
				VE.executeWithDelay(0.5, PostNext)
			else
				StopPosting("UI Error: " .. tostring(arg1))
			end
		end
	end

	if event == "AUCTION_ITEM_LIST_UPDATE" then
		if not module.data.isScanning or not module.data.selectedRecord then return end

		local batchCount, totalCount = GetNumAuctionItems("list")
		local record = module.data.selectedRecord

		-- Update progress bar
		if AuctionEnhancementsActionsFrameStatusBar then
			if totalCount > 0 then
				local totalPages = math.max(1, math.ceil(totalCount / 50))
				AuctionEnhancementsActionsFrameStatusBar:SetMinMaxValues(0, totalPages)
				AuctionEnhancementsActionsFrameStatusBar:SetValue(module.data.scanPage + 1)
			else
				AuctionEnhancementsActionsFrameStatusBar:SetMinMaxValues(0, 1)
				AuctionEnhancementsActionsFrameStatusBar:SetValue(1)
			end
		end

		-- Process results
		for i = 1, batchCount do
			local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo("list", i)
			local itemLink = GetAuctionItemLink("list", i)

			if itemLink then
				local itemID, suffixID = ParseItemLink(itemLink)
				if itemID == record.ID and suffixID == record.suffixID then
					local price = buyoutPrice > 0 and buyoutPrice or (bidAmount > 0 and bidAmount or minBid)
					local pricePerItem = math.ceil(price / count)
					local duration = GetAuctionItemTimeLeft("list", i)
					local key = pricePerItem .. ":" .. duration
					if not module.data.scanResults[key] then
						module.data.scanResults[key] = { from = "Auction", price = pricePerItem, duration = duration, count = 0 }
					end
					module.data.scanResults[key].count = module.data.scanResults[key].count + count
				end
			end
		end

		-- Update the listings table with current data
		if AuctionEnhancementsListingsFrame.list then
			local sortedKeys = {}
			for key in pairs(module.data.scanResults) do
				table.insert(sortedKeys, key)
			end
			table.sort(sortedKeys, function(a, b)
				local ra, rb = module.data.scanResults[a], module.data.scanResults[b]
				if ra.price ~= rb.price then
					return ra.price < rb.price
				end
				return ra.duration < rb.duration
			end)

			local records = {}
			for _, key in ipairs(sortedKeys) do
				table.insert(records, module.data.scanResults[key])
			end
			AuctionEnhancementsListingsFrame.list.records = records
			AuctionEnhancementsListingsFrame.list:Render()
		end

		-- Check if we need to fetch more pages
		if (module.data.scanPage + 1) * 50 < totalCount then
			local nextPage = module.data.scanPage + 1
			module.data.scanPage = nextPage

			local function FetchNext()
				if not module.data.isScanning then return end
				if CanSendAuctionQuery() then
					QueryAuctionItems(record.name, 0, 0, 0, 0, 0, nextPage, 0, 0)
				else
					VE.executeWithDelay(0.2, FetchNext)
				end
			end
			VE.executeWithDelay(0.1, FetchNext)
		else
			-- Scan complete

			local sortedKeys = {}
			local minPrice = 0
			for key in pairs(module.data.scanResults) do
				table.insert(sortedKeys, key)
			end
			table.sort(sortedKeys, function(a, b)
				local ra, rb = module.data.scanResults[a], module.data.scanResults[b]
				if ra.price ~= rb.price then
					return ra.price < rb.price
				end
				return ra.duration < rb.duration
			end)

			for _, key in ipairs(sortedKeys) do
				local res = module.data.scanResults[key]
				if res.from == "Auction" and (minPrice == 0 or res.price < minPrice) then
					minPrice = res.price
				end
			end

			-- Store the lowest price found in persistent data
			if minPrice > 0 then
				local key = string.format("%s:%s", tostring(record.ID), tostring(record.suffixID or 0))
				if not VanillaEnhancedData.auctionPrices then VanillaEnhancedData.auctionPrices = {} end
				VanillaEnhancedData.auctionPrices[key] = minPrice
			end

			for _, key in ipairs(sortedKeys) do
				local res = module.data.scanResults[key]
				if res.from == "Auction" then
					local percentage = 0
					if minPrice > 0 then
						percentage = (res.price / minPrice) * 100
					end

					local countStr = tostring(res.count)
					if type(res.count) == "number" then
						countStr = countStr .. "x"
					end
				end
			end

			CancelScan()
		end
	end

	if event == "GET_ITEM_INFO_RECEIVED" then
		if module.data.selectedRecord and tonumber(module.data.selectedRecord.ID) == tonumber(arg1) then
			SelectItem(module.data.selectedRecord)
		end
	end

	if event == "MERCHANT_SHOW" then
		ScanBagPrices()
	end

	if event == "AUCTION_HOUSE_SHOW" then
		-- Open this tab when Auction House is opened.
		AuctionFrameTab_OnClick(module.data.tabIndex)
		OpenAllBags()
	end

	if event == "BAG_UPDATE" or event == "BAG_UPDATE_DELAYED" then
		if module.data.isPosting and module.data.isWaitingForBag then
			VE.executeWithDelay(0.2, PostNext)
		end

		if AuctionEnhancementsBagItemsFrame and AuctionEnhancementsBagItemsFrame:IsShown() then
			RefreshBagItemsList()
		end
	end

	if event == "AUCTION_HOUSE_CLOSED" then
		SelectItem(nil)
		if module.data.isPosting then
			StopPosting()
		end
	end
end
