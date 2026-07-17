-- Based on ShaguDPS
-- https://github.com/shagu/ShaguDPS

local module = VE.registerModule({
	identifier = "DpsMeter",
	meta = {
		label = "DPS Meter",
		description = "A simple and lightweight DPS and damage meter.",
	},
	config = {
		height = 15,
		spacing = 0,
		visible = false,
		texture = 2,
		pastel = false,
		lock = false,
		width = 177,
		bars = 8,
		bgAlpha = 0.2,
		segment = 0, -- 0: Overall, 1: Current
		view = 1, -- 1: Damage, 2: DPS, 3: Heal, 4: HPS
	},
})

-- ShaguDPS logic adapted for VanillaEnhanced
module.data = {
	damage = { [0] = {}, [1] = {} },
	heal = { [0] = {}, [1] = {} },
	classes = {},
}

local internals = { ["_sum"] = true, ["_ctime"] = true, ["_tick"] = true, ["_esum"] = true, ["_effective"] = true }
local textures = {
	"Interface\\BUTTONS\\WHITE8X8",
	"Interface\\TargetingFrame\\UI-StatusBar",
	"Interface\\Tooltips\\UI-Tooltip-Background",
	"Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar"
}

local backdrop_window = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local backdrop_border = {
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local backdrop_button = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 8,
	insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

local function round(input, places)
	if not places then places = 0 end
	if type(input) == "number" and type(places) == "number" then
		local pow = 1
		for i = 1, places do pow = pow * 10 end
		return floor(input * pow + 0.5) / pow
	end
end

local function formatNumber(n, decimal)
	if not n then return "0" end
	if n >= 1000000 then
		return string.format("%.1fm", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fk", n / 1000)
	else
		return tostring(decimal and round(n, 1) or floor(n))
	end
end

-- Parser Logic
local validUnits = { ["player"] = true }
for i=1,4 do validUnits["party" .. i] = true end
for i=1,40 do validUnits["raid" .. i] = true end

local validPets = { ["pet"] = true }
for i=1,4 do validPets["partypet" .. i] = true end
for i=1,40 do validPets["raidpet" .. i] = true end

local unit_cache = {}
local function UnitByName(name)
	if unit_cache[name] and UnitName(unit_cache[name]) == name then return unit_cache[name] end
	for unit in pairs(validUnits) do if UnitName(unit) == name then unit_cache[name] = unit return unit end end
	for unit in pairs(validPets) do if UnitName(unit) == name then unit_cache[name] = unit return unit end end
end

local function combat()
	if UnitAffectingCombat("player") or UnitAffectingCombat("pet") then return true end
	local raid, group = GetNumRaidMembers(), GetNumPartyMembers()
	if raid >= 1 then
		for i = 1, raid do if UnitAffectingCombat("raid"..i) or UnitAffectingCombat("raidpet"..i) then return true end end
	else
		for i = 1, group do if UnitAffectingCombat("party"..i) or UnitAffectingCombat("partypet"..i) then return true end end
	end
	return nil
end

local start_next_segment = nil
local parserFrame = CreateFrame("Frame")
parserFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
parserFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

parserFrame.UpdateState = function(self)
	local state = combat() == true and "COMBAT" or "NO_COMBAT"
	if not self.oldstate or self.oldstate ~= state then
		self.oldstate = state
		if state == "NO_COMBAT" then start_next_segment = true end
	end
end

parserFrame:SetScript("OnEvent", function() this:UpdateState() end)
parserFrame:SetScript("OnUpdate", function()
	if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end
	this:UpdateState()
end)

local function ScanName(name)
	if not name then return end
	for unit, _ in pairs(validUnits) do
		if UnitExists(unit) and UnitName(unit) == name then
			if UnitIsPlayer(unit) then
				local _, class = UnitClass(unit)
				module.data["classes"][name] = class
				return "PLAYER"
			end
		end
	end
	for unit, _ in pairs(validPets) do
		if UnitExists(unit) and UnitName(unit) == name then
			if strsub(unit,0,3) == "pet" then module.data["classes"][name] = UnitName("player")
			elseif strsub(unit,0,8) == "partypet" then module.data["classes"][name] = UnitName("party" .. strsub(unit,9))
			elseif strsub(unit,0,7) == "raidpet" then module.data["classes"][name] = UnitName("raid" .. strsub(unit,8))
			end
			return "PET"
		end
	end
end

local function AddData(source, action, target, value, school, datatype)
	if type(source) ~= "string" or not tonumber(value) then return end
	source = VE.trim(source)
	if datatype == "damage" and source == target then return end

	if start_next_segment and module.data["classes"][source] then
		module.data["damage"][1] = {}
		module.data["heal"][1] = {}
		start_next_segment = nil
	end

	local effective = 0
	if datatype == "heal" then
		local unitstr = UnitByName(target)
		if unitstr then effective = math.min(UnitHealthMax(unitstr) - UnitHealth(unitstr), value) end
	end

	for segment = 0, 1 do
		local entry = module.data[datatype][segment]
		if not entry[source] then
			local type = ScanName(source)
			if type == "PET" then
				local owner = module.data["classes"][source]
				if not entry[owner] and ScanName(owner) then entry[owner] = { ["_sum"] = 0, ["_ctime"] = 1 } end
			elseif not type then break end
			entry[source] = { ["_sum"] = 0, ["_ctime"] = 1 }
		end

		if entry[source] then
			entry[source][action] = (entry[source][action] or 0) + tonumber(value)
			entry[source]["_sum"] = (entry[source]["_sum"] or 0) + tonumber(value)
			if datatype == "heal" then
				entry[source]["_esum"] = (entry[source]["_esum"] or 0) + tonumber(effective)
				entry[source]["_effective"] = entry[source]["_effective"] or {}
				entry[source]["_effective"][action] = (entry[source]["_effective"][action] or 0) + tonumber(effective)
			end
			entry[source]["_ctime"] = entry[source]["_ctime"] or 1
			entry[source]["_tick"] = entry[source]["_tick"] or GetTime()
			if entry[source]["_tick"] + 5 < GetTime() then
				entry[source]["_tick"] = GetTime()
				entry[source]["_ctime"] = entry[source]["_ctime"] + 5
			else
				entry[source]["_ctime"] = entry[source]["_ctime"] + (GetTime() - entry[source]["_tick"])
				entry[source]["_tick"] = GetTime()
			end
		end
	end
	if module.frame then module.frame.needs_refresh = true end
end

-- Parser Vanilla Logic
local sanitize_cache = {}
local function sanitize(pattern)
	if not sanitize_cache[pattern] then
		local ret = pattern
		ret = gsub(ret, "([%+%-%*%(%)%?%[%]%^])", "%%%1")
		ret = gsub(ret, "%d%$","")
		ret = gsub(ret, "(%%%a)","%(%1+%)")
		ret = gsub(ret, "%%s%+",".+")
		ret = gsub(ret, "%(.%+%)%(%%d%+%)","%(.-%)%(%%d%+%)")
		sanitize_cache[pattern] = ret
	end
	return sanitize_cache[pattern]
end

local capture_cache = {}
local function captures(pat)
	if not capture_cache[pat] then
		capture_cache[pat] = { nil, nil, nil, nil, nil }
		for a, b, c, d, e in string.gfind(gsub(pat, "%((.+)%)", "%1"), gsub(pat, "%d%$", "%%(.-)$")) do
			capture_cache[pat][1], capture_cache[pat][2], capture_cache[pat][3], capture_cache[pat][4], capture_cache[pat][5] = tonumber(a), tonumber(b), tonumber(c), tonumber(d), tonumber(e)
		end
	end
	local r = capture_cache[pat]
	return r[1], r[2], r[3], r[4], r[5]
end

local function cfind(str, pat)
	local a, b, c, d, e = captures(pat)
	local match, num, va, vb, vc, vd, ve = string.find(str, sanitize(pat))
	local ra = e == 1 and ve or d == 1 and vd or c == 1 and vc or b == 1 and vb or va
	local rb = e == 2 and ve or d == 2 and vd or c == 2 and vc or a == 2 and va or vb
	local rc = e == 3 and ve or d == 3 and vd or a == 3 and va or b == 3 and vb or vc
	local rd = e == 4 and ve or a == 4 and va or c == 4 and vc or b == 4 and vb or vd
	local re = a == 5 and va or d == 5 and vd or c == 5 and vc or b == 5 and vb or ve
	return match, num, ra, rb, rc, rd, re
end

local combatlog_strings = {
	["Hit Damage (self vs. other)"] = { COMBATHITSELFOTHER, COMBATHITSCHOOLSELFOTHER, COMBATHITCRITSELFOTHER, COMBATHITCRITSCHOOLSELFOTHER },
	["Hit Damage (other vs. self)"] = { COMBATHITOTHERSELF, COMBATHITCRITOTHERSELF, COMBATHITSCHOOLOTHERSELF, COMBATHITCRITSCHOOLOTHERSELF },
	["Hit Damage (other vs. other)"] = { COMBATHITOTHEROTHER, COMBATHITCRITOTHEROTHER, COMBATHITSCHOOLOTHEROTHER, COMBATHITCRITSCHOOLOTHEROTHER },
	["Spell Damage (self vs. self/other)"] = { SPELLLOGSCHOOLSELFSELF, SPELLLOGCRITSCHOOLSELFSELF, SPELLLOGSELFSELF, SPELLLOGCRITSELFSELF, SPELLLOGSCHOOLSELFOTHER, SPELLLOGCRITSCHOOLSELFOTHER, SPELLLOGSELFOTHER, SPELLLOGCRITSELFOTHER },
	["Spell Damage (other vs. self)"] = { SPELLLOGSCHOOLOTHERSELF, SPELLLOGCRITSCHOOLOTHERSELF, SPELLLOGOTHERSELF, SPELLLOGCRITOTHERSELF },
	["Spell Damage (other vs. other)"] = { SPELLLOGSCHOOLOTHEROTHER, SPELLLOGCRITSCHOOLOTHEROTHER, SPELLLOGOTHEROTHER, SPELLLOGCRITOTHEROTHER },
	["Shield Damage (self vs. other)"] = { DAMAGESHIELDSELFOTHER },
	["Shield Damage (other vs. self/other)"] = { DAMAGESHIELDOTHERSELF, DAMAGESHIELDOTHEROTHER },
	["Periodic Damage (self/other vs. other)"] = { PERIODICAURADAMAGESELFOTHER, PERIODICAURADAMAGEOTHEROTHER },
	["Periodic Damage (self/other vs. self)"] = { PERIODICAURADAMAGESELFSELF, PERIODICAURADAMAGEOTHERSELF },
	["Heal (self vs. self/other)"] = { HEALEDCRITSELFSELF, HEALEDSELFSELF, HEALEDCRITSELFOTHER, HEALEDSELFOTHER },
	["Heal (other vs. self/other)"] = { HEALEDCRITOTHERSELF, HEALEDOTHERSELF, HEALEDCRITOTHEROTHER, HEALEDOTHEROTHER },
	["Periodic Heal (self/other vs. other)"] = { PERIODICAURAHEALSELFOTHER, PERIODICAURAHEALOTHEROTHER },
	["Periodic Heal (other vs. self/other)"] = { PERIODICAURAHEALSELFSELF, PERIODICAURAHEALOTHERSELF }
}

local combatlog_events = {
	["CHAT_MSG_COMBAT_SELF_HITS"] = combatlog_strings["Hit Damage (self vs. other)"],
	["CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS"] = combatlog_strings["Hit Damage (other vs. self)"],
	["CHAT_MSG_COMBAT_PARTY_HITS"] = combatlog_strings["Hit Damage (other vs. other)"],
	["CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS"] = combatlog_strings["Hit Damage (other vs. other)"],
	["CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS"] = combatlog_strings["Hit Damage (other vs. other)"],
	["CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS"] = combatlog_strings["Hit Damage (other vs. other)"],
	["CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS"] = combatlog_strings["Hit Damage (other vs. other)"],
	["CHAT_MSG_COMBAT_PET_HITS"] = combatlog_strings["Hit Damage (other vs. other)"],
	["CHAT_MSG_SPELL_SELF_DAMAGE"] = combatlog_strings["Spell Damage (self vs. self/other)"],
	["CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE"] = combatlog_strings["Spell Damage (other vs. self)"],
	["CHAT_MSG_SPELL_PARTY_DAMAGE"] = combatlog_strings["Spell Damage (other vs. other)"],
	["CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE"] = combatlog_strings["Spell Damage (other vs. other)"],
	["CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE"] = combatlog_strings["Spell Damage (other vs. other)"],
	["CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE"] = combatlog_strings["Spell Damage (other vs. other)"],
	["CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE"] = combatlog_strings["Spell Damage (other vs. other)"],
	["CHAT_MSG_SPELL_PET_DAMAGE"] = combatlog_strings["Spell Damage (other vs. other)"],
	["CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF"] = combatlog_strings["Shield Damage (self vs. other)"],
	["CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS"] = combatlog_strings["Shield Damage (other vs. self/other)"],
	["CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE"] = combatlog_strings["Periodic Damage (self/other vs. other)"],
	["CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE"] = combatlog_strings["Periodic Damage (self/other vs. other)"],
	["CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE"] = combatlog_strings["Periodic Damage (self/other vs. other)"],
	["CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE"] = combatlog_strings["Periodic Damage (self/other vs. other)"],
	["CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE"] = combatlog_strings["Periodic Damage (self/other vs. self)"],
	["CHAT_MSG_SPELL_SELF_BUFF"] = combatlog_strings["Heal (self vs. self/other)"],
	["CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF"] = combatlog_strings["Heal (other vs. self/other)"],
	["CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF"] = combatlog_strings["Heal (other vs. self/other)"],
	["CHAT_MSG_SPELL_PARTY_BUFF"] = combatlog_strings["Heal (other vs. self/other)"],
	["CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS"] = combatlog_strings["Periodic Heal (self/other vs. other)"],
	["CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS"] = combatlog_strings["Periodic Heal (self/other vs. other)"],
	["CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS"] = combatlog_strings["Periodic Heal (self/other vs. other)"],
	["CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS"] = combatlog_strings["Periodic Heal (other vs. self/other)"]
}

local combatlog_parser = {
	[SPELLLOGSCHOOLSELFSELF] = function(d, attack, value, school) return d.source, attack, d.target, value, school, "damage" end,
	[SPELLLOGCRITSCHOOLSELFSELF] = function(d, attack, value, school) return d.source, attack, d.target, value, school, "damage" end,
	[SPELLLOGSELFSELF] = function(d, attack, value) return d.source, attack, d.target, value, d.school, "damage" end,
	[SPELLLOGCRITSELFSELF] = function(d, attack, value) return d.source, attack, d.target, value, d.school, "damage" end,
	[PERIODICAURADAMAGESELFSELF] = function(d, value, school, attack) return d.source, attack, d.target, value, school, "damage" end,
	[SPELLLOGSCHOOLSELFOTHER] = function(d, attack, target, value, school) return d.source, attack, target, value, school, "damage" end,
	[SPELLLOGCRITSCHOOLSELFOTHER] = function(d, attack, target, value, school) return d.source, attack, target, value, school, "damage" end,
	[SPELLLOGSELFOTHER] = function(d, attack, target, value) return d.source, attack, target, value, d.school, "damage" end,
	[SPELLLOGCRITSELFOTHER] = function(d, attack, target, value) return d.source, attack, target, value, d.school, "damage" end,
	[PERIODICAURADAMAGESELFOTHER] = function(d, target, value, school, attack) return d.source, attack, target, value, school, "damage" end,
	[COMBATHITSELFOTHER] = function(d, target, value) return d.source, d.attack, target, value, d.school, "damage" end,
	[COMBATHITCRITSELFOTHER] = function(d, target, value) return d.source, d.attack, target, value, d.school, "damage" end,
	[COMBATHITSCHOOLSELFOTHER] = function(d, target, value, school) return d.source, d.attack, target, value, school, "damage" end,
	[COMBATHITCRITSCHOOLSELFOTHER] = function(d, target, value, school) return d.source, d.attack, target, value, school, "damage" end,
	[DAMAGESHIELDSELFOTHER] = function(d, value, school, target) return d.source, "Reflect ("..school..")", target, value, school, "damage" end,
	[SPELLLOGSCHOOLOTHERSELF] = function(d, source, attack, value, school) return source, attack, d.target, value, school, "damage" end,
	[SPELLLOGCRITSCHOOLOTHERSELF] = function(d, source, attack, value, school) return source, attack, d.target, value, school, "damage" end,
	[SPELLLOGOTHERSELF] = function(d, source, attack, value) return source, attack, d.target, value, d.school, "damage" end,
	[SPELLLOGCRITOTHERSELF] = function(d, source, attack, value) return source, attack, d.target, value, d.school, "damage" end,
	[PERIODICAURADAMAGEOTHERSELF] = function(d, value, school, source, attack) return source, attack, d.target, value, school, "damage" end,
	[COMBATHITOTHERSELF] = function(d, source, value) return source, d.attack, d.target, value, d.school, "damage" end,
	[COMBATHITCRITOTHERSELF] = function(d, source, value) return source, d.attack, d.target, value, d.school, "damage" end,
	[COMBATHITSCHOOLOTHERSELF] = function(d, source, value, school) return source, d.attack, d.target, value, school, "damage" end,
	[COMBATHITCRITSCHOOLOTHERSELF] = function(d, source, value, school) return source, d.attack, d.target, value, school, "damage" end,
	[SPELLLOGSCHOOLOTHEROTHER] = function(d, source, attack, target, value, school) return source, attack, target, value, school, "damage" end,
	[SPELLLOGCRITSCHOOLOTHEROTHER] = function(d, source, attack, target, value, school) return source, attack, target, value, school, "damage" end,
	[SPELLLOGOTHEROTHER] = function(d, source, attack, target, value) return source, attack, target, value, d.school, "damage" end,
	[SPELLLOGCRITOTHEROTHER] = function(d, source, attack, target, value, school) return source, attack, target, value, school, "damage" end,
	[PERIODICAURADAMAGEOTHEROTHER] = function(d, target, value, school, source, attack) return source, attack, target, value, school, "damage" end,
	[COMBATHITOTHEROTHER] = function(d, source, target, value) return source, d.attack, target, value, d.school, "damage" end,
	[COMBATHITCRITOTHEROTHER] = function(d, source, target, value) return source, d.attack, target, value, d.school, "damage" end,
	[COMBATHITSCHOOLOTHEROTHER] = function(d, source, target, value, school) return source, d.attack, target, value, school, "damage" end,
	[COMBATHITCRITSCHOOLOTHEROTHER] = function(d, source, target, value, school) return source, d.attack, target, value, school, "damage" end,
	[DAMAGESHIELDOTHERSELF] = function(d, source, value, school) return source, "Reflect ("..school..")", d.target, value, school, "damage" end,
	[DAMAGESHIELDOTHEROTHER] = function(d, source, value, school, target) return source, "Reflect ("..school..")", target, value, school, "damage" end,
	[HEALEDCRITOTHERSELF] = function(d, source, spell, value) return source, spell, d.target, value, d.school, "heal" end,
	[HEALEDOTHERSELF] = function(d, source, spell, value) return source, spell, d.target, value, d.school, "heal" end,
	[PERIODICAURAHEALOTHERSELF] = function(d, value, source, spell) return source, spell, d.target, value, d.school, "heal" end,
	[HEALEDCRITSELFSELF] = function(d, spell, value) return d.source, spell, d.target, value, d.school, "heal" end,
	[HEALEDSELFSELF] = function(d, spell, value) return d.source, spell, d.target, value, d.school, "heal" end,
	[PERIODICAURAHEALSELFSELF] = function(d, value, spell) return d.source, spell, d.target, value, d.school, "heal" end,
	[HEALEDCRITSELFOTHER] = function(d, spell, target, value) return d.source, spell, target, value, d.school, "heal" end,
	[HEALEDSELFOTHER] = function(d, spell, target, value) return d.source, spell, target, value, d.school, "heal" end,
	[PERIODICAURAHEALSELFOTHER] = function(d, target, value, spell) return d.source, spell, target, value, d.school, "heal" end,
	[HEALEDCRITOTHEROTHER] = function(d, source, spell, target, value) return source, spell, target, value, d.school, "heal" end,
	[HEALEDOTHEROTHER] = function(d, source, spell, target, value) return source, spell, target, value, d.school, "heal" end,
	[PERIODICAURAHEALOTHEROTHER] = function(d, target, value, source, spell) return source, spell, target, value, d.school, "heal" end,
}

local logFrame = CreateFrame("Frame")
for event in pairs(combatlog_events) do logFrame:RegisterEvent(event) end
local absorb = sanitize(ABSORB_TRAILER)
local resist = sanitize(RESIST_TRAILER)
local defaults = {}
local player = UnitName("player")

logFrame:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	if not arg1 then return end
	arg1 = string.gsub(arg1, absorb, "")
	arg1 = string.gsub(arg1, resist, "")
	defaults.source, defaults.target, defaults.school, defaults.attack, defaults.spell, defaults.value = player, player, "physical", "Auto Hit", UNKNOWN, 0
	for _, pattern in pairs(combatlog_events[event]) do
		local result, num, a1, a2, a3, a4, a5 = cfind(arg1, pattern)
		if result then return AddData(combatlog_parser[pattern](defaults, a1, a2, a3, a4, a5)) end
	end
end)

-- UI Logic
local function spairs(t, order)
	local keys = {}
	for k in pairs(t) do table.insert(keys, k) end
	if order then table.sort(keys, function(a,b) return order(t, a, b) end) else table.sort(keys) end
	local i = 0
	return function() i = i + 1; if keys[i] then return keys[i], t[keys[i]] end end
end

local sort_algorithms = {
	normal = function(t,a,b)
		if t[a]["_esum"] and t[b]["_esum"] and t[a]["_esum"] ~= t[b]["_esum"] then return t[b]["_esum"] < t[a]["_esum"]
		else return t[b]["_sum"] < t[a]["_sum"] end
	end,
	per_second = function(t,a,b)
		if t[a]["_esum"] and t[b]["_esum"] and t[a]["_esum"] ~= t[b]["_esum"] then return t[b]["_esum"] / t[b]["_ctime"] < t[a]["_esum"] / t[a]["_ctime"]
		else return t[b]["_sum"] / t[b]["_ctime"] < t[a]["_sum"] / t[a]["_ctime"] end
	end,
	single_spell = function(t,a,b)
		if t["_effective"] and t["_effective"][a] and t["_effective"][b] and t["_effective"][a] ~= t["_effective"][b] then return t["_effective"][b] < t["_effective"][a]
		elseif tonumber(t[b]) and tonumber(t[a]) then return t[b] < t[a] end
	end
}

local function barTooltipShow()
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT")

	local segment = this:GetParent().segment
	local unit = this.unit
	if not segment or not unit or not segment[unit] then return end

	local value = segment[unit]["_sum"]
	local persec = round(segment[unit]["_sum"] / segment[unit]["_ctime"], 1)

	GameTooltip:AddLine(unit .. ":")

	if module.config.view == 1 or module.config.view == 2 then
		GameTooltip:AddDoubleLine("|cffffffffDamage", "|cffffffff" .. formatNumber(value))
		GameTooltip:AddDoubleLine("|cffffffffDamage Per Second", "|cffffffff" .. formatNumber(persec, true))
	elseif module.config.view == 3 or module.config.view == 4 then
		local evalue = segment[unit]["_esum"] or 0
		local epersec = round(evalue / segment[unit]["_ctime"], 1)

		GameTooltip:AddDoubleLine("|cffffffffHealing", "|cffffffff" .. formatNumber(evalue))
		GameTooltip:AddDoubleLine("|cffaaaaaaOverheal", "|cffcc8888+" .. formatNumber(value - evalue))
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine("|cffffffffHealing Per Second", "|cffffffff" .. formatNumber(epersec, true))
		GameTooltip:AddDoubleLine("|cffaaaaaaOverheal Per Second", "|cffcc8888+" .. formatNumber(persec - epersec, true))
	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Details:")

	for attack, damage in spairs(segment[unit], sort_algorithms.single_spell) do
		if attack and not internals[attack] then
			local percent = damage == 0 and 0 or round(damage / segment[unit]["_sum"] * 100, 1)
			if segment[unit]["_effective"] and segment[unit]["_effective"][attack] then
				local effective = segment[unit]["_effective"][attack]
				local epercent = effective == 0 and 0 or round(effective / segment[unit]["_esum"] * 100, 1)
				local str = string.format("|cffcc8888+%s|cffffffff %s (%.1f%%)", formatNumber(damage - effective), formatNumber(effective), epercent)
				GameTooltip:AddDoubleLine("|cffffffff" .. attack, str)
			else
				local str = string.format("|cffffffff %s (%.1f%%)", formatNumber(damage), percent)
				GameTooltip:AddDoubleLine("|cffffffff" .. attack, str)
			end
		end
	end
	GameTooltip:Show()
end

local function barTooltipHide()
	GameTooltip:Hide()
end

local view_templates = {
	[1] = { name = "Damage", sort = "normal", bar_max = "best", bar_val = "value", bar_string = "%s (%.1f%%)", params = { "value", "percent" } },
	[2] = { name = "DPS", sort = "per_second", bar_max = "persecond_best", bar_val = "value_persecond", bar_string = "%s (%.1f%%)", params = { "value_persecond", "percent_persecond" } },
	[3] = { name = "Heal", sort = "normal", bar_max = "best", bar_val = "effective_value", lower_max = "best", lower_val = "value", bar_string = "%s (%.1f%%)", params = { "effective_value", "effective_percent" } },
	[4] = { name = "HPS", sort = "per_second", bar_max = "persecond_best", bar_val = "effective_value_persecond", lower_max = "persecond_best", lower_val = "value_persecond", bar_string = "%s (%.1f%%)", params = { "effective_value_persecond", "effective_percent" } },
}

module.updateTransparency = function(val)
	module.config.bgAlpha = val
	if not VanillaEnhancedData["DpsMeter"] then VanillaEnhancedData["DpsMeter"] = {} end
	VanillaEnhancedData["DpsMeter"].bgAlpha = val
	if module.frame then
		module.frame:SetBackdropColor(0, 0, 0, val)
	end
end

local function Resize(self)
	local width = self:GetWidth()
	local height = self:GetTop() - self:GetBottom()
	local bars = (height - 24) / module.config.height
	bars = math.floor(bars)

	module.config.width = width
	if module.config.bars ~= bars then
		module.config.bars = bars
		self:Refresh()
	end

	-- Save size
	if not VanillaEnhancedData["DpsMeter"] then VanillaEnhancedData["DpsMeter"] = {} end
	VanillaEnhancedData["DpsMeter"].width = module.config.width
	VanillaEnhancedData["DpsMeter"].bars = module.config.bars
end

local function Refresh(self, force)
	if not VE.isModuleEnabled(module.identifier) then self:Hide(); return end
	if module.config.visible then self:Show() else self:Hide(); return end

	local wid = module.identifier
	local cfg = module.config

	if force then
		self:SetWidth(cfg.width)
		self:SetHeight(cfg.height * cfg.bars + 24 + 3)
		self.btnSegment.caption:SetText(cfg.segment == 1 and "Current" or "Overall")
		self.btnMode.caption:SetText(view_templates[cfg.view].name)
	end

	for _, bar in pairs(self.bars) do bar:Hide(); bar.lowerBar:Hide() end

	local datatype = (cfg.view == 1 or cfg.view == 2) and "damage" or "heal"
	local segment = module.data[datatype][cfg.segment]
	local template = view_templates[cfg.view]

	-- GetCaps
	local caps = { best = 0, all = 0, persecond_best = 0, persecond_all = 0, effective_best = 0, effective_all = 0, effective_persecond_best = 0, effective_persecond_all = 0 }
	local count = 0
	for name, data in pairs(segment) do
		count = count + 1
		if data["_sum"] and data["_ctime"] then
			caps.all = caps.all + data["_sum"]
			if data["_sum"] > caps.best then caps.best = data["_sum"] end
			caps.persecond_all = caps.persecond_all + data["_sum"] / data["_ctime"]
			if data["_sum"] / data["_ctime"] > caps.persecond_best then caps.persecond_best = data["_sum"] / data["_ctime"] end
		end
		if data["_esum"] and data["_ctime"] then
			caps.effective_all = caps.effective_all + data["_esum"]
			caps.effective_persecond_all = caps.effective_persecond_all + data["_esum"] / data["_ctime"]
			if data["_esum"] / data["_ctime"] > caps.effective_persecond_best then caps.effective_persecond_best = data["_esum"] / data["_ctime"] end
		end
	end

	self.segment = segment

	local i = 1
	for name, unitdata in spairs(segment, sort_algorithms[template.sort]) do
		local barIndex = i - (self.scroll or 0)
		if barIndex >= 1 and barIndex <= cfg.bars then
			local bar = self.bars[barIndex] or module.CreateBar(self, barIndex)
			
			bar.unit = name
			local v = { name = name }
			v.value = unitdata["_sum"]
			v.value_persecond = round(v.value / unitdata["_ctime"], 1)
			v.percent = v.value == 0 and 0 or round(v.value / caps.all * 100, 1)
			v.percent_persecond = v.value_persecond == 0 and 0 or round(v.value_persecond / caps.persecond_all * 100, 1)

			if unitdata["_esum"] then
				v.effective_value = unitdata["_esum"]
				v.effective_value_persecond = round(v.effective_value / unitdata["_ctime"], 1)
				v.effective_percent = v.effective_value == 0 and 0 or round(v.effective_value / caps.effective_all * 100, 1)
			end

			local owner = module.data.classes[name]
			local class = owner and RAID_CLASS_COLORS[owner] or { r = 0.5, g = 0.5, b = 0.5 }
			
			bar:SetMinMaxValues(0, caps[template.bar_max] or 1)
			bar:SetValue(v[template.bar_val] or 0)
			bar:SetStatusBarColor(class.r, class.g, class.b)
			bar.textLeft:SetText(i .. ". " .. name)
			
			local a = template.params
			local isDecimal = (a[1] == "value_persecond" or a[1] == "effective_value_persecond")
			bar.textRight:SetText(string.format(template.bar_string, formatNumber(v[a[1]] or 0, isDecimal), v[a[2]] or 0))
			
			if template.lower_max and template.lower_val then
				bar.lowerBar:SetMinMaxValues(0, caps[template.lower_max] or 1)
				bar.lowerBar:SetValue(v[template.lower_val] or 0)
				bar.lowerBar:Show()
			end
			
			bar:Show()
		end
		i = i + 1
	end
	self.totalUnits = count
end

module.CreateBar = function(parent, i)
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetStatusBarTexture(textures[module.config.texture] or textures[1])
	bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -module.config.height * (i-1) - 24)
	bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -module.config.height * (i-1) - 24)
	bar:SetHeight(module.config.height - module.config.spacing)
	bar:SetFrameLevel(4)

	bar.lowerBar = CreateFrame("StatusBar", nil, parent)
	bar.lowerBar:SetStatusBarTexture(textures[module.config.texture] or textures[1])
	bar.lowerBar:SetPoint("TOPLEFT", bar)
	bar.lowerBar:SetPoint("TOPRIGHT", bar)
	bar.lowerBar:SetHeight(bar:GetHeight())
	bar.lowerBar:SetStatusBarColor(1, 1, 1, .4)
	bar.lowerBar:SetFrameLevel(2)

	bar.textLeft = bar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	bar.textLeft:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
	bar.textLeft:SetShadowOffset(1, -1)
	bar.textLeft:SetShadowColor(0, 0, 0, 1)
	bar.textLeft:SetJustifyH("LEFT")
	bar.textLeft:SetPoint("LEFT", 5, 0)

	bar.textRight = bar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	bar.textRight:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
	bar.textRight:SetShadowOffset(1, -1)
	bar.textRight:SetShadowColor(0, 0, 0, 1)
	bar.textRight:SetJustifyH("RIGHT")
	bar.textRight:SetPoint("RIGHT", -5, 0)
	
	bar:EnableMouse(true)
	bar:SetScript("OnEnter", barTooltipShow)
	bar:SetScript("OnLeave", barTooltipHide)

	parent.bars[i] = bar
	return bar
