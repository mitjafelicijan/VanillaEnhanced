VE.panels.Camera = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedCameraFrame", parent)
	frame:SetAllPoints(parent)

	-- Left column

	VE.elements.DropDown(frame, 20, -20, 200, CAMERA_FOLLOWING_STYLE, VE.GetCVarAsNumber("cameraSmoothStyle"), {
		{ key = 1, text = CAMERA_SMART, tooltip = OPTION_TOOLTIP_CAMERA1 },
		{ key = 2, text = CAMERA_ALWAYS, tooltip = OPTION_TOOLTIP_CAMERA2 },
		{ key = 0, text = CAMERA_NEVER, tooltip = OPTION_TOOLTIP_CAMERA3 },
	}, function(key)
		VE.SetCVar("cameraSmoothStyle", key)
	end)

	VE.elements.Slider(frame, 20, -80, 200, MOUSE_LOOK_SPEED, OPTION_TOOLTIP_MOUSE_LOOK_SPEED, nil, 90, 270, 10, VE.GetCVarAsNumber("cameraYawMoveSpeed"), function(value)
		VE.SetCVar("cameraYawMoveSpeed", value)
	end)

	VE.elements.Checkbox(frame, 20, -140, 140, FOLLOW_TERRAIN, OPTION_TOOLTIP_FOLLOW_TERRAIN, nil, VE.GetCVarAsBoolean("cameraTerrainTilt"), function(checked)
		VE.SetCVar("cameraTerrainTilt", checked)
	end)

	VE.elements.Checkbox(frame, 20, -170, 140, HEAD_BOB, OPTION_TOOLTIP_HEAD_BOB, nil, VE.GetCVarAsBoolean("cameraBobbing"), function(checked)
		VE.SetCVar("cameraBobbing", checked)
	end)

	VE.elements.Checkbox(frame, 20, -200, 140, WATER_COLLISION, OPTION_TOOLTIP_WATER_COLLISION, nil, VE.GetCVarAsBoolean("cameraWaterCollision"), function(checked)
		VE.SetCVar("cameraWaterCollision", checked)
	end)

	VE.elements.Checkbox(frame, 20, -230, 140, SMART_PIVOT, OPTION_TOOLTIP_SMART_PIVOT, nil, VE.GetCVarAsBoolean("cameraPivot"), function(checked)
		VE.SetCVar("cameraPivot", checked)
	end)

	do
		local module = VE.getModule("MaxCameraZoom")
		if module then
			VE.elements.Checkbox(frame, 20, -260, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	-- Right column

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
