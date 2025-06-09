local module = VE.registerModule({
	identifier = "BigPlayerFrame",
	meta = {
		label = "Big Player Frame",
		description = "Increases the healthbar of the player and target unitframe with heal prediction.",
	},
	plug = nil,
	superWoWRequired = true,
	config = {
		classColors = false,
	},
	data = {},
	options = {
		{
			identifier = "BigPlayerFrameClassColors",
			meta = {
				label = "Class colors",
				description = "Use class colors for the health statusbar.",
			},
			superWoWRequired = true,
		},
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("PLAYER_TARGET_CHANGED")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		PlayerFrameTexture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-TargetingFrame")
		PlayerFrameHealthBar:SetPoint("TOPLEFT", 106, -22)
		PlayerFrameHealthBar:SetHeight(30)
		PlayerStatusTexture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-Player-Status")

		TargetFrameTexture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-TargetingFrame")
		TargetFrameHealthBar:SetPoint("TOPRIGHT", -106, -22)
		TargetFrameHealthBar:SetHeight(30)
		TargetFrameNameBackground.Show = function() return end
		TargetFrameNameBackground:Hide()

		local original = TargetFrame_CheckClassification
		function TargetFrame_CheckClassification()
			local classification = UnitClassification("target")
			if classification == "worldboss" then
				TargetFrameTexture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-TargetingFrame-Elite")
			elseif classification == "rareelite" then
				TargetFrameTexture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-TargetingFrame-Elite")
			elseif classification == "elite" then
				TargetFrameTexture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-TargetingFrame-Elite")
			elseif classification == "rare" then
				TargetFrameTexture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-TargetingFrame-Rare")
			else
				TargetFrameTexture:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\UI-TargetingFrame")
			end
		end

		if VE.isOptionEnabled("BigPlayerFrameClassColors") then
			local color = VE.config.ClassColors[UnitClass("player")]
			PlayerFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b, 1)

			local Original_UnitFrameHealthBar_Update = UnitFrameHealthBar_Update
			function UnitFrameHealthBar_Update(statusbar, unit)
				-- VE.print(string.format("unit: %s, class: %s, status: %s", unit, UnitClass(unit), statusbar:GetName()))
				Original_UnitFrameHealthBar_Update(statusbar, unit)

				local statusbarName = statusbar:GetName()

				if statusbarName == "PlayerFrameHealthBar" then
					local color = VE.config.ClassColors[UnitClass("player")]
					if color then PlayerFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b, 1) end
				end

				if statusbarName == "TargetFrameHealthBar" then
					local color = VE.config.ClassColors[UnitClass("target")]
					if color then TargetFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b, 1) end
				end
			end
		end
	end

	if event == "PLAYER_TARGET_CHANGED" and VE.isOptionEnabled("BigPlayerFrameClassColors") then
		local color = VE.config.ClassColors[UnitClass("target")]
		if color then
			TargetFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b, 1)
		end
	end
end)
