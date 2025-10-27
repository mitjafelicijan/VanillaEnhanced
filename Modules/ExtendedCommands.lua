local module = VE.registerModule({
	identifier = "ExtendedCommands",
	meta = {
		label = "Extended Commands",
		description = "Adds a set of classic-style macros, expanding the available commands to more closely resemble the original WoW Classic client.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		raidPullout = {
			disableDrag = true,
			initialLeftOffset = 10,
			initialTopOffset = -190,
			frameWidth = 80,
			frameHeight = 200,
			perRow = 4,

		},
	},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local print = VE.print
local gfind = string.gmatch or string.gfind

local function CurrentDruidForm()
	local inForm = nil
	for i = 1, GetNumShapeshiftForms() do
		_, _, active, _ = GetShapeshiftFormInfo(i)
		if active ~= nil then
			inForm = i
		end
	end
	return inForm
end

local function GoIntoDruidFormId(formId)
	local form = CurrentDruidForm()
	if form ~= nil and form ~= formId then
		CastShapeshiftForm(form)
	end
	_, _, active, _ = GetShapeshiftFormInfo(formId)
	if active == nil then
		CastShapeshiftForm(formId)
	end
end

local function ShowRaidPullouts()
	local currentIdx = 0
	for i = 1,8 do
		local pullout = RaidPullout_GenerateGroupFrame(i)
		if pullout then
			local col = math.mod(currentIdx, module.config.raidPullout.perRow)
			local row = math.floor(currentIdx / module.config.raidPullout.perRow)
			local leftOffset = module.config.raidPullout.initialLeftOffset + (col * module.config.raidPullout.frameWidth)
			local topOffset = module.config.raidPullout.initialTopOffset - (row * module.config.raidPullout.frameHeight)

			if module.config.raidPullout.disableDrag then
				pullout:EnableMouse(false)
				pullout:SetMovable(false)
			end

			-- Make bar a bit bigger.
			-- FIXME: This targets correct bars but the style is all messed up.
			if false then
				for j = 1,5 do
					button = getglobal(pullout:GetName().."Button"..j);
					print(pullout:GetName().."Button"..j)
					if button then
						-- button:SetHeight(30)

						-- Make background texture taller
						local bg = getglobal(button:GetName().."Frame")
						if bg then
							bg:SetHeight(30)  -- increase background texture height
						end

						healthBar = getglobal(button:GetName().."HealthBar");
						healthBar:SetHeight(10)
						manaBar = getglobal(button:GetName().."ManaBar");
						manaBar:SetHeight(10)
					end
				end
			end

			pullout:ClearAllPoints()
			pullout:SetPoint("TOPLEFT", UIParent, "TOPLEFT", leftOffset, topOffset)
			pullout:Show()

			currentIdx = currentIdx + 1
		end
	end
end

local function HideRaidPullouts()
	for i = 1, 8 do
		local pullout = getglobal("RaidPullout"..i)
		if pullout then
			pullout:Hide()
		end
	end
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("VARIABLES_LOADED")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	SLASH_TweeksReload1 = "/reloadui"
	SLASH_TweeksReload2 = "/reload"
	SLASH_TweeksReload3 = "/rl"
	SlashCmdList["TweeksReload"] = function()
		ConsoleExec("reloadui")
	end

	SLASH_RaidPullout1 = "/raidpullout"
	SLASH_RaidPullout2 = "/rp"
	SlashCmdList["RaidPullout"] = function(arg)
		if GetNumRaidMembers() == 0 then
			VE.print("|cffff8000Not in a Raid! Pullout frames not available!")
			return
		end

		if arg == "" then
			VE.print("Usage: /rp show||hide||reload")
		end

		if arg == "show" then
			HideRaidPullouts()
			ShowRaidPullouts()
		end

		if arg == "hide" then
			HideRaidPullouts()
		end

		if arg == "reload" then
			HideRaidPullouts()
			ShowRaidPullouts()
		end
	end

	SLASH_CANCELFORM1 = "/cancelform"
	SlashCmdList["CANCELFORM"] = function()
		-- Druid forms.
		for i = 1, GetNumShapeshiftForms() do
			_, _, active, _ = GetShapeshiftFormInfo(i)
			if active ~= nil then
				CastShapeshiftForm(i)
			end
		end

		-- Priest Shadowform aura.
		for i = 1, 15 do
			buffTexture = GetPlayerBuffTexture(i)
			if buffTexture ~= nil then
				startPos, endPos = string.find(buffTexture, "Spell_Shadow_Shadowform")
				if startPos ~= nil and endPos ~= nil then CancelPlayerBuff(i) end
			end
		end
	end

	SLASH_DISMOUNT1 = "/dismount"
	SlashCmdList["DISMOUNT"] = function()
		for i = 0, 15 do
			buffTexture = GetPlayerBuffTexture(i)
			if buffTexture ~= nil then
				local startPos, endPos = nil, nil
				-- Normal mounts.
				startPos, endPos = string.find(buffTexture, "Ability_Mount_")
				if startPos ~= nil and endPos ~= nil then CancelPlayerBuff(i) end
				-- Turtle mounts.
				startPos, endPos = string.find(buffTexture, "inv_pet_speedy")
				if startPos ~= nil and endPos ~= nil then CancelPlayerBuff(i) end
				-- Warlock mounts.
				startPos, endPos = string.find(buffTexture, "Spell_Nature_Swiftness")
				if startPos ~= nil and endPos ~= nil then CancelPlayerBuff(i) end
				-- Ghostwolf form.
				startPos, endPos = string.find(buffTexture, "Spell_Nature_SpiritWolf")
				if startPos ~= nil and endPos ~= nil then CancelPlayerBuff(i) end
				-- Qiraji Battle tanks.
				startPos, endPos = string.find(buffTexture, "inv_misc_qirajicrystal")
				if startPos ~= nil and endPos ~= nil then CancelPlayerBuff(i) end
			end
		end
	end

	SLASH_USE1 = "/use"
	SlashCmdList["USE"] = function(msg, editbox)
		for bagID = 0, NUM_BAG_SLOTS do
			for slotIndex = 1, GetContainerNumSlots(bagID) do
				local name = GetContainerItemLink(bagID, slotIndex)
				if name and string.find(name, msg) then
					UseContainerItem(bagID, slotIndex)
				end
			end
		end
	end

	-- OBSOLETE: This is replaced with macros now.
	SLASH_MCAST1 = "/mcast"
	SlashCmdList["MCAST"] = function(msg)
		local spell = msg or nil
		local unit = GetMouseFocus() and GetMouseFocus().unit
		if not unit or not spell then return end

		CastSpellByName(spell)
		if SpellIsTargeting() then
			SpellTargetUnit(unit)
		end
	end

	-- OBSOLETE: This is replaced with macros now.
	SLASH_DCAST1 = "/dcast"
	SlashCmdList["DCAST"] = function(msg, editbox)
		VE.executeWithDelay(2, function()
			-- Attempt to cast the spell
			local success = CastSpellByName(msg)

			-- Check if the cast was successful
			if not success then
				VE.print("Failed to cast " .. msg)
			else
				VE.print("Successfully cast " .. msg)
			end

		end)
	end

	SLASH_TARGETLASTTARGET1 = "/targetlasttarget"
	SlashCmdList["TARGETLASTTARGET"] = function()
		TargetUnit("playertarget")
		-- This one below is causing issues.
		-- TargetLastTarget()
	end

	SLASH_TARGETMOUSEOVERUNIT1 = "/targetmouseoverunit"
	SlashCmdList["TARGETMOUSEOVERUNIT"] = function()
		local frame = GetMouseFocus()
		if frame and frame.unit then
			TargetUnit(frame.unit)
		else
			TargetUnit("mouseover")
		end
	end

	SLASH_STOPATTACK1 = "/stopattack"
	SlashCmdList["STOPATTACK"] = function()
		ClearTarget()
		TargetLastTarget()
	end

	SLASH_CLEARTARGET1 = "/cleartarget"
	SlashCmdList["CLEARTARGET"] = function()
		ClearTarget()
	end

	SLASH_FEEDPET1 = "/feedpet"
	SlashCmdList["FEEDPET"] = function(food)
		for b = 0, 4 do
			for s = 1, GetContainerNumSlots(b) do
				local itemLink = GetContainerItemLink(b, s)
				if itemLink and string.find(itemLink, food) then
					PickupContainerItem(b, s)
					DropItemOnUnit("pet")
					return
				end
			end
		end
		VE.print("Food not found in bags.")
	end

	do
		SLASH_BEARFORM1 = "/bearform"
		SlashCmdList["BEARFORM"] = function(msg, editbox)
			GoIntoDruidFormId(1)
		end
	end

	do
		SLASH_AQUATICFORM1 = "/aquaticform"
		SlashCmdList["AQUATICFORM"] = function(msg, editbox)
			GoIntoDruidFormId(2)
		end
	end

	do
		SLASH_CATFORM1 = "/catform"
		SlashCmdList["CATFORM"] = function(msg, editbox)
			GoIntoDruidFormId(3)
		end
	end

	do
		SLASH_TRAVELFORM1 = "/travelform"
		SlashCmdList["TRAVELFORM"] = function(msg, editbox)
			GoIntoDruidFormId(4)
		end
	end

	SLASH_SANDBOX1 = "/sandbox"
	SLASH_SANDBOX2 = "/sa"
	SlashCmdList["SANDBOX"] = function(msg, editbox)
		VE.iprint("Currently empty! Used for debugging only!")
	end
end)
