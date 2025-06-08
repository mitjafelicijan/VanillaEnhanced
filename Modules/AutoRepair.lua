local module = VE.registerModule({
	identifier = "AutoRepair",
	meta = {
		label = "Automatic Gear Repair",
		description = "Automatically initiates gear repairs upon interacting with a merchant.",
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
module.plug:RegisterEvent("MERCHANT_SHOW")

module.plug:SetScript("OnEvent", function()
	if not VE.isModuleEnabled(module.identifier) then return end

	-- Always open all bags.
	OpenAllBags()

	if IsShiftKeyDown() then return end
	if CanMerchantRepair() then
		local repairCost, canRepair = GetRepairAllCost()
		if repairCost > 0 and GetMoney() >= repairCost then
			RepairAllItems()
			VE.print(string.format("|cff00ff00Gear repaired: |cffffffff%s", VE.getCoinText(repairCost)))
		end
	end
end)
