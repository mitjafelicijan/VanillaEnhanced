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
		classCache = {},
		urlPatterns = {
			"(https?://[%w%d%._%-%/%%]+)",
			"(www%.[%w%d%._%-%/%%]+)",
			"([%w%d%-_]+%.%a%a+/[%w%d%._%-%/%%]+)",
			"([%w%d%-_]+%.%a%a+)",
			"(%d+%.%d+%.%d+%.%d+)",
		},
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function CopyURL(url)
	if not url then return end

	if not StaticPopupDialogs["VE_COPY_URL"] then
		StaticPopupDialogs["VE_COPY_URL"] = {
			text = "Copy URL (Ctrl+C)",
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
			editBox:SetWidth(270)
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

local function UpdateClassCache()
	-- Guild
	if IsInGuild() then
		local numGuild = GetNumGuildMembers()
		for i = 1, numGuild do
			local name, _, _, _, class = GetGuildRosterInfo(i)
			if name and class then
				module.data.classCache[name] = class
			end
		end
	end
	
	-- Raid
	local numRaid = GetNumRaidMembers()
	if numRaid > 0 then
		for i = 1, numRaid do
			local name, _, _, _, class, fileName = GetRaidRosterInfo(i)
			if name and (fileName or class) then
				module.data.classCache[name] = fileName or class
			end
		end
	end
	
	-- Party
	local numParty = GetNumPartyMembers()
	if numParty > 0 then
		for i = 1, numParty do
			local name = UnitName("party"..i)
			local _, class = UnitClass("party"..i)
			if name and class then
				module.data.classCache[name] = class
			end
		end
	end

	-- Self
	local name = UnitName("player")
	local _, class = UnitClass("player")
	if name and class then
		module.data.classCache[name] = class
	end
	
	-- Friends
	local numFriends = GetNumFriends()
	for i = 1, numFriends do
		local name, _, class = GetFriendInfo(i)
		if name and class then
			module.data.classCache[name] = class
		end
	end
end

local function GetClassColor(name)
	if not name then return nil end
	
	local class = module.data.classCache[name]
	
	-- If not in cache, try to find the unit directly
	if not class then
		if UnitName("player") == name then
			_, class = UnitClass("player")
		elseif GetNumRaidMembers() > 0 then
			for i=1, 40 do
				local u = "raid"..i
				if UnitName(u) == name then
					_, class = UnitClass(u)
					break
				end
			end
		elseif GetNumPartyMembers() > 0 then
			for i=1, 4 do
				local u = "party"..i
				if UnitName(u) == name then
					_, class = UnitClass(u)
					break
				end
			end
		end
		
		-- Store in cache if found
		if class then
			module.data.classCache[name] = class
		end
	end
	
	if class then
		-- Normalize class name (handle WARRIOR, Warrior, etc.)
		local classKey = string.upper(string.sub(class, 1, 1)) .. string.lower(string.sub(class, 2))
		local color = VE.config.ClassColors[classKey]
		if color then
			return string.format("%02x%02x%02x", math.floor(color.r * 255), math.floor(color.g * 255), math.floor(color.b * 255))
		end
	end
	return nil
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

local function ColorizeNames(msg)
	-- Matches: |Hplayer:Name[:extra]|hDisplay|h
	-- Display can contain brackets or colors from other addons
	msg = string.gsub(msg, "(|Hplayer:([^:]+)([:%d]*)|h)(.-)(|h)", function(linkStart, name, extra, display, linkEnd)
		local color = GetClassColor(name)
		if color then
			-- Strip existing colors from display if any (like from CleanChat)
			display = string.gsub(display, "|c%x%x%x%x%x%x%x%x", "")
			display = string.gsub(display, "|r", "")
			return linkStart .. "|cff" .. color .. display .. "|r" .. linkEnd
		end
		return linkStart .. display .. linkEnd
	end)

	return msg
end

local function ShortenChannelNames()
	CHAT_GUILD_GET = "[G] %s: "
	CHAT_OFFICER_GET = "[O] %s: "
	CHAT_PARTY_GET = "[P] %s: "
	CHAT_RAID_GET = "[R] %s: "
	CHAT_RAID_LEADER_GET = "[RL] %s: "
	CHAT_RAID_WARNING_GET = "[RW] %s: "
	CHAT_BATTLEGROUND_GET = "[BG] %s: "
	CHAT_BATTLEGROUND_LEADER_GET = "[BGL] %s: "
end

local function ShortenNumberedChannels(msg)
	if not msg then return msg end
	msg = string.gsub(msg, "%[(%d+)%. General%]", "[%1. G]")
	msg = string.gsub(msg, "%[(%d+)%. Trade%]", "[%1. T]")
	msg = string.gsub(msg, "%[(%d+)%. LocalDefense%]", "[%1. LD]")
	msg = string.gsub(msg, "%[(%d+)%. WorldDefense%]", "[%1. WD]")
	msg = string.gsub(msg, "%[(%d+)%. LookingForGroup%]", "[%1. LFG]")
	msg = string.gsub(msg, "%[(%d+)%. GuildRecruitment%]", "[%1. GR]")
	msg = string.gsub(msg, "%[(%d+)%. Hardcore%]", "[%1. HC]")
	return msg
end

local function HookChatFrame(frame)
	if not frame or frame.VE_AddMessage_Org then return end

	frame.VE_AddMessage_Org = frame.AddMessage
	frame.AddMessage = function(this, msg, r, g, b, id)
		if msg then
			msg = ProcessMessage(msg)
			msg = ColorizeNames(msg)
			msg = ShortenNumberedChannels(msg)
		end
		this:VE_AddMessage_Org(msg, r, g, b, id)
	end
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

	if event == "PLAYER_ENTERING_WORLD" or event == "GUILD_ROSTER_UPDATE" or 
		event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" or 
		event == "FRIENDLIST_UPDATE" then
		UpdateClassCache()
		ShortenChannelNames()
	end

	if event == "PLAYER_ENTERING_WORLD" then
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

		-- Register additional events for name coloring
		module.plug:RegisterEvent("GUILD_ROSTER_UPDATE")
		module.plug:RegisterEvent("RAID_ROSTER_UPDATE")
		module.plug:RegisterEvent("PARTY_MEMBERS_CHANGED")
		module.plug:RegisterEvent("FRIENDLIST_UPDATE")
	end
end)

-- Hook existing frames for reloads
for i=1, NUM_CHAT_WINDOWS do
	local frame = getglobal("ChatFrame" .. i)
	if frame then
		HookChatFrame(frame)
	end
end

-- Shorten channel names on load
if VE.isModuleEnabled(module.identifier) then
	ShortenChannelNames()
end
