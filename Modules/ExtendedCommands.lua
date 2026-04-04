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
		dismountPatterns = {
			"^Increases speed by (.+)%%",
			"speed based on",
			"Slow and steady...",
			"Riding",
		},
	},
	data = {
		tooltip = nil,
	},
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

	module.data.tooltip = CreateFrame("GameTooltip", "VETooltip", UIParent, "GameTooltipTemplate")
	module.data.tooltip:SetOwner(UIParent, "ANCHOR_NONE")

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

		-- Priest Shadowform and Shaman Spirit Wolf aura.
		for i = 0, 15 do
			buffTexture = GetPlayerBuffTexture(i)
			if buffTexture ~= nil then
				startPos, endPos = string.find(buffTexture, "Spell_Shadow_Shadowform")
				if startPos ~= nil and endPos ~= nil then CancelPlayerBuff(i) end
				
				startPos, endPos = string.find(buffTexture, "Spell_Nature_SpiritWolf")
				if startPos ~= nil and endPos ~= nil then CancelPlayerBuff(i) end
			end
		end
	end

	SLASH_DISMOUNT1 = "/dismount"
	SlashCmdList["DISMOUNT"] = function()
		local buff = 0
		while GetPlayerBuff(buff) >= 0 do
			module.data.tooltip:SetPlayerBuff(GetPlayerBuff(buff))
			local desc = VETooltipTextLeft2:GetText()
			if desc then
				for _, str in pairs(module.config.dismountPatterns) do
					if string.find(desc, str) then
						CancelPlayerBuff(buff)
						return
					end
				end
			end
			buff = buff + 1
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

	-- 1 = Head
	-- 2 = Neck
	-- 3 = Shoulder
	-- 5 = Chest
	-- 6 = Waist
	-- 7 = Legs
	-- 8 = Feet
	-- 9 = Wrist
	-- 10 = Hands
	-- 11 = Finger 1
	-- 12 = Finger 2
	-- 13 = Trinket 1
	-- 14 = Trinket 2
	-- 15 = Back
	-- 16 = Main Hand
	-- 17 = Off Hand
	-- 18 = Ranged
	SLASH_EQUIP1 = "/equip"
	SlashCmdList["EQUIP"] = function(msg, editbox)
		local _, _, slotText, itemName = string.find(msg, "^(%d+)%s+(.+)$")

		if not slotText or not itemName then
			DEFAULT_CHAT_FRAME:AddMessage("Usage: /equip slotid item name")
			return
		end

		local equipSlot = tonumber(slotText)
		if not equipSlot then
			DEFAULT_CHAT_FRAME:AddMessage("Invalid slot id: " .. slotText)
			return
		end

		local searchName = string.lower(itemName)

		for bagID = 0, NUM_BAG_SLOTS do
			for slotIndex = 1, GetContainerNumSlots(bagID) do
				local link = GetContainerItemLink(bagID, slotIndex)

				if link then
					local itemText = string.lower(link)
					if string.find(itemText, searchName, 1, 1) then
						PickupContainerItem(bagID, slotIndex)
						PickupInventoryItem(equipSlot)
						return
					end
				end
			end
		end
		VE.printf("Item not found: %s", itemName)
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

	SLASH_STARTATTACK1 = "/startattack"
	SlashCmdList["STARTATTACK"] = function()
		if not IsCurrentAction(0) then
			AttackTarget()
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

	do
		SLASH_RESETINSTANCES1 = "/reset"
		SLASH_RESETINSTANCES2 = "/resetinstances"
		SlashCmdList["RESETINSTANCES"] = function(msg, editbox)
			ResetInstances()
		end
	end

	SLASH_SANDBOX1 = "/sandbox"
	SLASH_SANDBOX2 = "/sa"
	SlashCmdList["SANDBOX"] = function(msg, editbox)
		VE.iprint("Currently empty! Used for debugging only!")
	end
end)
