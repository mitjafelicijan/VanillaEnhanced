local module = VE.registerModule({
	identifier = "EventTrace",
	meta = {
		label = "|cffff0000Development EventTrace",
		description = "|cffff0000Only for development!|r Show a list of incoming events.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		width = 360,
		height = 500,
		yoffset = 0,
		rowHeight = 18,
	},
	data = {
		panel = nil,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function debugBackground(parent)
	local tex = parent:CreateTexture(nil, "MEDIUM")
	tex:SetAllPoints()
	tex:SetTexture("Interface\\OptionsFrame\\21stepgrayscale")
end

local function appendEventMessage(parent, time, message, args)
	local eventFrame = CreateFrame("Frame", nil, parent)
	eventFrame:SetWidth(module.data.panel:GetWidth())
	eventFrame:SetHeight(module.config.rowHeight)
	eventFrame:SetPoint("TopLeft", 8, -module.config.yoffset)
	eventFrame:SetFrameStrata("HIGH")
	eventFrame:EnableMouse(true)
	eventFrame.time = time
	eventFrame.message = message
	eventFrame.args = args

	local parts = {
		"|cffaaaaaa" .. time,
		"|cffc4ce02" .. VE.count(args),
		"|cffffffff" .. event,
	}

	eventFrame.text = eventFrame:CreateFontString(nil, "HIGH")
	eventFrame.text:SetPoint("LEFT", 12, 0)
	eventFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 10)
	eventFrame.text:SetText(table.concat(parts, "   "))

	eventFrame.bg = eventFrame:CreateTexture(nil, "BACKGROUND")
	eventFrame.bg:SetAllPoints()
	eventFrame.bg:SetTexture("Interface\\AddOns\\WoWDeveloper\\UI\\Gradient")
	eventFrame.bg:Hide()

	eventFrame:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText(this.message)
		GameTooltip:AddLine(this.time, 0.8, 0.8, 0.8)

		this.bg:Show()

		if this.args then
			if VE.count(this.args) > 0 then
				GameTooltip:AddLine(" ", 0, 0, 0)
				for _, arg in ipairs(this.args) do
					GameTooltip:AddLine(arg, 1, 1, 1)
				end
			end
		end

		GameTooltip:Show()
	end)

	eventFrame:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		this.bg:Hide()
	end)

	module.config.yoffset = module.config.yoffset + module.config.rowHeight
end

do
	SLASH_VE_ET1 = "/etrace"
	SLASH_VE_ET2 = "/eventtrace"
	SlashCmdList["VE_ET"] = function(msg, editbox)
		if not VE.isModuleEnabled(module.identifier) then
			StaticPopupDialogs["VE_ETRACE_ENABLE"] = {
				text = "Do you want to enable Event Trace module?",
				button1 = "Yes",
				button2 = "No",
				OnAccept = function()
					VE.enableModule(module.identifier)
					ConsoleExec("reloadui")
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
			}
			StaticPopup_Show("VE_ETRACE_ENABLE")
		else
			if msg == "" and module.data.panel then
				if module.data.panel:IsShown() then
					module.data.panel:Hide()
				else
					module.data.panel:Show()
				end
			elseif msg == "disable" then
				VE.disableModule(module.identifier)
				ConsoleExec("reloadui")
			end
		end
	end
end

