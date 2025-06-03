local module = VE.registerModule({
	identifier = "NearbyTargets",
	meta = {
		label = "Nearby Targets",
		description = "Tracks and displays nearby hostile targets, providing real-time health, distance, and threat information. Configurable to show up to 15 target bars.",
	},
	plug = nil,
	superWoWRequired = true,
	config = {
		bars = 15,
	},
	data = {},
})

-- Check for SuperWoW dependency.
if not VE.superWoWCheck(module) then
	VE.iprint(string.format("No SuperWoW detected. %s is NOT enabled.", module.meta.label))
	return
end

local print = VE.print
local dprint = VE.dprint
local iprint = VE.iprint

local function IsNamePlateFrame(frame)
	overlayRegion = frame:GetRegions()
	if not overlayRegion or overlayRegion:GetObjectType() ~= "Texture" or overlayRegion:GetTexture() ~= "Interface\\Tooltips\\Nameplate-Border" then
		return false
	end
	return true
end

local function GetNearbyNameplates()
	local enemies = {}
	local seenGuids = {}
	local frames = {WorldFrame:GetChildren()}
	for _, nameplate in pairs(frames) do
		if IsNamePlateFrame(nameplate) then
			local unitGUID = nameplate:GetName(1)
			if UnitExists(unitGUID) and UnitCanAttack("player", unitGUID) and not UnitIsDeadOrGhost(unitGUID) and not seenGuids[unitGUID] then
				table.insert(enemies, {
					name = UnitName(unitGUID),
					guid = unitGUID,
					health = UnitHealth(unitGUID),
					healthMax = UnitHealthMax(unitGUID),
					inRange = CheckInteractDistance(unitGUID, 2),
					distance = CheckInteractDistance(unitGUID, 2) and "Close" or "Far",
				})

				seenGuids[unitGUID] = true
			end
		end
	end

	table.sort(enemies, function(a, b)
		return a.distance < b.distance
	end)

	return enemies
end

local function UpdateNearbyEnemies()
	for idx = 1, module.config.bars do
		getglobal(string.format("NearbyTargetsFrame%s", idx)):Hide()
	end

	for idx, enemy in pairs(GetNearbyNameplates()) do
		if idx <= module.config.bars then
			local frame = string.format("NearbyTargetsFrame%s", idx)
			local nameText = string.format("NearbyTargetsFrame%sNameText", idx)
			local healthStatus = string.format("NearbyTargetsFrame%sHealthBar", idx)
			local inRange = string.format("NearbyTargetsFrame%sInRange", idx)
			getglobal(frame).unit = enemy.guid
			-- getglobal(nameText):SetText(string.format("%s (%s)", enemy.name, enemy.distance))
			getglobal(nameText):SetText(enemy.name)
			getglobal(healthStatus):SetStatusBarColor(0.9, 0.0, 0.0)
			getglobal(healthStatus):SetMinMaxValues(0, enemy.healthMax)
			getglobal(healthStatus):SetValue(enemy.health)

			if enemy.inRange then
				getglobal(inRange):Show()
			else
				getglobal(inRange):Hide()
			end

			getglobal(frame):Show()
		end
	end
end

SLASH_NEARBYENEMIES1 = "/nearenemies"
SLASH_NEARBYENEMIES2 = "/ne"
SlashCmdList["NEARBYENEMIES"] = function()
	if VE.isModuleEnabled(module.identifier) then
		VE.disableModule(module.identifier)
	else
		VE.enableModule(module.identifier)
	end
	ConsoleExec("reloadui")
end

function NearbyEnemyFrame_OnClick()
	if not UnitExists(this.unit) then return nil end
	TargetUnit(this.unit)
end

function NearbyEnemyFrame_OnLoad()
	this:SetScript("OnMouseDown", function()
		if IsControlKeyDown() and IsAltKeyDown() then
			NearbyTargets:StartMoving()
		end
	end)

	this:SetScript("OnMouseUp", function()
		NearbyTargets:StopMovingOrSizing()
	end)

	this:SetScript("OnHide", function()
		NearbyTargets:StopMovingOrSizing()
	end)
end

function NearbyTargets_OnLoad()
	this:RegisterEvent("UNIT_AURA")
	this:RegisterEvent("UNIT_HEALTH")
	this:RegisterEvent("UNIT_MAXHEALTH")
	this:RegisterEvent("UNIT_MANA")
	this:RegisterEvent("UNIT_RAGE")
	this:RegisterEvent("UNIT_FOCUS")
	this:RegisterEvent("UNIT_ENERGY")
	this:RegisterEvent("UNIT_HAPPINESS")
	this:RegisterEvent("UNIT_MAXMANA")
	this:RegisterEvent("UNIT_MAXRAGE")
	this:RegisterEvent("UNIT_MAXFOCUS")
	this:RegisterEvent("UNIT_MAXENERGY")
	this:RegisterEvent("UNIT_MAXHAPPINESS")
	this:RegisterEvent("UNIT_DISPLAYPOWER")
	this:RegisterEvent("PLAYER_TARGET_CHANGED")
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function NearbyTargets_OnEvent()
	if not VE.isModuleEnabled(module.identifier) then
		this:UnregisterAllEvents()
		return
	end

	UpdateNearbyEnemies()
	this:Show()
end
