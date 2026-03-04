local module = VE.registerModule({
	identifier = "ClassPortraits",
	meta = {
		label = "Class Portraits",
		description = "Displays class icons instead of default portraits on unit frames.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		iconPath = "Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-Class-Portraits",
		classes = {
			["HUNTER"] = {
				0,
				0.25,
				0.25,
				0.5,
			},
			["WARRIOR"] = {
				0,
				0.25,
				0,
				0.25,
			},
			["ROGUE"] = {
				0.49609375,
				0.7421875,
				0,
				0.25,
			},
			["MAGE"] = {
				0.25,
				0.49609375,
				0,
				0.25,
			},
			["PRIEST"] = {
				0.49609375,
				0.7421875,
				0.25,
				0.5,
			},
			["WARLOCK"] = {
				0.7421875,
				0.98828125,
				0.25,
				0.5,
			},
			["DRUID"] = {
				0.7421875,
				0.98828125,
				0,
				0.25,
			},
			["SHAMAN"] = {
				0.25,
				0.49609375,
				0.25,
				0.5,
			},
			["PALADIN"] = {
				0,
				0.25,
				0.5,
				0.75,
			},
		},
	},
	data = {
		partyFrames = {
			[1] = PartyMemberFrame1,
			[2] = PartyMemberFrame2,
			[3] = PartyMemberFrame3,
			[4] = PartyMemberFrame4,
		}
	},
})

if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function UpdatePortrait(portrait, unit)
	if not portrait then return end
	
	local _, class = UnitClass(unit)
	local iconCoords = module.config.classes[class]
	
	if iconCoords then
		portrait:SetTexture(module.config.iconPath, true)
		portrait:SetTexCoord(unpack(iconCoords))
	else
		portrait:SetTexCoord(0, 1, 0, 1)
	end
end

local function UpdatePlayerPortrait()
	UpdatePortrait(PlayerFrame.portrait, "player")
end

local function UpdatePartyPortrait(index)
	if module.data.partyFrames[index] then
		UpdatePortrait(module.data.partyFrames[index].portrait, "party" .. index)
	end
end

local function UpdateTargetPortrait()
	if UnitName("target") ~= nil and TargetFrame.portrait then
		if UnitIsPlayer("target") then
			UpdatePortrait(TargetFrame.portrait, "target")
		else
			TargetFrame.portrait:SetTexCoord(0, 1, 0, 1)
		end
	end
end

local function UpdateTargetTargetPortrait()
	if UnitName("targettarget") ~= nil and TargetofTargetFrame.portrait then
		if UnitIsPlayer("targettarget") then
			UpdatePortrait(TargetofTargetFrame.portrait, "targettarget")
		else
			TargetofTargetFrame.portrait:SetTexCoord(0, 1, 0, 1)
		end
	end
end

local function UpdateAll()
	UpdatePlayerPortrait()
	
	for i = 1, GetNumPartyMembers() do
		UpdatePartyPortrait(i)
	end
	
	UpdateTargetPortrait()
	UpdateTargetTargetPortrait()
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("UNIT_PORTRAIT_UPDATE")
module.plug:RegisterEvent("PLAYER_TARGET_CHANGED")
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("PARTY_MEMBERS_CHANGED")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	
	if event == "UNIT_PORTRAIT_UPDATE" then
		local unit = arg1
		if not unit then return end
		if unit == "player" then
			UpdatePlayerPortrait()
		elseif string.sub(unit, 1, 5) == "party" then
			local index = tonumber(string.sub(unit, 6))
			if index then UpdatePartyPortrait(index) end
		elseif unit == "target" then
			UpdateTargetPortrait()
		elseif unit == "targettarget" then
			UpdateTargetTargetPortrait()
		end
	elseif event == "PLAYER_TARGET_CHANGED" then
		UpdateTargetPortrait()
		UpdateTargetTargetPortrait()
	elseif event == "PLAYER_ENTERING_WORLD" or event == "PARTY_MEMBERS_CHANGED" then
		UpdateAll()
	end
end)