module.plug = CreateFrame("Frame", module.identifier, UIParent)
module.plug:RegisterAllEvents()

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if not VanillaEnhancedData["etraceFilter"] then
		VanillaEnhancedData["etraceFilter"] = ""
	end

	if event == "ADDON_LOADED" and not module.data.panel then
		module.data.panel = CreateFrame("Frame", "EventTraceFrame", UIParent)
		module.data.panel:SetPoint("Center", UIParent, "Center", 0, 0)
		module.data.panel:SetWidth(module.config.width)
		module.data.panel:SetHeight(module.config.height)
		module.data.panel:SetMovable(true)
		module.data.panel:EnableMouse(true)
		module.data.panel:RegisterForDrag("LeftButton")
		module.data.panel:SetScript("OnDragStart", function() this:StartMoving() end)
		module.data.panel:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
		module.data.panel:SetBackdrop({
			bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground",
			edgeFile = "Interface\\TutorialFrame\\TutorialFrameBorder",
			tile = false,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 6, right = 6, top = 6, bottom = 6 }
		})

		-- Panel title.
		module.data.panel.text = module.data.panel:CreateFontString(nil, "HIGH", "GameFontNormal")
		module.data.panel.text:SetText("Event Trace")
		module.data.panel.text:SetPoint("Top", 0, -6)

		-- Create a close button.
		local close = CreateFrame("Button", nil, module.data.panel, "UIPanelCloseButton")
		close:SetPoint("TopRight", module.data.panel, "TopRight", 3, 4)
		close:SetScript("OnClick", function() module.data.panel:Hide() end)

		-- Panel title.
		local filterTitle = module.data.panel:CreateFontString(nil, "HIGH", "GameFontNormal")
		filterTitle:SetText("Exclude events (matches and comma separated)")
		filterTitle:SetPoint("TopLeft", 16, -32)

		local filterEditBox = CreateFrame("EditBox", nil, module.data.panel, "InputBoxTemplate")
		filterEditBox:SetWidth(module.config.width - 30)
		filterEditBox:SetHeight(20)
		filterEditBox:SetPoint("TopLeft", 20, -50)
		filterEditBox:SetAutoFocus(false)
		filterEditBox:SetFontObject("NumberFontNormal")
		filterEditBox:SetMaxLetters(200)

		if VanillaEnhancedData["etraceFilter"] then
			filterEditBox:SetText(VanillaEnhancedData["etraceFilter"])
		else
			filterEditBox:SetText("CHAT_,TABARD_")
			VanillaEnhancedData["etraceFilter"] = text
		end

		filterEditBox:SetScript("OnTextChanged", function()
			VanillaEnhancedData["etraceFilter"] = this:GetText()
		end)

		-- Scrollable frame.
		module.data.panel.scrollFrame = CreateFrame("ScrollFrame", "EventTraceFrameScroll", module.data.panel, "UIPanelScrollFrameTemplate")
		module.data.panel.scrollFrame:SetPoint("TopLeft", module.data.panel, "TopLeft", 4, -85)
		module.data.panel.scrollFrame:SetPoint("BottomRight", module.data.panel, "BottomRight", -30, 7)

		module.data.panel.scrollChild = CreateFrame("Frame", nil, module.data.panel.scrollFrame)
		module.data.panel.scrollChild:SetWidth(module.data.panel:GetWidth())
		module.data.panel.scrollChild:SetHeight(module.data.panel:GetHeight())
		module.data.panel.scrollChild:SetHeight(100)

		module.data.panel.scrollFrame:SetScrollChild(module.data.panel.scrollChild)

		module.data.panel:SetScript("OnUpdate", function()
			module.data.panel.scrollChild:SetHeight(module.config.yoffset)
			module.data.panel.scrollFrame:SetScrollChild(module.data.panel.scrollChild)
		end)

		-- Hide on start.
		-- module.data.panel:Hide()
	end

	if module.data.panel and module.data.panel:IsVisible() and VanillaEnhancedData["etraceFilter"] then
		local allowed = true
		local filters = VE.split(VanillaEnhancedData["etraceFilter"], ",")
		for i, v in ipairs(filters) do
			if string.find(event, v) then allowed = false end
		end

		if allowed then
			args = {}
			for i = 1, 30 do
				if getglobal("arg" .. i) then
					local text = tostring(getglobal("arg" .. i))
					table.insert(args, string.format("arg%d: %s", i, text))
				end
			end
			appendEventMessage(module.data.panel.scrollChild, VE.formattedTime(), event, args)
		end
	end
end)
