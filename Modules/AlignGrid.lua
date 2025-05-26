local module = VE.registerModule({
	identifier = "AlignGrid",
	meta = {
		label = "Draw Align Grid",
		description = "Draws an align grid on a screen if Ctrl+Alt+Shift is being pressed.",
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

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	if module.plug.grid then return end

	module.plug.grid = CreateFrame("Frame")
	module.plug.grid:SetAllPoints(UIParent)
	module.plug.grid:Hide()

	local w, h = GetScreenWidth() * UIParent:GetEffectiveScale(), GetScreenHeight() * UIParent:GetEffectiveScale()
	local ratio = w / h
	local sqsize = w / 20
	local wline = floor(sqsize - mod(sqsize, 2))
	local hline = floor(sqsize / ratio - mod((sqsize / ratio), 2))

	-- Plot vertical lines.
	for i = 0, wline do
		local t = module.plug.grid:CreateTexture(nil, "BACKGROUND")
		if i == wline / 2 then
			t:SetTexture(1, 1, 0, 0.7) -- Yellow line in the middle
		else
			t:SetTexture(0, 0, 0, 0.7) -- Black lines elsewhere
		end
		t:SetPoint("TOPLEFT", module.plug.grid, "TOPLEFT", i * w / wline - 1, 0)
		t:SetPoint("BOTTOMRIGHT", module.plug.grid, "BOTTOMLEFT", i * w / wline + 1, 0)
	end

	-- Plot horizontal lines.
	for i = 0, hline do
		local t = module.plug.grid:CreateTexture(nil, "BACKGROUND")
		if i == hline / 2 then
			t:SetTexture(1, 1, 0, 0.7) -- Yellow line in the middle
		else
			t:SetTexture(0, 0, 0, 0.7) -- Black lines elsewhere
		end
		t:SetPoint("TOPLEFT", module.plug.grid, "TOPLEFT", 0, -i * h / hline + 1)
		t:SetPoint("BOTTOMRIGHT", module.plug.grid, "TOPRIGHT", 0, -i * h / hline - 1)
	end

end)

module.plug:SetScript("OnUpdate", function()
	if not VE.isModuleEnabled(module.identifier) then return end
	if not module.plug.grid then return end

	if IsControlKeyDown() and IsShiftKeyDown() and IsAltKeyDown() then
		module.plug.grid:Show()
	else
		module.plug.grid:Hide()
	end
end)
