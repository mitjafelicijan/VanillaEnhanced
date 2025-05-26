local module = VE.registerModule({
	identifier = "MinimapClock",
	meta = {
		label = "Mini Map Clock",
		description = "Displays a small clock on the minimap to show the local and server time and add stopwatch.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {},
	data = {
		running = false,
		elapsed = 0,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function FormatTime(time)
	local hour, minutes, seconds, mili = 0, 0, 0, 0

	hour = math.floor(time/3600)
	if hour < 10 then hour = "0"..hour end

	minutes = math.floor((time-math.floor(time/3600)*3600)/60)
	if minutes < 10 then minutes = "0"..minutes end

	seconds = math.floor(time-math.floor(time/3600)*3600-math.floor((time-math.floor(time/3600)*3600)/60)*60)
	if seconds < 10 then seconds = "0"..seconds end

	return hour, minutes, seconds
end

local function UpdateStopWatch()
	if StopWatch then
		local hours, minutes, seconds = FormatTime(module.data.elapsed)
		StopWatch.hours:SetText(tostring(hours))
		StopWatch.minutes:SetText(tostring(minutes))
		StopWatch.seconds:SetText(tostring(seconds))
	end
end

module.plug = CreateFrame("Frame")
module.plug:RegisterEvent("VARIABLES_LOADED")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if not MinimapClock then
		MinimapClock = CreateFrame("Button", "MinimapClock", Minimap)
		MinimapClock:Hide()
		MinimapClock:SetFrameLevel(64)
		MinimapClock:SetPoint("Bottom", MinimapCluster, "Bottom", 8, 18)
		MinimapClock:SetWidth(50)
		MinimapClock:SetHeight(23)
		MinimapClock:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 8, edgeSize = 16,
			insets = { left = 3, right = 3, top = 3, bottom = 3 }
		})
		MinimapClock:SetBackdropBorderColor(.9, .8, .5, 1)
		MinimapClock:SetBackdropColor(.4, .4, .4, 1)
		MinimapClock:Show()
		MinimapClock:EnableMouse(true)

		MinimapClock.text = MinimapClock:CreateFontString("Status", "LOW", "GameFontNormal")
		MinimapClock.text:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
		MinimapClock.text:SetAllPoints(MinimapClock)
		MinimapClock.text:SetFontObject(GameFontWhite)

		MinimapClock:SetScript("OnUpdate", function()
			this.text:SetText(date("%H:%M"))
		end)

		MinimapClock:SetScript("OnEnter", function()
			local h, m = GetGameTime()
			local servertime = string.format("%.2d:%.2d", h, m)
			local time = date("%H:%M")

			GameTooltip:ClearLines()
			GameTooltip:SetOwner(this, ANCHOR_BOTTOMLEFT)

			GameTooltip:AddLine("Clock")
			GameTooltip:AddDoubleLine("Localtime", time, 1, 1, 1, 1, 1, 1)
			GameTooltip:AddDoubleLine("Servertime", servertime, 1, 1, 1, 1, 1, 1)
			GameTooltip:AddLine("|n")
			GameTooltip:AddLine("Click to toggle stopwatch.")
			GameTooltip:Show()
		end)

		MinimapClock:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		MinimapClock:SetScript("OnClick", function()
			if StopWatch then
				if StopWatch:IsShown() then
					StopWatch:Hide()
				else
					StopWatch:Show()
				end
			end
		end)
	end

	if not StopWatch then
		StopWatch = CreateFrame("Frame", "StopWatch", UIParent)
		StopWatch:SetFrameLevel(64)
		StopWatch:SetPoint("Top", UIParent, "Top", 0, 0)
		StopWatch:SetWidth(120)
		StopWatch:SetHeight(60)
		StopWatch:SetClampedToScreen(true)
		StopWatch:EnableMouse(true)
		StopWatch:SetMovable(true)
		StopWatch:RegisterForDrag("LeftButton")
		StopWatch:SetScript("OnDragStart", function() this:StartMoving() end)
		StopWatch:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

		StopWatch.background = StopWatch:CreateTexture(nil, "BACKGROUND")
		StopWatch.background:SetAllPoints(StopWatch)
		StopWatch.background:SetTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\StopWatch-Background")

		StopWatch.hours = StopWatch:CreateFontString("Status", "ARTWORK", "GameFontHighlight")
		StopWatch.hours:SetPoint("Left", StopWatch, "Left", 10, 2)
		StopWatch.hours:SetJustifyH("Right")
		StopWatch.hours:SetText("00")

		StopWatch.separator1 = StopWatch:CreateFontString("Status", "ARTWORK", "GameFontHighlight")
		StopWatch.separator1:SetPoint("Left", StopWatch, "Left", 28, 3)
		StopWatch.separator1:SetText(":")

		StopWatch.minutes = StopWatch:CreateFontString("Status", "ARTWORK", "GameFontHighlight")
		StopWatch.minutes:SetPoint("Left", StopWatch, "Left", 32, 2)
		StopWatch.minutes:SetJustifyH("Right")
		StopWatch.minutes:SetText("00")

		StopWatch.separator2 = StopWatch:CreateFontString("Status", "ARTWORK", "GameFontHighlight")
		StopWatch.separator2:SetPoint("Left", StopWatch, "Left", 50, 3)
		StopWatch.separator2:SetText(":")

		StopWatch.seconds = StopWatch:CreateFontString("Status", "ARTWORK", "GameFontHighlight")
		StopWatch.seconds:SetPoint("Left", StopWatch, "Left", 54, 2)
		StopWatch.seconds:SetJustifyH("Right")
		StopWatch.seconds:SetText("00")

		StopWatch.start = CreateFrame("Button", nil, StopWatch)
		StopWatch.start:SetPoint("Right", StopWatch, "Right", -21, 2)
		StopWatch.start:SetWidth(24)
		StopWatch.start:SetHeight(24)
		StopWatch.start:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
		StopWatch.start:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
		StopWatch.start:SetHighlightTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
		StopWatch.start:SetScript("OnClick", function(self)
			module.data.running = true
			UpdateStopWatch()
			StopWatch.start:Hide()
			StopWatch.pause:Show()
		end)

		StopWatch.pause = CreateFrame("Button", nil, StopWatch)
		StopWatch.pause:SetPoint("Right", StopWatch, "Right", -21, 2)
		StopWatch.pause:SetWidth(24)
		StopWatch.pause:SetHeight(24)
		StopWatch.pause:SetNormalTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\StopWatch-PauseButton")
		StopWatch.pause:SetPushedTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\StopWatch-PauseButton")
		StopWatch.pause:SetHighlightTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\StopWatch-PauseButton")
		StopWatch.pause:SetScript("OnClick", function(self)
			module.data.running = false
			UpdateStopWatch()
			StopWatch.pause:Hide()
			StopWatch.start:Show()
		end)
		StopWatch.pause:Hide()

		StopWatch.reset = CreateFrame("Button", nil, StopWatch)
		StopWatch.reset:SetPoint("Right", StopWatch, "Right", -2, 2)
		StopWatch.reset:SetWidth(24)
		StopWatch.reset:SetHeight(24)
		StopWatch.reset:SetNormalTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\StopWatch-ResetButton")
		StopWatch.reset:SetPushedTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\StopWatch-ResetButton")
		StopWatch.reset:SetHighlightTexture("Interface\\AddOns\\VanillaEnhanced\\Assets\\StopWatch-ResetButton")
		StopWatch.reset:SetScript("OnClick", function(self)
			module.data.elapsed = 0
			module.data.running = false
			StopWatch.pause:Hide()
			StopWatch.start:Show()
			UpdateStopWatch()
		end)

		StopWatch:SetScript("OnUpdate", function(self, elapsed)
			if module.data.running then
				module.data.elapsed = module.data.elapsed + arg1
				UpdateStopWatch()
			end
		end)

		StopWatch:Hide()
	end
end)
