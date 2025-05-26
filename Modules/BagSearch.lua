local module = VE.registerModule({
	identifier = "BagSearch",
	meta = {
		label = "Bag Search",
		description = "Adds a search box to the backpack for searching your bags, keyring and bank.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	local search = CreateFrame("Frame", nil, ContainerFrame1)
	search:SetPoint("BOTTOMLEFT", ContainerFrame1Item15, "TOPLEFT", 3, 2)
	search:SetPoint("BOTTOMRIGHT", ContainerFrame1Item13, "TOP", 20, 2)
	search:SetHeight(20)

	search.text = search:CreateFontString(nil, "HIGH", "GameTooltipTextSmall")
	local font, size = search.text:GetFont()

	search.edit = CreateFrame("EditBox", nil, search, "InputBoxTemplate")
	search.edit:SetMaxLetters(14)
	search.edit:SetAllPoints(search)
	search.edit:SetFont(font, size, "OUTLINE")
	search.edit:SetAutoFocus(false)
	search.edit:SetText("Search")
	search.edit:SetTextColor(1,1,1,1)

	local function buttons(alpha)
		-- Bags & Keyring
		for i = 1, 12 do
			local frame = getglobal("ContainerFrame"..i)
			if frame then
				local name = frame:GetName()
				local id = frame:GetID()
				for i = 1, MAX_CONTAINER_ITEMS do
					local button = getglobal(name.."Item"..i)
					local link = GetContainerItemLink(id, button:GetID())
					if button and link then
						button:SetAlpha(alpha)
					end
				end
			end
		end

		-- Bank
		if BankFrame:IsVisible() then
			for i = 1, 28 do
				local button = getglobal("BankFrameItem"..i)
				local link = GetContainerItemLink(-1, i)
				if button and link then
					button:SetAlpha(alpha)
				end
			end
		end
	end

	local function searchBags()
		-- Bags & Keyring
		for i = 1, 12 do
			local frame = getglobal("ContainerFrame"..i)
			if frame then
				local name = frame:GetName()
				local id = frame:GetID()
				for i = 1, MAX_CONTAINER_ITEMS do
					local button = getglobal(name.."Item"..i)
					local link = GetContainerItemLink(id, button:GetID())
					if button and button:IsShown() and link then
						local _, _, istring  = string.find(link, "|H(.+)|h")
						local name = GetItemInfo(istring)
						if strfind(strlower(name), strlower(string.gsub(this:GetText(), "([^%w])", "%%%1"))) then
							button:SetAlpha(1)
						end
					end
				end
			end
		end

		-- Bank
		if BankFrame:IsVisible() then
			for i = 1, 28 do
				local button = getglobal("BankFrameItem"..i)
				local link = GetContainerItemLink(-1, i)
				if button and link then
					local _, _, istring = string.find(link, "|H(.+)|h")
					local name = GetItemInfo(istring)
					if strfind(strlower(name), strlower(string.gsub(this:GetText(), "([^%w])", "%%%1"))) then
						button:SetAlpha(1)
					end
				end
			end
		end
	end

	local function reset()
		search.edit:SetText("Search")
		buttons(1)
	end

	search.edit:SetScript("OnEditFocusGained", function()
		search.edit:SetText("")
	end)

	search.edit:SetScript("OnEditFocusLost", function()
		reset()
	end)

	search.edit:SetScript("OnTabPressed", function()
		search.edit:ClearFocus()
		reset()
	end)

	search.edit:SetScript("OnTextChanged", function()
		if this:GetText() == "Search" then return end
		buttons(.25)
		searchBags()
	end)

	search:SetScript("OnShow", function()
		if ContainerFrame1:GetID() == 0 then
			-- Backpack
			search.edit:Show()
		else
			search.edit:Hide()
		end
	end)
end)
