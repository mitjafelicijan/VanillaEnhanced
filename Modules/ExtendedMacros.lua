--[[

TODO
	- Change icon depending on a spell
	- have some sort of if else option
	- add startattack and missing commands
	- add option to parse [] [] [] like classic addons


	/cast [condition1] Healing Wave; [condition2] Windfury Totem; [condition3] Healing Wave (Rank 3); Frost Shock
	/castsequence [options] reset=condition1/... action1, action2, ...
	/castsequence reset=30 Piercing Howl, Hamstring
	
]]

local module = VE.registerModule({
	identifier = "ExtendedMacros",
	meta = {
		label = "Extended Macros",
		description = "Extends the default macro system with support for #showtooltip directives, allowing macros to dynamically update their icons and display correct tooltips based on their content.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		numMacros = 32, -- This is 16 general and 16 character ones.
	},
	data = {
		macroCache = {},
		spellCache = {},
		spellRankCache = {},
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function updateActionBarButtonTexture(slot, texture)
	for i = 1, 12 do
		local button = getglobal("ActionButton"..slot)
		local icon = getglobal(button:GetName().."Icon")
		if icon then
			icon:SetTexture("Interface\\Icons\\Spell_Fire_Fireball")
		end
	end
end

local function getMacroByName(name)
	for idx, macro in pairs(module.data.macroCache) do
		if name == macro.name then
			return macro
		end
	end
end

local function updateActionBarIcons()
	for i = 1, 120 do
		local button = getglobal("ActionButton"..i)
		if button then
			local icon = getglobal(button:GetName().."Icon")
			if icon then
				icon:SetTexture("Interface\\Icons\\Spell_Fire_Fireball")
			end
		end
	end
end

-- Parses macros and creates simple AST.
local function updateMacroCache()
	VE.iprint("> updating macro cache")

	wipe(module.data.macroCache)

	for idx = 1, module.config.numMacros do
		local name, icon, body = GetMacroInfo(idx)
		if name ~= nil then
			VE.printf(" > name: %s", name)

			-- Parsing all the lines.
			local list = VE.split(body, "\n")
			for i = 1, VE.count(list) do
				local line = VE.trim(list[i])
				VE.printf("   > %s", line)

				if VE.startsWith(line, "#showtooltip") then
					local spellName = VE.trim(VE.removePrefix(line, "#showtooltip"))

					if string.len(spellName) > 0 then
						icon = GetSpellTexture(spellName, "spell")
					end

					VE.printf("     > this is tooltip for: '%s', icon: %s", spellName, icon)
				elseif VE.startsWith(line, "/castsequence") then
					VE.printf("     > this is castsequence")
				elseif VE.startsWith(line, "/cast") then
					VE.printf("     > this is a cast")
				elseif VE.startsWith(line, "/script") or VE.startsWith(line, "/run") then
					VE.printf("     > this is a script")
				else
					VE.printf("     > this is a slashcommand")
				end
			end

			table.insert(module.data.macroCache, {
				idx = idx,
				name = name,
				icon = icon,
				body = body,
				sequence = {},
			})
		end
	end

	updateActionBarIcons()
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("SPELLS_CHANGED")
module.plug:RegisterEvent("UPDATE_MACROS")
module.plug:RegisterEvent("ACTIONBAR_SLOT_CHANGED")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	
	-- Hooks into the action exectuion.
	if event == "PLAYER_ENTERING_WORLD" then
		VE.iprint("hooking up to action events")
		local old_UseAction = UseAction
		function UseAction(slot, checkCursor, onSelf)
			local slotName = GetActionText(slot)
			local macro = nil

			if slotName ~= nil then
				macro = getMacroByName(slotName)
				if macro ~= nil then
					macroFound = true
				end
			end

			if macro then
				VE.iprint("execute macro")
			else
				VE.iprint("execute action")
				-- old_UseAction(slot, checkCursor, onSelf)
			end

			-- if text then
			-- 	for i=1, module.config.numMacros do
			-- 		local name, icon, body = GetMacroInfo(i)
			-- 		if name == text then
			-- 			VE.printf("idx: %d, name: %s, icon: %s, slot: %s, body: \n%s", i, name, icon, slot, body)
						
			-- 			local texture = "Interface\\Icons\\Spell_Fire_Fireball"
			-- 			EditMacro(i, name, texture, body)
			-- 			updateActionBarButtonTexture(slot, texture)
						
			-- 			macroFound = true
			-- 			break
			-- 		end
			-- 	end
			-- end

		end
	else
		VE.printf("Other event: %s", event)
		updateMacroCache()
	end
end)
