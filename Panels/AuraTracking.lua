VE.panels.AuraTracking = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedAuraTrackingFrame", parent)
	frame:SetAllPoints(parent)

	-- Left column

	do
		local module = VE.getModule("AuraTracker")
		if module then
			VE.elements.Checkbox(frame, 20, -20, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	VE.elements.InputArea(frame, 16, -45, 500, 40, "title", "tooltip description", nil, (VanillaEnhancedData["AuraTrackerUserAuars"] or ""), 200, function(text)
		VanillaEnhancedData["AuraTrackerUserAuars"] = text
	end)

	-- Right column

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
