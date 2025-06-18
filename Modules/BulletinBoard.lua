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
			{ id = "tower-of-karazhan", list = {}, level = "60", type = "raid", name = "Tower of Karazhan", keywords = {"kara", "karazhan"} },
			{ id = "emerald-sanctum", list = {}, level = "60", type = "raid", name = "Emerald Sanctum", keywords = {"emerald", "sanctum", "es"} },
		},
		cleanupRules = { "%d+", "/", ",", "%.", "-", "+", "'", "!", ";", "<", ">" },
	},
	data = {
		instances = {},
		listings = {},
		trade = {},
		lastUpdate = 0,
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

	local listing = {
		lfg = false,
		lfm = false,
		wtb = false,
		wts = false,
		tank = false,
		healer = false,
		dps = false,
		instance = nil,
		sender = sender,
		message = message,
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

		for key, instance in pairs(module.data.instances) do
			if token == key then
				listing.instance = instance
				break
			end
		end
	end

	if (listing.lfg or listing.lfm) and listing.instance then
		table.insert(module.data.listings, 1, listing)

		if module.config.debug then
			local _meta = (string.format("instance: %s; lfg: %s; lfm: %s; tank: %s, heals: %s; dps: %s; sender: %s", tostring(listing.instance), tostring(listing.lfg), tostring(listing.lfm), tostring(listing.tank), tostring(listing.healer), tostring(listing.dps), listing.sender))
			local _message = (string.format("  --> message: %s", listing.message))
			if not listing.instance then
				eprint(_meta)
				eprint(_message)
			else
				print(_meta)
				print(_message)
			end
		end
	end

	-- Truncate table to only N listings (same as max rows in UI).
	local listingSize = VE.count(module.data.listings)
	if listingSize > module.config.maxListings then
		for i = module.config.maxListings + 1, listingSize do
			module.data.listings[i] = nil
			-- dprint(string.format("removing %s listing (%s still in queue)", i, VE.count(module.data.listings)))
		end
	end

	tokens = nil
	listing = nil
	listingSize = nil
end

local function UpdateListings()
	local numListings = VE.count(module.data.listings)
	
	-- Show active ones.
	for i, listing in pairs(module.data.listings) do
		getglobal(string.format("BulletinBoardEntry%s", i)).meta = listing
		getglobal(string.format("BulletinBoardEntry%sSender", i)):SetText(listing.sender)
		getglobal(string.format("BulletinBoardEntry%sMessage", i)):SetText(listing.message)
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
	end

	-- This makes scrollbars work properly.
	BulletinBoardScrollChild:SetHeight(module.config.rowHeight * numListings)
	BulletinBoardScrollFrame:UpdateScrollChildRect()

	numListings = nil
end

function BulletinBoardListing_OnClick()
	if IsControlKeyDown() then
		InviteUnit(this.meta.sender)
	else
		ChatFrame_SendTell(this.meta.sender)
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
	GameTooltip:AddLine(this.meta.sender)

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

local function CreateMultiSelectDropdown1(name, parent, items, width, fn)
    local frame = CreateFrame("Button", name, parent, "UIDropDownMenuTemplate")
    frame:SetWidth(width or 150)
    frame:SetHeight(44)
    
    -- Store selected items
    frame.selectedItems = {}
    for _, item in ipairs(items) do
        frame.selectedItems[item] = false
    end
    
    -- Function to count selected items
    local function CountSelected()
        local count = 0
        for _, selected in pairs(frame.selectedItems) do
            if selected then count = count + 1 end
        end
        return count
    end
    
    -- Function to update the dropdown text
    local function UpdateText()
        local selectedCount = CountSelected()
        local firstSelected
        
        if selectedCount > 0 then
            for item, selected in pairs(frame.selectedItems) do
                if selected then
                    firstSelected = item
                    break
                end
            end
        end
        
        local text
        if selectedCount == 0 then
            text = "Select options"
        elseif selectedCount == 1 then
            text = firstSelected
        else
            text = string.format("%d selected", selectedCount)
        end
        getglobal(frame:GetName().."Text"):SetText(text)
    end
    
    -- Create an invisible frame for our timer
    frame.timerFrame = CreateFrame("Frame", nil, frame)
    frame.timerFrame:Hide()
    
    -- Custom dropdown handler
    local function Dropdown_OnClick()
        local value = this.value
        frame.selectedItems[value] = not frame.selectedItems[value]
        UpdateText()

        frame.timerFrame.startTime = GetTime()
        frame.timerFrame:SetScript("OnUpdate", function()
            if GetTime() - this.startTime > 0.01 then
                this:SetScript("OnUpdate", nil)
                ToggleDropDownMenu(1, nil, frame, frame:GetName(), 8, 7)
                this:Hide()
            end
        end)
        frame.timerFrame:Show()
	end

	-- Initialize the dropdown
	UIDropDownMenu_Initialize(frame, function()
		for _, item in ipairs(items) do
			local info = {
				text = item,
				value = item,
				func = Dropdown_OnClick,
				checked = frame.selectedItems[item],
				isTitle = false,
				notCheckable = false
			}
			UIDropDownMenu_AddButton(info)
		end
	end)

	-- Initial setup
	UIDropDownMenu_SetWidth(width or 150, frame)
	UIDropDownMenu_SetButtonWidth(24, frame)
	UIDropDownMenu_JustifyText("LEFT", frame)
	UpdateText()

    return frame
end

local function CreateMultiSelectDropdown(name, parent, items, width)
    local frame = CreateFrame("Button", name, parent, "UIDropDownMenuTemplate")
    frame:SetWidth(width or 150)
    frame:SetHeight(44)
    
    -- Store selected items by id
    frame.selectedItems = {}
    
    -- Function to count selected items
    local function CountSelected()
        local count = 0
        for _, selected in pairs(frame.selectedItems) do
            if selected then count = count + 1 end
        end
        return count
    end
    
    -- Function to update the dropdown text
    local function UpdateText()
        local selectedCount = CountSelected()
        local firstSelectedName
        
        if selectedCount > 0 then
            for _, item in ipairs(items) do
                if frame.selectedItems[item.id] then
                    firstSelectedName = item.name
                    break
                end
            end
        end
        
        local text
        if selectedCount == 0 then
            text = "Select options"
        elseif selectedCount == 1 then
            text = firstSelectedName
        else
            text = string.format("%d selected", selectedCount)
        end
        getglobal(frame:GetName().."Text"):SetText(text)
    end
    
    -- Create timer frame (vanilla-compatible OnUpdate)
    frame.timerFrame = CreateFrame("Frame", nil, frame)
    frame.timerFrame:Hide()
    frame.timerFrame:SetScript("OnUpdate", function()
        if not this.startTime then return end
        if GetTime() - this.startTime > 0.01 then
            this:SetScript("OnUpdate", nil)
            this.startTime = nil
            ToggleDropDownMenu(1, nil, frame, frame:GetName(), 8, 7)
            this:Hide()
        end
    end)
    
    -- Custom dropdown handler
    local function Dropdown_OnClick()
        local id = this.value
        frame.selectedItems[id] = not frame.selectedItems[id]
        UpdateText()
        
        -- Schedule menu reopen
        frame.timerFrame.startTime = GetTime()
        frame.timerFrame:Show()
    end
    
    -- Initialize the dropdown
    UIDropDownMenu_Initialize(frame, function()
        for _, item in ipairs(items) do
            local info = {
                text = item.name,
                value = item.id,
                func = Dropdown_OnClick,
                checked = frame.selectedItems[item.id],
                isTitle = false,
                notCheckable = false
            }
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Initial setup
    UIDropDownMenu_SetWidth(width or 150, frame)
    UIDropDownMenu_SetButtonWidth(24, frame)
    UIDropDownMenu_JustifyText("LEFT", frame)
    UpdateText()
    
    -- Public methods
    function frame:GetSelectedIds()
        local selected = {}
        for id, isSelected in pairs(self.selectedItems) do
            if isSelected then table.insert(selected, id) end
        end
        return selected
    end
    
    function frame:SetSelectedIds(ids)
        for id, _ in pairs(self.selectedItems) do
            self.selectedItems[id] = false
        end
        for _, id in ipairs(ids) do
            self.selectedItems[id] = true
        end
        UpdateText()
    end
    
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

	-- InitializeBulletinBoardTypeDropdown()

	local items = {"Option 1", "Option 2", "Option 3", "Option 4"}
	local items = {
		{id = "opt1", name = "Option 1"},
		{id = "opt2", name = "Option 2"},
		{id = "opt3", name = "Option 3"},
		{id = "opt4", name = "Option 4"}
	}
	local dropdown = CreateMultiSelectDropdown("BulletinBoardTypeDropdown", BulletinBoard, items, 120, function(selected)
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


	-- if not BulletinBoardDungeonsDropdown.initialized then
	-- 	UIDropDownMenu_SetWidth(120, BulletinBoardDungeonsDropdown)
	-- 	UIDropDownMenu_Initialize(BulletinBoardDungeonsDropdown, function()
	-- 		local options = {
	-- 			{ text = "Option A", value = "A" },
	-- 			{ text = "Option B", value = "B" },
	-- 			{ text = "Option C", value = "C" },
	-- 		}

	-- 		local info = {}
	-- 		info.text = "Dungeons"
	-- 		info.value = nil
	-- 		info.keepShownOnClick = true

	-- 		UIDropDownMenu_AddButton(info)
	-- 		if UIDROPDOWNMENU_MENU_LEVEL == 1 then
	-- 			for _, instance in ipairs(module.config.instances) do
	-- 				if instance.type == "dungeon" then
	-- 					local info = {}
	-- 					info.text = instance.name
	-- 					info.value = instance.id
	-- 					info.keepShownOnClick = true
	-- 					-- info.checked = BulletinBoardInstanceDropdown.selected[instance.id] or false
	-- 					info.func = function()
	-- 						UIDropDownMenu_SetSelectedID(BulletinBoardDungeonsDropdown, this:GetID())
	-- 						print(this.value)
	-- 					end
	-- 					UIDropDownMenu_AddButton(info)
	-- 				end
	-- 			end
	-- 		end

	-- 		UIDropDownMenu_SetSelectedID(BulletinBoardDungeonsDropdown, 1)
	-- 	end)

	-- 	BulletinBoardDungeonsDropdown.initialized = true
	-- end
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
