local module = VE.registerModule({
	identifier = "QuestItemTooltip",
	meta = {
		label = "Shows Quest Items in Tooltip",
		description = "Adds quest requirements/items in unit tooltips for simple gather and kill quests.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		words = {
			["slain"] = true,
		},
	},
	data = {
		objectives = {},
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local gfind = string.gmatch or string.gfind
local print = VE.print

local function cleanName(str)
	str = string.gsub(str, "%S+", function(word)
		if module.config.words[word] then
			return ""
		else
			return word
		end
	end)

	str = string.gsub(str, "%s+", " ")
	str = string.gsub(str, "^%s*(.-)%s*$", "%1")

	return str
end

local function queryQuestData(title)
	local numEntries, numQuests = GetNumQuestLogEntries()
	for i = 1, numEntries do
		local questTitle, questLevel = GetQuestLogTitle(i)
		if questLevel > 0 then
			local numObjectives = GetNumQuestLeaderBoards(i)
			for n = 1, numObjectives do
				local description, objectiveType, isCompleted = GetQuestLogLeaderBoard(n, i)
				for name, current, total in string.gfind(description, "(.-):%s*(%d+)%/(%d+)") do
					name = cleanName(name)
					if name == title then
						local percent = current / total
						local r, g, b

						if percent >= 1 then
							r, g, b = 0, 1, 0
						elseif percent >= 0.5 then
							r, g, b = 1, 1, 0
						else
							r, g, b = 1, 0, 0
						end

						GameTooltip:AddDoubleLine(
							string.format("\n[%d] %s", questLevel, questTitle),
							string.format("\n%d/%d", current, total),
							1, 1, 0,
							r, g, b
						)
						GameTooltip:Show()
					end
				end
			end
		end
	end
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	GameTooltip:SetScript("OnShow", function(self, ...)
		local title = getglobal("GameTooltipTextLeft1")
		if title then
			queryQuestData(title:GetText())
		end
	end)
end)
