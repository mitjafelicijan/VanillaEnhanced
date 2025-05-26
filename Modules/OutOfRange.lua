local module = VE.registerModule({
	identifier = "OutOfRange",
	meta = {
		label = "Out of Range",
		description = "Colors action buttons red when the selected ability or spell is out of range, providing a clear visual cue during combat.",
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

	VE.hooksecurefunc("ActionButton_OnUpdate", function(elapsed)
		if ( this.rangeTimer ) then
			this.rangeTimer = this.rangeTimer - elapsed
			if ( this.rangeTimer <= 0.2 ) then -- 0.1
				if ( IsActionInRange( ActionButton_GetPagedID(this)) == 0 ) then
					if not this.a then
						this.r, this.g, this.b, this.a = 1.0, 0.1, 0.1, 1.0 -- out of range colour
					end
					getglobal(this:GetName() .. "Icon"):SetVertexColor(this.r, this.g, this.b, this.a)
				elseif IsUsableAction(ActionButton_GetPagedID(this)) then
					getglobal(this:GetName() .. "Icon"):SetVertexColor(1.0, 1.0, 1.0, 1.0)
				end
				this.rangeTimer = TOOLTIP_UPDATE_TIME
			end
		end
	end, true)
end)
