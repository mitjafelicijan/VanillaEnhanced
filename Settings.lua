-- CVARS: https://www.townlong-yak.com/framexml/1.12.1/UIOptionsFrame.lua

local categories = {
	{ key = "controls", label = "Controls", description = "", active = true, features = nil },
	{ key = "display", label = "Display", description = "", active = false, features = nil },
	{ key = "interface", label = "Interface", description = "", active = false, features = nil },
	{ key = "camera", label = "Camera", description = "", active = false, features = nil },
	{ key = "combat", label = "Combat", description = "", active = false, features = nil },
	{ key = "actionbars", label = "Action Bars", description = "", active = false, features = nil },
	{ key = "chatsocial", label = "Chat & Social", description = "", active = false, features = nil },
	{ key = "raidparty", label = "Raid & Party", description = "", active = false, features = nil },
	{ key = "features", label = "Features", description = "", active = false, features = nil },
	{ key = "automation", label = "Automation", description = "", active = false, features = nil },
	{ key = "addons", label = "AddOns", description = "", active = false, features = nil },
}

local config = {
	frameWidth = 730,
	frameHeight = 540,
	sidebarWidth = 150,
	hoverAlpha = 0.2,
	addonLoaded = false,
	overrideMenu = true,
	hideOnLoad = true,
	startPanel = "controls",
}

local frame = CreateFrame("Frame", "VanillaEnhancedFrame", UIParent)
frame:EnableMouse(true)
frame:EnableKeyboard(true)
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- This enables closing of frame when Escape key pressed.
tinsert(UISpecialFrames, frame:GetName())

do
	SLASH_VE1 = "/ve"
	SlashCmdList["VE"] = function(cmd)
		if cmd == "" then
			if frame:IsVisible() then frame:Hide() else frame:Show() end
		else
			if cmd == "list" then
				VE.listModules()
			end
			if cmd == "legacy" then
				ShowUIPanel(UIOptionsFrame)
			end
		end
	end
end

