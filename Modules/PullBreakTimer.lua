local module = VE.registerModule({
	identifier = "PullBreakTimer",
	meta = {
		label = "Pull and Break Timer",
		description = "Shows a countdown timer for pull and break timers in raids that is compatible with BigWigs.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {},
	data = {
		ticker = nil,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function parseMessage(str)
	local key, value
	for k, v in string.gfind(str, "(%w+)%s+(%d+)") do
		key = k
		value = v
	end

	if key and value then
		return key, tonumber(value)
	end

	for k in string.gfind(str, "(%w+)") do
		key = k
	end

	return key, nil
end

local function StartCountdown(seconds)
	if not module.plug then return end

	local endTime = GetTime() + seconds
	local totalTime = seconds

	-- Create a frame for OnUpdate
	module.data.ticker = CreateFrame("Frame")
	module.data.ticker:SetScript("OnUpdate", function()
		local remaining = endTime - GetTime()

		module.plug.bar.timer:SetText(tostring(string.format("%.1f", remaining)) .. "s")

		-- Timer finished.
		if remaining < 0 then
			module.plug.bar:Hide()
			-- PlaySoundFile("Interface\\AddOns\\VanillaEnhanced\\Audio\\pull.ogg")
			module.plug.bar.progress:SetValue(0)
			module.data.ticker:SetScript("OnUpdate", nil)
			return
		end

		-- Calculate percentage remaining and update the bar.
		local percentRemaining = (remaining / totalTime) * 100
		module.plug.bar.progress:SetValue(percentRemaining)
	end)
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("CHAT_MSG_ADDON")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" and not module.plug.bar then
		module.plug.bar = CreateFrame("Frame", "PullBreakTimer", UIParent)
		module.plug.bar:SetPoint("Top", UIParent, "Top", 0, -50)
		module.plug.bar:SetWidth(250)
		module.plug.bar:SetHeight(40)
		module.plug.bar:Hide()

		-- Background frame (very bottom layer with black texture).
		module.plug.bar.bgFrame = CreateFrame("Frame", nil, module.plug.bar)
		module.plug.bar.bgFrame:SetFrameStrata("BACKGROUND")
		module.plug.bar.bgFrame:SetPoint("Center", module.plug.bar, "Center", 0, 0)
		module.plug.bar.bgFrame:SetWidth(218)
		module.plug.bar.bgFrame:SetHeight(18)
		module.plug.bar.bg = module.plug.bar.bgFrame:CreateTexture(nil, "BACKGROUND")
		module.plug.bar.bg:SetAllPoints(module.plug.bar.bgFrame)
		module.plug.bar.bg:SetTexture(0, 0, 0, 0.8)

		-- Progress bar frame (bottom layer).
		module.plug.bar.progress = CreateFrame("StatusBar", nil, module.plug.bar, "TextStatusBar")
		module.plug.bar.progress:SetFrameStrata("BACKGROUND")
		module.plug.bar.progress:SetPoint("Center", module.plug.bar, "Center", 0, 0)
		module.plug.bar.progress:SetWidth(218)
		module.plug.bar.progress:SetHeight(20)
		module.plug.bar.progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		module.plug.bar.progress:SetStatusBarColor(1.0, 0.7, 0.0, 1.0)
		module.plug.bar.progress:SetMinMaxValues(0, 100)
		module.plug.bar.progress:SetValue(50)

		-- Label frame (middle layer) with two labels.
		module.plug.bar.labelFrame = CreateFrame("Frame", nil, module.plug.bar)
		module.plug.bar.labelFrame:SetAllPoints()
		module.plug.bar.labelFrame:SetFrameStrata("MEDIUM")

		-- Left label.
		module.plug.bar.label = module.plug.bar.labelFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		module.plug.bar.label:SetPoint("Left", module.plug.bar, "Left", 21, 1)
		module.plug.bar.label:SetTextColor(1.0, 1.0, 0.8, 1.0)
		module.plug.bar.label:SetText("Pull Timer")

		-- Right countdown label.
		module.plug.bar.timer = module.plug.bar.labelFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		module.plug.bar.timer:SetPoint("Right", module.plug.bar, "Right", -21, 1)
		module.plug.bar.timer:SetTextColor(1.0, 1.0, 0.8, 1.0)
		module.plug.bar.timer:SetText("10.0s")

		-- Texture frame (top layer).
		module.plug.bar.texFrame = CreateFrame("Frame", nil, module.plug.bar)
		module.plug.bar.texFrame:SetAllPoints()
		module.plug.bar.texFrame:SetFrameStrata("HIGH")
		module.plug.bar.tex = module.plug.bar.texFrame:CreateTexture(nil, "BACKGROUND")
		module.plug.bar.tex:SetAllPoints(module.plug.bar)
		module.plug.bar.tex:SetTexture("Interface\\Glues\\LoadingBar\\Loading-BarBorder")
	end

	if event == "CHAT_MSG_ADDON" then
		local event = event
		local prefix = arg1
		local message = arg2
		local distribution = arg3
		local sender = arg4

		-- XXX: Change to true if you want to print out addon messages.
		if false then
			if tostring(prefix) ~= "TW_SHOP" and tostring(prefix) ~= "pfQuest" and tostring(prefix) ~= "gatherer_turtle_p2p;2.0.0" then
				VE.dprint("Event: " .. tostring(event))
				VE.dprint("Prefix: " .. tostring(prefix))
				VE.dprint("Message: " .. tostring(message))
				VE.dprint("Distribution: " .. tostring(distribution))
				VE.dprint("Sender: " .. tostring(sender))
				VE.dprint("=====================")
			end
		end

		if prefix == "BigWigs" then
			local key, value = parseMessage(tostring(message))

			if key == "PulltimerSync" then
				module.plug.bar.label:SetText("Pull Timer")
				module.plug.bar.timer:SetText(tostring(value) .. ".0s")
				module.plug.bar:Show()
				StartCountdown(tonumber(value))
			end

			if key == "PulltimerStopSync" then
				module.plug.bar:Hide()
				if module.data.ticker then
					module.data.ticker:SetScript("OnUpdate", nil)
				end
			end
		end
	end
end)
