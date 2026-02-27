local module = VE.registerModule({
	identifier = "AuctionEnhancements",
	meta = {
		label = "Auction Enhancements",
		description = "Adds new post form to the auction house, and a new tab for viewing items in your bags. (WIP)",
	},
	plug = nil,
	superWoWRequired = false,
	config = {},
	data = {
		AuctionFrameTab_OnClick = nil,
		sniffTooltip = nil,
		tabIndex = 0,
		bagItems = nil,
	},
})

local print = VE.print

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
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

local function ParseItemLink(itemLink)
	local _, _, itemString = string.find(itemLink, "(item:[^|]+)")
	if not itemString then
		return nil, 0
	end

	local parts = VE.split(itemString, ":")

	local itemID = tonumber(parts[2])
	local suffixID = tonumber(parts[8]) or 0
	return itemID, suffixID
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

				if itemID and not isSoulbound and not isQuestItem and not isUnique then
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
	-- VE.dframe(AuctionEnhancementsBagItemsFrame, 0, 1, 0, 0.1)
end

local function AddAuctionHouseListingsFrame()
	AuctionEnhancementsListingsFrame:ClearAllPoints()
	AuctionEnhancementsListingsFrame:SetParent(AuctionFrame)
	AuctionEnhancementsListingsFrame:SetPoint("TopLeft", AuctionFrame, "TopLeft", 210, -160)
	-- VE.dframe(AuctionEnhancementsListingsFrame, 0, 1, 0, 0.1)
end

local function AddAuctionHouseFormFrame()
	AuctionEnhancementsFormFrame:ClearAllPoints()
	AuctionEnhancementsFormFrame:SetParent(AuctionFrame)
	AuctionEnhancementsFormFrame:SetPoint("TopLeft", AuctionFrame, "TopLeft", 210, -50)
	-- VE.dframe(AuctionEnhancementsFormFrame, 1, 0, 1, 1)
end

function AuctionEnhancements_OnLoad()
	this:RegisterEvent("ADDON_LOADED")
	this:RegisterEvent("AUCTION_HOUSE_SHOW")
	this:RegisterEvent("AUCTION_HOUSE_CLOSED")
	this:RegisterEvent("BAG_UPDATE")
	this:RegisterEvent("BAG_UPDATE_DELAYED")
end

local BAG_ITEMS_ROW_HEIGHT = 36
local BAG_ITEMS_VISIBLE_ROWS = 9

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
					row.itemLink = record.itemLink
					row.bag = record.bag
					row.slot = record.slot
					row:Show()
				else
					row.itemLink = nil
					row.bag = nil
					row.slot = nil
					row:Hide()
				end
			end
		end,
	}
end

local function RefreshBagItemsList()
	if not AuctionEnhancementsBagItemsFrame or not AuctionEnhancementsBagItemsFrame.list then
		return
	end

	local records = GetBagItemsGrouped()
	AuctionEnhancementsBagItemsFrame.list.records = records
	AuctionEnhancementsBagItemsFrame.list:Render()
end

function AuctionEnhancements_OnEvent()
	if not VE.isModuleEnabled(module.identifier) then
		this:UnregisterAllEvents()
		return
	end

	VE.iprint(string.format("AuctionEnhancements_OnEvent(%s)", event))

	if event == "ADDON_LOADED" then
		if (string.lower(arg1) == "blizzard_auctionui") then
			AddAuctionHousePostButton()
			AddAuctionHouseBagItemsFrame()
			AddAuctionHouseListingsFrame()
			AddAuctionHouseFormFrame()
			CreateBagItemsList()

			AuctionFrame:SetMovable(true)
			AuctionFrame:SetScript("OnMouseDown", function() this:StartMoving() end)
			AuctionFrame:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)

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
					AuctionEnhancementsListingsFrame:Show()
					AuctionEnhancementsFormFrame:Show()
					OpenAllBags(true)
					RefreshBagItemsList()

					VE.dframe(AuctionEnhancementsListingsFrame, 1, 1, 0, 0.4)
					VE.dframe(AuctionEnhancementsFormFrame, 1, 0, 1, 0.4)

					VE.dframe(AuctionEnhancementsListingsFrameStatusBar, 0, 0, 0, 1)
					AuctionEnhancementsListingsFrameStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
					AuctionEnhancementsListingsFrameStatusBar:SetStatusBarColor(0.6, 0.6, 0.6)
					AuctionEnhancementsListingsFrameStatusBar:SetMinMaxValues(1, 8)
					AuctionEnhancementsListingsFrameStatusBar:SetValue(5)
					AuctionEnhancementsListingsFrameScan:Disable()

					-- GetItemsInBags()
				else
					AuctionEnhancementsBagItemsFrame:Hide()
					AuctionEnhancementsListingsFrame:Hide()
				end
			end
		end

		-- Create a tooltip for sniffing soulbound, quest and unique items.
		if not module.data.sniffTooltip then
			module.data.sniffTooltip = CreateFrame("GameTooltip", "AuctionSniffTooltip", UIParent, "GameTooltipTemplate")
			module.data.sniffTooltip:SetOwner(UIParent, "ANCHOR_NONE")
		end

	end

	if event == "AUCTION_HOUSE_SHOW" then
		-- Open this tab when Auction House is opened.
		AuctionFrameTab_OnClick(module.data.tabIndex)
		OpenAllBags()
	end

	if event == "BAG_UPDATE" or event == "BAG_UPDATE_DELAYED" then
		if AuctionEnhancementsBagItemsFrame and AuctionEnhancementsBagItemsFrame:IsShown() then
			RefreshBagItemsList()
		end
	end

	if event == "AUCTION_HOUSE_CLOSED" then
	end
end
