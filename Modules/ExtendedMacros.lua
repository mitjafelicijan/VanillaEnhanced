--[[
    Extended Macros Module
    Extends the default macro system with support for conditions, #showtooltip, and custom commands.
]]

local module = VE.registerModule({
	identifier = "ExtendedMacros",
	meta = {
		label = "Extended Macros",
		description = "Extends the default macro system with support for #showtooltip directives and conditional logic [help,harm,@target].",
	},
	plug = nil,
	superWoWRequired = true,
	config = {
		numMacros = 36, -- 18 general, 18 character
	},
	data = {
		macroCache = {},
		sequenceState = {},
		spellCache = {},
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function GetSpellTextureByName(name)
	if not name or name == "" then return nil end
	local cleanName = string.gsub(name, "%s*%(Rank %d+%)", "")
	cleanName = VE.trim(cleanName)
	
	if module.data.spellCache[cleanName] then
		return module.data.spellCache[cleanName]
	end
	
	local i = 1
	while true do
		local n = GetSpellName(i, "spell")
		if not n then break end
		if n == cleanName then
			local tex = GetSpellTexture(i, "spell")
			module.data.spellCache[cleanName] = tex
			return tex
		end
		i = i + 1
	end
	return nil
end

local function GetItemTextureByName(name)
	if not name or name == "" then return nil end
	local lowerName = string.lower(name)
	for b = 0, 4 do
		for s = 1, GetContainerNumSlots(b) do
			local link = GetContainerItemLink(b, s)
			if link and string.find(string.lower(link), lowerName) then
				local tex = GetContainerItemInfo(b, s)
				return tex
			end
		end
	end
	for i = 1, 19 do
		local link = GetInventoryItemLink("player", i)
		if link and string.find(string.lower(link), lowerName) then
			return GetInventoryItemTexture("player", i)
		end
	end
	return nil
end

local function checkCondition(cond, target)
	if not target then target = "target" end
	local neg = false
	if string.sub(cond, 1, 2) == "no" then
		local sub = string.sub(cond, 3)
		if sub == "dead" or sub == "combat" or sub == "exists" or sub == "stealth" or sub == "pet" or sub == "mounted" then
			neg = true
			cond = sub
		end
	end

	local res = false
	if cond == "help" then res = UnitCanAssist("player", target)
	elseif cond == "harm" then res = UnitCanHarm("player", target)
	elseif cond == "exists" then res = UnitExists(target)
	elseif cond == "dead" then res = UnitIsDead(target)
	elseif cond == "combat" then res = UnitAffectingCombat("player")
	elseif cond == "pet" then res = UnitExists("pet")
	elseif cond == "stealth" then
		res = false
		for i = 0, 15 do
			local t = GetPlayerBuffTexture(i)
			if not t then break end
			if string.find(t, "Stealth") or string.find(t, "Prowl") or string.find(t, "Shadowform") then
				res = true
				break
			end
		end
	elseif cond == "mounted" then
		if IsMounted then res = IsMounted() else
			res = false
			for i = 0, 15 do
				local t = GetPlayerBuffTexture(i)
				if not t then break end
				if string.find(t, "Mount") or string.find(t, "Ability_Mount") then
					res = true; break
				end
			end
		end
	elseif string.sub(cond, 1, 3) == "mod" then
		local m = string.sub(cond, 5)
		if m == "shift" then res = IsShiftKeyDown()
		elseif m == "ctrl" then res = IsControlKeyDown()
		elseif m == "alt" then res = IsAltKeyDown()
		else res = IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown() end
	elseif string.find(cond, "form:") or string.find(cond, "stance:") then
		local _, _, f = string.find(cond, ":(%d+)")
		local current = 0
		for i = 1, GetNumShapeshiftForms() do
			local _, _, active = GetShapeshiftFormInfo(i)
			if active then current = i; break end
		end
		res = (tonumber(f) == current)
	end

	if neg then return not res else return res end
end

local function evaluateConditions(condGroups)
	if not condGroups or table.getn(condGroups) == 0 then return true, nil end

	for _, group in ipairs(condGroups) do
		local pass = true
		local target = nil
		local conds = VE.split(group, ",")
		for _, c in ipairs(conds) do
			c = VE.trim(c)
			if string.sub(c, 1, 1) == "@" then
				target = string.sub(c, 2)
			elseif string.sub(c, 1, 7) == "target=" then
				target = string.sub(c, 8)
			elseif c ~= "" then
				if not checkCondition(c, target or "target") then
					pass = false
					break
				end
			end
		end
		if pass then return true, target end
	end
	return false, nil
end

local function parseMacro(body)
	local lines = {}
	if not body then return lines end
	local cleanBody = string.gsub(body, "\r\n", "\n")
	cleanBody = string.gsub(cleanBody, "\r", "\n")
	
	local rawLines = VE.split(cleanBody, "\n")
	for _, raw in ipairs(rawLines) do
		local originalRaw = raw
		raw = VE.trim(raw)
		if raw ~= "" then
			if string.sub(raw, 1, 1) == "#" then
				local _, _, cmd, arg = string.find(raw, "^#(%w+)%s*(.*)")
				if cmd then
					table.insert(lines, { isDirective = true, command = cmd, arg = arg, raw = raw })
				end
			elseif string.sub(raw, 1, 1) == "/" then
				local _, _, cmd, rest = string.find(raw, "^/(%w+)%s*(.*)")
				if cmd then
					local options = {}
					local parts = VE.split(rest or "", ";")
					for _, part in ipairs(parts) do
						local conds = {}
						local pRest = part
						while true do
							local s, e, c = string.find(pRest, "%s*%[(.-)%]")
							if not s then break end
							table.insert(conds, c)
							pRest = string.sub(pRest, e + 1)
						end
						table.insert(options, { conditions = conds, action = VE.trim(pRest) })
					end
					table.insert(lines, { isDirective = false, command = cmd, options = options, raw = raw })
				else
					table.insert(lines, { isDirective = false, isText = true, raw = raw })
				end
			else
				table.insert(lines, { isDirective = false, isText = true, raw = raw })
			end
		end
	end
	return lines
end

local function updateMacroCache()
	module.data.macroCache = {}
	for i = 1, module.config.numMacros do
		local name, icon, body = GetMacroInfo(i)
		if name then
			module.data.macroCache[i] = {
				name = name,
				icon = icon,
				body = body,
				parsed = parseMacro(body)
			}
		end
	end
end

local function executeMacro(macro, onSelf)
	if not macro then return end
	local numLines = table.getn(macro.parsed)
	for i = 1, numLines do
		local line = macro.parsed[i]
		if line.isDirective then
			-- ignore
		elseif line.isText then
			if RunLine then 
				RunLine(line.raw) 
			else
				ChatFrameEditBox:SetText(line.raw)
				ChatFrameEditBox:GetScript("OnEnter")(ChatFrameEditBox)
			end
		else
			local cmd = line.command
			if RunLine and cmd ~= "castsequence" then
				RunLine(line.raw)
			elseif cmd == "cast" or cmd == "use" or cmd == "castsequence" then
				for _, opt in ipairs(line.options) do
					local ok, target = evaluateConditions(opt.conditions)
					if ok then
						local action = opt.action
						local finalTarget = target
						if onSelf and not finalTarget then finalTarget = "player" end

						if cmd == "castsequence" then
							local spellsText = string.gsub(action, "reset=[%w/]+%s*", "")
							local spells = VE.split(spellsText, ",")
							local state = module.data.sequenceState[macro.name] or { index = 1, lastTarget = UnitName("target") }
							
							local spell = spells[state.index] or spells[1]
							CastSpellByName(spell, finalTarget)
							
							state.index = state.index + 1
							if state.index > table.getn(spells) then state.index = 1 end
							state.lastTarget = UnitName("target")
							module.data.sequenceState[macro.name] = state
						else
							CastSpellByName(action, finalTarget)
						end
						break
					end
				end
			elseif cmd == "startattack" then
				if not IsCurrentAction(0) then AttackTarget() end
			elseif cmd == "stopattack" then
				if IsCurrentAction(0) then AttackTarget() end
			elseif cmd == "stopcasting" then
				SpellStopCasting()
			elseif cmd == "petattack" then
				PetAttack()
			elseif cmd == "petfollow" then
				PetFollow()
			elseif cmd == "petpassive" then
				PetPassiveMode()
			elseif cmd == "petdefensive" then
				PetDefensiveMode()
			else
				local arg = (line.options[1] and line.options[1].action or "")
				if not runSlashCommand(cmd, arg) then
					if RunLine then
						RunLine("/" .. cmd .. " " .. arg)
					else
						ChatFrameEditBox:SetText("/" .. cmd .. " " .. arg)
						ChatFrameEditBox:GetScript("OnEnter")(ChatFrameEditBox)
					end
				end
			end
		end
	end
end

local function updateButtonIcon(button)
	if not button or not button:IsVisible() then return end
	local action = button.action
	if not action then return end
	local text = GetActionText(action)
	if text then
		local macro = getMacroByName(text)
		if macro then
			local icon = getEvaluatedIcon(macro)
			if icon then
				local iconTexture = getglobal(button:GetName() .. "Icon")
				if iconTexture then
					iconTexture:SetTexture(icon)
				end
			end
		end
	end
end

local function updateAllVisibleIcons()
	local bars = {
		"ActionButton",
		"MultiBarBottomLeftButton",
		"MultiBarBottomRightButton",
		"MultiBarRightButton",
		"MultiBarLeftButton",
		"BonusActionButton"
	}
	for _, bar in ipairs(bars) do
		for i = 1, 12 do
			local b = getglobal(bar .. i)
			if b then updateButtonIcon(b) end
		end
	end
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("UPDATE_MACROS")
module.plug:RegisterEvent("SPELLS_CHANGED")
module.plug:RegisterEvent("PLAYER_TARGET_CHANGED")
module.plug:RegisterEvent("MODIFIER_STATE_CHANGED")
module.plug:RegisterEvent("ACTIONBAR_UPDATE_STATE")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		updateMacroCache()
		
		local old_UseAction = UseAction
		_G["UseAction"] = function(slot, checkCursor, onSelf)
			local text = GetActionText(slot)
			if text then
				local macro = getMacroByName(text)
				if macro then
					executeMacro(macro, onSelf)
					return
				end
			end
			if old_UseAction then
				old_UseAction(slot, checkCursor, onSelf)
			end
		end

		VE.hooksecurefunc("ActionButton_Update", function()
			updateButtonIcon(this)
		end, true)
	elseif event == "UPDATE_MACROS" or event == "SPELLS_CHANGED" then
		updateMacroCache()
	end
	
	updateAllVisibleIcons()
end)
