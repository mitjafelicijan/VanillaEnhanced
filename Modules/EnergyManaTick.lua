local module = VE.registerModule({
	identifier = "EnergyManaTick",
	meta = {
		label = "Energy & Mana Tick",
		description = "Displays visual indicators for energy and mana ticks on the screen.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {},
	data = {
		pwidth = PlayerFrameManaBar:GetWidth(),
		pheight = PlayerFrameManaBar:GetHeight(),
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

module.plug = CreateFrame("Frame", module.identifier, PlayerFrameManaBar)
module.plug:SetAllPoints(PlayerFrameManaBar)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("UNIT_DISPLAYPOWER")
module.plug:RegisterEvent("UNIT_ENERGY")
module.plug:RegisterEvent("UNIT_MANA")

module.plug.spark = module.plug:CreateTexture(nil, "OVERLAY")
module.plug.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
module.plug.spark:SetHeight(module.data.pheight + 12)
module.plug.spark:SetWidth(module.data.pheight + 8)
module.plug.spark:SetBlendMode("ADD")
module.plug.spark:SetAlpha(0.6)

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if UnitPowerType("player") == 0 then
		this.mode = "MANA"
		-- hide if full mana and not in combat
		if (UnitMana("player") == UnitManaMax("player")) and (not UnitAffectingCombat("player")) then
			this:Hide()
		else
			this:Show()
		end
	elseif UnitPowerType("player") == 3 then
		this.mode = "ENERGY"
		this:Show()
	else
		this:Hide()
	end

	if event == "PLAYER_ENTERING_WORLD" then
		this.lastMana = UnitMana("player")
	end

	if (this.mode == "ENERGY") or ((event == "UNIT_MANA" or event == "UNIT_ENERGY") and arg1 == "player") then
		this.currentMana = UnitMana("player")
		local diff = 0
		if this.lastMana then
			diff = this.currentMana - this.lastMana
		end

		if this.mode == "MANA" and diff < 0 then
			this.target = 5
		elseif this.mode == "MANA" and diff > 0 then
			if this.max ~= 5 and diff > (this.badtick and this.badtick*1.2 or 5) then
				this.target = 2
			else
				this.badtick = diff
			end
		elseif this.mode == "ENERGY" and diff >= 0 then
			this.target = 2
		end
		this.lastMana = this.currentMana
	end
end)

module.plug:SetScript("OnUpdate", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	if this.target then
		this.start, this.max = GetTime(), this.target
		this.target = nil
	end

	if not this.start then return end

	this.current = GetTime() - this.start

	if this.current > this.max then
		this.start, this.max, this.current = GetTime(), 2, 0
	end

	local pos = (module.data.pwidth ~= "-1" and module.data.pwidth or width) * (this.current / this.max)
	if not module.data.pheight then return end
	this.spark:SetPoint("LEFT", pos-((module.data.pheight+5)/2), 0)
end)
