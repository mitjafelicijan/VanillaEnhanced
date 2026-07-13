local module = VE.registerModule({
	identifier = "BulletinBoard",
	meta = {
		label = "Bulletin Board",
		description = "Automatically detects LFG messages, filters them by dungeon, and keeps the list up to date.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		debug = false,
		maxListings = 100,      -- How many rows does the UI table have.
		rowHeight = 22,         -- Size of row height (if bigger then adds padding)
		updateInterval = 10,    -- At what freq do we update UI.
		channels = {            -- Which channels do we listen to for messages.
			"Trade",
			"World",
			"LookingForGroup",
		},
		instances = {
			-- Dungeons
			{ id = "ragefire-chasm", list = {}, level = "13-16", type = "dungeon", name = "Ragefire Chasm", keywords = {"rfc", "ragefire", "chasm"} },
			{ id = "deadmines", list = {}, level = "17-21", type = "dungeon", name = "Deadmines",  keywords = {"deadmines", "vc"} },
			{ id = "wailing-caverns", list = {}, level = "17-23", type = "dungeon", name = "Wailing Caverns", keywords = {"wc", "wailing"} },
			{ id = "shadowfang-keep", list = {}, level = "18-23", type = "dungeon", name = "Shadowfang Keep", keywords = {"sfk", "arugal", "shadowfang"} },
			{ id = "blackfathom-deeps", list = {}, level = "20-27", type = "dungeon", name = "Blackfathom Deeps", keywords = {"bfd", "blackfathom", "deeps"} },
			{ id = "the-stockade", list = {}, level = "23-30", type = "dungeon", name = "The Stockade", keywords = {"stocks", "stockades"} },
			{ id = "razorfen-kraul", list = {}, level = "25-32", type = "dungeon", name = "Razorfen Kraul", keywords = {"rfk", "kraul"} },
			{ id = "dragonmaw-retreat", list = {}, level = "26-35", type = "dungeon", name = "Dragonmaw Retreat", keywords = {"dragonmaw", "dmr"} },
			{ id = "gnomeregan", list = {}, level = "28-35", type = "dungeon", name = "Gnomeregan", keywords = {"gnomer", "gnomeregan"} },
			{ id = "scarlet-monastery-graveyard", list = {}, level = "29-35", type = "dungeon", name = "Scarlet Monastery Graveyard", keywords = {"sm", "gy"} },
			{ id = "scarlet-monastery-library", list = {}, level = "31-37", type = "dungeon", name = "Scarlet Monastery Library", keywords = {"sm", "lib"} },
			{ id = "scarlet-monastery-cathedral", list = {}, level = "36-42", type = "dungeon", name = "Scarlet Monastery Cathedral", keywords = {"sm", "cath"} },
			{ id = "crescent-grove", list = {}, level = "32-38", type = "dungeon", name = "Crescent Grove", keywords = {"crescent", "grove"} },
			{ id = "razorfen-downs", list = {}, level = "37-43", type = "dungeon", name = "Razorfen Downs", keywords = {"rfd", "downs"} },
			{ id = "uldaman", list = {}, level = "41-47", type = "dungeon", name = "Uldaman", keywords = {"ulda", "uld", "uldman", "uldaman"} },
			{ id = "gilneas-city", list = {}, level = "43-49", type = "dungeon", name = "Gilneas City", keywords = {"gilneas"} },
			{ id = "zul-farrak", list = {}, level = "44-49", type = "dungeon", name = "Zul'Farrak", keywords = {"zf", "farrak", "zulfarrak"} },
			{ id = "maraudon", list = {}, level = "47-52", type = "dungeon", name = "Maraudon", keywords = {"mara", "maraudon", "purple", "orange", "inner", "wicked", "grotto", "foulspore"} },
			{ id = "blackrock-depths", list = {}, level = "49-53", type = "dungeon", name = "Blackrock Depths", keywords = {"brd"} },
			{ id = "dire-maul", list = {}, level = "55-60", type = "dungeon", name = "Dire Maul", keywords = {"dm", "dme", "dmw", "dmn", "dm:e", "dm:n", "dm:w", "dire", "maul"} },
			{ id = "stratholme", list = {}, level = "55-60", type = "dungeon", name = "Stratholme", keywords = {"strat", "stratholme"} },
			{ id = "scholomance", list = {}, level = "55-60", type = "dungeon", name = "Scholomance", keywords = {"scholo", "scholomance"} },
			{ id = "hateforge-quarry", list = {}, level = "52-60", type = "dungeon", name = "Hateforge Quarry", keywords = {"hateforge", "Quarry"} },
			{ id = "lower-blackrock-spire", list = {}, level = "55-60", type = "dungeon", name = "Lower Blackrock Spire", keywords = {"lbrs"} },
			{ id = "upper-blackrock-spire", list = {}, level = "55-60", type = "dungeon", name = "Upper Blackrock Spire", keywords = {"ubrs"} },
			{ id = "stormwind-vault", list = {}, level = "60", type = "dungeon", name = "Stormwind Vault", keywords = {"sw", "swv", "vault"} },
			-- Raids
			{ id = "sunken-temple", list = {}, level = "50", type = "raid", name = "Sunken Temple", keywords = {"sunken"} },
			{ id = "molten-core", list = {}, level = "60", type = "raid", name = "Molten Core", keywords = {"mc", "molten"} },
			{ id = "onyxias-lair", list = {}, level = "60", type = "raid", name = "Onyxia's Lair", keywords = {"onyxia", "ony"} },
			{ id = "blackwing-lair", list = {}, level = "60", type = "raid", name = "Blackwing Lair", keywords = {"blackwing", "bwl"} },
			{ id = "dragons-of-nightmare", list = {}, level = "60", type = "raid", name = "Dragons of Nightmare", keywords = {"dragons"} },
			{ id = "zul-gurub", list = {}, level = "60", type = "raid", name = "Zul'Gurub", keywords = {"zg"} },
			{ id = "ruins-of-ahn-qiraj", list = {}, level = "60", type = "raid", name = "Ruins of Ahn'Qiraj", keywords = {"aq", "aq20"} },
			{ id = "temple-of-ahn-qiraj", list = {}, level = "60", type = "raid", name = "Temple of Ahn'Qiraj", keywords = {"aq", "aq40"} },
			{ id = "naxxramas", list = {}, level = "60", type = "raid", name = "Naxxramas", keywords = {"naxx", "naxxramas"} },
			-- { id = "tower-of-karazhan", list = {}, level = "60", type = "raid", name = "Tower of Karazhan", keywords = {"kara", "karazhan"} },
			-- { id = "emerald-sanctum", list = {}, level = "60", type = "raid", name = "Emerald Sanctum", keywords = {"emerald", "sanctum", "es"} },
		},
		cleanupRules = { "%d+", "/", ",", "%.", "-", "+", "'", "!", ";", "<", ">" },
	},
	data = {
		instances = {},
		listings = {},
		trade = {},
		lastUpdate = 0,
		selectedInstances = {},
		filterInstances = {},
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local print = VE.print
local dprint = VE.dprint
local iprint = VE.iprint
local eprint = VE.eprint

local function GetInstanceName(instance)
	for _, item in pairs(module.config.instances) do
		if instance == item.id then
			return {
				level = item.level,
				type = item.type,
				name = item.name,
			}
		end
	end
end

local function IsAllowedChannel(channel)
	for _, ch in pairs(module.config.channels) do
		if ch == channel then return true end
	end
	return false
end

local function ProcessMessage(sender, message)
	message = VE.trim(message)

	-- Check if message already in the queue.
	for _, item in pairs(module.data.listings) do
		if sender == item.sender and string.lower(message) == string.lower(item.message) then
			return
		end
	end

	local listing = {
		lfg = false,
		lfm = false,
		wtb = false,
		wts = false,
		type = nil,
		tank = false,
		healer = false,
		dps = false,
		instance = nil,
		sender = sender,
		message = message,
		time = GetTime(),
	}

	-- Remove unnecessary characters for easier parsing.
	for _, rule in pairs(module.config.cleanupRules) do
		message = VE.replace(message, rule, " ")
	end

	local tokens = VE.split(message, " ")
	for _, token in ipairs(tokens) do
		token = string.lower(token)
		if token == "lf" or token == "lfm" then listing.lfm = true end
		if token == "lfg" then listing.lfg = true end
		if token == "wtb" then listing.wtb = true end
		if token == "wts" then listing.wts = true end
		if token == "tank" or token == "ot" or token == "mt" then listing.tank = true end
		if token == "heal" or token == "heals" or token == "healer" or token == "healers" then listing.healer = true end
		if token == "dps" then listing.dps = true end

		if listing.lfg then listing.type = "LFG" end
		if listing.lfm then listing.type = "LFM" end

		for key, instance in pairs(module.data.instances) do
			if token == key then
				listing.instance = instance
				break
			end
		end
	end

	if (listing.lfg or listing.lfm) and listing.instance then
		table.insert(module.data.listings, 1, listing)
	end

	-- Truncate table to only N listings (same as max rows in UI).
	local listingSize = VE.count(module.data.listings)
	if listingSize > module.config.maxListings then
		for i = module.config.maxListings + 1, listingSize do
			module.data.listings[i] = nil
		end
	end

	tokens = nil
	listing = nil
	listingSize = nil
end

local function UpdateListings()
	-- Hide all rows.
	for i = 1, module.config.maxListings do
		getglobal(string.format("BulletinBoardEntry%s", i)):Hide()
	end

	local elapsed
	local elapsedFormatted

	-- Show active ones.
	local i = 1
	for _, listing in pairs(module.data.listings) do
		local numSelected = 0
		for id, isSelected in pairs(module.data.selectedInstances) do
			if isSelected then
				numSelected = numSelected + 1
			end
		end

		local allowed = true
		if numSelected > 0 then
			allowed = false
			for id, isSelected in pairs(module.data.selectedInstances) do
				if isSelected and id == listing.instance then
					allowed = true
				end
			end
		end

		if allowed then
			elapsed = GetTime() - listing.time
			elapsedFormatted = ""
			if elapsed < 60 then
				elapsedFormatted = string.format("%ds ago", math.floor(elapsed))
			elseif elapsed < 3600 then
				elapsedFormatted = string.format("%dm ago", math.floor(elapsed / 60))
			else
				elapsedFormatted = string.format("%dh ago", math.floor(elapsed / 3600))
			end

			getglobal(string.format("BulletinBoardEntry%s", i)).meta = listing
			getglobal(string.format("BulletinBoardEntry%sSender", i)):SetText(listing.sender)
			getglobal(string.format("BulletinBoardEntry%sType", i)):SetText(listing.type)
			getglobal(string.format("BulletinBoardEntry%sInstance", i)):SetText(GetInstanceName(listing.instance).name)
			getglobal(string.format("BulletinBoardEntry%sElapsed", i)):SetText(elapsedFormatted)
			getglobal(string.format("BulletinBoardEntry%s", i)):Show()

			if listing.dps then
				getglobal(string.format("BulletinBoardEntry%sRoleDPS", i)):SetAlpha(1.0)
				getglobal(string.format("BulletinBoardEntry%sRoleDPS", i)):SetDesaturated(0)
			else
				getglobal(string.format("BulletinBoardEntry%sRoleDPS", i)):SetAlpha(0.3)
				getglobal(string.format("BulletinBoardEntry%sRoleDPS", i)):SetDesaturated(1)
			end

			if listing.healer then
				getglobal(string.format("BulletinBoardEntry%sRoleHealer", i)):SetAlpha(1.0)
				getglobal(string.format("BulletinBoardEntry%sRoleHealer", i)):SetDesaturated(0)
			else
				getglobal(string.format("BulletinBoardEntry%sRoleHealer", i)):SetAlpha(0.3)
				getglobal(string.format("BulletinBoardEntry%sRoleHealer", i)):SetDesaturated(1)
			end

			if listing.tank then
				getglobal(string.format("BulletinBoardEntry%sRoleTank", i)):SetAlpha(1.0)
				getglobal(string.format("BulletinBoardEntry%sRoleTank", i)):SetDesaturated(0)
			else
				getglobal(string.format("BulletinBoardEntry%sRoleTank", i)):SetAlpha(0.3)
				getglobal(string.format("BulletinBoardEntry%sRoleTank", i)):SetDesaturated(1)
			end

			i = i + 1
		end
	end

	-- This makes scrollbars work properly.
	BulletinBoardScrollChild:SetHeight(module.config.rowHeight * i)
	BulletinBoardScrollFrame:UpdateScrollChildRect()

	elapsed = nil
	elapsedFormatted = nil
end

function BulletinBoardListing_OnClick()
	if arg1 == "LeftButton" then
		if IsControlKeyDown() then
			InviteByName(this.meta.sender)
		else
			ChatFrame_SendTell(this.meta.sender)
		end
	end

	if arg1 == "RightButton" then
		-- NOTE: /who has a cooldown
		SendWho(this.meta.sender)
	end
end

function BulletinBoardListing_OnEnter()
	if not this.meta then
		GameTooltip:Hide()
		return
	end

	local info = GetInstanceName(this.meta.instance)

	GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
	GameTooltip:SetText(info.name)
	GameTooltip:AddLine(string.format("%s (%s)", this.meta.sender, this.meta.type))

	local tokens = VE.split(this.meta.message, " ")
	local line = ""
	for i = 1, VE.count(tokens) do
		line = line .. tokens[i] .. " "
		if math.mod(i, 10) == 0 or i == VE.count(tokens) then
			GameTooltip:AddLine(VE.trim(line), 0.8, 0.8, 0.8)
			line = ""
		end
	end

	getglobal(string.format("%sBackground", this:GetName())):SetVertexColor(1, 1, 0, 0.2)
	GameTooltip:Show()

	info = nil
	tokens = nil
	line = nil
end

function BulletinBoard_Refresh()
	UpdateListings()
end

local function CreateMultiSelectDropdown(name, parent, items, width)
	local frame = CreateFrame("Button", "VE_BulletinBoardDropdown", parent, "UIDropDownMenuTemplate")
	frame:SetWidth(width or 150)
	frame:SetHeight(44)

	module.data.selectedInstances = {}

	-- Function to count selected items.
	local function CountSelected()
		local count = 0
		for _, selected in pairs(module.data.selectedInstances) do
			if selected then count = count + 1 end
		end
		return count
	end

	-- Function to update the dropdown text.
	local function UpdateText()
		local selectedCount = CountSelected()
		local firstSelectedName

		if selectedCount > 0 then
			for _, item in ipairs(items) do
				if module.data.selectedInstances[item.id] then
					firstSelectedName = item.name
					break
				end
			end
		end

		local text
		if selectedCount == 0 then
			text = "Select dungeons or raids"
		elseif selectedCount == 1 then
			text = firstSelectedName
		else
			text = string.format("%d selected", selectedCount)
		end
		getglobal(frame:GetName().."Text"):SetText(text)
	end

	-- Create timer frame (vanilla-compatible OnUpdate).
	frame.timerFrame = CreateFrame("Frame", nil, frame)
	frame.timerFrame:Hide()
	frame.timerFrame:SetScript("OnUpdate", function()
		if not this.startTime then return end
		if GetTime() - this.startTime > 0.01 then
			local level = this.level or 1
			local value = this.value
			this.startTime = nil
			if not UIDROPDOWNMENU_OPEN_MENU then UIDROPDOWNMENU_OPEN_MENU = frame:GetName() end
			ToggleDropDownMenu(level, value, frame, frame:GetName(), 8, 7)
			this:Hide()
		end
	end)

	-- Custom dropdown handler.
	local function Dropdown_OnClick()
		local id = this.value
		module.data.selectedInstances[id] = not module.data.selectedInstances[id]
		UpdateText()

		-- Schedule menu reopen.
		frame.timerFrame.startTime = GetTime()
		frame.timerFrame.level = UIDROPDOWNMENU_MENU_LEVEL
		frame.timerFrame.value = UIDROPDOWNMENU_MENU_VALUE
		frame.timerFrame:Show()

		UpdateListings()
	end

	-- Initialize the dropdown.
	UIDropDownMenu_Initialize(frame, function()
		local level = tonumber(UIDROPDOWNMENU_MENU_LEVEL) or 1
		local value = UIDROPDOWNMENU_MENU_VALUE

		if level == 1 then
			local info = {}
			info.text = "Dungeons (1-30)"
			info.value = "DUNGEON_LOW"
			info.hasArrow = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, level)

			info = {}
			info.text = "Dungeons (31-50)"
			info.value = "DUNGEON_MID"
			info.hasArrow = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, level)

			info = {}
			info.text = "Dungeons (51-60)"
			info.value = "DUNGEON_HIGH"
			info.hasArrow = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, level)

			info = {}
			info.text = "Raids"
			info.value = "RAID"
			info.hasArrow = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, level)
		elseif level == 2 then
			for _, item in ipairs(items) do
				local match = false
				local lv = tonumber(VE.find(item.level or "0", "(%d+)")) or 0

				if value == "RAID" and item.type == "raid" then
					match = true
				elseif item.type == "dungeon" then
					if value == "DUNGEON_LOW" and lv <= 30 then match = true
					elseif value == "DUNGEON_MID" and lv > 30 and lv <= 50 then match = true
					elseif value == "DUNGEON_HIGH" and lv > 50 then match = true end
				end

				if match then
					local info = {
						text = item.name,
						value = item.id,
						func = Dropdown_OnClick,
						checked = module.data.selectedInstances[item.id],
						isTitle = false,
						notCheckable = false
					}
					UIDropDownMenu_AddButton(info, level)
				end
			end
		end
	end)

	-- Initial setup.
	UIDropDownMenu_SetWidth(width or 150, frame)
	UIDropDownMenu_SetButtonWidth(24, frame)
	UIDropDownMenu_JustifyText("LEFT", frame)
	UpdateText()

	-- Public methods.
	-- function frame:GetSelectedIds()
	-- 	local selected = {}
	-- 	for id, isSelected in pairs(module.data.selectedInstances) do
	-- 		if isSelected then table.insert(selected, id) end
	-- 	end
	-- 	return selected
	-- end

	-- function frame:SetSelectedIds(ids)
	-- 	for id, _ in pairs(module.data.selectedInstances) do
	-- 		-- module.data.selectedInstances[id] = false
	-- 		module.data.selectedInstances[id] = nil
	-- 	end
	-- 	for _, id in ipairs(ids) do
	-- 		module.data.selectedInstances[id] = true
	-- 	end
	-- 	UpdateText()
	-- end

	return frame
