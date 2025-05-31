local module = VE.registerModule({
	identifier = "CastingBarPosition",
	meta = {
		label = "Casting Bar Position",
		description = "Moves the casting bar to a higher position on the screen for improved visibility.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		offsetPercentage = 30,
	},
	data = {
		offset = 0,
		finishTime = 0,
		casting = false,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterAllEvents()
module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "ADDON_LOADED" then
		local half = GetScreenHeight() / 2
		module.data.offset = half - ((half / 100) * module.config.offsetPercentage)
	end

	if event == "SPELLCAST_START" or event == "SPELLCAST_CHANNEL_START" then
		local duration = tonumber(arg2)
		if duration then
			module.data.finishTime = GetTime() + (duration / 1000)
			module.data.casting = true
		end
	end

	-- Handle spell pushback when player takes damage during casting
	if event == "SPELLCAST_DELAYED" then
		local disruption = tonumber(arg1)
		if disruption and module.data.casting then
			module.data.finishTime = module.data.finishTime + (disruption / 1000)
		end
	end

	-- Handle channeled spell pushback
	if event == "SPELLCAST_CHANNEL_UPDATE" then
		local remainingTime = tonumber(arg1)
		if remainingTime and module.data.casting then
			module.data.finishTime = GetTime() + (remainingTime / 1000)
		end
	end

	if event == "SPELLCAST_STOP" or
		event == "SPELLCAST_FAILED" or
		event == "SPELLCAST_INTERRUPTED" or
		event == "SPELLCAST_CHANNEL_STOP" then
		module.data.casting = false
		CastingBarFrame:Hide()
	end

	if CastingBarFrame:IsShown() then
		CastingBarFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, module.data.offset)
	end
end)

module.plug:SetScript("OnUpdate", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	-- Update the casting bar position
	if CastingBarFrame:IsShown() then
		CastingBarFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, module.data.offset)
	end

	-- This fixes casting bar sometimes staying visible if SPELLCAST_STOP, etc
	-- doesn't get triggered in the game.
	if module.data.finishTime > 0 and module.data.finishTime < GetTime() and module.data.casting then
		module.data.casting = false
		CastingBarFrame:Hide()
	end
end)
