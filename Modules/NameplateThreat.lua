local module = VE.registerModule({
	identifier = "NameplateThreat",
	meta = {
		label = "Nameplate Threat",
		description = "Colors nameplates of targets that are attacking the player in green.",
	},
	plug = nil,
	superWoWRequired = true,
	config = {},
	data = {
		initialized = 0,
		parentCount = 0,
	},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local function IsNamePlateFrame(frame)
	overlayRegion = frame:GetRegions()
	if not overlayRegion or overlayRegion:GetObjectType() ~= "Texture" or overlayRegion:GetTexture() ~= "Interface\\Tooltips\\Nameplate-Border" then
		return false
	end
	return true
end

local function GetHealthBarFromNameplate(frame)
	if not IsNamePlateFrame(frame) then return nil end
	local healthBar = frame:GetChildren()
	if healthBar and healthBar:IsObjectType("StatusBar") then
		return healthBar
	end
	return nil
end

module.plug = CreateFrame("Frame", module.identifier)
module.plug:RegisterEvent("PLAYER_ENTERING_WORLD")
module.plug:RegisterEvent("UNIT_CASTEVENT")

module.plug:SetScript("OnUpdate", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	module.data.parentCount = WorldFrame:GetNumChildren()
	if module.data.initialized < module.data.parentCount then
		local frames = {WorldFrame:GetChildren()}

		for i = module.data.initialized + 1, module.data.parentCount do
			nameplate = frames[i]
			if IsNamePlateFrame(nameplate) then
				nameplate:SetScript("OnUpdate", function()
					local unit = this:GetName(1)
					if not UnitExists(unit) or not UnitAffectingCombat(unit) then return end
					if UnitIsUnit(unit.."target", "player") then
						local healthBar = GetHealthBarFromNameplate(this)
						if healthBar then healthBar:SetStatusBarColor(0, 1, 0) end
					end
				end)

			end
		end

		module.data.initialized = module.data.parentCount
	end
end)
