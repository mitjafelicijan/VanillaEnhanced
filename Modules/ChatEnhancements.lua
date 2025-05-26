local module = VE.registerModule({
	identifier = "ChatEnhancements",
	meta = {
		label = "Chat Enhancements",
		description = "Enables the use of scroll and arrow keys for navigating and editing text in the chat input box.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		scrollSpeed = 3
	},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function ChatOnMouseWheel()
	if arg1 > 0 then
		if IsShiftKeyDown() then
			this:ScrollToTop()
		else
			for i=1, module.config.scrollSpeed do
				this:ScrollUp()
			end
		end
	elseif arg1 < 0 then
		if IsShiftKeyDown() then
			this:ScrollToBottom()
		else
			for i=1, module.config.scrollSpeed do
				this:ScrollDown()
			end
		end
	end
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	-- Enable arrow keys.
	ChatFrameEditBox:SetAltArrowKeyMode(false)

	-- Enable mouse scroll.
	for i=1, NUM_CHAT_WINDOWS do
		getglobal("ChatFrame" .. i):EnableMouseWheel(true)
		getglobal("ChatFrame" .. i):SetScript("OnMouseWheel", ChatOnMouseWheel)
	end

	-- Always select first tab (General).
	FCF_SelectDockFrame(ChatFrame1)
end)
