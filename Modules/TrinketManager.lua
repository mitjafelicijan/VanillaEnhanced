local module = VE.registerModule({
	identifier = "TrinketManager",
	meta = {
		label = "Trinket Manager",
		description = "Adds a frame to the bottom of the screen to manage your trinkets and idols.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		iconSize = 36,
		iconScale = 1.2,
		slots = {
			trinket1 = 13,
			trinker2 = 14,
			idol1 = 18,
		},
	},
	data = {},
})

local print = VE.print

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function FormatBindingText(keyText)
	if not keyText or type(keyText) ~= "string" then
		return ""
	end

	local replacements = {
		["SHIFT%-"] = "s-",
		["CTRL%-"] = "c-", 
		["ALT%-"] = "a-",
		["NUMPAD"] = "N",
		["PAGEUP"] = "PgUp",
		["PAGEDOWN"] = "PgDn"
	}

	local formatted = keyText
	for pattern, replacement in pairs(replacements) do
		formatted = string.gsub(formatted, pattern, replacement)
	end

	return formatted
end

local function GetBindingKeyText(name)
	local key = ""
	local key1, key2 = GetBindingKey("VE_USE_" .. string.upper(name))

	if key2 ~= "" then key = key2 end
	if key1 ~= "" then key = key1 end

	return FormatBindingText(key)
end

local function UpdateTrinketSlot(name, slot)
	local trinketLink = GetInventoryItemLink("player", slot)
	local texture = GetInventoryItemTexture("player", slot)

	if not texture then
		module.plug.frame[name]:Hide()
		return
	end

	module.plug.frame[name]:SetNormalTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
	module.plug.frame[name]:SetPushedTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

	module.plug.frame[name]:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
	module.plug.frame[name]:GetHighlightTexture():SetAllPoints()
	module.plug.frame[name]:GetHighlightTexture():SetBlendMode("ADD")
	module.plug.frame[name]:Show()

	local start, duration, enable = GetInventoryItemCooldown("player", slot)
	CooldownFrame_SetTimer(module.plug.frame[name].cooldown, start or 0, duration or 0, enable or 0)

	module.plug.frame[name]:SetScript("OnEnter", function()
		if trinketLink then
			GameTooltip:SetOwner(module.plug.frame[name], "ANCHOR_RIGHT")
			GameTooltip:SetInventoryItem("player", slot)
			GameTooltip:Show()
		end
	end)
	module.plug.frame[name]:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

local function CreateTrinketSlot(parent, name, offset, slot)
	module.plug.frame[name] = CreateFrame("Button", name, parent)
	module.plug.frame[name]:SetWidth(module.config.iconSize * module.config.iconScale)
	module.plug.frame[name]:SetHeight(module.config.iconSize * module.config.iconScale)
	module.plug.frame[name]:SetPoint("Left", parent, "Left", offset, 0)

	module.plug.frame[name].cooldown = CreateFrame("Model", name.."Cooldown", module.plug.frame[name], "CooldownFrameTemplate")
	module.plug.frame[name].cooldown:SetAllPoints()
	module.plug.frame[name].cooldown:SetFrameLevel(module.plug.frame[name]:GetFrameLevel() + 1)
	module.plug.frame[name].cooldown:SetScale(module.config.iconScale)
	module.plug.frame[name].cooldown.ScaleSet = true

	module.plug.frame[name].hotkey = module.plug.frame[name]:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	module.plug.frame[name].hotkey:SetPoint("TOPRIGHT", -2, -2)
	module.plug.frame[name].hotkey:SetTextColor(0.7, 0.7, 0.7)
	module.plug.frame[name].hotkey:SetText(GetBindingKeyText(name))

	VE.executeWithDelay(0.5, function()
		UpdateTrinketSlot(name, slot)
	end)

	module.plug.frame[name]:SetScript("OnClick", function()
		UseInventoryItem(slot)
	end)
end

