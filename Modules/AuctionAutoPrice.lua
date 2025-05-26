local module = VE.registerModule({
	identifier = "AuctionAutoPrice",
	meta = {
		label = "Auction House Scan",
		description = "Scans the Auction House to determine the current market price for an item, providing quick and accurate pricing information.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		undercutPercentage = 10,
	},
	data = {
		itemName = nil,
		invItemCount = nil,
		invItemPrice = nil,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function round(num)
	return math.floor(num + 0.5)
end

local function parseCurrency(amount)
	local copper = amount - math.floor(amount / 100) * 100
	local silver = math.floor(amount / 100) - math.floor(amount / 10000) * 100
	local gold = math.floor(amount / 10000)
	return gold, silver, copper
end

local function subtractPercent(number, percentage)
	local percent = number * (tonumber(percentage) / 100)
	return (number - percent)
end

local function saveUndercutPercentage(value)
	VanillaEnhancedData["AuctionAutoPriceUndercut"] = value
	module.config.undercutPercentage = value
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("NEW_AUCTION_UPDATE")
module.plug:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
module.plug:RegisterEvent("AUCTION_HOUSE_SHOW")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if VanillaEnhancedData["AuctionAutoPriceUndercut"] ~= nil then
		module.config.undercutPercentage = VanillaEnhancedData["AuctionAutoPriceUndercut"]
	end

	if event == "NEW_AUCTION_UPDATE" then
		local name, _, count, _, _, price = GetAuctionSellItemInfo()
		if name ~= nil then
			module.data.invItemCount = count
			module.data.invItemPrice = price
			module.data.itemName = name
			QueryAuctionItems(name, nil, nil, 0, 0, 0, 0, 0, 0)
		end
	end

	if event == "AUCTION_HOUSE_SHOW" then
		if (AuctionFrame and AuctionFrame:IsShown()) then
			if AuctionFrame.progress == nil then
				AuctionFrame.progress = AuctionFrame:CreateFontString(nil, "HIGH", "GameFontDisable")
				AuctionFrame.progress:SetPoint("BottomLeft", AuctionFrame, "BottomLeft", 220, 18)
				AuctionFrame.progress:Hide()
			end
			if AuctionFrame.undercutLabel == nil then
				AuctionFrame.undercutLabel = AuctionFrame:CreateFontString(nil, "HIGH", "GameFontDisable")
				AuctionFrame.undercutLabel:SetPoint("BottomRight", AuctionFrame, "BottomRight", -260, 18)
				AuctionFrame.undercutLabel:SetText("Undercut %")
				AuctionFrame.undercutLabel:Hide()
			end
			if AuctionFrame.undercutValue == nil then
				AuctionFrame.undercutValue = CreateFrame("EditBox", nil, AuctionFrame, "InputBoxTemplate")
				AuctionFrame.undercutValue:SetWidth(30)
				AuctionFrame.undercutValue:SetHeight(20)
				AuctionFrame.undercutValue:SetPoint("BottomRight", AuctionFrame, "BottomRight", -220, 15)
				AuctionFrame.undercutValue:SetAutoFocus(false)
				AuctionFrame.undercutValue:SetText(module.config.undercutPercentage)
				AuctionFrame.undercutValue:Hide()
				AuctionFrame.undercutValue:SetScript("OnEditFocusLost", function(self)
					saveUndercutPercentage(this:GetText())
				end)
				AuctionFrame.undercutValue:SetScript("OnEnterPressed", function(self)
					saveUndercutPercentage(this:GetText())
					this:ClearFocus()
				end)
				AuctionFrame.undercutValue:SetScript("OnEscapePressed", function(self)
					this:ClearFocus()
				end)
			end
		end
	end

	if event == "AUCTION_ITEM_LIST_UPDATE" then
		local numBatchAuctions, totalAuctions = GetNumAuctionItems("list")

		local sumBidAmount = 0
		local sumBuyoutPrice = 0

		if totalAuctions == 0 then
			AuctionFrame.progress:SetText("No auctions found on auction house.")
		else
			AuctionFrame.progress:SetText("Probed ".. totalAuctions .." items for the best price.")
		end

		for i = 1, numBatchAuctions do
			local name, _, count, _, _, _, bidAmount, _, buyoutPrice = GetAuctionItemInfo("list", i)
			if bidAmount > 0 and buyoutPrice > 0 then
				if name == module.data.itemName and name ~= nil then
					sumBidAmount = sumBidAmount + (bidAmount / count)
					sumBuyoutPrice = sumBuyoutPrice + (buyoutPrice / count)
				end
			end
		end

		local avgBidAmount = round(sumBidAmount/numBatchAuctions)
		local avgBuyoutPrice = round(sumBuyoutPrice/numBatchAuctions)

		if module.data.invItemCount ~= nil and module.data.invItemCount ~= nil then
			if avgBidAmount > avgBuyoutPrice then
				avgBidAmount = avgBuyoutPrice
			end

			local g1, s1, c1 = parseCurrency(subtractPercent(avgBidAmount * module.data.invItemCount, module.config.undercutPercentage))
			local g2, s2, c2 = parseCurrency(subtractPercent(avgBuyoutPrice * module.data.invItemCount, module.config.undercutPercentage))

			getglobal("StartPriceGold"):SetText(g1)
			getglobal("StartPriceSilver"):SetText(s1)
			getglobal("StartPriceCopper"):SetText(c1)

			getglobal("BuyoutPriceGold"):SetText(g2)
			getglobal("BuyoutPriceSilver"):SetText(s2)
			getglobal("BuyoutPriceCopper"):SetText(c2)
		end
	end
end)

module.plug:SetScript("OnUpdate", function()
	if (AuctionFrame and AuctionFrame:IsShown() and
		AuctionFrame.progress ~= nil and
		AuctionFrame.undercutLabel ~= nil and
		AuctionFrame.undercutValue ~= nil) then
		if (AuctionFrame.selectedTab == 3) then
			AuctionFrame.progress:Show()
			AuctionFrame.undercutLabel:Show()
			AuctionFrame.undercutValue:Show()
		else
			AuctionFrame.progress:Hide()
			AuctionFrame.undercutLabel:Hide()
			AuctionFrame.undercutValue:Hide()
		end
	end
end)
