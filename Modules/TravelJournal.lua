local module = VE.registerModule({
	identifier = "TravelJournal",
	meta = {
		label = "Travel Journal",
		description = "Add pins to map with custom notes.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		numOfPins = 50,  -- Number of available reusable pins for the map per zone.
		pinSize = 20,    -- Size of a pin icon.
	},
	data = {
		pins = {},
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

function ResetPinFrameById(id)
	for idx = 1, module.config.numOfPins do
		local pin = getglobal("TravelJournalPin" .. tostring(idx))
		if pin and pin.id == id then
			pin.id = nil
			pin:Hide()
			return
		end
	end
end

local function ResetAndHidePremadePinFrames()
	for idx = 1, module.config.numOfPins do
		local pinFrame = getglobal("TravelJournalPin" .. tostring(idx))
		pinFrame.id = nil
		pinFrame:Hide()
	end
end

local function FindFirstAvailablePinFrame()
	for idx = 1, module.config.numOfPins do
		local pin = getglobal("TravelJournalPin" .. tostring(idx))
		if pin.id == nil then
			return pin
		end
	end
	return nil -- No pin available
end

local function ShowNoteEditor(pinID, noteText)
	module.plug.editor.pinID = pinID
	module.plug.editor:Show()
	getglobal("TravelJournalEditBox"):SetText(noteText)
	getglobal("TravelJournalEditBox"):SetFocus()
end

local function HideNoteEditor()
	module.plug.editor.pinID = nil
	module.plug.editor:Hide()
	getglobal("TravelJournalEditBox"):SetText("")
end

local function CreatePremadePinFrame(idx)
	local pin = CreateFrame("Button", "TravelJournalPin" .. tostring(idx), WorldMapButton)
	pin:EnableMouse(true)
	pin:SetWidth(module.config.pinSize)
	pin:SetHeight(module.config.pinSize)
	pin:Hide()

	local texture = pin:CreateTexture(nil, "OVERLAY")
	texture:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
	texture:SetAllPoints(pin)

	-- Store coordinates in the pin frame for tooltip.
	pin.id = nil
	pin.x = 0.0
	pin.y = 0.0

	pin:SetScript("OnClick", function()
		if IsAltKeyDown() then
			module.plug.editor.pinId = nil
			module.plug.editor:Hide()
			local id = this.id
			StaticPopupDialogs["VE_TRAVELJOURNAL"] = {
				text = "Do you really want to delete this pin?",
				button1 = "Yes",
				button2 = "No",
				OnAccept = function()
					if module.data.pins[id] then
						module.data.pins[id] = nil
					end
					ResetPinFrameById(id)
					VanillaEnhancedData["travelJournal"] = module.data.pins
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
			}
			StaticPopup_Show("VE_TRAVELJOURNAL")
		end

		if IsControlKeyDown() then
			local pinData = module.data.pins[this.id]
			if pinData then
				ShowNoteEditor(this.id, pinData.note)
			end
		end
	end)

	pin:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		local pinData = module.data.pins[this.id]
		if pinData then
			GameTooltip:AddLine(pinData.created)
			GameTooltip:AddLine(pinData.note, 1, 1, 1)
			GameTooltip:Show()
		end
	end)

	pin:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	pin:SetPoint("BottomLeft", WorldMapButton, "BottomLeft",
		pin.x * WorldMapButton:GetWidth(),
		pin.y * WorldMapButton:GetHeight()
	)
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("WORLD_MAP_UPDATE")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" and not module.plug.editor then
		if VanillaEnhancedData["travelJournal"] then
			module.data.pins = VanillaEnhancedData["travelJournal"]
		end

		-- Create N premade pins that we can use.
		for idx = 1, module.config.numOfPins do
			CreatePremadePinFrame(idx)
		end

		module.plug.editor = CreateFrame("Frame", "TravelJournalEditor", WorldMapFrame)
		module.plug.editor:SetPoint("TopRight", WorldMapFrame, "TopRight", 300, 0)
		module.plug.editor:SetWidth(300)
		module.plug.editor:SetHeight(WorldMapFrame:GetHeight())
		module.plug.editor:SetFrameStrata("TOOLTIP")
		module.plug.editor:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\Glues\\Common\\TextPanel-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 6, right = 6, top = 6, bottom = 6 }
		})

		module.plug.editor.pinID = nil
		module.plug.editor:Hide()

		-- Create ScrollFrame
		local scroll = CreateFrame("ScrollFrame", "TravelJournalScrollFrame", module.plug.editor)
		scroll:SetPoint("Top", module.plug.editor, "Top", 0, -16)
		scroll:SetWidth(module.plug.editor:GetWidth() - 32)
		scroll:SetHeight(module.plug.editor:GetHeight() - 64)

		-- Create EditBox
		local input = CreateFrame("EditBox", "TravelJournalEditBox", scroll)
		input:SetWidth(scroll:GetWidth())
		input:SetHeight(scroll:GetHeight())
		input:SetPoint("TopLeft", scroll, "TopLeft")
		input:SetPoint("TopRight", scroll, "TopRight")
		input:SetFontObject(GameFontNormal)
		input:SetAutoFocus(false)
		input:SetMultiLine(true)
		input:EnableMouse(true)
		input:SetMaxLetters(1000)
		input:SetText("")
		input:SetScript("OnEscapePressed", function()
			input:ClearFocus()
			return true  -- This prevents the Escape from propagating to close other UI elements.
		end)

		-- Set the scroll frame content
		scroll:SetScrollChild(input)

		local saveBtn = CreateFrame("Button", nil, module.plug.editor, "UIPanelButtonTemplate")
		saveBtn:SetWidth(100)
		saveBtn:SetHeight(25)
		saveBtn:SetPoint("BottomRight", module.plug.editor, "Bottom", -10, 16)
		saveBtn:SetText("Save")
		saveBtn:SetScript("OnClick", function()
			local pinID = module.plug.editor.pinID
			local text = input:GetText()

			local pinData = module.data.pins[pinID]
			if pinData then
				pinData.note = text
			end

			VanillaEnhancedData["travelJournal"] = module.data.pins
			module.plug.editor:Hide()
			input:SetText("")
		end)

		-- Create Cancel button
		local cancelBtn = CreateFrame("Button", nil, module.plug.editor, "UIPanelButtonTemplate")
		cancelBtn:SetWidth(100)
		cancelBtn:SetHeight(25)
		cancelBtn:SetPoint("BottomLeft", module.plug.editor, "Bottom", 10, 16)
		cancelBtn:SetText("Cancel")
		cancelBtn:SetScript("OnClick", function()
			HideNoteEditor()
		end)

		-- Add handler for creating pins.
		WorldMapButton:SetScript("OnClick", function()
			if not IsControlKeyDown() then return end

			-- Get cursor position relative to WorldMapButton.
            local x, y = GetCursorPosition()
            local left = WorldMapButton:GetLeft()
            local bottom = WorldMapButton:GetBottom()
            local scale = WorldMapButton:GetEffectiveScale()

            -- Calculate relative position.
            x = (x/scale - left) / WorldMapButton:GetWidth()
            y = (y/scale - bottom) / WorldMapButton:GetHeight()

			local pin = FindFirstAvailablePinFrame()
			if not pin then
				VE.eprint("no pin available anymore")
			else
				local id = math.floor(GetTime() * 1000)

				pin.id = id
				pin:SetPoint("BottomLeft", WorldMapButton, "BottomLeft",
					x * WorldMapButton:GetWidth() - (pin:GetWidth() / 2),
					y * WorldMapButton:GetHeight() - (pin:GetHeight() / 2)
				)
				pin:Show()

				module.data.pins[id] = {
					id = id,
					x = x,
					y = y,
					continent = GetCurrentMapContinent(),
					zone = GetCurrentMapZone(),
					created = date("%d %B, %Y at %H:%M:%S"),
					note = "",
				}

				-- Save to global store.
				VanillaEnhancedData["travelJournal"] = module.data.pins

				-- Open text editor for a note.
				ShowNoteEditor(id, "")
			end
		end)
	end

	if event == "WORLD_MAP_UPDATE" then
		ResetAndHidePremadePinFrames()

		for id, pin in module.data.pins do
			if pin.continent == GetCurrentMapContinent() and pin.zone == GetCurrentMapZone() then
				local pinFrame = FindFirstAvailablePinFrame()
				if not pinFrame then
					VE.eprint("no pins available (max number of pins reached)")
				else
					pinFrame.id = id
					pinFrame.x = pin.x
					pinFrame.y = pin.y
					pinFrame.continent = pin.continent
					pinFrame.zone = pin.zone

					pinFrame:SetPoint("BottomLeft", WorldMapButton, "BottomLeft",
						pinFrame.x * WorldMapButton:GetWidth() - (pinFrame:GetWidth() / 2),
						pinFrame.y * WorldMapButton:GetHeight() - (pinFrame:GetHeight() / 2)
					)
					pinFrame:Show()
				end
			end
		end
	end
end)