local function UpdateIdolSlot(name, slot)
	local trinketLink = GetInventoryItemLink("player", slot)
	local texture = GetInventoryItemTexture("player", slot)

	if not module.plug.frame[name] then return end

	module.plug.frame[name]:SetNormalTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
	module.plug.frame[name]:SetPushedTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

	module.plug.frame[name]:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
	module.plug.frame[name]:GetHighlightTexture():SetAllPoints()
	module.plug.frame[name]:GetHighlightTexture():SetBlendMode("ADD")

	module.plug.frame[name]:SetScript("OnEnter", function()
		if trinketLink then
			GameTooltip:SetOwner(module.plug.frame[name], "ANCHOR_RIGHT")
			GameTooltip:SetInventoryItem("player", slot)
			GameTooltip:Show()
		end
	end)
	module.plug.frame[name]:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

local function CreateIdolSlot(parent, name, offset, slot)
	module.plug.frame[name] = CreateFrame("Button", name, parent)
	module.plug.frame[name]:SetWidth(module.config.iconSize * module.config.iconScale)
	module.plug.frame[name]:SetHeight(module.config.iconSize * module.config.iconScale)
	module.plug.frame[name]:SetPoint("Left", parent, "Left", offset, 0)

	VE.executeWithDelay(0.5, function()
		UpdateIdolSlot(name, slot)
	end)

	module.plug.frame[name]:SetScript("OnClick", function()
		UseInventoryItem(slot)
	end)
end

function UseTrinket1()
	UseInventoryItem(module.config.slots.trinket1)

	local start, duration = GetInventoryItemCooldown("player", module.config.slots.trinket1)
	CooldownFrame_SetTimer(module.plug.frame["Trinket1"].cooldown, start or GetTime(), duration or 30, 1)

	VE.executeWithDelay(0.5, function()
		UpdateTrinketSlot("Trinket1", module.config.slots.trinket1)
	end)
end

function UseTrinket2()
	UseInventoryItem(module.config.slots.trinket2)

	local start, duration = GetInventoryItemCooldown("player", module.config.slots.trinket2)
	CooldownFrame_SetTimer(module.plug.frame["Trinket2"].cooldown, start or GetTime(), duration or 30, 1)

	VE.executeWithDelay(0.5, function()
		UpdateTrinketSlot("Trinket2", module.config.slots.trinket2)
	end)
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("UNIT_INVENTORY_CHANGED")
module.plug:RegisterEvent("SPELL_UPDATE_COOLDOWN")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" and not module.plug.frame then
		local parent = MultiBarBottomRight

		if CompactActionBars and CompactActionBarsRight then
			parent = CompactActionBarsRight
		end

		module.plug.frame = CreateFrame("Frame", "TrinketManagerFrame", MultiBarBottomRight)
		module.plug.frame:SetPoint("Right", parent, "BottomRight", -1, (module.config.iconSize * 2) - 2)
		module.plug.frame:SetWidth(module.config.iconSize * 3 + 25)
		module.plug.frame:SetHeight(module.config.iconSize)
		module.plug.frame:SetFrameStrata("LOW")

		CreateTrinketSlot(module.plug.frame, "Trinket1", (module.config.iconSize * module.config.iconScale * 1) + 2, 13)
		CreateTrinketSlot(module.plug.frame, "Trinket2", (module.config.iconSize * module.config.iconScale * 2) + 4, 14)

		if UnitClass("player") == "Druid" then
			CreateIdolSlot(module.plug.frame, "Idol1", 0, module.config.slots.idol1)
		end
	end

	if event == "UNIT_INVENTORY_CHANGED" then
		if arg1 == "player" then
			UpdateTrinketSlot("Trinket1", 13)
			UpdateTrinketSlot("Trinket2", 14)
			UpdateIdolSlot("Idol1", module.config.slots.idol1)
		end
	end

	if event == "SPELL_UPDATE_COOLDOWN" then
		UpdateTrinketSlot("Trinket1", 13)
		UpdateTrinketSlot("Trinket2", 14)
	end
end)