frame:SetScript("OnEvent", function()
	if event == "PLAYER_ENTERING_WORLD" and not config.addonLoaded then
		config.addonLoaded = true

		if config.hideOnLoad then
			frame:Hide()
		end

		-- Update Blizzard parent addons if needed.

		-- Overwrite default "Interface Options" game menu button behaVE.ur.
		if config.overrideMenu then
			getglobal("GameMenuButtonUIOptions"):SetText("Game Options")
			getglobal("GameMenuButtonUIOptions"):SetScript("OnClick", function(self)
				PlaySound("igMainMenuOption")
				-- ShowUIPanel(UIOptionsFrame)
				HideUIPanel(GameMenuFrame)
				frame:Show()
			end)
		end

		-- Parent main frame.
		frame:SetPoint("Center", UIParent, "Center", 0, 0)
		frame:SetWidth(config.frameWidth)
		frame:SetHeight(config.frameHeight)
		frame:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 12, right = 12, top = 12, bottom = 12 }
		})

		-- Add a title to the frame.
		frame.title = CreateFrame("Frame", nil, frame)
		frame.title:SetPoint("Top", frame, "Top", 0, 12)
		frame.title:SetWidth(300)
		frame.title:SetHeight(64)

		-- Create a backdrop for the title.
		frame.title.tex = frame.title:CreateTexture(nil, "MEDIUM")
		frame.title.tex:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
		frame.title.tex:SetAllPoints()

		-- Create a font string for the title.
		frame.title.text = frame.title:CreateFontString(nil, "HIGH", "GameFontNormal")
		frame.title.text:SetText("Game Options")
		frame.title.text:SetPoint("Top", 0, -14)

		-- Left sidebar frame for categories.
		frame.sidebar = CreateFrame("Frame", nil, frame)
		frame.sidebar:SetPoint("Left", frame, "Left", 20, 5)
		frame.sidebar:SetWidth(config.sidebarWidth)
		frame.sidebar:SetHeight(config.frameHeight - 75)
		frame.sidebar:SetBackdrop({
			edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
			tile = true,
			tileSize = 8,
			edgeSize = 8,
			insets = { left = 12, right = 12, top = 12, bottom = 12 }
		})

		-- Render sidebar buttons.
		local yOffset = 6
		local ySpacing = 20
		for i, item in ipairs(categories) do
			local button = CreateFrame("Button", "VanillaEnhancedSidebarButton"..i, frame.sidebar)
			button.data = item
			button:SetPoint("TopLeft", 3, -yOffset)
			button:SetWidth(config.sidebarWidth - 6)
			button:SetHeight(ySpacing)

			button.bg = button:CreateTexture(nil, "BACKGROUND")
			button.bg:SetAllPoints(button)

			if button.data.active then
				button.bg:SetTexture(1, 1, 1, config.hoverAlpha)
			end

			button:SetScript("OnClick", function()
				if frame.panel.panels then
					if frame.panel.panels[this.data.key] then
						for _, panel in frame.panel.panels do
							panel:Hide()
						end

						frame.panel.panels[this.data.key]:Show()
						PlaySound("igMainMenuOptionCheckBoxOn")
						for i, _ in ipairs(categories) do
							getglobal("VanillaEnhancedSidebarButton"..i).data.active = false
							getglobal("VanillaEnhancedSidebarButton"..i).bg:SetTexture(1, 1, 1, 0)
						end

						button.data.active = true
						button.bg:SetTexture(1, 1, 1, config.hoverAlpha)
					end

				end
			end)

			button:SetScript("OnEnter", function()
				button.bg:SetTexture(1, 1, 1, config.hoverAlpha)
			end)

			button:SetScript("OnLeave", function()
				if not button.data.active then
					button.bg:SetTexture(1, 1, 1, 0)
				end
			end)

			local title = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			title:SetPoint("Left", 4, 0)
			title:SetText(item.label)

			yOffset = yOffset + ySpacing
		end

		-- Right options frame.
		frame.panel = CreateFrame("Frame", nil, frame)
		frame.panel:SetPoint("Right", frame, "Right", -20, 5)
		frame.panel:SetWidth(config.frameWidth - config.sidebarWidth - 50)
		frame.panel:SetHeight(config.frameHeight - 75)
		frame.panel:SetBackdrop({
			edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
			tile = true,
			tileSize = 8,
			edgeSize = 8,
			insets = { left = 12, right = 12, top = 12, bottom = 12 }
		})

		-- Register all the panels and show the first one.
		frame.panel.panels = {}
		frame.panel.panels["controls"] = VE.panels.Controls(frame.panel)
		frame.panel.panels["display"] = VE.panels.Display(frame.panel)
		frame.panel.panels["interface"] = VE.panels.Interface(frame.panel)
		frame.panel.panels["camera"] = VE.panels.Camera(frame.panel)
		frame.panel.panels["combat"] = VE.panels.Combat(frame.panel)
		frame.panel.panels["actionbars"] = VE.panels.ActionBars(frame.panel)
		frame.panel.panels["chatsocial"] = VE.panels.ChatSocial(frame.panel)
		frame.panel.panels["raidparty"] = VE.panels.RaidParty(frame.panel)
		frame.panel.panels["features"] = VE.panels.Features(frame.panel)
		frame.panel.panels["automation"] = VE.panels.Automation(frame.panel)
		frame.panel.panels["addons"] = VE.panels.Addons(frame.panel)
		frame.panel.panels[config.startPanel]:Show()

		-- Legacy Interface Options button.
		frame.apply = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		frame.apply:SetPoint("BottomLeft", 18, 18)
		frame.apply:SetWidth(90)
		frame.apply:SetHeight(22)
		frame.apply:SetText("Legacy")
		frame.apply:SetScript("OnClick", function(self)
			PlaySound("igMainMenuOptionCheckBoxOn")
			frame:Hide()
			ShowUIPanel(UIOptionsFrame)
		end)

		-- Main buttons (cancel or apply).
		frame.apply = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		frame.apply:SetPoint("BottomRight", -108, 18)
		frame.apply:SetWidth(90)
		frame.apply:SetHeight(22)
		frame.apply:SetText("Apply")
		frame.apply:SetScript("OnClick", function(self)
			PlaySound("igMainMenuOptionCheckBoxOn")
			ReloadUI()
		end)

		frame.cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		frame.cancel:SetPoint("BottomRight", -16, 18)
		frame.cancel:SetWidth(90)
		frame.cancel:SetHeight(22)
		frame.cancel:SetText("Cancel")
		frame.cancel:SetScript("OnClick", function(self)
			PlaySound("igMainMenuOptionCheckBoxOn")
			-- ShowUIPanel(GameMenuFrame)
			frame:Hide()
		end)
	end
end)
