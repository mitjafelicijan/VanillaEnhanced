local _G = getfenv(0)

-- Fix Shaman color to blue as it should be!
RAID_CLASS_COLORS['SHAMAN'] = { r = 0, g = 0, b = 1 }

-- Global fix for DropDownMenu nil concatenation error.
if not UIDROPDOWNMENU_OPEN_MENU then
	UIDROPDOWNMENU_OPEN_MENU = ""
end

if not VanillaEnhancedModules then
	VanillaEnhancedModules = {}
end

if not VanillaEnhancedData then
	VanillaEnhancedData = {}
end

if not VanillaEnhancedOptions then
	VanillaEnhancedOptions = {}
end

VE = {}

VE.panels = {}
VE.elements = {}
VE.modules = {}
VE.options = {}
VE.hooks = {}

VE.config = {
	Debug = false,
	BlackColor = { r = 0.00, g = 0.00, b = 0.00 },
	ClassColors = {
		Druid = { r = 1.00, g = 0.49, b = 0.04 },
		Hunter = { r = 0.67, g = 0.83, b = 0.45 },
		Mage = { r = 0.25, g = 0.78, b = 0.92 },
		Paladin = { r = 0.96, g = 0.55, b = 0.73 },
		Priest = { r = 1.00, g = 1.00, b = 1.00 },
		Rogue = { r = 1.00, g = 0.96, b = 0.41 },
		Shaman = { r = 0.14, g = 0.35, b = 1.00 },
		Warlock = { r = 0.53, g = 0.53, b = 0.93 },
		Warrior = { r = 0.78, g = 0.61, b = 0.43 },
	},
	PowerColors = {
		-- Mana = { r = 0.00, g = 0.70, b = 1.00 },  -- light blue
		Mana = { r = 1.00, g = 1.00, b = 1.00 },     -- white
		Rage = { r = 1.00, g = 0.00, b = 0.00 },
		Focus = { r = 1.00, g = 0.50, b = 0.25 },
		Energy = { r = 1.00, g = 1.00, b = 0.00 },
	},
}

VE.print = function(message)
	DEFAULT_CHAT_FRAME:AddMessage(tostring(message))
end

