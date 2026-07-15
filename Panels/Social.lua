VE.panels.Social = function(parent)
	local frame = CreateFrame("Frame", "VanillaEnhancedSocialFrame", parent)
	frame:SetAllPoints(parent)

	-- Left column (Chat)

	VE.elements.Checkbox(frame, 20, -20, 210, SIMPLE_CHAT_TEXT, OPTION_TOOLTIP_SIMPLE_CHAT, nil, VE.GetUVarAsBoolean("SIMPLE_CHAT"), function(checked)
		VE.SetUVar("SIMPLE_CHAT", checked)
	end)

	VE.elements.Checkbox(frame, 20, -50, 210, CHAT_LOCKED_TEXT, OPTION_TOOLTIP_CHAT_LOCKED, nil, VE.GetUVarAsBoolean("CHAT_LOCKED"), function(checked)
		VE.SetUVar("CHAT_LOCKED", checked)
	end)

	VE.elements.Checkbox(frame, 20, -80, 210, GUILDMEMBER_ALERT, OPTION_TOOLTIP_GUILDMEMBER_ALERT, nil, VE.GetCVarAsBoolean("guildMemberNotify"), function(checked)
		VE.SetCVar("guildMemberNotify", checked)
	end)

	VE.elements.Checkbox(frame, 20, -110, 210, REMOVE_CHAT_DELAY_TEXT, OPTION_TOOLTIP_REMOVE_CHAT_DELAY, nil, VE.GetUVarAsBoolean("REMOVE_CHAT_DELAY"), function(checked)
		VE.SetUVar("REMOVE_CHAT_DELAY", checked)
	end)

	VE.elements.Checkbox(frame, 20, -140, 210, CHAT_BUBBLES_TEXT, OPTION_TOOLTIP_CHAT_BUBBLES, nil, VE.GetCVarAsBoolean("ChatBubbles"), function(checked)
		VE.SetCVar("ChatBubbles", checked)
	end)

	VE.elements.Checkbox(frame, 20, -170, 210, PARTY_CHAT_BUBBLES_TEXT, OPTION_TOOLTIP_PARTY_CHAT_BUBBLES, nil, VE.GetCVarAsBoolean("ChatBubblesParty"), function(checked)
		VE.SetCVar("ChatBubblesParty", checked)
	end)

	VE.elements.Checkbox(frame, 20, -200, 210, SHOW_LOOT_SPAM, OPTION_TOOLTIP_SHOW_LOOT_SPAM, nil, VE.GetCVarAsBoolean("showLootSpam"), function(checked)
		VE.SetCVar("showLootSpam", checked)
	end)

	VE.elements.Checkbox(frame, 20, -230, 210, PROFANITY_FILTER, OPTION_TOOLTIP_PROFANITY_FILTER, nil, VE.GetCVarAsBoolean("profanityFilter"), function(checked)
		VE.SetCVar("profanityFilter", checked)
	end)

	do
		local module = VE.getModule("ChatEnhancements")
		if module then
			VE.elements.Checkbox(frame, 20, -270, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("LastMessageOnly")
		if module then
			VE.elements.Checkbox(frame, 20, -300, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	-- Right column (Blocking & Social Features)

	VE.elements.Checkbox(frame, 270, -20, 120, BLOCK_TRADES, OPTION_TOOLTIP_BLOCK_TRADES, nil, VE.GetCVarAsBoolean("BlockTrades"), function(checked)
		VE.SetCVar("BlockTrades", checked)
	end)

	do
		local module = VE.getModule("BlockAuctionHouse")
		if module then
			VE.elements.Checkbox(frame, 270, -50, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("BlockGrouping")
		if module then
			VE.elements.Checkbox(frame, 270, -80, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("BlockMailbox")
		if module then
			VE.elements.Checkbox(frame, 270, -110, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("SoloSelfFound")
		if module then
			VE.elements.Checkbox(frame, 270, -150, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("PullBreakTimer")
		if module then
			VE.elements.Checkbox(frame, 270, -180, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("BulletinBoard")
		if module then
			VE.elements.Checkbox(frame, 270, -210, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("AuctionEnhancements")
		if module then
			VE.elements.Checkbox(frame, 270, -250, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	do
		local module = VE.getModule("MailboxEnhancements")
		if module then
			VE.elements.Checkbox(frame, 270, -280, 220, module.meta.label, module.meta.description, nil, module.enabled, function(checked)
				if checked then VE.enableModule(module.identifier) else VE.disableModule(module.identifier) end
			end, module.superWoWRequired)
		end
	end

	if VE.config.Debug then VE.dframe(frame, 0.0, 1.0, 1.0, 0.2) end

	-- Hide the frame before sending it back.
	frame:Hide()
	return frame
end
