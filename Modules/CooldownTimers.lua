local module = VE.registerModule({
	identifier = "CooldownTimers",
	meta = {
		label = "Cooldown Timers",
		description = "Displays numerical timers on ability icons for precise cooldown tracking in combat.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		minDuration = 3,
		font = "GameFontHighlightLarge",
		overlayAlpha = 0.3,
	},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function CreateCooldownCountFrame(parent, start, duration)
	parent.timerFrame = CreateFrame("Frame", "CooldowTimer", parent)
	parent.timerFrame:SetFrameStrata("HIGH")
	parent.timerFrame:SetAllPoints(parent)
	parent.timerFrame:SetWidth(parent:GetWidth() + 50)
	parent.timerFrame:SetHeight(parent:GetHeight() + 50)
	parent.timerFrame.label = parent.timerFrame:CreateFontString(nil, "OVERLAY", module.config.font)
	parent.timerFrame.label:SetPoint("Center", parent.timerFrame, "Center", 0, 0)
	parent.timerFrame.label:SetText(tostring(duration))
	parent.timerFrame.label:SetShadowColor(0, 0, 0, 1)
	parent.timerFrame.label:SetShadowOffset(1, -1)
	VE.dframe(parent.timerFrame, 0, 0, 0, module.config.overlayAlpha)
	return parent.timerFrame
end

local function FormatDuration(duration)
	-- More than 200 hours.
	-- XXX: Duration is sometimes really big and doesn't match the one in
	--      the tooltip. Very strange!
	if duration > (60 * 60 * 200) then
		return "Err"
	end

	-- Less than 90 seconds.
	if duration <= 90 then
		return string.format("%d", math.floor(duration))
	end

	-- Less or equal than 1 hour and 30 min.
	if duration <= (60 * 90) then
		return string.format("%dm", math.ceil((duration-1) / 60))
	end

	return string.format("%dh", math.floor(math.ceil(duration / 60) / 60))
end

local function SaturateIcon(frame, state)
	if not frame:GetParent() then return end

	local frameName = frame:GetParent():GetName()

	-- Trinket/Idol cooldowns.
	if frameName == "Trinket1" or frameName == "Trinket2" or frameName == "Idol1" then
		local button = frame:GetParent()
		local normalTex = button:GetNormalTexture()

		if normalTex then
            normalTex:SetDesaturated(state)
        end

		return
	end

	-- Other cooldowns.
	if frameName then
		local icon = getglobal(frameName .. "Icon")
		if icon then
			icon:SetDesaturated(state)
		end
	end
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		if module.data.CooldownFrame_SetTimer then return end

		module.data.CooldownFrame_SetTimer = CooldownFrame_SetTimer
		CooldownFrame_SetTimer = function(cooldownFrame, start, duration, enable)
			if not cooldownFrame then return end
			module.data.CooldownFrame_SetTimer(cooldownFrame, start, duration, enable)

			if start > 0 and duration > module.config.minDuration and enable > 0 then
				local timerFrame = cooldownFrame.timerFrame

				if not timerFrame then
					timerFrame = CreateCooldownCountFrame(cooldownFrame, start, duration)
					timerFrame:SetScript("OnUpdate", function()
						local remain = this.duration - (GetTime() - this.start) + 1
						this.label:SetText(FormatDuration(remain))
						if remain <= 1 then
							this:Hide()
							SaturateIcon(cooldownFrame, false)
						end
					end)
				end

				timerFrame.start = start
				timerFrame.duration = duration
				timerFrame:Show()

				SaturateIcon(cooldownFrame, true)
			else
				if cooldownFrame.timerFrame then
					cooldownFrame.timerFrame:Hide()
					SaturateIcon(cooldownFrame, false)
				end
			end
		end
	end
end)
