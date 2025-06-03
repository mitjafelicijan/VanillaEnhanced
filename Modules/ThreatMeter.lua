local module = VE.registerModule({
	identifier = "ThreatMeter",
	meta = {
		label = "Threat Meter (wip)",
		description = "...",
	},
	plug = nil,
	superWoWRequired = true,
	config = {
		backgroundAlpha = 0.8,
		show = {},
	},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
	this:RegisterEvent("PLAYER_TARGET_CHANGED")
end

local print = VE.print
local dprint = VE.dprint
local iprint = VE.iprint

function ThreatMeter_OnLoad()
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	this:RegisterEvent("RAW_COMBATLOG")
end

function ThreatMeter_OnEvent()
	if not VE.isModuleEnabled(module.identifier) then
		this:UnregisterAllEvents()
		return
	end

	if event == "PLAYER_ENTERING_WORLD" then
		print("ThreatMeter")
	end

	if event == "RAW_COMBATLOG" then
		local event_name = arg1
		local event_text = arg2

		--arg1: original event name.
		--arg2: event text with GUIDs
		--dprint(string.format("event: %s, arg2: %s", event_name, arg2))
		-- dprint(string.format("event: %s", event_name))

		if event_name == "CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS" then
			dprint(string.format("event: %s", event_name))
			dprint(string.format("text: %s", event_text))

			-- local sourceGUID, action, destGUID, amount = event_text:match("^(0x%x+) (%a+) (0x%x+) for (%d+)")
			-- print(string.format("source: %s (%s)", sourceGUID, UnitName(sourceGUID)))

			-- Parse the combat text message
			-- local sourceGUID, action, destGUID, amount = strmatch(event_text, "^(0x%x+) (%a+) (0x%x+) for (%d+)")
			local sourceGUID, action, targetGUID, amount = event_text:match("^(0x%x+)%s+(%a+)%s+(0x%x+)%s+for%s+(%d+)")

			-- Since this is the chat message version, we don't have GUIDs here
			-- You'll need to get the GUIDs another way if needed
			-- print(string.format("source: %s", sourceName))
			-- print(string.format("action: %s", action))
			-- print(string.format("target: %s", destName))
			-- print(string.format("amount: %d", tonumber(amount) or 0))

		end
	end
end
