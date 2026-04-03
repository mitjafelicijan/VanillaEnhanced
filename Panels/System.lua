VE.panels.System = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedSystemFrame", parent)
	frame:SetAllPoints(parent)

	-- Left column (Camera)

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

	-- Right column (Mouse)

	VE.elements.Checkbox(frame, 270, -20, 140, INVERT_MOUSE, OPTION_TOOLTIP_INVERT_MOUSE, nil, VE.GetCVarAsBoolean("mouseInvertPitch"), function(checked)
		VE.SetCVar("mouseInvertPitch", checked)
	end)

	VE.elements.Checkbox(frame, 270, -50, 140, GAMEFIELD_DESELECT_TEXT, OPTION_TOOLTIP_GAMEFIELD_DESELECT, nil, not VE.GetCVarAsBoolean("deselectOnClick"), function(checked)
		VE.SetCVar("deselectOnClick", not checked)
	end)

	VE.elements.Checkbox(frame, 270, -80, 140, ASSIST_ATTACK, OPTION_TOOLTIP_ASSIST_ATTACK, nil, VE.GetCVarAsBoolean("assistAttack"), function(checked)
		VE.SetCVar("assistAttack", checked)
	end)

	VE.elements.Checkbox(frame, 270, -110, 140, CLEAR_AFK, OPTION_TOOLTIP_CLEAR_AFK, nil, VE.GetCVarAsBoolean("autoClearAFK"), function(checked)
		VE.SetCVar("autoClearAFK", checked)
	end)

	VE.elements.Checkbox(frame, 270, -140, 140, AUTO_SELF_CAST_TEXT, OPTION_TOOLTIP_AUTO_SELF_CAST, nil, VE.GetCVarAsBoolean("autoSelfCast"), function(checked)
		VE.SetCVar("autoSelfCast", checked)
	end)

	VE.elements.Slider(frame, 270, -190, 200, MOUSE_SENSITIVITY, OPTION_TOOLTIP_MOUSE_SENSITIVITY, nil, 0.5, 1.5, 0.1, VE.GetCVarAsNumber("mouseSpeed"), function(value)
		VE.SetCVar("mouseSpeed", value)
	end)

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
