local module = VE.registerModule({
	identifier = "ManaBarColor",
	meta = {
		label = "White Mana Bar Color",
		description = "Adjusts the default mana bar color to white for better visibility.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("VARIABLES_LOADED")
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	-- Changes global color variable.
	if event == "VARIABLES_LOADED" then
		ManaBarColor[0] = {
			r = VE.config.PowerColors.Mana.r,
			g = VE.config.PowerColors.Mana.g,
			b = VE.config.PowerColors.Mana.b,
			prefix = TEXT(MANA),
		}
	end

	-- If in party or raid, update the frames.
	-- This is a fix them you load into a game and mana bar color in unit
	-- frames is still set to previous color. This happens because of race
	-- condition with VARIABLES_LOADED event.
	if event == "PLAYER_ENTERING_WORLD" then
		if GetNumPartyMembers() > 0 and GetNumRaidMembers() == 0 then
			for i = 1, 4 do
				local frame = getglobal("PartyMemberFrame" .. i)
				if frame then
					UnitFrame_UpdateManaType(frame)
				end
			end
		end
	end
end)