end

local function CreateWindow()
	local frame = CreateFrame("Frame", "VEDpsMeterFrame", UIParent)
	frame:SetPoint("CENTER", 200, 0)
	frame.scroll = 0
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", function()
		local delta = arg1
		this.scroll = (this.scroll or 0) - delta
		local maxScroll = math.max(0, (this.totalUnits or 0) - module.config.bars)
		if this.scroll < 0 then this.scroll = 0 end
		if this.scroll > maxScroll then this.scroll = maxScroll end
		this:Refresh()
	end)
	frame:SetWidth(module.config.width)
	frame:SetHeight(module.config.height * module.config.bars + 22 + 3)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:SetMinResize(150, 40)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function() if not module.config.lock then this:StartMoving() end end)
	frame:SetScript("OnDragStop", function()
		this:StopMovingOrSizing()
		-- Save position
		if not VanillaEnhancedData["DpsMeter"] then VanillaEnhancedData["DpsMeter"] = {} end
		local point, _, relativePoint, xOfs, yOfs = this:GetPoint()
		VanillaEnhancedData["DpsMeter"].pos = { point, relativePoint, xOfs, yOfs }
	end)
	
	-- Load size and position
	if VanillaEnhancedData["DpsMeter"] then
		if VanillaEnhancedData["DpsMeter"].width then module.config.width = VanillaEnhancedData["DpsMeter"].width end
		if VanillaEnhancedData["DpsMeter"].bars then module.config.bars = VanillaEnhancedData["DpsMeter"].bars end
		if VanillaEnhancedData["DpsMeter"].bgAlpha then module.config.bgAlpha = VanillaEnhancedData["DpsMeter"].bgAlpha end
		if VanillaEnhancedData["DpsMeter"].visible ~= nil then module.config.visible = VanillaEnhancedData["DpsMeter"].visible end
		if VanillaEnhancedData["DpsMeter"].segment ~= nil then module.config.segment = VanillaEnhancedData["DpsMeter"].segment end
		if VanillaEnhancedData["DpsMeter"].view ~= nil then module.config.view = VanillaEnhancedData["DpsMeter"].view end
		if VanillaEnhancedData["DpsMeter"].pos then
			frame:ClearAllPoints()
			local p = VanillaEnhancedData["DpsMeter"].pos
			frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
		end
	end

	frame:SetWidth(module.config.width)
	frame:SetHeight(module.config.height * module.config.bars + 22 + 3)

	frame:SetBackdrop(backdrop_window)
	frame:SetBackdropColor(0, 0, 0, module.config.bgAlpha)

	frame.border = CreateFrame("Frame", nil, frame)
	frame.border:SetAllPoints()
	frame.border:SetBackdrop(backdrop_border)
	frame.border:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
	frame.border:SetFrameLevel(100)

	frame.title = frame:CreateTexture(nil, "ARTWORK")
	frame.title:SetTexture(0, 0, 0, 0.5)
	frame.title:SetHeight(20)
	frame.title:SetPoint("TOPLEFT", 4, -4)
	frame.title:SetPoint("TOPRIGHT", -4, -4)

	local function btnEnter()
		this:SetBackdropBorderColor(1, 0.8, 0, 1)
	end

	local function btnLeave()
		this:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
	end

	frame.btnSegment = CreateFrame("Button", nil, frame)
	frame.btnSegment:SetPoint("RIGHT", frame.title, "CENTER", -1, 0)
	frame.btnSegment:SetWidth(50)
	frame.btnSegment:SetHeight(16)
	frame.btnSegment:SetBackdrop(backdrop_button)
	frame.btnSegment:SetBackdropColor(0.2, 0.2, 0.2, 1)
	frame.btnSegment:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
	frame.btnSegment.caption = frame.btnSegment:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	frame.btnSegment.caption:SetAllPoints()
	frame.btnSegment.caption:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
	frame.btnSegment.caption:SetShadowOffset(1, -1)
	frame.btnSegment.caption:SetShadowColor(0, 0, 0, 1)
	frame.btnSegment:SetScript("OnEnter", btnEnter)
	frame.btnSegment:SetScript("OnLeave", btnLeave)
	frame.btnSegment:SetScript("OnClick", function()
		module.config.segment = module.config.segment == 1 and 0 or 1
		if not VanillaEnhancedData["DpsMeter"] then VanillaEnhancedData["DpsMeter"] = {} end
		VanillaEnhancedData["DpsMeter"].segment = module.config.segment
		frame.scroll = 0
		frame:Refresh(true)
	end)

	frame.btnMode = CreateFrame("Button", nil, frame)
	frame.btnMode:SetPoint("LEFT", frame.title, "CENTER", 1, 0)
	frame.btnMode:SetWidth(50)
	frame.btnMode:SetHeight(16)
	frame.btnMode:SetBackdrop(backdrop_button)
	frame.btnMode:SetBackdropColor(0.2, 0.2, 0.2, 1)
	frame.btnMode:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
	frame.btnMode.caption = frame.btnMode:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	frame.btnMode.caption:SetAllPoints()
	frame.btnMode.caption:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
	frame.btnMode.caption:SetShadowOffset(1, -1)
	frame.btnMode.caption:SetShadowColor(0, 0, 0, 1)
	frame.btnMode:SetScript("OnEnter", btnEnter)
	frame.btnMode:SetScript("OnLeave", btnLeave)
	frame.btnMode:SetScript("OnClick", function()
		module.config.view = module.config.view + 1
		if module.config.view > 4 then module.config.view = 1 end
		if not VanillaEnhancedData["DpsMeter"] then VanillaEnhancedData["DpsMeter"] = {} end
		VanillaEnhancedData["DpsMeter"].view = module.config.view
		frame.scroll = 0
		frame:Refresh(true)
	end)

	frame.btnReset = CreateFrame("Button", nil, frame)
	frame.btnReset:SetPoint("RIGHT", frame.title, "RIGHT", -2, 0)
	frame.btnReset:SetWidth(16)
	frame.btnReset:SetHeight(16)
	frame.btnReset:SetBackdrop(backdrop_button)
	frame.btnReset:SetBackdropColor(0.2, 0.2, 0.2, 1)
	frame.btnReset:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
	frame.btnReset.tex = frame.btnReset:CreateTexture(nil, "OVERLAY")
	frame.btnReset.tex:SetWidth(10)
	frame.btnReset.tex:SetHeight(10)
	frame.btnReset.tex:SetPoint("CENTER", 0, 0)
	frame.btnReset.tex:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\DpsMeter-Reset.tga")
	frame.btnReset:SetScript("OnEnter", btnEnter)
	frame.btnReset:SetScript("OnLeave", btnLeave)
	frame.btnReset:SetScript("OnClick", function()
		if IsShiftKeyDown() then
			module.data.damage = { [0] = {}, [1] = {} }
			module.data.heal = { [0] = {}, [1] = {} }
			frame:Refresh()
		else
			StaticPopupDialogs["VEDPSMETER_RESET"] = {
				text = "Do you wish to reset the data?",
				button1 = "Yes",
				button2 = "No",
				OnAccept = function()
					module.data.damage = { [0] = {}, [1] = {} }
					module.data.heal = { [0] = {}, [1] = {} }
					frame:Refresh()
				end,
				timeout = 0,
				whileDead = 1,
				hideOnEscape = 1,
			}
			StaticPopup_Show("VEDPSMETER_RESET")
		end
	end)

	frame.btnResize = CreateFrame("Frame", nil, frame)
	frame.btnResize:SetPoint("BOTTOMRIGHT", -4, 4)
	frame.btnResize:SetWidth(12)
	frame.btnResize:SetHeight(12)
	frame.btnResize:EnableMouse(true)
	frame.btnResize:SetFrameLevel(99)
	frame.btnResize.tex = frame.btnResize:CreateTexture(nil, "BACKGROUND")
	frame.btnResize.tex:SetAllPoints()
	frame.btnResize.tex:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\DpsMeter-Resize.tga")
	frame.btnResize:SetScript("OnMouseDown", function()
		if not this:GetParent().sizing and not module.config.lock then
			this:GetParent().sizing = true
			this:GetParent():StartSizing()
		end
	end)
	frame.btnResize:SetScript("OnMouseUp", function()
		this:GetParent().sizing = nil
		this:GetParent():StopMovingOrSizing()
		this:GetParent():Refresh(true)
	end)

	frame.bars = {}
	frame.Refresh = Refresh
	frame.Resize = Resize
	frame:SetScript("OnUpdate", function()
		if this.sizing then
			this:Resize()
		end

		if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + 0.2 end

		if not module.config.lock and MouseIsOver(this) then
			this.btnResize:SetAlpha(0.5)
		else
			this.btnResize:SetAlpha(0)
		end

		if this.needs_refresh then
			this.needs_refresh = nil
			this:Refresh()
		end
	end)
	
	module.frame = frame
	frame:Refresh(true)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
	if VE.isModuleEnabled(module.identifier) then
		CreateWindow()
	end
end)

SLASH_METER1 = "/meter"
SlashCmdList["METER"] = function()
	if not VE.isModuleEnabled(module.identifier) then
		VE.print("DPS Meter module is disabled in settings.")
		return
	end
	
	module.config.visible = not module.config.visible
	if not VanillaEnhancedData["DpsMeter"] then VanillaEnhancedData["DpsMeter"] = {} end
	VanillaEnhancedData["DpsMeter"].visible = module.config.visible

	if module.frame then
		module.frame:Refresh(true)
	end
end
