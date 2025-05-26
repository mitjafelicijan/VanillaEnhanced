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

local function GetItemsInBags()
	local items = {}

    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = GetContainerNumSlots(bag)
        
        for slot = 1, numSlots do
			local texture, itemCount, locked, quality, readable = GetContainerItemInfo(bag, slot)
			local itemLink = GetContainerItemLink(bag, slot)

			if itemCount and itemCount > 0 and itemLink then
				local _, _, name = string.find(itemLink, "|h%[(.-)%]|h|r")
				local _, _, itemID = string.find(itemLink, "item:(%d+):")
				local isSoulbound, isQuestItem, isUnique = CheckIfItemIsSellable(bag, slot) -- barow caller trinket

				if not isSoulbound and not isQuestItem and not isUnique then
					print(string.format("[%s] (%s,%s) %s (%s)", tostring(itemCount), bag, slot, name, itemID))

					table.insert(items, {
						ID = itemID,
						itemLink = itemLink,
						itemCount = itemCount,
						texture = texture,
						name = name,
						bag = bag,
						slot = slot,
					})
				end
			end
		end
	end

	return items
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

function AuctionEnhancements_OnLoad()
	this:RegisterEvent("ADDON_LOADED")
	this:RegisterEvent("AUCTION_HOUSE_SHOW")
	this:RegisterEvent("AUCTION_HOUSE_CLOSED")	
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
					OpenAllBags(true)

					-- VE.dframe(AuctionEnhancementsBagItemsFrameButton1, 1, 1, 0, 1)
					
					VE.dframe(AuctionEnhancementsListingsFrameStatusBar, 0, 0, 0, 1)
					AuctionEnhancementsListingsFrameStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
					AuctionEnhancementsListingsFrameStatusBar:SetStatusBarColor(0.6, 0.6, 0.6)
					AuctionEnhancementsListingsFrameStatusBar:SetMinMaxValues(1, 8)
					AuctionEnhancementsListingsFrameStatusBar:SetValue(5)
					AuctionEnhancementsListingsFrameScan:Disable()

					GetItemsInBags()
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

		SLASH_SELL1 = "/qwe"
		SlashCmdList["SELL"] = function()
			GetItemsInBags()

			-- ParseItemTooltip(0, 3) -- meat
			-- local isSoulbound, isQuestItem, isUnique = CheckIfItemIsSellable(4, 12) -- barow caller trinket
			-- local isSoulbound, isQuestItem, isUnique = CheckIfItemIsSellable(0, 3) -- barow caller trinket
			-- print(string.format("%s, %s, %s", tostring(isSoulbound), tostring(isQuestItem), tostring(isUnique)))
		end
	end

	if event == "AUCTION_HOUSE_SHOW" then
		-- Open this tab when Auction House is opened.
		AuctionFrameTab_OnClick(module.data.tabIndex)
	end

	if event == "AUCTION_HOUSE_CLOSED" then
	end
end
