local module = VE.registerModule({
	identifier = "AutoRoll",
	meta = {
		label = "Auto Roll on Items",
		description = "Automatically rolls on specific items and green quality items.",
	},
	plug = nil,
	superWoWRequired = true,
	config = {
		options = {
			Green = false,
			ZG = false,
			MC = false,
			AQ = false,
			Sand = false,
			ES = false,
			Naxx = false,
		},
		loot = {
			ZG = {
				[19698] = "Zulian Coin",
				[19699] = "Razzashi Coin",
				[19700] = "Hakkari Coin",
				[19701] = "Gurubashi Coin",
				[19702] = "Vilebranch Coin",
				[19703] = "Witherbark Coin",
				[19704] = "Sandfury Coin",
				[19705] = "Skullsplitter Coin",
				[19706] = "Bloodscalp Coin",
				[19707] = "Red Hakkari Bijou",
				[19708] = "Blue Hakkari Bijou",
				[19709] = "Yellow Hakkari Bijou",
				[19710] = "Orange Hakkari Bijou",
				[19711] = "Green Hakkari Bijou",
				[19712] = "Purple Hakkari Bijou",
				[19713] = "Bronze Hakkari Bijou",
				[19714] = "Silver Hakkari Bijou",
				[19715] = "Gold Hakkari Bijou",
			},
			MC = {
				[11382] = "Blood of the Mountain",
				[17010] = "Fiery Core",
				[17011] = "Lava Core",
			},
			AQ = {
				[20858] = "Stone Scarab",
				[20859] = "Gold Scarab",
				[20860] = "Silver Scarab",
				[20861] = "Bronze Scarab",
				[20862] = "Crystal Scarab",
				[20863] = "Clay Scarab",
				[20864] = "Bone Scarab",
				[20865] = "Ivory Scarab",
				[20866] = "Azure Idol",
				[20867] = "Onyx Idol",
				[20868] = "Lambent Idol",
				[20869] = "Amber Idol",
				[20870] = "Jasper Idol",
				[20871] = "Obsidian Idol",
				[20872] = "Vermillion Idol",
				[20873] = "Alabaster Idol",
				[20874] = "Idol of the Sun",
				[20875] = "Idol of Night",
				[20876] = "Idol of Death",
				[20877] = "Idol of the Sage",
				[20878] = "Idol of Rebirth",
				[20879] = "Idol of Life",
				[20881] = "Idol of Strife",
				[20882] = "Idol of War",
			},
			Sand = {
				[50203] = "Corrupted Sand",
			},
			ES = {
				[20381] = "Dreamscale",
				[61197] = "Fading Dream Fragment",
				[61198] = "Small Dream Shard",
			},
			Naxx = {
				[22373] = "Wartorn Leather Scrap",
				[22374] = "Wartorn Chain Scrap",
				[22375] = "Wartorn Plate Scrap",
				[22376] = "Wartorn Cloth Scrap",
				[22484] = "Necrotic Rune",
			},
		},
	},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function RollToString(roll)
	if roll == 1 then
		return "Need"
	elseif roll == 2 then
		return "Greed"
	elseif roll == 0 then
		return "Pass"
	end
	return ""
end

-- Helper to confirm BoP popup if it appears for the rolled item
local function ConfirmLootRoll(rollID, rollType)
	for i=1, STATICPOPUP_NUMDIALOGS do
		local frame = getglobal("StaticPopup"..i)
		if frame:IsShown() and frame.which == "CONFIRM_LOOT_ROLL" and frame.data == rollID and frame.data2 == rollType then
			getglobal("StaticPopup"..i.."Button1"):Click()
		end
	end
end

local function AutoRoll(id)
	local roll = nil
	local _, _, _, quality = GetLootRollItemInfo(id)
	local link = GetLootRollItemLink(id)
	local _, _, itemID = string.find(link or "", "item:(%d+)")
	itemID = tonumber(itemID)
	
	if not itemID then return end
	
	-- Check specific lists first
	if module.config.loot.ZG[itemID] then
		roll = module.config.options.ZG
	elseif module.config.loot.MC[itemID] then
		roll = module.config.options.MC
	elseif module.config.loot.AQ[itemID] then
		roll = module.config.options.AQ
	elseif module.config.loot.Sand[itemID] then
		roll = module.config.options.Sand
	elseif module.config.loot.ES[itemID] then
		roll = module.config.options.ES
	elseif module.config.loot.Naxx[itemID] then
		roll = module.config.options.Naxx
	elseif quality == 2 then -- Green items
		roll = module.config.options.Green
	end

	-- Execute roll if a valid option is selected (not disabled/false)
	if roll and type(roll) == "number" then
		RollOnLoot(id, roll)
		
		-- Optional: print message (LazyPig does this)
		-- local _, _, _, hex = GetItemQualityColor(quality)
		-- DEFAULT_CHAT_FRAME:AddMessage("VE AutoRoll: "..hex..RollToString(roll).." "..link)
		
		-- Attempt to confirm BoP popup
		ConfirmLootRoll(id, roll)
	end
end

module.frame = CreateFrame("Frame", module.identifier, UIParent)
module.frame:RegisterEvent("PLAYER_LOGIN")
module.frame:RegisterEvent("START_LOOT_ROLL")
module.frame:RegisterEvent("CONFIRM_LOOT_ROLL")

module.frame:SetScript("OnEvent", function()
	if event == "PLAYER_LOGIN" then
		if not VanillaEnhancedData[module.identifier] then
			VanillaEnhancedData[module.identifier] = module.config.options
		else
			-- Load saved config
			for k, v in pairs(VanillaEnhancedData[module.identifier]) do
				module.config.options[k] = v
			end
		end
	end

	if not VE.isModuleEnabled(module.identifier) then return end
	
	if event == "START_LOOT_ROLL" then
		AutoRoll(arg1)
	elseif event == "CONFIRM_LOOT_ROLL" then
		-- LazyPig logic: check for popups and auto-confirm if we rolled on it
		-- Since we can't easily link the popup to our specific action without more state,
		-- we rely on the immediate check in AutoRoll.
		-- However, we can re-check here if needed.
	end
end)
