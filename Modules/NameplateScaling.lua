local module = VE.registerModule({
	identifier = "NameplateScaling",
	meta = {
		label = "Nameplate Scaling",
		description = "Forces nameplate scale to be according to the global UI scale setting.",
	},
	plug = nil,
	superWoWRequired = false,
	config = {
		nameplate = {
			base = 115,
			notch = 25,
			height = 35,
			scaleTweak = 0.05,
		}
	},
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

local function AdjustNameplateScale(nameplate, scale)
	if not nameplate then return end
	local HealthBar = nameplate:GetChildren()
	local Border, Glow, Name, Level = nameplate:GetRegions()

	nameplate:SetWidth((module.config.nameplate.base + module.config.nameplate.notch) * scale)
	nameplate:SetHeight(module.config.nameplate.height * scale)

	HealthBar:ClearAllPoints()
	HealthBar:SetWidth(module.config.nameplate.base * scale)
	HealthBar:SetHeight(((module.config.nameplate.height / 2) - (5 * scale)) * scale)
	HealthBar:SetPoint("Bottom", nameplate, "Bottom", -(8 * scale), (2 * scale))

	Name:ClearAllPoints()
	Name:SetFont(STANDARD_TEXT_FONT, (12 * scale), "OUTLINE")
	Name:SetPoint("Bottom", nameplate, "Bottom", 0, (16 * scale) + (3 * scale))
	Name:SetShadowColor(0, 0, 0, .3)

	Level:ClearAllPoints()
	Level:SetPoint("Bottom", nameplate, "Bottom", (((module.config.nameplate.base / 2)) * scale), ((module.config.nameplate.height / 2) * scale) - (12 * scale))
	Level:SetFont(UNIT_NAME_FONT, (9 * scale), "OUTLINE")
	Level:SetShadowColor(0, 0, 0, .3)
end

module.plug = CreateFrame("Frame", module.identifier)

module.plug:SetScript("OnUpdate", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	module.data.parentCount = WorldFrame:GetNumChildren()
	if module.data.initialized < module.data.parentCount then
		local frames = {WorldFrame:GetChildren()}
		local scale = UIParent:GetScale() - module.config.nameplate.scaleTweak
		
		for i = module.data.initialized + 1, module.data.parentCount do
			nameplate = frames[i]
			if IsNamePlateFrame(nameplate) then
				AdjustNameplateScale(nameplate, scale)
				nameplate:SetScript("OnShow", function()
					AdjustNameplateScale(this, scale)
				end)
			end
		end
		
		module.data.initialized = module.data.parentCount
	end
end)
