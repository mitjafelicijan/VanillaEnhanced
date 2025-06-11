VE.panels.Addons = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedAddonsFrame", parent)
	frame:SetAllPoints(parent)

	local rowSize = 30
	local columnSize = 250
	local perColumn = 14
	local row = 0
	local column = 0
	local numAddons = GetNumAddOns()

	for i = 1, numAddons do
		local x = 20 + (column * columnSize)
		local y = -20 - (row * rowSize)
		local addonIdx = i

		local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(i)
		VE.elements.Checkbox(frame, x, y, 140, title, notes, nil, IsAddOnLoaded(addonIdx), function(checked)
			if checked then
				EnableAddOn(addonIdx)
			else
				DisableAddOn(addonIdx)
			end
		end)

		row = row + 1

		if math.mod(i, perColumn) == 0 then
			column = column + 1
			row = 0
		end
	end

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
