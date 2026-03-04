local module = VE.registerModule({
	identifier = "ChatEnhancements",
	meta = {
		label = "Chat Enhancements",
		description = "Enables the use of scroll and arrow keys for navigating and editing text in the chat input box.",
	},
	plug = nil,
	superWoWRequired = false,
	hooks = {},
	config = {
		scrollSpeed = 3
	},
	data = {
		urlPatterns = {
			"(https?://[%w%d%._%-%/%%]+)",
			"(www%.[%w%d%._%-%/%%]+)",
			"([%w%d%-_]+%.%a%a+/[%w%d%._%-%/%%]+)",
			"([%w%d%-_]+%.%a%a+)",
			"(%d+%.%d+%.%d+%.%d+)",
		},
	},
})

local function CopyURL(url)
	if not url then return end

	if not StaticPopupDialogs["VE_COPY_URL"] then
		StaticPopupDialogs["VE_COPY_URL"] = {
			text = "Copy URL (Ctrl+C)",
			button2 = CLOSE,
			hasEditBox = 1,
			hasWideEditBox = 1,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
			EditBoxOnEnterPressed = function()
				this:GetParent():Hide()
			end,
			EditBoxOnEscapePressed = function()
				this:GetParent():Hide()
			end,
		}
	end

	local dialog = StaticPopup_Show("VE_COPY_URL")
	if dialog then
		local editBox = getglobal(dialog:GetName() .. "WideEditBox") or getglobal(dialog:GetName() .. "EditBox")
		if editBox then
			editBox:SetText(url)
			editBox:SetFocus()
			editBox:HighlightText()
		end
	end
end

local function OnHyperlinkShow(link, text, button)
	if link and string.sub(link, 1, 4) == "url:" then
		local url = string.sub(link, 5)
		CopyURL(url)
	elseif link and string.sub(link, 1, 13) == "cleanchatURL:" then
		local url = string.sub(link, 14)
		CopyURL(url)
	else
		-- Original logic for item/spell links
		if module.hooks.ChatFrame_OnHyperlinkShow then
			module.hooks.ChatFrame_OnHyperlinkShow(link, text, button)
		end
	end
end

local function ProcessMessage(msg)
	if not msg or type(msg) ~= "string" then return msg end

	return string.gsub(msg, "(%S+)", function(word)
		-- Skip words that already contain WoW escape codes (like colors or links)
		if string.find(word, "|") then return word end

		for _, pattern in pairs(module.data.urlPatterns) do
			if string.find(word, pattern) then
				-- We found a URL. Wrap it in our link format.
				return string.gsub(word, pattern, "|cff00b2ff|Hurl:%1|h[%1]|h|r", 1)
			end
		end
		return word
	end)
end

local function HookChatFrame(frame)
	if not frame or frame.VE_AddMessage_Org then return end

	frame.VE_AddMessage_Org = frame.AddMessage
	frame.AddMessage = function(this, msg, r, g, b, id)
		if msg then
			msg = ProcessMessage(msg)
		end
		this:VE_AddMessage_Org(msg, r, g, b, id)
	end
end

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

	-- Hook hyperlink show.
	if not module.hooks.ChatFrame_OnHyperlinkShow then
		module.hooks.ChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow
		ChatFrame_OnHyperlinkShow = OnHyperlinkShow
	end

	-- Enable arrow keys.
	ChatFrameEditBox:SetAltArrowKeyMode(false)

	-- Enable mouse scroll and link clicking.
	for i=1, NUM_CHAT_WINDOWS do
		local frame = getglobal("ChatFrame" .. i)
		if frame then
			frame:EnableMouseWheel(true)
			frame:SetScript("OnMouseWheel", ChatOnMouseWheel)
			frame:EnableMouse(true)
			HookChatFrame(frame)
		end
	end

	-- Always select first tab (General).
	FCF_SelectDockFrame(ChatFrame1)
end)