VE.dprint = function(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cff00b2ff[dbg] |cffffa500" .. tostring(message))
end

VE.eprint = function(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[err] |cffffa500" .. tostring(message))
end

VE.iprint = function(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cffff00ff[info] |cffffff00" .. tostring(message))
end

VE.printf = function(format, ...)
	if type(arg) == "table" then
		DEFAULT_CHAT_FRAME:AddMessage(string.format(format, unpack(arg)))
	else
		DEFAULT_CHAT_FRAME:AddMessage(format)
	end
end

VE.formattedTime = function()
	local currentTime = GetTime()
	local hours = mod(floor(currentTime / 3600), 24)
	local minutes = mod(floor(currentTime / 60), 60)
	local seconds = mod(floor(currentTime), 60)
	local milliseconds = floor((currentTime - floor(currentTime)) * 1000)

	return string.format("%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
end

VE.randomBetween = function(min, max)
	return math.random(min, max)
end

VE.randomKey = function(obj)
	local names = {}
	local count = 0
	for name in pairs(obj) do
		table.insert(names, name)
		count = count + 1
	end

	local index = math.random(1, count)
	local random = names[index]

	return random
end

VE.count = function(t)
	return table.getn(t)
end

VE.split = function(str, pattern)
	local tab = {}
	if str ~= nil then
		local part = ""
		for i = 1, strlen(str) do
			local c = strsub(str, i, i)
			if c ~= pattern then
				part = part .. c
			else
				table.insert(tab, VE.trim(part))
				part = ""
			end
			c = nil
		end

		-- Insert last one if there is one.
		if strlen(VE.trim(part)) > 0 then
			table.insert(tab, VE.trim(part))
		end
		part = nil
	end
	return tab
end

VE.replace = function(str, pattern, replacement)
	return string.gsub(str, pattern, replacement)
end

VE.trim = function(str)
	str = string.gsub(str, "^%s+", "")
	str = string.gsub(str, "%s+$", "")
	return str
end

VE.findAll = function(str, pattern)
	local results = {}

	local iterator = string.gfind(str, pattern)
	while true do
		local a, b, c, d, e, f, g, h, i = iterator()
		if not a then break end

		local captures = {}
		for _, v in ipairs({a, b, c, d, e, f, g, h, i}) do
			if v ~= nil then table.insert(captures, v) end
		end

		table.insert(results, captures)
	end

	return results
end

-- Example: local a, b = VE.find(link, "item:(%d+):%d*:.*|h%[(.-)%]|h")
VE.find = function(str, pattern)
	local all = VE.findAll(str, pattern)
	if all and all[1] then
		return unpack(all[1])
	end
	return nil
end

VE.startsWith = function(str, word)
	return string.find(str, "^" .. word) == 1
end

VE.removePrefix = function(str, prefix)
	local prefix_len = string.len(prefix)
	if string.sub(str, 1, prefix_len) == prefix then
		return string.sub(str, prefix_len + 1)  -- Remove prefix and following space
	end
	return str
end

VE.dframe = function(node, r, g, b, a)
	node.t = node:CreateTexture(nil, "BACKGROUND")
	node.t:SetAllPoints(node)
	node.t:SetTexture(r, g, b, a)
	node:Show()
end

VE.hooksecurefunc = function(name, func, append)
	if not _G[name] then return end

	VE.hooks[tostring(func)] = {}
	VE.hooks[tostring(func)]["old"] = _G[name]
	VE.hooks[tostring(func)]["new"] = func

	if append then
		VE.hooks[tostring(func)]["function"] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
			VE.hooks[tostring(func)]["old"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
			VE.hooks[tostring(func)]["new"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
		end
	else
		VE.hooks[tostring(func)]["function"] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
			VE.hooks[tostring(func)]["new"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
			VE.hooks[tostring(func)]["old"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
		end
	end

	_G[name] = VE.hooks[tostring(func)]["function"]
end

VE.getTableID = function(table)
	if type(table) == "table" then
		return string.sub(tostring(table), 8)
	end
	return nil
end

VE.getCoinText = function(money)
	if type(money) ~= "number" then return "-" end

	local gold = floor(money/100/100)
	local silver = floor(mod((money/100),100))
	local copper = floor(mod(money,100))

	local parts = {}
	if gold > 0 then table.insert(parts, string.format("%dg", gold)) end
	if silver > 0 then table.insert(parts, string.format("%ds", silver)) end
	if copper > 0 then table.insert(parts, string.format("%dc", copper)) end

	return table.getn(parts) > 0 and table.concat(parts, " ") or "0c"
end

VE.moneyStringToCopper = function(text)
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


VE.copperToMoneyString = function(money)
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

VE.copperToColoredMoneyString = function(money)
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

VE.registerModule = function(module)
	if VanillaEnhancedModules[module.identifier] == nil then
		VanillaEnhancedModules[module.identifier] = false
	end

	if module.options then
		for _, option in pairs(module.options) do
			if VanillaEnhancedOptions[option.identifier] == nil then
				VanillaEnhancedOptions[option.identifier] = false
			end

			table.insert(VE.options, option)
		end
	end

	table.insert(VE.modules, module)
	return module
end

VE.enableModule = function(identifier)
	VanillaEnhancedModules[identifier] = true
end

VE.disableModule = function(identifier)
	VanillaEnhancedModules[identifier] = false
end

VE.getModule = function(identifier)
	if VanillaEnhancedModules then
		for _, module in VE.modules do
			if module.identifier == identifier then
				module.enabled = VanillaEnhancedModules[identifier]
				return module
			end
		end
	end
	return nil
end

VE.enableOption = function(identifier)
	VanillaEnhancedOptions[identifier] = true
end

VE.disableOption = function(identifier)
	VanillaEnhancedOptions[identifier] = false
end

VE.getOption = function(identifier)
	if VanillaEnhancedOptions then
		for _, option in VE.options do
			if option.identifier == identifier then
				option.enabled = VanillaEnhancedOptions[identifier]
				return option
			end
		end
	end
	return nil
end

VE.superWoWCheck = function(module)
	if not SUPERWOW_VERSION and module.superWoWRequired then
		return false
	end
	return true
end

VE.listModules = function()
	VE.print("Registered modules:")
	for _, module in VE.modules do
		VE.print(" - " .. module.identifier)
	end
end

VE.isModuleEnabled = function(module)
	if  VanillaEnhancedModules and VanillaEnhancedModules[module] ~= nil then
		return VanillaEnhancedModules[module]
	end
end

VE.isOptionEnabled = function(option)
	if  VanillaEnhancedOptions and VanillaEnhancedOptions[option] ~= nil then
		return VanillaEnhancedOptions[option]
	end
end

VE.executeWithDelay = function(delay, fn)
	local frame = CreateFrame("Frame")
	frame.timeSinceLastUpdate = 0
	frame:SetScript("OnUpdate", function()
		if not arg1 then return end
		this.timeSinceLastUpdate = this.timeSinceLastUpdate + arg1
		if this.timeSinceLastUpdate >= delay then -- 0.1 seconds = 100ms
			fn()
			this:SetScript("OnUpdate", nil)
		end
	end)
end

VE.GetSpellNameById = function(spellId)
	return GetSpellName(spellId, "BOOKTYPE_SPELL");
end

VE.GetSpellIdByName = function(spellName, spellPage)
	local whatPage = spellPage;
	if not spellPage then whatPage = GetNumSpellTabs() end

	local _, _, offset, numSpells = GetSpellTabInfo(whatPage);
	numSpells = offset + numSpells;
	if not spellPage then offset = 0 end

	for spellId = numSpells, offset+1, -1 do
		if GetSpellName(spellId, "BOOKTYPE_SPELL") == spellName then
			return spellId;
		end
	end

	return nil;
end

VE.GetSpellInfoByID = function(id)
	if not GetSpellInfo["spells"][id] then
		return nil, nil, nil, nil, nil, nil
	end

	local name, rank, icon, cost, isFunnel, powerType
	name = GetSpellInfo["spells"][id]["name"]
	rank = GetSpellInfo["spells"][id]["rank"]
	icon = GetSpellInfo["spells"][id]["icon"]
	cost = GetSpellInfo["spells"][id]["cost"]
	isFunnel = GetSpellInfo["spells"][id]["isFunnel"]
	powerType = GetSpellInfo["spells"][id]["powerType"]
	return name, rank, icon, cost, isFunnel, powerType
end

-- FIXME: Clean up names
VE.GetSpellInfoByIcon = function(Icon)
	local resultArray = {}
	for id,v in pairs(GetSpellInfo["spells"]) do
		local name, rank, icon, cost, isFunnel, powerType
		name = GetSpellInfo["spells"][id]["name"]
		rank = GetSpellInfo["spells"][id]["rank"]
		icon = GetSpellInfo["spells"][id]["icon"]
		cost = GetSpellInfo["spells"][id]["cost"]
		isFunnel = GetSpellInfo["spells"][id]["isFunnel"]
		powerType = GetSpellInfo["spells"][id]["powerType"]
		if icon == Icon then
			if type(resultArray[id]) ~= "table" then resultArray[id] = {} end
			resultArray[id]["name"] = name
			resultArray[id]["rank"] = rank
			resultArray[id]["icon"] = icon
			resultArray[id]["cost"] = cost
			resultArray[id]["isFunnel"] = isFunnel
			resultArray[id]["powerType"] = powerType
		end
	end
	return resultArray
end

-- FIXME: Clean up names
VE.GetSpellInfoByName = function(Name)
	local resultArray = {}
	for id,v in pairs(GetSpellInfo["spells"]) do
		local name, rank, icon, cost, isFunnel, powerType
		name = GetSpellInfo["spells"][id]["name"]
		rank = GetSpellInfo["spells"][id]["rank"]
		icon = GetSpellInfo["spells"][id]["icon"]
		cost = GetSpellInfo["spells"][id]["cost"]
		isFunnel = GetSpellInfo["spells"][id]["isFunnel"]
		powerType = GetSpellInfo["spells"][id]["powerType"]
		if Name == name then
			if type(resultArray[id]) ~= "table" then resultArray[id] = {} end
			resultArray[id]["name"] = name
			resultArray[id]["rank"] = rank
			resultArray[id]["icon"] = icon
			resultArray[id]["cost"] = cost
			resultArray[id]["isFunnel"] = isFunnel
			resultArray[id]["powerType"] = powerType
		end
	end
	return resultArray
end

-- FIXME: Clean up names
VE.GetSpellInfoByIconAndName = function(Icon, Name)
	local resultArray = {}
	for id,v in pairs(GetSpellInfo["spells"]) do
		local name, rank, icon, cost, isFunnel, powerType
		name = GetSpellInfo["spells"][id]["name"]
		rank = GetSpellInfo["spells"][id]["rank"]
		icon = GetSpellInfo["spells"][id]["icon"]
		cost = GetSpellInfo["spells"][id]["cost"]
		isFunnel = GetSpellInfo["spells"][id]["isFunnel"]
		powerType = GetSpellInfo["spells"][id]["powerType"]
		if icon == Icon and name == Name then
			if type(resultArray[id]) ~= "table" then resultArray[id] = {} end
			resultArray[id]["name"] = name
			resultArray[id]["rank"] = rank
			resultArray[id]["icon"] = icon
			resultArray[id]["cost"] = cost
			resultArray[id]["isFunnel"] = isFunnel
			resultArray[id]["powerType"] = powerType
		end
	end
	return resultArray
end

VE.BoolToNumber = function(value)
	return value and 1 or 0
end

VE.normalizeKey = function(value)
	if not value then return nil end
	return string.lower(value)
end

VE.GetCVarAsBoolean = function(key)
	return tonumber(GetCVar(key)) ~= 0
end

VE.GetCVarAsNumber = function(key)
	return tonumber(GetCVar(key))
end

VE.GetCVarAsString = function(key)
	return tostring(GetCVar(key))
end

VE.SetCVar = function(key, value)
	if type(value) == "boolean" then
		value = value and 1 or 0
	end
	SetCVar(key, value)
end

VE.GetUVarAsBoolean = function(key)
	return tonumber(getglobal(key)) ~= 0
end

VE.GetUVarAsNumber = function(key)
	return tonumber(getglobal(key))
end

VE.GetUVarAsString = function(key)
	return tostring(getglobal(key))
end

VE.SetUVar = function(key, value)
	if type(value) == "boolean" then
		value = value and 1 or 0
	end
	setglobal(key, value)
end

VE.GetCVarAsBoolean = function(key)
	return tonumber(GetCVar(key)) ~= 0
end

VE.GetCVarAsNumber = function(key)
	return tonumber(GetCVar(key))
end

VE.GetCVarAsString = function(key)
	return tostring(GetCVar(key))
end

VE.SetCVar = function(key, value)
	if type(value) == "boolean" then
		value = value and 1 or 0
	end
	SetCVar(key, value)
end

VE.GetUVarAsBoolean = function(key)
	return tonumber(getglobal(key)) ~= 0
end

VE.GetUVarAsNumber = function(key)
	return tonumber(getglobal(key))
end

VE.GetUVarAsString = function(key)
	return tostring(getglobal(key))
end

VE.SetUVar = function(key, value)
	if type(value) == "boolean" then
		value = value and 1 or 0
	end
	setglobal(key, value)
end