end

function BulletinBoardListing_OnLeave()
	getglobal(string.format("%sBackground", this:GetName())):SetVertexColor(0, 0, 0, 0.3)
	GameTooltip:Hide()
end

function BulletinBoard_OnLoad()
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	this:RegisterEvent("CHAT_MSG_CHANNEL")

	tinsert(UISpecialFrames, this:GetName())

	local dropdown = CreateMultiSelectDropdown("BulletinBoardTypeDropdown", BulletinBoard, module.config.instances, 200, function(selected)
		for _, item in ipairs(selected) do
			print(item)
		end
	end)
	dropdown:SetPoint("TOPLEFT", BulletinBoard, "TOPLEFT", 70, -40)
end

function BulletinBoard_OnShow()
	local nativeFrames = {
		CharacterFrame,
		SpellBookFrame,
		TalentFrame,
		QuestLogFrame,
	}

	for _, frame in ipairs(nativeFrames) do
		if frame and frame:IsShown() then
			frame:Hide()
		end
	end

	nativeFrames = nil
end

function BulletinBoard_OnEvent()
	if not VE.isModuleEnabled(module.identifier) then
		this:UnregisterAllEvents()
		return
	end

	if event == "PLAYER_ENTERING_WORLD" then
		for _, instance in pairs(module.config.instances) do
			for _, keyword in pairs(instance.keywords) do
				module.data.instances[keyword] = instance.id
			end
		end

		BulletinBoardScrollFrame:SetScrollChild(BulletinBoardScrollChild)

		local frame = nil
		for i = 1, module.config.maxListings do
			frame = CreateFrame("Button", string.format("BulletinBoardEntry%s", i), BulletinBoardScrollChild, "BulletinBoardListing")
			frame:SetPoint("TOPLEFT", BulletinBoardScrollChild, "TOPLEFT", 0, -((i-1) * module.config.rowHeight))
			frame:SetPoint("RIGHT", BulletinBoardScrollChild, "RIGHT")
			frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			frame:EnableMouse(true)
			getglobal(string.format("BulletinBoardEntry%sBackground", i)):SetVertexColor(0, 0, 0, 0.3)
		end

		this:SetScript("OnUpdate", function()
			module.data.lastUpdate = module.data.lastUpdate + arg1
			if module.data.lastUpdate >= module.config.updateInterval then
				module.data.lastUpdate = 0

				if this:IsShown() then
					UpdateListings()
				end
			end
		end)

		SLASH_BULLETINBOARD1 = "/bulletinboard"
		SLASH_BULLETINBOARD2 = "/bb"
		SlashCmdList["BULLETINBOARD"] = function()
			if VE.isModuleEnabled(module.identifier) then
				BulletinBoard:Show()
				UpdateListings()
			end
		end

		this:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end

	if event == "CHAT_MSG_CHANNEL" then
		if IsAllowedChannel(arg9) then
			ProcessMessage(arg2, arg1)
		end
	end
end
