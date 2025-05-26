local module = VE.registerModule({
	identifier = "FrameStack",
	meta = {
		label = "|cffff0000Development Framestack",
		description = "|cffff0000Only for development!|r Show a list of UI elements under the cursor for debugging layout and frame issues.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local DebugTooltip = CreateFrame("GameTooltip", "DebugTooltip", UIParent, "GameTooltipTemplate")

local function ShowTooltip(frame)
	if frame then
		DebugTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		DebugTooltip:ClearLines()

		-- Frame name and type
		DebugTooltip:AddLine(frame:GetName() or "<Unnamed Frame>", 1, 1, 1)
		DebugTooltip:AddLine("Type: " .. (frame:GetObjectType() or "Unknown"), 0.8, 0.8, 0.8)

		-- Position and size
		DebugTooltip:AddLine(string.format("Width: %.2f, Height: %.2f", frame:GetWidth(), frame:GetHeight()), 0.5, 1, 0.5)
		DebugTooltip:AddLine(string.format("Position: Top=%.2f, Bottom=%.2f, Left=%.2f, Right=%.2f",
		frame:GetTop() or 0, frame:GetBottom() or 0, frame:GetLeft() or 0, frame:GetRight() or 0), 0.5, 1, 0.5)

		-- Parent/children
		DebugTooltip:AddLine("Parent: " .. (frame:GetParent() and frame:GetParent():GetName() or "<None>"), 0.5, 0.5, 1)

		-- Mouse/keyboard interaction
		DebugTooltip:AddLine("Mouse Enabled: " .. tostring(frame:IsMouseEnabled()), 1, 0.5, 0.5)
		DebugTooltip:AddLine("Keyboard Enabled: " .. tostring(frame:IsKeyboardEnabled()), 1, 0.5, 0.5)

		-- Visibility
		DebugTooltip:AddLine("Visible: " .. tostring(frame:IsVisible()), 0.8, 1, 0.8)

		DebugTooltip:Show()
	end
end

do
	SLASH_VE_FS1 = "/fstack"
	SLASH_VE_FS2 = "/framestack"
	SlashCmdList["VE_FS"] = function(msg, editbox)
		if not VE.isModuleEnabled(module.identifier) and msg == "" then
			StaticPopupDialogs["VE_FSTACK_ENABLE"] = {
				text = "Do you want to enable Frame Stack module?",
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
			StaticPopup_Show("VE_FSTACK_ENABLE")
		else
			if msg == "disable" then
				VE.disableModule(module.identifier)
				ConsoleExec("reloadui")
			end
		end
	end
end

module.plug = CreateFrame("Frame", module.identifier, UIParent)
module.plug:SetAllPoints(UIParent)
module.plug:SetFrameStrata("BACKGROUND")
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnUpdate", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	local focusFrame = GetMouseFocus()
	if focusFrame ~= nil then
		if focusFrame and focusFrame:GetName() then
			ShowTooltip(focusFrame)
		end
	else
		DebugTooltip:Hide()
	end
end)
