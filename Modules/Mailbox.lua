local module = VE.registerModule({
	identifier = "Mailbox",
	meta = {
		label = "Mailbox Enhancements",
		description = "Makes mailboxes a bit more usable by adding Shift+Click to automatically recieve attachements in mail into your bags.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		multipleAttachments = false,
	},
	data = {
		page = 0,
		prevPageOnClick = nil,
		nextPageOnClick = nil,
		originalSendMailHandler = nil,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("MAIL_SHOW")
module.plug:RegisterEvent("MAIL_CLOSED")
module.plug:RegisterEvent("MAIL_SEND_SUCCESS")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if event == "MAIL_SHOW" then

		if not SendMailScrollFrame.attachments and module.config.multipleAttachments then
			SendMailScrollFrame:SetHeight(150)
			SendMailScrollChildFrame:SetHeight(130)

			SendMailFrame.attachments = CreateFrame("Frame", "SendMailScrollFrameAttachments", SendMailFrame)
			SendMailFrame.attachments:SetPoint("TopLeft", SendMailFrame, "TopLeft", 20, -600)
			SendMailFrame.attachments:SetWidth(SendMailScrollFrame:GetWidth() + 25)
			SendMailFrame.attachments:SetHeight(105)
			SendMailFrame.attachments:SetFrameLevel(4)

			SendMailFrame.attachmentsBackground = CreateFrame("Frame", nil, SendMailFrame)
			SendMailFrame.attachmentsBackground:SetPoint("TopLeft", SendMailFrame, "TopLeft", 18, -250)
			SendMailFrame.attachmentsBackground:SetWidth(SendMailScrollFrame:GetWidth() + 30)
			SendMailFrame.attachmentsBackground:SetHeight(110)
			SendMailFrame.attachmentsBackground:SetFrameLevel(5)
			VE.dframe(SendMailFrame.attachmentsBackground, 1, 0, 0, 1)

			SendMailFrame.horizontalBar = CreateFrame("Frame", nil, SendMailFrame)
			SendMailFrame.horizontalBar:SetPoint("TopLeft", SendMailFrame, "TopLeft", 16, -244)
			SendMailFrame.horizontalBar:SetWidth(SendMailScrollFrame:GetWidth() + 35)
			SendMailFrame.horizontalBar:SetHeight(16)
			SendMailFrame.horizontalBar:SetFrameLevel(6)
			-- VE.dframe(SendMailFrame.horizontalBar, 1, 0, 0, 1)

			SendMailFrame.horizontalBar.left = SendMailFrame.horizontalBar:CreateTexture("MailHorizontalBarLeft", "ARTWORK")
			SendMailFrame.horizontalBar.left:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
			SendMailFrame.horizontalBar.left:SetPoint("TopLeft", SendMailFrame.horizontalBar, "TopLeft")
			SendMailFrame.horizontalBar.left:SetTexCoord(0, 1, 0, .25)
			SendMailFrame.horizontalBar.left:SetWidth(256)
			SendMailFrame.horizontalBar.left:SetHeight(16)

			SendMailFrame.horizontalBar.right = SendMailFrame.horizontalBar:CreateTexture("MailHorizontalBarLeft", "ARTWORK")
			SendMailFrame.horizontalBar.right:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
			SendMailFrame.horizontalBar.right:SetPoint("TopRight", SendMailFrame.horizontalBar, "TopRight")
			SendMailFrame.horizontalBar.right:SetTexCoord(0, .29296875, .25, .5)
			SendMailFrame.horizontalBar.right:SetWidth(75)
			SendMailFrame.horizontalBar.right:SetHeight(16)

			VE.dframe(SendMailFrame.attachments, 0, 1, 0, 1)
		end

		-- Sets last recipient as current one.
		if VanillaEnhancedData["LastMailRecipient"] ~= nil then
			SendMailNameEditBox:SetText(VanillaEnhancedData["LastMailRecipient"])
			SendMailNameEditBox:ClearFocus()
		end

		-- Save original send mail handler.
		if module.data.originalSendMailHandler == nil then
			module.data.originalSendMailHandler = SendMailMailButton:GetScript("OnClick")
		end

		-- Save last recipient.
		SendMailMailButton:SetScript("OnClick", function(self)
			VanillaEnhancedData["LastMailRecipient"] = SendMailNameEditBox:GetText()
			if module.data.originalSendMailHandler then module.data.originalSendMailHandler(self) end
		end)

		module.data.prevPageOnClick = getglobal("InboxPrevPageButton"):GetScript("OnClick")
		getglobal("InboxPrevPageButton"):SetScript("OnClick", function(self, button)
			module.data.prevPageOnClick(self, button)
			module.data.page = module.data.page - 1
		end)

		module.data.nextPageOnClick = getglobal("InboxNextPageButton"):GetScript("OnClick")
		getglobal("InboxNextPageButton"):SetScript("OnClick", function(self, button)
			module.data.nextPageOnClick(self, button)
			module.data.page = module.data.page + 1
		end)

		for idx = 1, 7 do
			local button = getglobal("MailItem" .. idx .. "Button")
			local originalOnClick = button:GetScript("OnClick")
			button.idx = idx
			button:SetScript("OnClick", function(self, button)
				if IsShiftKeyDown() then
					local mailIndex = this.idx + (module.data.page * 7)
					GetInboxText(mailIndex)
					TakeInboxMoney(mailIndex)
					TakeInboxItem(mailIndex)
					DeleteInboxItem(mailIndex)
				else
					originalOnClick(self, button)
				end
			end)
		end
	end

	if event == "MAIL_SEND_SUCCESS" then
		if VanillaEnhancedData["LastMailRecipient"] ~= nil then
			SendMailNameEditBox:SetText(VanillaEnhancedData["LastMailRecipient"])
			SendMailNameEditBox:ClearFocus()
		end
	end

	if event == "MAIL_CLOSED" then
		getglobal("InboxPrevPageButton"):SetScript("OnClick", module.data.prevPageOnClick)
		getglobal("InboxNextPageButton"):SetScript("OnClick", module.data.nextPageOnClick)
	end
end)
